doc.api.resourcesdir = {"api.resourcesdir -> string", "The location of the built-in lua source files."}

doc.api.userfile = {"api.userfile(name)", "Returns the full path to the file ~/.hydra/{name}.lua"}
function api.userfile(name)
  return os.getenv("HOME") .. "/.hydra/" .. name .. ".lua"
end

doc.api.douserfile = {"api.douserfile(name)", "Convenience wrapper around dofile() and api.userfile(name)"}
function api.douserfile(name)
  local userfile = api.userfile(name)
  local exists, isdir = api.fileexists(userfile)
  if exists and not isdir then
    dofile(userfile)
  else
    api.notify.show("Hydra user-file missing", "", "Can't find file: " .. tostring(name), "")
  end
end

local function load_default_config()
  local fallbackinit = dofile(api.resourcesdir .. "/fallback_init.lua")
  fallbackinit.run()
end

local function clear_old_state()
  api.hotkey.disableall()
  api.menu.hide()
  api.pathwatcher.stopall()
  api.timer.stopall()
  api.textgrid.closeall()
  api.notify.unregisterall()
end

doc.api.reload = {"api.reload()", "Reloads your init-file. Makes sure to clear any state that makes sense to clear (hotkeys, pathwatchers, etc)."}
function api.reload()
  clear_old_state()

  local userfile = os.getenv("HOME") .. "/.hydra/init.lua"
  local exists, isdir = api.fileexists(userfile)

  if exists and not isdir then
    local ok, err = pcall(function() dofile(userfile) end)
    if not ok then
      api.notify.show("Hydra config error", "", tostring(err) .. " -- Falling back to sample config.", "")
      load_default_config()
    end
  else
    -- don't say (via alert) anything more than what the default config already says
    load_default_config()
  end
end

doc.api.errorhandler = {"api.errorhandler = function(err)", "Error handler for api.call; intended for you to set, not for third party libs"}
function api.errorhandler(err)
  print("Error: " .. err)
  api.notify.show("Hydra Error", "", tostring(err), "error")
end

function api.tryhandlingerror(firsterr)
  local ok, seconderr = pcall(function()
      api.errorhandler(firsterr)
  end)

  if not ok then
    api.notify.show("Hydra error", "", "Error while handling error: " .. tostring(seconderr) .. " -- Original error: " .. tostring(firsterr), "")
  end
end

doc.api.call = {"api.call(fn, ...) -> ...", "Just like pcall, except that failures are handled using api.errorhandler"}
function api.call(fn, ...)
  local results = table.pack(pcall(fn, ...))
  if not results[1] then
    -- print(debug.traceback())
    api.tryhandlingerror(results[2])
  end
  return table.unpack(results)
end

local function trimstring(s)
  return s:gsub("^%s+", ""):gsub("%s+$", "")
end

doc.api.exec = {"api.exec(command) -> string", "Runs a shell function and returns stdout as a string (without trailing newline)."}
function api.exec(command)
  local f = io.popen(command)
  local str = f:read("*a")
  f:close()
  return trimstring(str)
end

doc.api.uuid = {"api.uuid() -> string", "Returns a UUID as a string"}
function api.uuid()
  return api.exec("uuidgen")
end

-- swizzle! this is necessary so api.settings can save keys on exit
os.exit = api.exit
