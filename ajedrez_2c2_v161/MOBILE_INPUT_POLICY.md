# Mobile input policy

Ajedrez 2c2 is designed for Android touchscreens. Gameplay board input is handled only through `InputEventScreenTouch`; tapping a source and destination square and dragging a piece are supported. Mouse-button input and mouse-emulation duplicate-input guards are intentionally not part of gameplay. UI controls remain ordinary Godot `Control` nodes so their built-in touch handling and accessibility/layout behavior continue to work. Automated gameplay regression tests must simulate touchscreen events, not mouse clicks.
