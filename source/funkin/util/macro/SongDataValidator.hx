package funkin.util.macro;

import haxe.crypto.Sha1;
import haxe.rtti.Meta;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.io.Path;
import sys.FileSystem;
#end

class SongDataValidator
{
  static var _allCharts:Map<String, String> = null;
  static var _checkedCharts:Array<String> = [];
  static var _invalidCharts:Array<String> = [];

  /**
   * See if the chart for the variation is valid, i.e. if the chart content differs from the compilation-time one.
   * If it isn't, add it to an array of invalid charts.
   * @param chartContent    The content of the chart file.
   */
  public static function checkChartValidity(chartContent:String, songId:String, variation:String = "default"):Void
  {
    var songFormat:String = '${songId}::${variation}';

    // If the chart is already checked, do nothing.
    if (_checkedCharts.contains(songFormat)) return;

    // If the all charts list is null, fetch it from the class' type.
    if (_allCharts == null)
    {
      var metaData:Dynamic = Meta.getType(SongDataValidator);

      if (metaData.charts != null)
      {
        _allCharts = [];

        for (element in (metaData.charts ?? []))
        {
          if (element.length != 2) throw 'Malformed element in chart datas: ' + element;

          var song:String = element[0];
          var data:String = element[1];

          _allCharts.set(song, data);
        }
      }
      else
      {
        throw 'No chart datas found in SongDataValidator';
      }
    }

    var isValid:Bool = false;

    // If there is no chart found for the song and variation, it's a custom song and it should always be valid.
    if (!_allCharts.exists(songFormat))
    {
      isValid = true;
    }
    else
    {
      // Check if the content matches.
      var chartClean:String = Sha1.encode(chartContent);
      if (chartClean == _allCharts.get(songFormat)) isValid = true;
    }

    // Add to an array if the chart is invalid.
    if (!isValid)
    {
      trace('  [WARN] The chart file for the song $songId and variation $variation has been tampered with.');
      _invalidCharts.push(songFormat);
    }

    // Add the song to the checked charts so that we don't have to run checks again.
    _checkedCharts.push(songFormat);
  }

  /**
   * Returns true if the chart isn't in the invalid charts list.
   */
  public static function isChartValid(songId:String, variation:String = "default"):Bool
  {
    return !_invalidCharts.contains('${songId}::${variation}');
  }

  /**
   * Clear the lists so we can check for songs again.
   */
  public static function clearLists():Void
  {
    _checkedCharts = [];
    _invalidCharts = [];
  }

  #if macro
  public static inline final BASE_PATH:String = "assets/preload/data/songs";

  static var calledBefore:Bool = false;
  #end

  public static macro function loadSongData():Void
  {
    Context.onAfterTyping(function(_) {
      if (calledBefore) return;
      calledBefore = true;

      var allCharts:Array<Expr> = [];

      // Load songs from the assets folder.
      var songs:Array<String> = FileSystem.readDirectory(BASE_PATH);
      for (song in songs)
      {
        var songFiles:Array<String> = FileSystem.readDirectory(Path.join([BASE_PATH, song]));
        for (file in songFiles)
        {
          if (!StringTools.endsWith(file, ".json")) continue; // Exclude non-json files.

          var splitter:Array<String> = StringTools.replace(file, ".json", "").split("-");

          if (splitter[1] != "chart") continue; // Exclude non-chart files.

          var variation:String = splitter[2] ?? "default";
          var chart:String = sys.io.File.getContent(Path.join([BASE_PATH, song, file]));

          chart = Sha1.encode(StringTools.trim(chart));

          var entry = [macro $v{'${song}::${variation}'}, macro $v{chart}];

          allCharts.push(macro $a{entry});
        }
      }

      // Add the chart data to the class.
      var dataClass = Context.getType('funkin.util.macro.SongDataValidator');

      switch (dataClass)
      {
        case TInst(t, _):
          var dataClassType = t.get();
          dataClassType.meta.remove('charts');
          dataClassType.meta.add('charts', allCharts, Context.currentPos());
        default:
          throw 'Could not find SongDataValidator type';
      }
    });
  }
}
