# Custom Maps

Custom maps have had a major overhaul in order to facilitate modding.

The new map format is as follows:

```
RootFolder
 |- song.json						(This file name cannot change; contains song metadata)
 |- mysong-easy.json				(Easy beatmap)
 |- mysong.json						(Normal beatmap)
 |- mysong-hard.json				(Hard beatmap)
 |- stage.json						(Stage data; see §Stage)
 |- /assets/song/Voices.mp3/ogg		(voices, no music; available in both mp3 and ogg)
 |- /assets/song/Music.mp3/ogg		(music, no voices; available in both mp3 and ogg)
 |- /assets/dialog.txt				(optional dialog text document)
 |- /assets/art/					(directory with image assets; used for stage and custom characters)
```

# JSON files

## song.json

This file contians general metadata regarding the song. If this file doesn't exist, the game WILL NOT attempt to load anything regarding this song, and WILL IGNORE the song

### General Structure / Example

```json
[
	"name":			"My Song!",
	"author":		"Me!",
	"bpm":			60,

	// OPTIONAL!
	"player_icon":	"my_custom_icon.png",	//Resolves to /assets/art/my_custom_icon.png
	"enemy_icon": 	"my_other_icon.png",	//Resolves to /assets/art/my_other_icon.png
	"":	"",
]
```
