package funkin;

import funkin.Section.SwagSection;
import funkin.noteStuff.NoteBasic.NoteData;
import funkin.play.PlayState;
import haxe.Json;
import lime.utils.Assets;

typedef SwagSong =
{
  var song:String;
  var notes:FunnyNotes;
  var difficulties:Array<String>;
  var noteMap:Map<String, Array<SwagSection>>;
  var bpm:Float;
  var needsVoices:Bool;
  var voiceList:Array<String>;
  var speed:FunnySpeed;
  var speedMap:Map<String, Float>;

  var player1:String;
  var player2:String;
  var validScore:Bool;
  var extraNotes:Map<String, Array<SwagSection>>;
}

typedef FunnySpeed =
{
  var ?easy:Float;
  var ?normal:Float;
  var ?hard:Float;
}

typedef FunnyNotes =
{
  var ?easy:Array<SwagSection>;
  var ?normal:Array<SwagSection>;
  var ?hard:Array<SwagSection>;
}

class SongLoad
{
  public static var curDiff:String = 'normal';
  public static var curNotes:Array<SwagSection>;
  public static var songData:SwagSong;

  public static function loadFromJson(jsonInput:String, ?folder:String):SwagSong
  {
    var rawJson:String = null;
    try
    {
      rawJson = Assets.getText(Paths.json('songs/${folder.toLowerCase()}/${jsonInput.toLowerCase()}')).trim();
    }
    catch (e)
    {
      trace('Failed to load song data: ${e}');
      rawJson = null;
    }

    if (rawJson == null)
    {
      return null;
    }

    while (!rawJson.endsWith("}"))
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return parseJSONshit(rawJson);
  }

  public static function getSong(?diff:String):Array<SwagSection>
  {
    if (diff == null) diff = SongLoad.curDiff;

    var songShit:Array<SwagSection> = [];

    // THIS IS OVERWRITTEN, WILL BE DEPRECTATED AND REPLACED SOOOOON
    if (songData != null)
    {
      switch (diff)
      {
        case 'easy':
          songShit = songData.notes.easy;
        case 'normal':
          songShit = songData.notes.normal;
        case 'hard':
          songShit = songData.notes.hard;
      }
    }

    checkAndCreateNotemap(curDiff);

    songShit = songData.noteMap[diff];

    return songShit;
  }

  public static function checkAndCreateNotemap(diff:String):Void
  {
    if (songData == null || songData.noteMap == null) return;
    if (songData.noteMap[diff] == null) songData.noteMap[diff] = [];
  }

  public static function getSpeed(?diff:String):Float
  {
    if (PlayState.instance != null && PlayState.instance.currentChart != null)
    {
      return getSpeed_NEW(diff);
    }

    if (diff == null) diff = SongLoad.curDiff;

    var speedShit:Float = 1;

    // all this shit is overridden by the thing that loads it from speedMap Map object!!!
    // replace and delete later!
    switch (diff)
    {
      case 'easy':
        speedShit = songData?.speed?.easy ?? 1.0;
      case 'normal':
        speedShit = songData?.speed?.normal ?? 1.0;
      case 'hard':
        speedShit = songData?.speed?.hard ?? 1.0;
    }

    if (songData?.speedMap == null || songData?.speedMap[diff] == null)
    {
      speedShit = 1;
    }
    else
    {
      speedShit = songData.speedMap[diff];
    }

    return speedShit;
  }

  public static function getSpeed_NEW(?diff:String):Float
  {
    if (PlayState.instance == null
      || PlayState.instance.currentChart == null
      || PlayState.instance.currentChart.scrollSpeed == 0.0) return 1.0;

    return PlayState.instance.currentChart.scrollSpeed;
  }

  public static function getDefaultSwagSong():SwagSong
  {
    return {
      song: 'Test',
      notes: {easy: [], normal: [], hard: []},
      difficulties: ["easy", "normal", "hard"],
      noteMap: new Map(),
      speedMap: new Map(),
      bpm: 150,
      needsVoices: true,
      player1: 'bf',
      player2: 'dad',
      speed:
        {
          easy: 1,
          normal: 1,
          hard: 1
        },
      validScore: false,
      voiceList: ["BF", "BF-pixel"],
      extraNotes: []
    };
  }

  public static function getDefaultNoteData():NoteData
  {
    return new NoteData();
  }

