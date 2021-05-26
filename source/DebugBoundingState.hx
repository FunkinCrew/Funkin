package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.Assets;
import sys.io.File;

class DebugBoundingState extends FlxState
{
	override function create()
	{
		var bg:FlxSprite = FlxGridOverlay.create(10, 10);

		bg.scrollFactor.set();
		add(bg);

		var tex = Paths.getSparrowAtlas('characters/temp');
		// tex.frames[0].uv

		var bf:FlxSprite = new FlxSprite();
		bf.loadGraphic(tex.parent);
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

	override function update(elapsed:Float)
	{
		CoolUtil.mouseCamDrag();
		super.update(elapsed);
	}
}
