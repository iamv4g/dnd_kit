import 'package:jaspr/jaspr.dart';

import '../doc_components.dart';
import '../docs_nav.dart';
import '../docs_shell.dart';

/// `/docs/install`
class InstallPage extends StatelessComponent {
  const InstallPage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'install',
      toc: const [
        (id: 'flutter', label: 'Flutter'),
        (id: 'jaspr', label: 'Jaspr (web)'),
        (id: 'engine', label: 'Shared engine'),
      ],
      body: [
        docLead(
          'Add one package for your platform. Each adapter depends on the '
          'shared engine for you — you only depend on dnd_kit directly when '
          'building a custom adapter or testing the drag math.',
        ),
        youWillLearn(const [
          'Which package to add for Flutter, Jaspr, or a custom adapter.',
          'The current stable version line of the family.',
        ]),
        docSection(
          id: 'flutter',
          title: 'Flutter',
          children: [
            docProseRich([
              docText('Add '),
              inlineCode('dnd_kit_flutter'),
              docText(' to a Flutter app:'),
            ]),
            docCodeBlock(
              'pubspec.yaml',
              'dependencies:\n  dnd_kit_flutter: ^0.4.0',
            ),
          ],
        ),
        docSection(
          id: 'jaspr',
          title: 'Jaspr (web)',
          children: [
            docProseRich([
              docText('Add '),
              inlineCode('dnd_kit_jaspr'),
              docText(' to a Jaspr app. It needs no Flutter SDK:'),
            ]),
            docCodeBlock(
              'pubspec.yaml',
              'dependencies:\n  dnd_kit_jaspr: ^0.4.0',
            ),
          ],
        ),
        docSection(
          id: 'engine',
          title: 'Shared engine',
          children: [
            docProseRich([
              docText('Depend on '),
              inlineCode('dnd_kit'),
              docText(
                ' directly only for custom adapters or contract tests — the '
                'adapters already bundle it:',
              ),
            ]),
            docCodeBlock('pubspec.yaml', 'dependencies:\n  dnd_kit: ^0.4.0'),
          ],
        ),
        nextSteps([
          NextStep(
            label: 'Quickstart',
            desc: 'Wire your first drag-and-drop in three steps.',
            href: docHref('quickstart'),
          ),
        ]),
      ],
    );
  }
}
