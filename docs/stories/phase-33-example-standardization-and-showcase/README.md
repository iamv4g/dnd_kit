# Phase 33 - Example Standardization And Showcase Page

The documentation section (Phase 32) gave the website a concept taxonomy, but
the example apps did not match it: the Flutter and Jaspr galleries shared almost
no demos and used different structures. Before the website can host a showcase
page presenting Flutter and Jaspr side by side, the examples must converge on
one catalog.

This phase standardizes the examples, then builds the showcase page on top.

## Principle

- The canonical demo catalog mirrors the docs concept taxonomy, so examples,
  docs, and the showcase share one vocabulary.
- `examples/` holds exactly two gallery projects (`flutter_example_gallery`,
  `jaspr_example_gallery`); every demo lives under `lib/demos/` as a file or a
  subfolder. The standalone Flutter packages fold into the Flutter gallery.
- A spec lands before demo code, so the parity target is agreed first.

## Delivery Sequence

| Story | Scope | Decision |
| --- | --- | --- |
| **US-083** | Define the examples standard: canonical demo catalog, naming/structure conventions, and the Flutter/Jaspr parity matrix (no demo code) | No ADR (product contract doc under the existing examples decisions) |
| US-084+ | Rename `example_gallery` → `flutter_example_gallery`, fold the standalone packages into `lib/demos/`, and fill the parity gaps so both galleries expose the full catalog | TBD |
| US-085+ | Add the website showcase page presenting Flutter and Jaspr demos | TBD (Flutter-on-web delivery decided in that story) |

US-084+ and the showcase story are placeholders; only US-083 is in scope now.

## Validation Ladder

- US-083 is a documentation-only story: `docs/product/examples-standard.md`
  defines the catalog and parity matrix, and `examples/README.md` points to it.
- No build or test change is expected; the standard does not touch demo code.
