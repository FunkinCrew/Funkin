package funkin.data.song.importer;

import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.importer.QuaverData.QuaverTimingPoint;
import funkin.data.song.importer.QuaverData.QuaverSliderVelocity;
import funkin.data.song.importer.QuaverData.QuaverHitObject;
import funkin.data.song.importer.QuaverData.QuaverMode;

class QuaverImporter
{
  // Quaver's file format is basically a YAML. This is not a full YAML parser.
  public static function parseQuaverFile(quaverContent:String):Null<QuaverData>
  {
    if (quaverContent == null || quaverContent.length == 0) return null;

    var lines:Array<String> = quaverContent.split('\n');
    var result:Dynamic = {};
    var currentSection:Null<String> = null;
    var currentItem:Dynamic = null;

    inline function ensureSection(sectionName:String):Array<Dynamic>
    {
      var section:Array<Dynamic> = cast Reflect.field(result, sectionName);
      if (section == null)
      {
        section = [];
        Reflect.setField(result, sectionName, section);
      }
      return section;
    }

    inline function flushCurrentItem():Void
    {
      if (currentItem != null && currentSection != null)
      {
        var converted:Dynamic = switch (currentSection)
        {
          case 'TimingPoints': new QuaverTimingPoint(currentItem.StartTime, currentItem.Bpm, currentItem.Signature);
          case 'SliderVelocities': new QuaverSliderVelocity(currentItem.StartTime, currentItem.Multiplier);
          case 'HitObjects': new QuaverHitObject(currentItem.StartTime, currentItem.Lane, currentItem.EndTime);
          default: currentItem;
        };
        ensureSection(currentSection).push(converted);
        currentItem = null;
      }
    }

    for (rawLine in lines)
    {
      var line:String = StringTools.rtrim(rawLine);
      var trimmedLine:String = StringTools.trim(line);
      if (trimmedLine.length == 0 || line.length == 0) continue;

      var isIndented:Bool = (line != trimmedLine);

      // Section headers have no indentation and are not list items.
      if (!isIndented && !StringTools.startsWith(trimmedLine, '-'))
      {
        flushCurrentItem();
        currentSection = null;

        var parts:Array<String> = trimmedLine.split(':');
        if (parts.length == 0) continue;

        var key:String = StringTools.trim(parts.shift());
        if (key.length == 0) continue;

        var value:String = StringTools.trim(parts.join(':'));

        if (value == '')
        {
          currentSection = key;
          ensureSection(currentSection);
        }
        else if (key == 'Mode')
        {
          result.Mode = switch (value)
          {
            case 'Keys4': QuaverMode.Keys4;
            case 'Keys7': QuaverMode.Keys7;
            default: QuaverMode.Keys4;
          };
        }
        else
        {
          Reflect.setField(result, key, parseValue(value));
        }
      }
      else if (currentSection != null)
      {
        // This is the start of an object, push the previous one if it exists.
        if (StringTools.startsWith(trimmedLine, '-'))
        {
          flushCurrentItem();
          currentItem = {};
          trimmedLine = StringTools.ltrim(trimmedLine.substr(1));
        }

        var parts:Array<String> = trimmedLine.split(':');
        if (parts.length == 0) continue;

        var key:String = StringTools.trim(parts.shift());
        var value:String = StringTools.trim(parts.join(':'));

        // Push to the current item if we're parsing an object, otherwise, push to the section array.
        if (currentItem != null)
        {
          if (key.length > 0) Reflect.setField(currentItem, key, parseValue(value));
        }
        else
        {
          ensureSection(currentSection).push(parseValue(value));
        }
      }
    }

    flushCurrentItem();

    return result;
  }

  /**
   * Migrates QuaverData to SongMetadata.
   * @param data The QuaverData to migrate.
   * @return SongMetadata The migrated SongMetadata.
   */
  public static function migrateMetadata(data:QuaverData):SongMetadata
  {
    var metadata:SongMetadata = new SongMetadata(data.TitleUnicode ?? data.Title, data.ArtistUnicode ?? data.Artist ?? Constants.DEFAULT_ARTIST,
      data.Creator ?? Constants.DEFAULT_CHARTER, Constants.DEFAULT_VARIATION);

    metadata.generatedBy = 'Chart Editor Import (Quaver)';
    metadata.playData.difficulties = [data.DifficultyName];
    metadata.playData.ratings.set(data.DifficultyName, 0); // Quaver doesn't store difficulty ratings
    metadata.playData.previewStart = data.SongPreviewTime;
    metadata.playData.previewEnd = data.SongPreviewTime + 30000;
    metadata.timeChanges = data.TimingPoints.map(function(tp:QuaverTimingPoint):SongTimeChange
    {
      return new SongTimeChange(tp.startTime, tp.bpm, tp.signature);
    });

    // The first time change specified is also the initial BPM.
    metadata.timeChanges.push(new SongTimeChange(0, data.TimingPoints.length > 0 ? data.TimingPoints[0].bpm : Constants.DEFAULT_BPM));

    trace('Time changes: ' + metadata.timeChanges);

    return metadata;
  }

  /**
   * Migrates QuaverData to SongChartData.
   * @param data The QuaverData to migrate.
   * @return SongChartData The migrated SongChartData.
   */
  public static function migrateChart(data:QuaverData):SongChartData
  {
    return new SongChartData([data.DifficultyName => Constants.DEFAULT_SCROLLSPEED], [], [data.DifficultyName => convertNotes(data.HitObjects)]);
  }

  static function convertNotes(hitObjects:Array<QuaverHitObject>):Array<SongNoteData>
  {
    var result:Array<SongNoteData> = [];

    for (hitObject in hitObjects)
    {
      var holdTime:Int = 0;
      if (hitObject.endTime != null)
      {
        holdTime = Std.int(hitObject.endTime - hitObject.startTime);
      }

      result.push(new SongNoteData(hitObject.startTime, (hitObject.lane - 1), holdTime));
    }
    return result;
  }

  static function parseValue(v:String):Any
  {
    var result:Null<Any>;

    if (v == 'true') return true;
    if (v == 'false') return false;
    if (v == '[]') return [];

    if (v.contains('.'))
    {
      result = Std.parseFloat(v);
      if (!Math.isNaN(result)) return result;
    }
    else
    {
      result = Std.parseInt(v);
      if (result != null) return result;
    }

    return v;
  }
}
