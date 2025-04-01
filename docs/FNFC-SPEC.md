# .fnfc File Specification

*Updated 2024-04-29*

- Manifest version: `1.0.0`
- Metadata version: `2.2.2`
- Chart data version: `2.0.0`

## Introduction

This document describes the structure of the FNFC file format used for saving and loading charts in the Chart Editor for Friday Night Funkin'. It is designed to refactor how the game stores levels, as the original format was clunky and poorly extensible.

FNFC files are a store of all the required files for crediting and editing charts. This includes any relevant audio files, which is perfect for collaboration between charters.

## Overview

Friday Night Funkin' charts utilize a concept called "variations"; these are groups of difficulties which share gameplay data. This is done to prevent significant redundancy; if each chart

If a difficulty for a song should have the same events as another difficulty, those difficulties should be in the same variation (for example, Normal and Hard). If a particular difficulty for a song should have different song events, characters, stages, or music (including instruments or vocals) from the base variation, they should use a different variation. Difficulties for a song start in the `default` variation.

An example of this is the Erect and Nightmare difficulties. These are defined in an alternative variation, which allows for those difficulties to utilize different events and music from the base variation.

The Chart Editor is made aware of which variations are available in the current chart file by querying the `playData.songVariations` key in the `default` variation's metadata file.

The chart data itself is split into two files. The `<songid>-metadata.json` file should contain all the information the game needs to display a song in menus such as Freeplay, including but not limited to the song name, artist, and BPM. The `<songid>-chart.json` should only contain the note data for each difficulty of that variation, and the song event data for the variation. This allows the game to, when it first loads, parse and cache the metadata for all available songs for use in menus, while keeping the bulky chart file data unloaded until that chart specifically is played.

Note that the game itself does not store its songs as FNFC files; rather, it stores the `metadata.json`, `chart.json`, and `.ogg` files separately.

Note also that the files may include some values whose functionality are not yet fully implemented into the game itself.

## File Contents

FNFC files are standard ZIP files containing the following:

- `manifest.json`: This file contains minimal information to minimize work in the parsing of chart files.
- `Inst.ogg`: Song instrumental for the default variation.
- `Inst-<instid>.ogg`: *(optional)* An alternative instrumental which can be used.
- `Voices-<charid>.ogg`: *(optional)* Song vocals for a specific character, for the default variation.
- `Voices-<charid>-<variation>.ogg`: *(optional)* Song vocals for a specific character, for an alternate variation.
- `<songid>-metadata.json`: Song metadata for the `default` variation.
- `<songid>-metadata-<variation>.json`: *(optional)* Song metadata for alternate variations.
- `<songid>-chart.json`: Song chart data for the `default` variation.
- `<songid>-chart-<variation>.json`: *(optional)* Song chart data for alternate variations.

## Files

