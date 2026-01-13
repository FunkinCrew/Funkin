import haxe.Json;
import haxe.Log;
import haxe.macro.Compiler;
import sys.FileSystem;
import sys.io.File;

using StringTools;

#if !interp
package art;

// needs this thing to be run by interp, just for me lol!
#end
// general use of this!!
// if run in INTERP MODE:
//		- art>haxe --main SongConverter --interp
//		- song to convert: ../assets/preload/data/
//		it will run through EVERY folder in there and convert the old songs to the new format!
// TODO make instructions for the C# script version!
class SongConverter
{
  public static var VERSION:String = '0.1.0';

  // TODO
  // Update engine shit, to accomodate single file
  static function main()
  {
    // trace(Compiler.get);
    // trace(Compiler.getDefine('sysfsd'));

    Sys.stdout().writeString('Please type directory you want to convert: ');
    Sys.stdout().flush();
    final input = Sys.stdin().readLine();
    trace('Hello ${input}!');

    /* Sys.stdout().writeString('What type of conversion do you need?\n\t0: Old charts to new chart\n\t1: new chart to .... new chart? lol\n>');
      Sys.stdout().flush();
      final deleteShitIDK = Std.parseInt(Sys.stdin().readLine());

      trace(deleteShitIDK); */

    var songCount:Int = 0;

    for (fileThing in FileSystem.readDirectory('${input}/.'))
    {
      // trace(fileThing);
      // trace(FileSystem.isDirectory(${input} + "/" + fileThing));

      if (FileSystem.isDirectory(${input} + "/" + fileThing) && fileThing.toLowerCase() != 'smash')
      {
        trace('Formatting $fileThing');
        formatSongs(fileThing, input);

        songCount++;
      }
    }

    trace('CONVERTED $songCount SONGS!!');

    var timer:Int = 5;

    while (timer > 0)
    {
      Sys.stdout().writeString('CLOSING IN $timer SECONDS!');
      Sys.sleep(1);
      Sys.print("\r");
      timer -= 1;
    }
  }

  public static function formatSongs(songName:String, root:String)
  {
    var existsArray:Array<Bool> = [];

    var songMap:Map<String, Dynamic> = new Map();
    var speedMap:Map<String, Dynamic> = new Map();

    for (songFile in FileSystem.readDirectory('$root/$songName/'))
    {
      if (!songFile.endsWith('json') || !songFile.startsWith(songName)) continue; // ACCOMODATE FOR PICO SPEAKER EVENTUALLY!

      var funnyFile:Dynamic = cast Json.parse(File.getContent('$root/$songName/$songFile'));

      var songSplit:Array<String> = songFile.split('-');
      var songShit:String = 'normal';

      if (songSplit.length > 1)
      {
        if (songSplit[1] == 'new.json')
        {
          FileSystem.deleteFile('$root/$songName/$songFile');
          trace('DELETEING $songFile');
          continue;
        }

        songShit = songSplit[1].substr(0, songSplit[1].length - 5);
      }

      if (songShit != 'normal')
      {
        songMap[songShit] = funnyFile.song.notes;
        speedMap[songShit] = funnyFile.song.speed;
      }
      else
      {
        //

        if (funnyFile.song.notes is Array)
        {
          songMap[songShit] = funnyFile.song.notes[1];
          speedMap[songShit] = funnyFile.song.speed[1];
        }
        else if (Type.typeof(funnyFile.song.notes) == TObject)
        {
          var dipshitMap:Map<String, Dynamic> = cast funnyFile.song.notes;

          // songMap[songShit] = dipshitMap.get('normal');
        }
        else
        {
          songMap[songShit] = funnyFile.song.notes;
          speedMap[songShit] = funnyFile.song.speed;
        }
      }
    }

    var fileNormal:Dynamic = cast Json.parse(File.getContent('$root/$songName/$songName.json'));

    fileNormal.song.notes = songMap;
    fileNormal.song.speed = speedMap;

    fileNormal.song.hasDialogueFile = false;
    fileNormal.song.stageDefault = getStage(songName);

    fileNormal.version = 'FNF SongConverter $VERSION';

    var daJson = Json.stringify(fileNormal, null, "\t");
    // trace(daJson);
    File.saveContent('$root/$songName/$songName.json', daJson);
  }

  static function noteCleaner(notes:Array<Dynamic>):Array<Dynamic>
  {
    var swagArray:Array<Dynamic> = [];
    for (i in notes)
    {
      if (i.sectionNotes.length > 0) swagArray.push(i);
    }

    return swagArray;
  }

  /**
   * Quicky lil function just for me formatting the old songs hehehe
   */
  static function getStage(songName:String):String
  {
    switch (songName)
    {
      case 'spookeez' | 'monster' | 'south':
        return "spooky";
      case 'pico' | 'blammed' | 'philly':
        return 'philly';
      case "milf" | 'satin-panties' | 'high':
        return 'limo';
      case "cocoa" | 'eggnog':
        return 'mall';
      case 'winter-horrorland':
        return 'mallEvil';
      case 'senpai' | 'roses':
        return 'school';
      case 'thorns':
        return 'schoolEvil';
      case 'guns' | 'stress' | 'ugh':
        return 'tank';
      default:
        return 'stage';
    }
  }
}
