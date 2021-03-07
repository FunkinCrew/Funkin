package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import flash.display.BitmapData;
#end
import haxe.Json;
import haxe.format.JsonParser;
import tjson.TJSON;
class MenuItem extends FlxSpriteGroup
{
	public var targetY:Float = 0;
	public var week:FlxSprite;

	public function new(x:Float, y:Float, weekNum:Int = 0)
	{
		super(x, y);
		var parsedWeekJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/storySongList.json")).songs;
		var rawPic = BitmapData.fromFile('assets/images/campaign-ui-week/week'+weekNum+".png");
		var rawXml = File.getContent('assets/images/campaign-ui-week/week'+weekNum+".xml");
		var tex = FlxAtlasFrames.fromSparrow(rawPic, rawXml);

		week = new FlxSprite();
		week.frames = tex;
		// TUTORIAL IS WEEK 0
		trace(parsedWeekJson[weekNum][0]);
		week.animation.addByPrefix("default", parsedWeekJson[weekNum][0], 24);
		add(week);

		week.animation.play('default');
		week.animation.pause();
		week.updateHitbox();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		y = FlxMath.lerp(y, (targetY * 120) + 480, 0.17);
	}
}
