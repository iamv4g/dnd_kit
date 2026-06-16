import 'dart:convert';
import 'dart:io';

const _globalFallbackFiles = {
  'analysis_options.yaml',
  'pubspec.lock',
  'pubspec.yaml',
};

const _docsOnlyBasenames = {
  'changelog.md',
  'example.md',
  'license',
  'license.md',
  'readme.md',
};

Future<void> main(List<String> args) async {
  final cli = _CliOptions.parse(args);
  final root = _normalizePath(Directory.current.absolute.path);
  final changedFiles = cli.changedFiles ?? await _gitDiffFiles(cli.diffRef);

  stdout.writeln(
    '[affected_validate] mode=${cli.mode} diff=${cli.diffRef} '
    'changed=${changedFiles.length}',
  );

  if (changedFiles.isEmpty) {
    stdout.writeln(
      '[affected_validate] No changed files detected. Nothing to verify.',
    );
    return;
  }

  final workspace = await _WorkspaceState.load(root);
  final plan = workspace.plan(changedFiles);

  _printPlan(plan);

  if (cli.mode == 'plan') {
    return;
  }

  if (plan.requiresFullValidation) {
    stdout.writeln(
      '[affected_validate] Falling back to full workspace validation because '
      '${plan.fullValidationReasons.join(', ')} changed.',
    );
    await _runFull(cli.mode);
    return;
  }

  switch (cli.mode) {
    case 'analyze':
      await _runAnalyze(plan.selectedPackages);
      return;
    case 'test':
      await _runTests(plan.selectedPackages);
      return;
    case 'validate':
      await _runChangedFormat(changedFiles);
      await _runAnalyze(plan.selectedPackages);
      await _runTests(plan.selectedPackages);
      return;
    default:
      throw StateError('Unsupported mode: ${cli.mode}');
  }
}

void _printPlan(_SelectionPlan plan) {
  stdout.writeln(
    '[affected_validate] code packages: '
    '${plan.codeChangedPackages.isEmpty ? '(none)' : plan.codeChangedPackages.join(', ')}',
  );
  stdout.writeln(
    '[affected_validate] selected packages: '
    '${plan.selectedPackages.isEmpty ? '(none)' : plan.selectedPackages.join(', ')}',
  );

  if (plan.ignoredFiles.isNotEmpty) {
    stdout.writeln(
      '[affected_validate] docs-only / ignored package files: '
      '${plan.ignoredFiles.join(', ')}',
    );
  }
}

Future<void> _runFull(String mode) async {
  switch (mode) {
    case 'analyze':
      await _runCommand('dart', ['run', 'melos', 'run', 'analyze']);
      return;
    case 'test':
      await _runCommand('dart', ['test', 'packages/dnd_kit_core']);
      await _runCommand('dart', ['test', 'packages/dnd_kit_jaspr']);
      await _runCommand('flutter', ['test', 'packages/dnd_kit_flutter']);
      await _runCommand('flutter', ['test', 'examples/kanban_board']);
      await _runCommand('flutter', ['test', 'examples/multi_container_sortable']);
      await _runCommand('flutter', ['test', 'examples/example_gallery']);
      return;
    case 'validate':
      await _runCommand('dart', ['run', 'melos', 'run', 'validate:full']);
      return;
    default:
      throw StateError('Unsupported full-run mode: $mode');
  }
}

Future<void> _runChangedFormat(List<String> changedFiles) async {
  final dartFiles = changedFiles
      .where((path) => path.endsWith('.dart'))
      .where((path) => File(path).existsSync())
      .toList()
    ..sort();

  if (dartFiles.isEmpty) {
    stdout.writeln('[affected_validate] No changed Dart files to format-check.');
    return;
  }

  await _runCommand('dart', [
    'format',
    '--set-exit-if-changed',
    ...dartFiles,
  ]);
}

Future<void> _runAnalyze(List<String> packages) async {
  if (packages.isEmpty) {
    stdout.writeln('[affected_validate] No affected packages to analyze.');
    return;
  }

  await _runMelosExec(
    packages,
    [
      'exec',
      '--concurrency',
      '1',
      '--',
      'dart analyze',
    ],
  );
}

