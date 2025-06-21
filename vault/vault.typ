#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch
#import "./snippets.typ"

#let vault = new-vault(
  note-paths: csv("./vault.csv").flatten(),
  include-from-vault: path => include path,
  formatters: ()
)
