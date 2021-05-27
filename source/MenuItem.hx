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
		// WHAT THE FUCK
		// IS THIS :GRIEF:
		// WHY THE FUCK DO YOU READ A FILE FUCKING 5 TIMES
		// NO WONDER THERE ARE PREFORMANCE ISSUE
		
		var parsedWeekJson:StoryMenuState.StorySongsJson = CoolUtil.parseJson(FNFAssets.getText("assets/data/storySongList.json"));
		var rawPic = FNFAssets.getBitmapData('assets/images/campaign-ui-week/week'+weekNum+".png");
		
		var rawXml:String = "";
		if (FNFAssets.exists('assets/images/campaign-ui-week/week' + weekNum + ".xml")) {
			rawXml = FNFAssets.getText('assets/images/campaign-ui-week/week' + weekNum + ".xml");
		}
		if (rawXml != "") {
			var tex = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
			var animName:String = "";
			if (parsedWeekJson.version == 1)
			{
				animName = parsedWeekJson.songs[weekNum][0];
			}
			if (parsedWeekJson.version == 2)
			{
				animName = parsedWeekJson.weeks[weekNum].animation;
			}
			week = new FlxSprite();
			week.frames = tex;
			// TUTORIAL IS WEEK 0
			week.animation.addByPrefix("default", animName, 24);
			add(week);

			week.animation.play('default');
			week.animation.pause();
			week.updateHitbox();
		} else {
			week.loadGraphic(rawPic);
			add(week);
			week.updateHitbox();
		}
		
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		y = FlxMath.lerp(y, (targetY * 120) + 480, 0.17 / (CoolUtil.fps / 60));
	}
}
