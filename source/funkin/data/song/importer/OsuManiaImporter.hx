package funkin.data.song.importer;

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.importer.OsuManiaData;
import funkin.data.song.importer.OsuManiaData.TimingPoint;
import funkin.data.song.importer.OsuManiaData.ManiaHitObject;

class OsuManiaImporter
{
  public static function parseOsuFile(osuContent:String):OsuManiaData
  {
    var lines:Array<String> = osuContent.split("\n");
    var result:Dynamic = {};
    var currentSection:String = null;

    var nonCSVLikeSections = ["General", "Editor", "Metadata", "Difficulty"];

    for (line in lines)
    {
      line = StringTools.trim(line);
      if (line == "" || StringTools.startsWith(line, "//")) continue;

      // Section header like [General]
      var sectionRegex = ~/^\[(.+)\]$/;
      if (sectionRegex.match(line))
      {
        currentSection = sectionRegex.matched(1);
        if (nonCSVLikeSections.contains(currentSection))
        {
          Reflect.setField(result, currentSection, {});
        }
        else
        {
          Reflect.setField(result, currentSection, []);
        }
        continue;
      }

      // Key-value pairs (INI style)
      if (currentSection != null && nonCSVLikeSections.contains(currentSection))
      {
        var parts:Array<String> = line.split(":");
        var key:String = StringTools.trim(parts.shift());
        var value:String = StringTools.trim(parts.join(":"));
        if (Reflect.field(result, currentSection) == null) Reflect.setField(result, currentSection, {});
        Reflect.setField(Reflect.field(result, currentSection), key, value);
      }
      // For CSV-like sections
      else if (currentSection != null)
      {
        var theArray:Array<String> = cast Reflect.field(result, currentSection);
        theArray.push(line);
        Reflect.setField(result, currentSection, theArray);
      }
    }

    return result;
  }

  /**
   * @param data The raw parsed JSON data to migrate, as a Dynamic.
   * @param difficulty
   * @return SongMetadata
   */
  public static function migrateMetadata(songData:OsuManiaData, difficulty:String = 'normal'):SongMetadata
  {
    trace('Migrating song metadata from Osu!Mania.');

    var songMetadata:SongMetadata = new SongMetadata('Import', songData.Metadata.ArtistUnicode ?? songData.Metadata.Artist ?? Constants.DEFAULT_ARTIST,
      songData.Metadata.Creator ?? Constants.DEFAULT_CHARTER, Constants.DEFAULT_VARIATION);

    // Set generatedBy string for debugging.
    songMetadata.generatedBy = 'Chart Editor Import (Osu!Mania)';

    songMetadata.playData.stage = 'mainStage';
    songMetadata.songName = songData.Metadata.TitleUnicode ?? songData.Metadata.Title ?? 'Import';
    songMetadata.playData.difficulties = [difficulty];

    songMetadata.playData.songVariations = [];

    songMetadata.timeChanges = rebuildTimeChanges(songData);

    songMetadata.playData.characters = new SongCharacterData('bf', 'gf', 'dad');
    songMetadata.playData.ratings.set(difficulty, songData.Difficulty.OverallDifficulty ?? 0);

    return songMetadata;
  }

  static function rebuildTimeChanges(songData:OsuManiaData):Array<SongTimeChange>
  {
    var timings:Array<TimingPoint> = parseTimingPoints(cast songData.TimingPoints);
    var bpmPoints:Array<TimingPoint> = timings.filter((tp) -> tp.uninherited == 1);

    var result:Array<SongTimeChange> = [];
    if (bpmPoints.length >= 1)
    {
      result.push(new SongTimeChange(0, bpmPoints[0].bpm ?? Constants.DEFAULT_BPM));

      for (i in 1...bpmPoints.length)
      {
        var bpmPoint:TimingPoint = bpmPoints[i];

        result.push(new SongTimeChange(bpmPoint.time, bpmPoint.bpm ?? Constants.DEFAULT_BPM));
      }
    }

    if (result.length == 0)
    {
      result.push(new SongTimeChange(0, Constants.DEFAULT_BPM));
      trace("[WARN] No BPM points found, resulting to default BPM...");
    }

    return result;
  }

  public static function migrateChartData(songData:OsuManiaData, difficulty:String = 'normal'):SongChartData
  {
    trace('Migrating song chart data from Osu!Mania.');

    // Osu!Mania doesn't have a scroll speed variable as its controlled by the player
    var songChartData:SongChartData = new SongChartData([difficulty => Constants.DEFAULT_SCROLLSPEED], [], [difficulty => []]);

    // songData.HitObjects is a Array<String> here so im casting it so haxe stops yelling at me
    var osuNotes:Array<ManiaHitObject> = parseManiaHitObjects(cast songData.HitObjects, songData.Difficulty.CircleSize);
    songChartData.notes.set(difficulty, convertNotes(osuNotes, songData.Difficulty.CircleSize));

    songChartData.events = [];

    return songChartData;
  }

  static final STRUMLINE_SIZE = 4;

  static function convertNotes(hitObjects:Array<ManiaHitObject>, keyCount:Int):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = [];

    for (hitObject in hitObjects)
    {
      var wrappedColumn:Int = hitObject.column % (keyCount * 2); // wrap overflow for 9K+
      if (keyCount <= 4) // if its 5K+ dont add the copies beatmap into the opponent
      {
        var noteOffset:Int = Std.int(Math.abs(keyCount - STRUMLINE_SIZE)); // to make it on the opponent strumline when on 3K it has a one note offset
        var flippedNoteData:Int = wrappedColumn + keyCount + noteOffset;
        result.push(new SongNoteData(hitObject.time, flippedNoteData, hitObject.holdDuration ?? 0, ''));
      }
      result.push(new SongNoteData(hitObject.time, wrappedColumn, hitObject.holdDuration ?? 0, ''));
    }

    return result;
  }

  static function parseTimingPoints(timingLines:Array<String>):Array<TimingPoint>
  {
    return timingLines.map(function(line:String):TimingPoint {
      var parts = line.split(",");
      var time = Std.parseFloat(parts[0]);
      var beatLength = Std.parseFloat(parts[1]);
      var meter = Std.parseInt(parts[2]);
      var sampleSet = Std.parseInt(parts[3]);
      var sampleIndex = Std.parseInt(parts[4]);
      var volume = Std.parseInt(parts[5]);
      var uninherited = Std.parseInt(parts[6]);
      var effects = Std.parseInt(parts[7]);

      return new TimingPoint(time, beatLength, meter, sampleSet, sampleIndex, volume, uninherited, effects);
    });
  }

  static function parseManiaHitObjects(hitObjectsLines:Array<String>, ?columns:Int = 4):Array<ManiaHitObject>
  {
    return hitObjectsLines.map(function(line:String):ManiaHitObject {
      var parts = line.split(",");

      var x:Int = Std.parseInt(parts[0]);
      var time:Int = Std.parseInt(parts[2]);
      var type:Int = Std.parseInt(parts[3]);
      var hasHold:Bool = (type & 128) == 128;

      var noteD:Int = Std.int(x / (512 / columns));
      var holdEndTime:Null<Int> = hasHold ? Std.parseInt(parts[5].split(":")[0]) : null;

      var holdDuration:Int = (holdEndTime != null) ? (holdEndTime - time) : 0;

      return new ManiaHitObject(time, noteD, holdDuration);
    });
  }
}
