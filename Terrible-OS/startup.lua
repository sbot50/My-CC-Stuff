-- put in install script
--[[ settings.load()
settings.set("shell.allow_disk_startup",false)
settings.save() ]]--

-- real startup
shell.run("./os/main.lua")
