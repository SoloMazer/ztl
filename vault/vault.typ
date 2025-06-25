
// Define your colorscheme
// I'm using Gruvbox
#let fg = rgb("3c3836")
#let bg = rgb("fbf1c7")
#let red = rgb("cc241d")
#let green = rgb("98971a")
#let yellow = rgb("d79921")
#let blue = rgb("458588")
#let purple = rgb("b16286")
#let aqua = rgb("689d6a")
// toggle for Dark/Light mode
#let dark-mode = false
#if dark-mode {
  fg = rgb("ebdbb2")
  bg = rgb("282828")
}

#import "@preview/basalt-lib:1.0.0": new-vault, xlink, as-branch
#let vault = new-vault(
  note-paths: csv("./vault.csv").flatten(),
  include-from-vault: path => include path,
  formatters: (
  
    (body, ..sink) => {
      set text(fill: fg)
      set page(fill: bg)
      show heading.where(level: 1): set text(fill: blue)
      show heading.where(level: 2): set text(fill: purple)
      show heading.where(level: 3): set text(fill: yellow)
      body
    },
    
  )
)

#import "@preview/theorion:0.3.3": *
#import cosmos.clouds: *
#show: show-theorion

// #let theorem = theorem.with(
//   fill: blue.transparentize(50%),
//   radius: 10pt
// )

// #let (theorem-counter, theorem-box, theorem, show-theorem) = make-frame(
//   "theorem",
//   theorion-i18n-map.at("theorem"),
//   inherited-levels: 2,
//   render: render-fn.with(fill: red.transparentize(85%)),
// )


// #let definition = definition.with(
//   fill: purple.transparentize(50%),
//   radius: 10pt
// )

// #let corollary = corollary.with(
//   fill: yellow.transparentize(50%),
//   radius: 10pt
// )

