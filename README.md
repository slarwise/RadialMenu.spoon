# RadialMenu.spoon

![Demo](https://user-images.githubusercontent.com/25964718/264169405-0c6acc0d-1947-4f49-b8db-3ce5db538666.png)

A launcher for MacOS with a radial menu selector. Built with
[Hammerspoon](https://github.com/Hammerspoon/hammerspoon), an automation
software for MacOS.

Very similar to
[RecursiveBinder.spoon](https://www.hammerspoon.org/Spoons/RecursiveBinder.html),
but with a different UI. h, j, k and l chooses the left, top, bottom and right
item. Space opens spotlight.

To install, clone this repository into the Spoons directory:

```sh
git clone https://github.com/slarwise/RadialMenu.spoon ~/.hammerspoon/Spoons/
```

Load the spoon and set a keybinding to launch the launcher:

```lua
hs.loadSpoon("RadialMenu")
spoon.RadialMenu:bindHotKeys({
  launch = { { "alt" }, "space" }
})
```