Future<void> _runTests(List<String> packages) async {
  if (packages.isEmpty) {
    stdout.writeln('[affected_validate] No affected packages to test.');
    return;
  }

  await _runMelosExec(
    packages,
    [
      'exec',
      '--concurrency',
      '1',
      '--no-flutter',
      '--dir-exists',
      'test',
      '--',
      'dart test',
    ],
  );
  await _runMelosExec(
    packages,
    [
      'exec',
      '--concurrency',
      '1',
      '--flutter',
      '--dir-exists',
      'test',
      '--',
      'flutter test',
    ],
  );
}

Future<void> _runMelosExec(List<String> packages, List<String> args) async {
  final subcommand = args.first;
  final tailArgs = args.sublist(1);
  final scopeArgs = <String>[];
  for (final package in packages) {
    scopeArgs.addAll(['--scope', package]);
  }

  await _runCommand('dart', ['run', 'melos', subcommand, ...scopeArgs, ...tailArgs]);
}

Future<List<String>> _gitDiffFiles(String diffRef) async {
  final trackedResult = await Process.run('git', ['diff', '--name-only', diffRef, '--']);
  if (trackedResult.exitCode != 0) {
    stderr.writeln(trackedResult.stdout);
    stderr.writeln(trackedResult.stderr);
    exit(trackedResult.exitCode);
  }

  final untrackedResult = await Process.run('git', ['ls-files', '--others', '--exclude-standard']);
  if (untrackedResult.exitCode != 0) {
    stderr.writeln(untrackedResult.stdout);
    stderr.writeln(untrackedResult.stderr);
    exit(untrackedResult.exitCode);
  }

  final changedFiles = <String>{};
  for (final output in [
    trackedResult.stdout as String,
    untrackedResult.stdout as String,
  ]) {
    changedFiles.addAll(
      LineSplitter.split(output).map(_normalizePath).where((line) => line.isNotEmpty),
    );
  }

  return changedFiles.toList()..sort();
}

Future<void> _runCommand(String executable, List<String> args) async {
  stdout.writeln('\$ $executable ${args.join(' ')}');

  final process = await Process.start(executable, args);
  await stdout.addStream(process.stdout);
  await stderr.addStream(process.stderr);

  final exitCode = await process.exitCode;
  if (exitCode != 0) {
    exit(exitCode);
  }
}

String _normalizePath(String path) {
  return path.replaceAll('\\', '/');
}

class _CliOptions {
  _CliOptions({
    required this.mode,
    required this.diffRef,
    required this.changedFiles,
  });

  factory _CliOptions.parse(List<String> args) {
    var mode = 'validate';
    String? diffRef;
    List<String>? changedFiles;

    for (final arg in args) {
      if (!arg.startsWith('--')) {
        mode = arg;
        continue;
      }

      if (arg.startsWith('--diff=')) {
        diffRef = arg.substring('--diff='.length).trim();
        continue;
      }

      if (arg.startsWith('--files=')) {
        final value = arg.substring('--files='.length);
        changedFiles = value
            .split(',')
            .map((file) => _normalizePath(file.trim()))
            .where((file) => file.isNotEmpty)
            .toList()
          ..sort();
        continue;
      }

      throw ArgumentError('Unsupported argument: $arg');
    }

    if (!{'analyze', 'plan', 'test', 'validate'}.contains(mode)) {
      throw ArgumentError('Unsupported mode: $mode');
    }

    return _CliOptions(
      mode: mode,
      diffRef: diffRef ?? Platform.environment['MELOS_DIFF']?.trim() ?? 'HEAD',
      changedFiles: changedFiles,
    );
  }

  final List<String>? changedFiles;
  final String diffRef;
  final String mode;
}

class _PackageInfo {
  _PackageInfo({
    required this.name,
    required this.relativeLocation,
  });

  factory _PackageInfo.fromJson(Map<String, Object?> json, String rootPath) {
    final location = _normalizePath(json['location']! as String);
    final relativeLocation =
        location.startsWith('$rootPath/') ? location.substring(rootPath.length + 1) : location;

    return _PackageInfo(
      name: json['name']! as String,
      relativeLocation: relativeLocation,
    );
  }

  final String name;
  final String relativeLocation;
}

class _SelectionPlan {
  _SelectionPlan({
    required this.codeChangedPackages,
    required this.fullValidationReasons,
    required this.ignoredFiles,
    required this.selectedPackages,
  });

  final List<String> codeChangedPackages;
  final List<String> fullValidationReasons;
  final List<String> ignoredFiles;
  final List<String> selectedPackages;

