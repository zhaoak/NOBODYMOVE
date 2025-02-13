# No Defenestration Allowed

This document explains the UI windowing system present in NOBODY MOVE.

The components of the windowing/UI system are as follows:

## uiWindow (uiWindow.lua)

A defined area of the screen (a window, if you will) that UI elements can be drawn to.
A uiWindow will handle resizing itself and the elements inside it in response
to game window size/resolution changes.

A window's rendering function is always called before its elements' rendering functions.
This means that elements will always visually render on top of windows.

## uiElement (uiElements.lua)

A specific type of interactable UI element, such as a button, slider, or label.
