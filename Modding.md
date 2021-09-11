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

### Charting your song