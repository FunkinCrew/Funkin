# Lua Modcharts

In the 1.4.2 release of Kade Engine, we introduced Mod Charts. Mod Charts are a way of changing gameplay without hard coded values. This is achieved by using the Lua Scripting language to create script files that run during runtime.

Song data is located in `assets/data/<song>/`, so the Lua file containing your scripts should be located at exactly `assets/data/<song>/modchart.lua`. (replace <song> with the name of the song. for example, `assets/data/milf/` for milf)

If the file doesn't exist, Lua code won't be ran.

## Examples

Full Example

```lua
function start (song)
	print("Song: " .. song .. " @ " .. bpm .. " downscroll: " .. downscroll)
end


function update (elapsed) -- example https://twitter.com/KadeDeveloper/status/1382178179184422918
	local currentBeat = (songPos / 1000)*(bpm/60)
	for i=0,7 do
		setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi), i)
		setActorY(_G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi), i)
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
		setActorAngle(getActorAngle(i) + 15, i)
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
			setActorX(_G['defaultStrum'..i..'X'] + 32 * math.sin((currentBeat + i*0.25) * math.pi), i)
			setActorY(_G['defaultStrum'..i..'Y'] + 32 * math.cos((currentBeat + i*0.25) * math.pi), i)
		end
	else
        	for i=0,7 do
			setActorX(_G['defaultStrum'..i..'X'],i)
			setActorY(_G['defaultStrum'..i..'Y'],i)
        	end
    	end
end
```

Showing/Hiding receptors/the hud

```lua
function start (song)
    showOnlyStrums = true -- remove all hud elements besides notes and strums
    for i=0,3 do -- fade out the first 4 receptors (the ai receptors)
		tweenFadeIn(i,0,0.6)
    end
end
```

Looping through all of the rendered notes

```lua
for i = 0, getRenderedNotes() do -- sets all of the rendered notes to 0 0 on the x and y axsis
	setRenderedNotePos(0,0,i)
end
```

Centering BF's Side

```lua
function setDefault(id)
	_G['defaultStrum'..id..'X'] = getActorX(id)
end

-- put this somewhere in a function

for i = 4, 7 do -- go to the center
	tweenPosXAngle(i, _G['defaultStrum'..i..'X'] - 275,getActorAngle(i) + 360, 0.6, 'setDefault')
end
```


### Available Hooks

Current calls to functions include,

|  Name   |   Arguments    |                         Description                          |
| :-----: | :------------: | :----------------------------------------------------------: |
|  start  |   Song Name    |              Gets called when the song starts               |
| update  | Elapsed frames |       Gets called every frame (after the song starts)       |
| stepHit |  Current Step  | Gets called when ever a step hits (steps are in between beats, aka 4 steps are in a beat) |
| beatHit |  Current Beat  |              Gets called when ever a beat hits              |



### Global Variables

Kade Engine provides a list of global variables to be used in the lua scripting interface.

|        G Name        | Type  |                         Description                          |
| :------------------: | :---: | :----------------------------------------------------------: |
|         bpm          | Float |                 The current BPM of the song                  |
|        fpsCap        |  Int  |           The current FPS Cap (set by the player)            |
|      downscroll      | Bool  |          Whether the player is in downscroll or not          |
|     cameraAngle      | Float |       The angle that the Main Camera should be rotated       |
|     camHudAngle      | Float |           The angle that the Hud should be rotated           |
|    followXOffset     | Float | The x offset to be added when the camera moves between a character |
|    followYOffset     | Float | The y offset to be added when the camera moves between a character |
|    showOnlyStrums    | Bool  |    Whether to show the Hud and Strums or only the Strums     |
|  strumLine1Visible   | Bool  |         Whether to show the first strum line or not          |
|  strumLine2Visible   | Bool  |         Whether to show the secondstrum line or not          |
|   defaultStrum0-7X   | Float | (0-7 is strum0,strum1,strum2,etc) get the default X coordinate for the strum |
|   defaultStrum0-7Y   | Float | (0-7 is strum0,strum1,strum2,etc) get the default Y coordinate for the strum |
| defaultStrum0-7Angle | Float | (0-7 is strum0,strum1,strum2,etc) get the default Angle for the strum |
|     screenWidth      |  Int  |              The width of the current gamespace              |
|     screenHeight     |  Int  |             The height of the current gamespace              |
|       hudWidth       |  Int  |                     The width of the hud                     |
|      hudHeight       |  Int  |                    The height of the hud                     |
|	  scrollSpeed	   |  Int  |				   The current scrollspeed					  |
|	  	mustHit		   | Bool  |  		If the current section is a must hit section		  |
|	  strumLineY	   | Float |  			The current Strum Line Y Position				  |

## Functions

Kade Engine exposes a lot of functions that let you modify elements in the game field.



To get started every sprite has an id, and there are some id's that are accessible without creating one.

These premade id's are the following:

| Sprite Id  |                  Value                   |
| :--------: | :--------------------------------------: |
|    0-7     |         Represents Receptor 0-7          |
| boyfriend  | Represents the Boyfriend Actor (player1) |
|    dad     |    Represents the Dad Actor (player2)    |
| girlfriend |     Represents the Girlfriend Actor      |



