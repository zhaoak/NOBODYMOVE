# No Defenestration Allowed

This document explains the UI windowing system present in NOBODY MOVE.

The components of the windowing/UI system are as follows:

## uiWindow (uiWindow.lua)

A defined area of the screen (a window, if you will) that can be drawn to and can contain both
`uiElement`s and other `uiWindow`s as children.

Children are stored in an int-keyed table called `contains`, where the key of each child represents
the order the children are in in terms of navigating UI with controller inputs.
*NOTE*: Any children's `originX`/`originY` values are specified *relative to their parents origin*;
that is, they use their parent window's `originX`/`originY` as (0, 0).

A uiWindow will handle resizing itself and the elements/subwindows inside it in response
to game window size/resolution changes.

A `uiWindow` and `uiElement` only render if its parent's `shouldRender` property is true.

A window's rendering function is always called before its children's rendering functions.
Since elements cannot contain windows, this means that elements will always visually render on top of windows.

### `uiWindow` exclusive properties

- `contains`(tbl, int-keyed): An ordered list of a `uiWindow`s children
- `scrollable`(bool, default false): Whether the window's contents can be scrolled
- `currentScrollOffset`(num): How many pixels down the window is currently scrolled
- `create`(func): "Creation" function, see "How to use" section
- `draw`(func): rendering function for window
- `name`(string): Used as key for table in `uiWindowList`

## uiElement (uiElements.lua)

A specific type of interactable UI element, such as a button, slider, or label.
Shares many properties with `uiWindow`s, listed below.

### `uiElement` exclusive properties

- `name`(string): Used as key for table in `uiElementList`

### properties shared between `uiWindow` and `uiElement`

- `originX`,`originY`(nums): Top-left corner position of item. See note in `uiWindow` section.
- `width`,`height`(nums): Width and height of item in pixels.
- `borderColor`(tbl): Table for RGBA color value of item border in format `{R, G, B, A}`
- `shouldRender`(bool): Whether item should be rendered this frame
- `interactable`(bool): Whether item can respond to mouse/controller inputs on item
- `selectable`(bool): Whether item can be "selected" by scrolling through parent window's `contains` list using controller inputs

# How to use

To create a new piece of UI onscreen (for example, a health bar), you should:

Write a "creation" and "draw" function for the new piece of UI in `gameUi.lua`.
The creation function should only create a new uiWindow if it doesn't already exist,
and only return desired screen coordinates/width/height values if it already does.
The draw function should draw the window and its contents, including any elements contained
within the uiWindow's data.


