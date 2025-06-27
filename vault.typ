// Commented out is my personal config
// Use this as a refernce for yours.
// Edit this file to your liking.
// Refer to basalt-lib formatting guide for more info.
//
// Also ignore the './vault.csv not found' warning.
// It will be generated during `ztl init`.

// Define your colorscheme
// // I'm using Gruvbox
// #let fg = rgb("282828")
// #let bg = rgb("fbf1c7")
// #let red = rgb("cc241d")
// #let green = rgb("98971a")
// #let yellow = rgb("d79921")
// #let blue = rgb("458588")
// #let purple = rgb("b16286")
// #let aqua = rgb("689d6a")
// #let orange = rgb("d65d0e")
// #let gray = rgb("928374")

// // toggle for Dark/Light mode
// #let dark-mode = false
// #if dark-mode {
//   fg = rgb("ebdbb2")
//   bg = rgb("282828")
// }

// // Import and customize the theorion package
// #import "@preview/theorion:0.3.3": *
// #import cosmos.clouds: *

// #let theorem = theorem.with(
//   fill: blue.transparentize(40%),
//   stroke: none,
//   radius: 7pt
// )
// #let definition = definition.with(
//   fill: purple.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let corollary = corollary.with(
//   fill: green.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let lemma = lemma.with(
//   fill: aqua.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let proposition = proposition.with(
//   fill: yellow.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let axiom = axiom.with(
//   fill: orange.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let postulate = postulate.with(
//   fill: red.transparentize(50%),
//   stroke: none,
//   radius: 7pt
// )
// #let tip = tip-box.with(
//   fill: green
// )
// #let important = important-box.with(
//   fill: purple
// )
// #let warning = warning-box.with(
//   fill: red
// )
// #let remark = remark.with(
//   fill: blue
// )
// #let note = note-box.with(
//   fill: aqua
// )
// #let caution = caution-box.with(
//   fill: orange
// )

#import "@preview/basalt-lib:1.0.0": as-branch, new-vault, xlink
#let vault = new-vault(
  note-paths: csv("./vault.csv").flatten(),
  include-from-vault: path => include path,
  formatters: (
    // (body, ..sink) => {
    //   set text(
    //     fill: fg,
    //     font: "Libertinus Serif",
    //     size: 12pt
    //   )
    //   set page(fill: bg)
    //   show heading.where(level: 1): set text(fill: blue)
    //   show heading.where(level: 2): set text(fill: purple)
    //   show heading.where(level: 3): set text(fill: yellow)
    //   show: show-theorion
    //   body
    // },
  ),
)
