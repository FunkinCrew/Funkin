# Creating A Custom Week

## Requirements
1. The ability to compile Kade Engine from the source code. All information related to building Kade Engine is listed [here.](https://kadedev.github.io/Kade-Engine/building)
2. A text editor. Some form of IDE that can support Haxe is recommended, such as Visual Studio Code.

### Step 1. Navigation
Navigate to your Kade Engine source code. In the `source` folder, look for `StoryMenuState.hx`. Open it in your text editor.

### Step 2. Songlist

Scroll down to Line 26, or Search (Windows/Linux: `Ctrl+F` | Mac: `Cmd+F`) for "weekData". You should find an Array that looks like this:

=====

var weekData:Array<Dynamic> = [
		
    ['Tutorial'],
		
    ['Bopeebo', 'Fresh', 'Dadbattle'],
		
    ['Spookeez', 'South', "Monster"],
		
    ['Pico', 'Philly', "Blammed"],
		
    ['Satin-Panties', "High", "Milf"],
		
    ['Cocoa', 'Eggnog', 'Winter-Horrorland'],
		
    ['Senpai', 'Roses', 'Thorns']
    
	];
  
=====
  
Copy `['Senpai', 'Roses', 'Thorns']` into an empty line below it, and change the song names to the song names you want to use.
Don't forget to add a comma at the end of the previous Week, and you have your songlist for the week completed!
 
=====

Example:

['Ugh', 'Guns', 'Stress']
 
=====
 
 ### Step 3. Songlist
Directly below the songlist should be an Array titled `weekCharacters`. This array tells the game what characters to display in the top yellow bar when a certain week is selected.
It's not very useful unless you followed the Characters guide (will link to it once it's actually done). If you have, though, you can insert the name of your character into the first pair of quotes in a new "week". Example:

=====
Example:

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
  
=====

### Step 4. Week Names

Underneath the song list, there should be another array called "weekNames". Creating a new line in that array, just enter a string that represents what you want the week to be called.

=====

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
  
  =====
  
  Now, compile the game, and if all goes correctly, the Story Mode menu shouldn't crash your game. If you make your way to the bottom of the list, there's your custom week! Except... its displaying as a HaxeFlixel Logo?
  
  ### Step 5. Graphics
  
  Being honest here, Prokube doesn't really know. More information will be added later, but for now I gotta go.
