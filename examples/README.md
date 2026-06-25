# Examples

Example apps are added story by story as behavior becomes real. The demo
catalog, naming, layout, and Flutter/Jaspr parity target are defined in the
[Examples Standard](../docs/product/examples-standard.md).

## Two galleries

`examples/` holds exactly two projects:

- `examples/flutter_example_gallery` — the Flutter gallery.
- `examples/jaspr_example_gallery` — the Jaspr gallery.

Both expose the canonical demo catalog (`basic`, `collision`, `sensors`,
`modifiers`, `auto-scroll`, `sortable`, `multi-container`, `accessibility`).
Each demo lives under `lib/demos/` as a single `<slug>_demo.dart` file, or as a
`<slug>/` subfolder when it needs several files. Demos still missing on an
adapter are tracked parity gaps, not permitted differences — see the standard
for the current matrix.

> Migration note: the Flutter side currently still uses `example_gallery` plus
> the standalone packages `basic_drag_drop`, `kanban_board`, and
> `multi_container_sortable`. The standard folds these into
> `flutter_example_gallery/lib/demos/`; that rename and migration is follow-up
> work.
