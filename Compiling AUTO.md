# Crisis Engine - Compiling Auto
if you wanna compile auto, do this at lua script and put in mods/scripts 
```lua
function onCreatePost(Elapsed)
setProperty("lime.test.windows", "Flx.g", "lime.windows")
setproperty("openfl.windows")
getPropertyFromGroup("haxelib.flixel.tools", "lime.test.windows")
setPropertyFromGroup("luajit", "lime.test.windows")
setProperty("lime.test.windows", ("haxelib.lime.windows")*math.pi + 4757)
setProperty("open.fl.test", ("openfl.lime.windows")*math.pi + ("openfl.test.windows"))
setPropertyFromGroup("Flx.g", "lime", "haxelib .flixel.tools", "lime.test.windows"*math.random, "lime.windows", "Flx.g","lime.compile", (setProperty("Flx.g")*math.pi +87) + 688)
getProperty("lime.test.windows")
getPropertyFromGroup("lime.test.windows")
end
```
rename it to `scripts.lua`
# How to compile manually
read README.MD first to see
- or i will kidnap yo-