### Sprites

##### makeSprite(string SpritePath,string SpriteId,bool DrawBehind)

Creates a sprite out of the specified image, returns the id you gave it.

*Note: Sprite Path is normally the FILE NAME so if your file is named `Image` it'll go to assets/data/songName/Image.png so don't include the extension*

### Hud/Camera

##### setHudPosition(int x, int y)

Sets the game hud's position in space.

##### getHudX()

Returns the hud's x position

##### getHudY()

Returns the hud's y position

##### setCamPosition(int x, int y)

Set's the current camera's position in space

##### getCamX()

Returns the current camera's x position

##### getCamY()

Returns the current camera's y position

##### setCamZoom(int zoomAmount)

Set's the current camera's zoom

##### setHudZoom(int zoomAmount)

Set's the hud's zoom

### Actors

##### getRenderedNotes()

Returns the amount of rendered notes.

##### getRenderedNoteX(int id)

Returns the x position of the rendered note id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteY(int id)

Returns the y position of the rendered note id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteScaleX(int id)

Returns the scale x of the rendered note id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteScaleY(int id)

Returns the scale y of the rendered note id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteType(int id)

Returns the note data of an note (0-3, left, down, up, right)

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### isSustain(int id)

Returns whether a rendered note is a sustain note or not (if they appear as the trail)

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### isParentSustain(int id)

Returns whether a rendered note's parrent is a sustain note or not (if they appear as the trail)

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteParentX(int id)

Returns the current parent x of the specified rendered note's id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteParentY(int id)

Returns the current parent y of the specified rendered note's id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteCalcX(int id)

Returns what the game would normally put the specified rendered note x.

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### anyNotes()

Returns the number of rendered notes on the screen.

##### getRenderedNoteStrumtime(int id)

Returns strum time of the rendered note.

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteAlpha(int id)

Returns the alpha of the rendered note id

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteWidth(int id)

Returns the width of the specified rendered note.

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### getRenderedNoteAngle(int id)

Returns the angle of the specified rendered note.

*Note: Rendered Notes id's are special in the way that they act. 0 = closest note to any receptor, last index = the farthest away from any receptor.*

##### setRenderedNotePos(int x, int y, int id)

Set's the position of the rendered note id

*Note: Setting a Rendered Note's property will stop the note from updating it's alpha & x properties*

##### setRenderedNoteAlpha(float alpha, int id)

Set's the alpha of the rendered note id

*Note: Setting a Rendered Note's property will stop the note from updating it's alpha & x properties*

##### setRenderedNoteScale(float scale, int id)

Set's the scale of the rendered note id

*Note: Setting a Rendered Note's property will stop the note from updating it's alpha & x properties*

##### setRenderedNoteScaleX(float scale, int id) **Currently broken**

Set's the scale x of the rendered note id

*Note: Setting a Rendered Note's property will stop the note from updating it's alpha & x properties*

##### setRenderedNoteScaleY(float scale, int id) **Currently broken**

Set's the scale y of the rendered note id

*Note: Setting a Rendered Note's property will stop the note from updating it's alpha & x properties*

##### getActorX(string/int id)

Returns the x position for the sprite id

##### getActorY(string/int id)

Returns the y position for the sprite id

##### getActorScaleX(string/int id)

Returns the scale x for the sprite id

##### getActorScaleY(string/int id)

Returns the scale y for the sprite id

##### getActorAlpha(string/int id)

Returns the alpha for the sprite id

##### getActorAngle(string/int id)

Returns the angle for the sprite id

##### setActorX(int x, string/int id)

Set's the x position for the sprite id

##### setActorY(int y, string/int id)

Set's the y position for the sprite id

##### setActorAlpha(float alpha, string/int id)

Set's the alpha for the sprite id

##### setActorAngle(int alpha, string/int id)

Set's the angle for the sprite id

##### setActorScale(float scale, string/int id)

Set's the scale for the sprite id

##### setActorScaleX(float x, string/int id) **Currently broken**

Set's the scale x for the sprite id

##### setActorScaleY(float y, string/int id) **Currently broken**

Set's the scale y for the sprite id

##### getActorWidth(string/int id)

Returns the width for the sprite id

##### getActorHeight(string/int id)

Returns the height for the sprite id

### Tweens

*Note, On Complete functions are based by the function name (and they also well get called when the tween completes)*

##### tweenPos(string/int id, int toX, int toY, float time, string onComplete)

Smoothly tween into a x and y position

##### tweenPosXAngle(string/int id, int toX, float toAngle, float time, string onComplete)

Smoothly tween into a x position and angle

##### tweenPosYAngle(string/int id, int toY, float toAngle, float time, string onComplete)

Smoothly tween into a y position and angle

##### tweenAngle(string/int id, float toAngle, float time, string onComplete)

Smoothly tween into a angle

##### tweenFadeIn(string/int id, float toAlpha, float time, string onComplete)

Smoothly fade in to an alpha

##### tweenFadeOut(string/int id, float toAlpha, float time, string onComplete)

Smoothly fade out to an alpha
