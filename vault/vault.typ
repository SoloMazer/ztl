#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch

#let vault = new-vault(
  note-paths: csv("note-paths.csv").flatten(),
  include-from-vault: path => include path,
  formatters: (),
)
