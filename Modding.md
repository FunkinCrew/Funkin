# Modding Guide Thingy for Leather Engine 0.3

## Setup

The first thing you'll need to do is open up the mods folder in the executeable directory. Then after that, make a new folder with the name of your mod.

Inside this folder, you'll need two things for the game to recognize your mod as a mod. A PNG image named _polymod_icon and a JSON text file named _polymod_meta, you can find examples for these in the Template Mod that should also be in the mods folder.

Once you have those two files in, you should probably edit them to match your mod (little tip here, the in-game title of your mod is determined by the `title` variable in *_polymod_meta.json* that's in your mod folder).

Once all that is done, it's time to add other things to your mod!

## Adding in a Song

### Adding in the audio

If you want to add a song to your mod, you'll need the audio files which are .oggs. You'll need 1 for the Instrumental (Background Music), and Vocal Track (if the song has one).

Once you have your audio files ready, the next step is to make a new folder in your mod's folder, and call it `songs`. In the songs folder you just made, make another folder with the name of your song **IN LOWERCASE** then add both your audio files into that folder with the names, Inst (for the instrumental) and Voices (for the vocals).

### Adding in a song chart

If you want to add your chart to the mod (and make the song actually playable) then your first step is to make a new folder in the mod folder called `data`.

In the new data folder, you have to add another folder called `song data` and in that folder, and another folder with the exact same name as your song's name **IN LOWERCASE**.

In that folder, just put the .jsons for your charts of the song, these usually are named *[song name here]-[difficulty goes here]* or *[song name here] (for normal mode)*.

### Adding the song to freeplay

If you want to add your song to the freeplay menu (you probably do) then start off by making a new folder called `_append` in the mod folder.

In _append add a folder named `data` and in that folder add a .txt file named `freeplaySonglist`.

Then in that text file, just add a line for your song (or songs) that is in the format: `[SONG NAME HERE]:[CHARACTER NAME]:[WEEK NUMBER]`.

## Adding in a Character

