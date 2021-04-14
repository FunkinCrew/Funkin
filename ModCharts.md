# Kade Engine Lua Mod Chart Documentation

In the latest version of Kade Engine we introduced Mod Charts. Mod Charts are a way of changing gameplay without hard coded values, this is achieved by using the Lua Scripting language to create script files that run during runtime.

All files **are located in** `assets/data/song/modchart.lua`

Lua code will only be ran if that file exists.



### Examples

Full Example

```lua
function start (song)
	print("Song: " .. song .. " @ " .. bpm .. " donwscroll: " .. downscroll)
end


function update (elapsed) -- example https://twitter.com/KadeDeveloper/status/1382178179184422918
	local currentBeat = (songPos / 1000)*(bpm/60)
	for i=0,7 do
		_G['strum'..i..'X'] = _G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi)
		_G['strum'..i..'Y'] = _G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi)
	end
end

function beatHit (beat)
   -- do nothing
end

function stepHit (step)
   -- do nothing
end

print("Mod Chart script loaded :)")
```

Spinning Receptor Example

```lua
function update (elapsed)
	for i=0,7 do
		_G['strum'..i..'Angle'] = _G['strum'..i..'Angle'] + 15
	end
end
```

Spinning Hud Example

```lua
function update (elapsed)
	camHudAngle = camHudAngle + 0.005
end
```

Spin at a specific part of the song

```lua
function update (elapsed)
	if curStep >= 352 and curStep < 400 then
		local currentBeat = (songPos / 1000)*(bpm/60)
		for i=0,7 do
			_G['strum'..i..'X'] = _G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi)
			_G['strum'..i..'Y'] = _G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi)
		end
	else
    	_G['strum'..i..'X'] = _G['defaultStrum'..i..'X']
        _G['strum'..i..'Y'] = _G['defaultStrum'..i..'Y']
    end
end
```

Showing/Hiding receptors/the hud

```lua
function start (song)
    showOnlyStrums = true -- remove all hud elements besides notes and strums
    _G['strumLine1Visible'] = false -- remove the first line of strums (the ai notes)
end
```



### Available Hooks

Current calls to functions include,

|  Name   |   Arguments    |                         Description                          |
| :-----: | :------------: | :----------------------------------------------------------: |
|  start  |   Song Name    |              Get's called when the song starts               |
| update  | Elapsed frames |       Get's called every frame (after the song starts)       |
| stepHit |  Current Step  | Get's called when ever a step hits (steps are in between beats, aka 4 steps are in a beat) |
| beatHit |  Current Beat  |              Get's called when ever a beat hits              |



### Global Variables

Kade Engine provides a list of global variables to be used in the lua scripting interface.

|        G Name        | Type  |                         Description                          |
| :------------------: | :---: | :----------------------------------------------------------: |
|         bpm          | Float |                 The current BPM of the song                  |
|        fpsCap        |  Int  |           The current FPS Cap (set by the player)            |
|      downscroll      | Bool  |          Whether the player is in downscroll or not          |
|       hudZoom        | Float |      The amount of zoom the Hud should be zoomed in/out      |
|      cameraZoom      | Float |  The amount of zoom the Main Camera should be zoomed in/out  |
|     cameraAngle      | Float |       The angle that the Main Camera should be rotated       |
|     camHudAngle      | Float |           The angle that the Hud should be rotated           |
|    followXOffset     | Float | The x offset to be added when the camera moves between a character |
|    followYOffset     | Float | The y offset to be added when the camera moves between a character |
|    showOnlyStrums    | Bool  |    Whether to show the Hud and Strums or only the Strums     |
|  strumLine1Visible   | Bool  |         Whether to show the first strum line or not          |
|  strumLine2Visible   | Bool  |         Whether to show the secondstrum line or not          |
|      strum0-7X       | Float | (0-7 is strum0,strum1,strum2,etc) get/set the X coordinate for the strum |
|      strum0-7Y       | Float | (0-7 is strum0,strum1,strum2,etc) get/set the Y coordinate for the strum |
|    strum0-7Angle     | Float | (0-7 is strum0,strum1,strum2,etc) get/set the Angle for the strum |
|   defaultStrum0-7X   | Float | (0-7 is strum0,strum1,strum2,etc) get the default X coordinate for the strum |
|   defaultStrum0-7Y   | Float | (0-7 is strum0,strum1,strum2,etc) get the default Y coordinate for the strum |
| defaultStrum0-7Angle | Float | (0-7 is strum0,strum1,strum2,etc) get the default Angle for the strum |

