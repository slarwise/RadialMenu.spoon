-- DONE: Draw a transparent circle around the icons? Look at e.g. The Last Of Us
-- TODO: Verify that it is centered on the screen
-- TODO: Any other key than hjkl exit, not just escape?
-- DONE: Probably don't have individual applications on the first screen.
-- Can use H J K L to go to a second level away from the center
--                 Safari
--                  Mail
-- System Finder              Wezterm Terminal
--                Downloads
--               Garageband
--
-- So k goes to Safari, and K to Mail
-- Maybe space goes to spotlight, like a catch-all thing
-- Space on a submenu like applications could open Spotlight
-- prefilled with kind:Application
-- TODO: Center the text vertically

local M = {}

local positions = {
  top = {
    imageAlignment = "center",
    textAlignment = "center",
    frame = { h = "33%", w = "100%", x = 0, y = 0 },
    keyBind = "k",
  },
  left = {
    imageAlignment = "left",
    textAlignment = "left",
    frame = { h = "33%", w = "100%", x = 0, y = "33%" },
    keyBind = "h",
  },
  right = {
    imageAlignment = "right",
    textAlignment = "right",
    frame = { h = "33%", w = "100%", x = 0, y = "33%" },
    keyBind = "l",
  },
  bottom = {
    imageAlignment = "center",
    textAlignment = "center",
    frame = { h = "33%", w = "100%", x = 0, y = "66%" },
    keyBind = "j",
  },
}

local function appNameToBundleID(name)
  local ok, output, _ = hs.osascript.applescript(
    string.format('id of app "%s"', name)
  )
  if not ok then
    return nil
  else
    return output
  end
end

local appsScreen = {
  top = {
    image = hs.image.imageFromAppBundle(appNameToBundleID("Safari")),
    func = function() hs.application.launchOrFocus("Safari") end,
    hs.image.imageFromName
  },
  left = {
    image = hs.image.imageFromAppBundle(appNameToBundleID("Finder")),
    func = function() hs.application.launchOrFocus("Finder") end
  },
  right = {
    image = hs.image.imageFromAppBundle(appNameToBundleID("Wezterm")),
    func = function() hs.application.launchOrFocus("Wezterm") end
  },
  bottom = {
    image = hs.image.imageFromAppBundle(appNameToBundleID("System Settings")),
    func = function() hs.application.launchOrFocus("System Settings") end
  },
  spotlightQuery = "kind: Application ",
}

local foldersScreen = {
  top = {
    text = "Downloads",
    func = function() hs.open("/Users/arvidbjurklint/Downloads") end
  },
  left = {
    image = hs.image.imageFromName(hs.image.systemImageNames.TrashFull),
    func = function() hs.open("/Users/arvidbjurklint/.Trash") end
  },
  right = {
    text = "Projects",
    func = function() hs.open("/Users/arvidbjurklint/projects") end
  },
  spotlightQuery = "kind: Folder ",
}

local hammerspoonScreen = {
  top = {
    text = "Reload",
    func = function() hs.reload() end
  },
  left = {
    text = "Console",
    func = function() hs.openConsole() end
  },
  right = {
    text = "Docs",
    func = function()
      hs.urlevent.openURL("https://www.hammerspoon.org/docs")
    end
  },
}

local utilsScreen = {
  top = {
    text = "Screensaver",
    func = function() hs.caffeinate.startScreensaver() end
  },
  left = {
    text = "Sleep",
    func = function() hs.caffeinate.systemSleep() end
  },
  right = {
    text = "Lock",
    func = function() hs.caffeinate.lockScreen() end
  },
  bottom = {
    text = "Shade",
    func = function() spoon.Shade:toggleShade() end,
  }
}

local startScreen = {
  top = {
    text = "Apps",
    func = function() M:launch(appsScreen) end,
  },
  left = {
    image = hs.image.imageFromName(hs.image.systemImageNames.Folder),
    func = function() M:launch(foldersScreen) end,
  },
  right = {
    image = hs.image.imageFromAppBundle(appNameToBundleID("Hammerspoon")),
    func = function() M:launch(hammerspoonScreen) end,
  },
  bottom = {
    image = hs.image.imageFromName(hs.image.systemImageNames.Computer),
    func = function() M:launch(utilsScreen) end,
  },
  spotlightQuery = nil,
}

local function newCanvas()
  local screenFrame = hs.screen.mainScreen():frame()
  local canvasWidth = 300
  local canvasHeight = 300
  local rectangle = hs.geometry.rect(
    (screenFrame.w / 2) - (canvasWidth / 2),
    (screenFrame.h / 2) - (canvasHeight / 2),
    canvasWidth,
    canvasHeight)
  local canvas = hs.canvas.new(rectangle)
  if not canvas then return end
  canvas:appendElements({
    {
      action = "fill",
      type = "circle",
      radius = "50%",
      center = { x = "50%", y = "50%" },
      fillColor = { white = 0.3, alpha = 0.7 },
    }
  })
  return canvas
end

function M:init()
  M.logger = hs.logger.new("RadialMenu", "debug")
  M.canvas = nil
end

function M:launch(screen)
  if not screen then
    screen = startScreen
  end
  -- Draw and show canvas
  local elements = {}
  for position, _ in pairs(positions) do
    if screen[position] then
      if screen[position].image then
        table.insert(elements, {
          type = "image",
          image = screen[position].image,
          imageAlignment = positions[position].imageAlignment,
          frame = positions[position].frame,
        })
      elseif screen[position].text then
        table.insert(elements, {
          type = "text",
          text = "\n" .. screen[position].text,
          textAlignment = positions[position].textAlignment,
          frame = positions[position].frame,
        })
      end
    end
  end
  M.canvas = newCanvas()
  M.canvas:appendElements(elements)
  M.canvas:show()

  -- Setup cancellation hotkeys
  local modal = hs.hotkey.modal.new()
  modal:bind({}, "escape", function()
    modal:exit()
    M.canvas:delete()
  end)
  modal:bind({ "ctrl" }, "[", function()
    modal:exit()
    M.canvas:delete()
  end)

  -- Setup selection keys
  for position, _ in pairs(positions) do
    if screen[position] then
      modal:bind({}, positions[position].keyBind, function()
        modal:exit()
        M.canvas:delete()
        screen[position].func()
      end)
    end
  end

  -- Setup Spotlight search
  modal:bind({}, "space", function()
    modal:exit()
    M.canvas:delete()
    hs.eventtap.keyStroke({ "cmd" }, "space")
    if screen.spotlightQuery then
      hs.eventtap.keyStrokes(screen.spotlightQuery)
    end
  end)

  modal:enter()
end

function M:bindHotKeys(mapping)
  local spec = {
    launch = hs.fnutils.partial(self.launch, self)
  }
  hs.spoons.bindHotkeysToSpec(spec, mapping)
  return self
end

return M