Note that each component file contains its own separate [Semantic Version](https://semver.org/) number which the game adheres to when parsing. New functionality (with backwards compatibility) should be represented by a `1.x.0` change and breaking changes should be kept to a minimum, and represented by a `x.0.0` change.

### manifest.json

`manifest.json` is a JSON-formatted text file, containing a single object with the following keys:

- `version`: The Semantic Version string for the manifest file.
- `songId`: The song ID associated with this chart. Used to allow the Chart Editor to easily determine the proper filenames for the `metadata` and `chart` files.

#### manifest.json Example

```jsonc
{
  "version": "1.0.0", // The Semantic Version string.
  "songId": "dadbattle" // The song ID.
}
```

### Inst.ogg

This is an audio file in the OGG container format with the Vorbis audio codec.

This file is mandatory. A chart file without an instrumental track is considered invalid.

This file is used as the default backing track for the song.

### Inst-<instid>.ogg

This is an audio file in the OGG container format with the Vorbis audio codec.

This file is optional if no alternative instrumental is specified in any variation.

This file is used as an alternate backing track for the song. It is specified using the `playData.characters.instrumental` key in the current variation's metadata file.

### Voices-<charid>.ogg

This is an audio file in the OGG container format with the Vorbis audio codec.

This file is optional. The game will look for the specified file but will ignore if it is missing.

This file is used for the character vocal track for the song. The game will look for and play the vocal track for the player (using the ID specified by the `playData.characters.player` key in the current variation's metadata file), and the opponent (using the ID specified by the `playData.characters.opponent` key in the current variation's metadata file).

### Voices-<charid>-<variation>.ogg

This is an audio file in the OGG container format with the Vorbis audio codec.

This file is optional. The game will look for the specified file but will ignore if it is missing.

This file is used for the character vocal track for the song, for the given variation. The game will look for and play the vocal track for the player and the opponent using the same JSON keys as the `Voices-<charid>.ogg` files for the default variation, while also applying the current variation ID.

### <songid>-metadata.json

`<songid>-metadata.json` is a JSON-formatted text file, specifying metadata about the default variation for this song. It has the following keys:

- `version`: The Semantic Version string for the metadata file.
- `songName`: The human readable name for the song, as a string.
- `artist`: The human readable artist(s) for the song, as a string.
- `timeFormat`: The time format. In the future, this will allow chart files to define the timestamps for BPM changes, note data, or event data, in fractional beats and steps, but for now the only supported value is the string `"ms"`.
- `timeChanges`: An array of Song Time Change objects. Note that at least one Song Time Change object must be specified, with a timestamp of `0`.
- `playData`: A Song Play Data object.
- `offsets`: A Song Offset Data object.
- `generatedBy`: A string specified when creating a chart. Should only be used for debugging purposes, and not read or used by the game. Custom engines should modify `Constants.hx` to ensure unique values in case of issues with the metadata or chart data.

The Song Time Change objects have the following keys:
- `t`: The timestamp for the BPM change, in milliseconds, as a float.
- `bpm`: The new song timing, in beats per minute, as a float.
- `n`: *optional* Time signature numerator, as an integer. Defaults to 4. (int). Optional, defaults to `4`.
- `d`: *optional* Time signature denominator, as an integer. Should only ever be a power of two. Defaults to `4`.
- `bt`: *optional* Beat tuplets. This defines how many steps each beat is divided into. Defaults to `[4, 4, 4, 4]`

The Song Play Data objects have the following keys:
- `album`: The album ID to display in the Freeplay menu, as a string ID.
- `previewStart`: The timestamp to begin the audio preview for this track in the Freeplay Menu, in milliseconds, as a float.
- `previewEnd`: The timestamp to end the audio preview for this track in the Freeplay Menu, in milliseconds, as a float.
- `ratings`: An map object; each key is a difficulty ID and each value is an integer difficulty rating value for display in Freeplay.
- `songVariations`: An array of string variation IDs this song has. The game will attempt to read `<songid>-metadata-<variationid>.json` and `<songid>-chart-<variationid>.json` files for each variation ID included in this list.
- `difficulties`: An array of string difficulties this song has available to play. Any difficulties in this list will be made available to players in-game, and any difficulties not in this list will be ignored.
- `characters`: A Song Character Data object.
- `stage`: The stage to use for this chart, as a string ID.
- `noteStyle`: The note style to use for this chart, as a string ID.

The Song Character Data objects have the following keys:
- `player`: The player character to use, as a string ID.
- `girlfriend`: The girlfriend character to use, as a string ID.
- `opponent`: The opponent character to use, as a string ID.
- `instrumental`: The instrumental ID to use. Defaults to a blank string to use `Inst.ogg`
- `altInstrumentals`:

The Song Offset Data objects have the following keys:

#### <songid>-metadata.json Example

```jsonc
{
  "version": "2.2.2", // Semantic Version string
  "songName": "DadBattle", // Readable song name
  "artist": "Kawai Sprite", // Song artist(s)
  "timeFormat": "ms", // Time format to use
  "timeChanges": [{ // List of BPM changes. Must have at least one.
    "t": 0, // BPM change timestamp in milliseconds.
    "bpm": 180 // The target BPM.
  }],
  "playData": {
    "album": "volume1", // The album to display in Freeplay.
    "previewStart": 0, // Time (ms) to start preview at
    "previewEnd": 15000, // Time (ms) to end preview at
    "ratings": { // Rating data for each difficulty
      "easy": 1, // Rating for Easy difficulty
      "normal": 3, // Rating for Normal difficulty
      "hard": 5 // Rating for Hard difficulty
    },
    "songVariations": [ // Available variation files.
      "erect" // This says dadbattle-metadata-erect.json exists.
    ],
    "difficulties": [ // Available difficulties.
      "easy",
      "normal",
      "hard"
    ],
    "characters": { // Characters to use for this variation.
      "player": "bf", // Boyfriend
      "girlfriend": "gf", // Girlfriend
      "opponent": "dad" // Daddy Dearest
    },
    "stage": "mainStage", // Week 1 stage.
    "noteStyle": "funkin" // Default note style.
  },
  "generatedBy": "EliteMasterEric (by hand)" // Unique string.
}

```

### <songid>-chart.json
Song chart data for the `default` variation.

### <songid>-metadata-<variation>.json
*(optional)* Song metadata for alternate variations.

### <songid>-chart-<variation>.json
*(optional)* Song chart data for alternate variations.
