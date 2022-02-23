package util.assets;

using StringTools;

class DataAssets
{
	static function buildDataPath(path:String):String
	{
		return 'assets/data/${path}';
	}

	public static function listDataFilesInPath(path:String, ?ext:String = '.json'):Array<String>
	{
		var textAssets = openfl.utils.Assets.list();
		var queryPath = buildDataPath(path);

		var results:Array<String> = [];
		for (textPath in textAssets)
		{
			if (textPath.startsWith(queryPath) && textPath.endsWith(ext))
			{
				var pathNoSuffix = textPath.substring(0, textPath.length - ext.length);
				var pathNoPrefix = pathNoSuffix.substring(queryPath.length);
				results.push(pathNoPrefix);
			}
		}

		return results;
	}
}
