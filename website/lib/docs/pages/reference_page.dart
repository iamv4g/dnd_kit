import 'package:jaspr/jaspr.dart';

import '../../data/site_data.dart';
import '../doc_components.dart';
import '../docs_shell.dart';

/// `/docs/reference`
class ReferencePage extends StatelessComponent {
  const ReferencePage({super.key});

  @override
  Component build(BuildContext context) {
    return DocsShell(
      slug: 'reference',
      toc: const [
        (id: 'api', label: 'API docs'),
        (id: 'changelog', label: 'Changelog'),
        (id: 'source', label: 'Source & issues'),
      ],
      body: [
        docLead(
          'The full generated API reference lives on pub.dev. Browse the '
          'package you depend on, or read the engine for the shared contracts.',
        ),
        docSection(
          id: 'api',
          title: 'API docs',
          children: [
            nextSteps([
              NextStep(
                label: 'dnd_kit_flutter',
                desc: 'Flutter adapter — widgets, sensors, overlays, sortable.',
                href: _doc('dnd_kit_flutter'),
                external: true,
              ),
              NextStep(
                label: 'dnd_kit_jaspr',
                desc:
                    'Jaspr (web) adapter — components over the shared engine.',
                href: _doc('dnd_kit_jaspr'),
                external: true,
              ),
              NextStep(
                label: 'dnd_kit',
                desc: 'Shared engine — collision, modifiers, sortable math.',
                href: _doc('dnd_kit'),
                external: true,
              ),
            ]),
          ],
        ),
        docSection(
          id: 'changelog',
          title: 'Changelog',
          children: [
            docProse(
              'Each package publishes its changelog on pub.dev. The family '
              'releases in lockstep — engine first, then the adapters.',
            ),
            nextSteps([
              NextStep(
                label: 'dnd_kit_flutter changelog',
                desc: 'Release notes for the Flutter adapter.',
                href: _changelog('dnd_kit_flutter'),
                external: true,
              ),
              NextStep(
                label: 'dnd_kit_jaspr changelog',
                desc: 'Release notes for the web adapter.',
                href: _changelog('dnd_kit_jaspr'),
                external: true,
              ),
              NextStep(
                label: 'dnd_kit changelog',
                desc: 'Release notes for the shared engine.',
                href: _changelog('dnd_kit'),
                external: true,
              ),
            ]),
          ],
        ),
        docSection(
          id: 'source',
          title: 'Source & issues',
          children: [
            docProse(
              'The whole family lives in one repository. File issues and read '
              'the examples there.',
            ),
            nextSteps([
              NextStep(
                label: 'GitHub repository',
                desc: 'Source, examples, and issue tracker.',
                href: SiteLinks.github,
                external: true,
              ),
            ]),
          ],
        ),
      ],
    );
  }
}

String _doc(String pkg) => 'https://pub.dev/documentation/$pkg/latest/';
String _changelog(String pkg) => 'https://pub.dev/packages/$pkg/changelog';
