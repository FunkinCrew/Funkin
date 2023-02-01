package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import openfl.Assets;
import sys.io.File;

class DebugBoundingState extends FlxState
{
	override function create()
	{
		var bf:FlxSprite = new FlxSprite().loadGraphic(Paths.image('characters/temp'));
		add(bf);

		FlxG.stage.window.onDropFile.add(function(path:String)
		{
			trace("DROPPED FILE FROM: " + Std.string(path));
			var newPath = "./" + Paths.image('characters/temp');
			File.copy(path, newPath);

			var swag = Paths.image('characters/temp');

			if (bf != null)
				remove(bf);
			FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
			Assets.cache.clear();

			bf.loadGraphic(Paths.image('characters/temp'));
			add(bf);
		});

		super.create();
	}
}
