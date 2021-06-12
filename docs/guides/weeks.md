# Creating A Custom Week

## Requirements
1. The ability to compile Kade Engine from the source code. All information related to building Kade Engine is listed [here.](https://kadedev.github.io/Kade-Engine/building)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.

---
### Step 1. Navigation
Navigate to your Kade Engine source code. In the `source` folder, look for `StoryMenuState.hx`. Open it in your text editor.

### Step 2. Songlist

Scroll down to Line 26, or Search (Windows/Linux: `Ctrl+F`, Mac: `Cmd+F`) for "weekData". You should find an Array that looks like this:

---

```haxe
var weekData:Array<Dynamic> = [
		
    ['Tutorial'],
		
    ['Bopeebo', 'Fresh', 'Dadbattle'],
		
    ['Spookeez', 'South', "Monster"],
		
    ['Pico', 'Philly', "Blammed"],
		
    ['Satin-Panties', "High", "Milf"],
		
    ['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		
    ['Senpai', 'Roses', 'Thorns']
    
];
```

---

Copy `['Senpai', 'Roses', 'Thorns']` into an empty line below it, and change the song names to the song names you want to use.
Don't forget to add a comma at the end of the previous Week, and you have your songlist for the week completed!

Example
---

---

```haxe
var weekData:Array<Dynamic> = [
		
    ['Tutorial'],
		
    ['Bopeebo', 'Fresh', 'Dadbattle'],
		
    ['Spookeez', 'South', "Monster"],
		
    ['Pico', 'Philly', "Blammed"],
		
    ['Satin-Panties', "High", "Milf"],
		
    ['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		
    ['Senpai', 'Roses', 'Thorns'],

    ['Ugh', 'Guns', 'Stress']
    
];
```
 
---
 
### Step 3. Week Characters
Directly below the songlist should be an Array titled `weekCharacters`. This array tells the game what characters to display in the top yellow bar when a certain week is selected.
It's not very useful unless you followed the Characters guide (will link to it once it's actually done). If you have, though, you can insert the name of your character into the first pair of quotes in a new "week". Example:

Example
---

---

```haxe
var weekCharacters:Array<Dynamic> = [
		
    ['', 'bf', 'gf'],
		
    ['dad', 'bf', 'gf'],
		
    ['spooky', 'bf', 'gf'],
		
    ['pico', 'bf', 'gf'],
		
    ['mom', 'bf', 'gf'],
		
    ['parents-christmas', 'bf', 'gf'],
		
    ['senpai', 'bf', 'gf'],
    
    ['tankman', 'bf', 'gf']
	
  ];
```

---

### Step 4. Week Names

Underneath the song list, there should be another array called `weekNames`. Creating a new line in that array, just enter a string that represents what you want the week to be called.

Example
---

---
```haxe
var weekNames:Array<String> = [
		
	"How to Funk",
		
	"Daddy dearest",
		
	"Spooky Month",
		
	"PICO",
		
	"Mommy Must Murder",
		
	"Red Snow",
		
	"Hating Simulator ft. Moawlings",
    		
	"Tankman"
	
];
```

---

  Now, compile the game, and if all goes correctly, the Story Mode menu shouldn't crash your game. If you make your way to the bottom of the list, there's your custom week! Except... its displaying as a HaxeFlixel Logo?
  
### Step 5. Graphics
  
Displaying a week icon for your custom week is as simple as dropping a .png into `assets/images/storymenu`. Rename the file to `week7.png`, `week8.png`, etc.

Example
---

---

![frrf](https://user-images.githubusercontent.com/68293280/118160164-cdab6d00-b3d2-11eb-9b29-a940eaf45025.png)

![frrf 2](https://user-images.githubusercontent.com/68293280/118160865-b8830e00-b3d3-11eb-8a23-818a1b4cfdb2.png)

NOTE: You will have to add a new item to `weekUnlocked`, so that the week is playable.

![frrf 3](https://user-images.githubusercontent.com/68293280/118161461-7908f180-b3d4-11eb-89fa-e531ae5804d8.png)


### Conclusion

If you followed all of the steps correctly, you have successfully created a new week in the Story Mode.
