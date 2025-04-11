# No Defenestration Allowed

This document explains the UI windowing system present in NOBODY MOVE.

The components of the windowing/UI system are as follows:

## uiWindow (uiWindow.lua)

A defined area of the screen (a window, if you will) that can be drawn to and can contain both
`uiElement`s and other `uiWindow`s as children.

Children are stored in an int-keyed table called `contains`, where the key of each child represents
the order the children are in in terms of navigating UI with controller inputs.

*NOTE*: 
All `originX`/`originY` values are specified in pixel *screen coordinates*,
where (0,0) is the top-left corner of the game window.
Similarly, width/height values are always in pixels.

A uiWindow will handle resizing itself and the elements/subwindows inside it in response
to game window size/resolution changes.

A `uiWindow` and `uiElement` only render if its parent's `shouldRender` property is true.

A window's rendering function is always called before its children's rendering functions.
This means that child elements will always visually render on top of their parent window.

### `uiWindow` exclusive properties

- `windowUid`(num): UID value for this `uiWindow`
- `contains`(tbl, int-keyed): An ordered list of a `uiWindow`s children. **Do not put the same child in multiple parents!**
- `scrollable`(bool, default false): Whether the window's contents can be scrolled
- `currentScrollOffset`(num): How many pixels down the window is currently scrolled
- `create`(func): "Creation" function, see "How to use" section

## uiElement (uiElements.lua)

A specific type of interactable UI element, such as a button, slider, or label.
Shares many properties with `uiWindow`s, listed below.

### `uiElement` exclusive properties

- `elementUid`(num): UID value for this `uiElement`
- many properties may be used to store data for specific elements, such as sliders, buttons, or checkboxes

### properties shared between `uiWindow` and `uiElement`

- `name`(string): Internal name, used for identification by human 
- `originX`,`originY`(nums): Current top-left corner position of item. See note in `uiWindow` section.
- `width`,`height`(nums): Current width and height of item in pixels.
- `originXTarget`,`originYTarget`(nums): A number between 0 and 1 describing where the origin point for this item should reside on an axis relative to its parent's origin.
                                         0 = the parent window's originX/originY, 1 = the parent window's originX/originY + parent window's width/height.
                                         If the item has no parent window, uses the game window's dimensions for width/height and (0,0) for the parent's origin point.
- `widthTarget`,`heightTarget`(nums): A number between 0 and 1 describing how wide/tall the item should be compared to its parent's width/height.
                                      If the item has no parent window, uses the game window's dimensions for comparisons.
- `parentWindowUid`(num): UID of parent window. If item has no parent, this is set to -1.
- `shouldRender`(bool): Whether item should be rendered this frame
- `interactable`(bool): Whether item can be interacted with/manipulated via mouse/controller inputs
- `selectable`(bool): Whether item can be "selected" by scrolling through parent window's `contains` list using controller inputs
- `draw`(func): rendering function for item

# How to use

To create a new piece of UI onscreen (for example, a health bar), you should:

Write a "creation" and "draw" function for the new piece of UI in `gameUi.lua`.
The creation function should also create any subwindows of the newly created window, if there are any,
and add the subwindows as children using the `addItem` function.
The draw function should draw the window and its contents, including any elements contained
within the uiWindow's data.
Call the creation function for your new UI in the `setup` function in `gameUi.lua`,
and your new UI should appear ingame.
