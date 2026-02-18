package funkin.util.assets;

@:nullSafety
class DataAssets
{
  static function buildDataPath(path:String):String
  {
    return 'assets/data/${path}';
  }

  /**
   * List data files that match the given prefix and suffix.
   * @param path A path prefix for the data file name.
   * @param suffix A path suffix for the data file name.
   * @param blacklist An array of paths to exclude from the list.
   * @param nested Whether to parse nested data files as only the last part of the path.
   *     Use `true`, if you expect files will be at `<path>/<id>/<id><suffix>`
   * @return A list of results, with path and extension removed.
   */
  public static function listDataFilesInPath(path:String, suffix:String = '.json', ?blacklist:Array<String>, nested:Bool = false):Array<String>
  {
    if (blacklist == null) blacklist = [];

    var textAssets:Array<String> = openfl.utils.Assets.list(TEXT);

    var queryPath:String = 'assets/${path}';

    var results:Array<String> = [];
    for (textPath in textAssets)
    {
      if (textPath.startsWith(queryPath) && textPath.endsWith(suffix))
      {
        var pathNoSuffix:String = textPath.substring(0, textPath.length - suffix.length);
        var pathNoPrefix:String = pathNoSuffix.substring(queryPath.length);

        var id:String = pathNoPrefix;
        if (nested)
        {
          var parts:Array<String> = pathNoPrefix.split('/');
          id = parts[0];
        }

        if (blacklist.contains(id)) continue;

        // No duplicates!
        if (!results.contains(id)) results.push(id);
      }
    }

    trace('[ASSETS] Got ${results.length} data files in path: ${queryPath}*${suffix}');

    return results;
  }
}