  /**
   *	Casts the an array to NOTE data (for LOADING shit from json usually)
   */
  public static function castArrayToNoteData(noteStuff:Array<SwagSection>)
  {
    if (noteStuff == null) return;

    for (sectionIndex => section in noteStuff)
    {
      if (section == null || section.sectionNotes == null) continue;
      for (noteIndex => noteDataArray in section.sectionNotes)
      {
        var arrayDipshit:Array<Dynamic> = cast noteDataArray; // crackhead

        if (arrayDipshit != null) // array isnt null, that means it loaded it as an array and needs to be manually parsed?
        {
          // at this point noteStuff[sectionIndex].sectionNotes[noteIndex] is an array because of the cast from the first line in this function
          // so this line right here turns it back into the NoteData typedef type because of another bastard cast
          noteStuff[sectionIndex].sectionNotes[noteIndex] = cast SongLoad.getDefaultNoteData(); // turn it from an array (because of the cast), back to noteData? yeah that works

          noteStuff[sectionIndex].sectionNotes[noteIndex].strumTime = arrayDipshit[0];
          noteStuff[sectionIndex].sectionNotes[noteIndex].noteData = arrayDipshit[1];
          noteStuff[sectionIndex].sectionNotes[noteIndex].sustainLength = arrayDipshit[2];
          if (arrayDipshit.length > 3)
          {
            noteStuff[sectionIndex].sectionNotes[noteIndex].noteKind = arrayDipshit[3];
          }
        }
        else if (noteDataArray != null)
        {
          // array is NULL, so it checks if noteDataArray (doesnt exactly NEED to be an 'array' is also null or not.)
          // At this point it should be an OBJECT that can be easily casted!!!

          noteStuff[sectionIndex].sectionNotes[noteIndex] = cast noteDataArray;
        }
        else
          throw "shit brokey"; // i actually dont know how throw works lol
      }
    }
  }

  /**
   * Cast notedata to ARRAY (usually used for level SAVING)
   */
  public static function castNoteDataToArray(noteStuff:Array<SwagSection>)
  {
    if (noteStuff == null) return;

    for (sectionIndex => section in noteStuff)
    {
      for (noteIndex => noteTypeDefShit in section.sectionNotes)
      {
        var dipshitArray:Array<Dynamic> = [
          noteTypeDefShit.strumTime,
          noteTypeDefShit.noteData,
          noteTypeDefShit.sustainLength,
          noteTypeDefShit.noteKind
        ];

        noteStuff[sectionIndex].sectionNotes[noteIndex] = cast dipshitArray;
      }
    }
  }

  public static function castNoteDataToNoteData(noteStuff:Array<SwagSection>)
  {
    if (noteStuff == null) return;

    for (sectionIndex => section in noteStuff)
    {
      for (noteIndex => noteTypedefShit in section.sectionNotes)
      {
        trace(noteTypedefShit);
        noteStuff[sectionIndex].sectionNotes[noteIndex] = noteTypedefShit;
      }
    }
  }

  public static function parseJSONshit(rawJson:String):SwagSong
  {
    var songParsed:Dynamic;
    try
    {
      songParsed = Json.parse(rawJson);
    }
    catch (e)
    {
      FlxG.log.warn("Error parsing JSON: " + e.message);
      trace("Error parsing JSON: " + e.message);
      return null;
    }

    var swagShit:SwagSong = cast songParsed.song;
    swagShit.difficulties = []; // reset it to default before load
    swagShit.noteMap = new Map();
    swagShit.speedMap = new Map();
    for (diff in Reflect.fields(songParsed.song.notes))
    {
      swagShit.difficulties.push(diff);
      swagShit.noteMap[diff] = cast Reflect.field(songParsed.song.notes, diff);

      castArrayToNoteData(swagShit.noteMap[diff]);

      // castNoteDataToNoteData(swagShit.noteMap[diff]);

      /* 
        switch (diff)
        {
          case "easy":
            castArrayToNoteData(swagShit.notes.hard);

          case "normal":
            castArrayToNoteData(swagShit.notes.normal);
          case "hard":
            castArrayToNoteData(swagShit.notes.hard);
        }
       */
    }

    for (diff in swagShit.difficulties)
    {
      swagShit.speedMap[diff] = cast Reflect.field(songParsed.song.speed, diff);
    }

    // trace(swagShit.noteMap.toString());
    // trace(swagShit.speedMap.toString());
    // trace('that was just notemap string lol');

    swagShit.validScore = true;

    trace("SONG SHIT ABOUTTA WEEK AGOOO");
    for (field in Reflect.fields(Json.parse(rawJson).song.speed))
    {
      // swagShit.speed[field] = Reflect.field(Json.parse(rawJson).song.speed, field);
      // swagShit.notes[field] = Reflect.field(Json.parse(rawJson).song.notes, field);
      // trace(swagShit.notes[field]);
    }

    // swagShit.notes = cast Json.parse(rawJson).song.notes[SongLoad.curDiff]; // by default uses

    trace('THAT SHIT WAS JUST THE NORMAL NOTES!!!');
    songData = swagShit;
    // curNotes = songData.notes.get('normal');

    return swagShit;
  }
}
