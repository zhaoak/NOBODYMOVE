# No Defenestration Allowed

This document explains the UI and windowing system present in NOBODY MOVE.

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

## uiElement (uiElements.lua)

A specific type of interactable UI element, such as a button, slider, or label.
Shares many properties with `uiWindow`s, listed below.

### `uiElement` exclusive properties

- `elementUid`(num): UID value for this `uiElement`
- `extra`(table): Table containing any additional data needed to render the element or track its state.
                  Contents will vary based on the type of element and its data storage needs.
                  See the "uiElement Types" section for specifics.
- many properties may be used to store data for specific elements, such as sliders, buttons, or checkboxes

### properties shared between `uiWindow` and `uiElement`

- `name`(string): Internal name, used for identification by programmer
- `originX`,`originY`(nums): Current top-left corner position of item. Auto-set by resizing code.
- `width`,`height`(nums): Current width and height of item in pixels. Auto-set by resizing code.
- `originXTarget`,`originYTarget`(nums): A number between 0 and 1 describing where the origin point for this item should reside on an axis relative to its parent's origin.
                                         0 = the parent window's originX/originY, 1 = the parent window's originX/originY + parent window's width/height.
                                         If the item has no parent window, uses the game window's dimensions for width/height and (0,0) for the parent's origin point.
- `widthTarget`,`heightTarget`(nums): A number between 0 and 1 describing how wide/tall the item should be compared to its parent's width/height.
                                      If the item has no parent window, uses the game window's dimensions for comparisons.
- `parentWindowUid`(num): UID of parent window. If item has no parent, this is set to -1.
- `shouldRender`(bool): Whether item should be rendered this frame
- `interactable`(bool): Whether item is permitted to run callbacks based on player input
- `selectable`(bool): Whether item can be "selected" by scrolling through parent window's `contains` list using controller inputs
- `draw`(func): rendering function for item
- `onInput`(table): callback functions run in response to player game inputs, keyed with the following strings:
                    - "primary": confirm/trigger action/select from children (default bind: leftclick/A button on gamepad)
                    - "secondary": perform secondary action (default bind: rightclick/X button on gamepad)
                    - "tertiary": perform tertiary action (default bind: rightshift/Y button on gamepad)
                    - "cancel": cancel action/return to parent window (default bind: ESC/B button on gamepad)
## uiElement types

### Textbox

Rectangular section of the screen to display text in.
To change the text's font, rotation, size, or other properties,
specify what you want in the `values` table using the following list of keys.
The `values` table is then passed to the `createTextBox` function as an argument.

- textTable(table): Table containing string-color pairs to print in the following format: `{color1, string1, color2, string2, ...}`
    - color1(table): Table containing red, green, blue, and optional alpha values in format: `{r, g, b, a}`
    - string1(table): String to render using the corresponding color1 values.
        - color2 and string2 correspond, as do any additional pairs provided.
        - So, a textTable value of `{{1,0,0,1}, "horse", {0,1,0,1}, "crime"}` would print:
        - "horsecrime" with "horse" in red and "crime" in green.
- font(Font): Love font object to use when drawing text. Defaults to currently set font.
- align(string): alignment mode of text, one of: "center", "left", "right", "justify"
- angle(number): rotation of text in radians; 0 is normal, un-rotated text, pi is upside-down, 2pi is equal to 0
- sx,sy(numbers): x/y scale factors for text, 1 is normal scale
- ox,oy(numbers): x/y origin offsets for text, 0 is no offset
- kx, ky(numbers): x/y shearing factors

# How to use

To create a new piece of UI onscreen (for example, a health bar), you should:

Write a "creation" and "draw" function for the new piece of UI in `gameUi.lua`.
The creation function should also create any subwindows of the newly created window, if there are any,
and add the subwindows as children using the `addItem` function.
The draw function should draw the window, but not any of its children;
each child will get its own draw function.
Call the creation function for your new UI in the `setup` function in `gameUi.lua`,
and your new UI should appear ingame.