  bool get requiresFullValidation => fullValidationReasons.isNotEmpty;
}

class _WorkspaceState {
  _WorkspaceState({
    required this.packages,
    required this.reverseDependents,
  }) : _packagesByLongestPath = [...packages]..sort(
            (left, right) => right.relativeLocation.length.compareTo(left.relativeLocation.length),
          );

  static Future<_WorkspaceState> load(String rootPath) async {
    final packageResult = await Process.run('dart', ['run', 'melos', 'list', '--json']);
    if (packageResult.exitCode != 0) {
      stderr.writeln(packageResult.stdout);
      stderr.writeln(packageResult.stderr);
      exit(packageResult.exitCode);
    }

    final graphResult = await Process.run('dart', ['run', 'melos', 'list', '--graph']);
    if (graphResult.exitCode != 0) {
      stderr.writeln(graphResult.stdout);
      stderr.writeln(graphResult.stderr);
      exit(graphResult.exitCode);
    }

    final packageJson = jsonDecode(packageResult.stdout as String) as List<Object?>;
    final graphJson = jsonDecode(graphResult.stdout as String) as Map<String, Object?>;

    final packages = packageJson
        .cast<Map<String, Object?>>()
        .map((json) => _PackageInfo.fromJson(json, rootPath))
        .toList();

    final reverseDependents = <String, Set<String>>{};
    for (final package in packages) {
      reverseDependents.putIfAbsent(package.name, () => <String>{});
    }

    graphJson.forEach((package, dependencies) {
      for (final dependency in (dependencies as List<Object?>).cast<String>()) {
        reverseDependents.putIfAbsent(dependency, () => <String>{}).add(package);
      }
    });

    return _WorkspaceState(
      packages: packages,
      reverseDependents: reverseDependents,
    );
  }

  final List<_PackageInfo> _packagesByLongestPath;
  final List<_PackageInfo> packages;
  final Map<String, Set<String>> reverseDependents;

  _SelectionPlan plan(List<String> changedFiles) {
    final codeChangedPackages = <String>{};
    final fullValidationReasons = <String>{};
    final ignoredFiles = <String>[];

    for (final changedFile in changedFiles) {
      if (_requiresFullValidation(changedFile)) {
        fullValidationReasons.add(changedFile);
        continue;
      }

      final package = _packageForFile(changedFile);
      if (package == null) {
        continue;
      }

      final relativeWithinPackage =
          changedFile.substring(package.relativeLocation.length + 1).toLowerCase();

      if (_isDocsOnlyPackageFile(relativeWithinPackage)) {
        ignoredFiles.add(changedFile);
        continue;
      }

      codeChangedPackages.add(package.name);
    }

    final selectedPackages = _expandDependents(codeChangedPackages);

    return _SelectionPlan(
      codeChangedPackages: codeChangedPackages.toList()..sort(),
      fullValidationReasons: fullValidationReasons.toList()..sort(),
      ignoredFiles: ignoredFiles..sort(),
      selectedPackages: selectedPackages.toList()..sort(),
    );
  }

  Set<String> _expandDependents(Set<String> seeds) {
    final queue = List<String>.from(seeds);
    final seen = <String>{...seeds};

    while (queue.isNotEmpty) {
      final current = queue.removeLast();
      for (final dependent in reverseDependents[current] ?? const <String>{}) {
        if (seen.add(dependent)) {
          queue.add(dependent);
        }
      }
    }

    return seen;
  }

  _PackageInfo? _packageForFile(String changedFile) {
    for (final package in _packagesByLongestPath) {
      if (changedFile == package.relativeLocation ||
          changedFile.startsWith('${package.relativeLocation}/')) {
        return package;
      }
    }

    return null;
  }

  bool _isDocsOnlyPackageFile(String relativePath) {
    if (relativePath.isEmpty) {
      return false;
    }

    final segments = relativePath.split('/');
    if (segments.first == 'doc' || segments.first == 'docs') {
      return true;
    }

    return _docsOnlyBasenames.contains(segments.last);
  }

  bool _requiresFullValidation(String changedFile) {
    if (_globalFallbackFiles.contains(changedFile)) {
      return true;
    }

    return changedFile.startsWith('.github/workflows/') ||
        changedFile.startsWith('scripts/') ||
        changedFile.startsWith('tool/');
  }
}
