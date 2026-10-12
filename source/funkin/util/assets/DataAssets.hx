package funkin.util.assets;

@:nullSafety
class DataAssets
{
  static function buildDataPath(path:String):String
  {
    return 'assets/data/${path}';
  }

  public static function listDataFilesInPath(path:String, suffix:String = '.json'):Array<String>
  {
    var textAssets = openfl.utils.Assets.list(TEXT);

    var queryPath = buildDataPath(path);

    var results:Array<String> = [];
    for (textPath in textAssets)
    {
      if (textPath.startsWith(queryPath) && textPath.endsWith(suffix))
      {
        var pathNoSuffix = textPath.substring(0, textPath.length - suffix.length);
        var pathNoPrefix = pathNoSuffix.substring(queryPath.length);

        // No duplicates! Why does this happen?
        if (!results.contains(pathNoPrefix)) results.push(pathNoPrefix);
      }
    }

    return results;
  }
}
