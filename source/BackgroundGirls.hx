package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flash.display.BitmapData;
import lime.utils.Assets;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
#end
class BackgroundGirls extends FlxSprite
{
	public function new(x:Float, y:Float, ?gorlsPic:BitmapData, ?gorlsXml:String)
	{
		super(x, y);

		// BG fangirls dissuaded
		if (gorlsPic != null && gorlsXml != null) {
			frames = FlxAtlasFrames.fromSparrow(gorlsPic, gorlsXml);
		} else {
			frames = FlxAtlasFrames.fromSparrow('assets/images/weeb/bgFreaks.png', 'assets/images/weeb/bgFreaks.xml');
		}

		animation.addByIndices('danceLeft', 'BG girls group', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG girls group', CoolUtil.numberArray(30, 15), "", 24, false);

		animation.play('danceLeft');
	}

	var danceDir:Bool = false;

	public function getScared():Void
	{
		animation.addByIndices('danceLeft', 'BG fangirls dissuaded', CoolUtil.numberArray(14), "", 24, false);
		animation.addByIndices('danceRight', 'BG fangirls dissuaded', CoolUtil.numberArray(30, 15), "", 24, false);
		dance();
	}

	public function dance():Void
	{
		danceDir = !danceDir;

		if (danceDir)
			animation.play('danceRight', true);
		else
			animation.play('danceLeft', true);
	}
}
