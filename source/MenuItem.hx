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
		var parsedVersionJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/gameInfo.json")).version;
		var parsedName_1Json:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/gameInfo.json")).name_1;
		var parsedName_2Json:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/gameInfo.json")).name_2;
		var parsedName_3Json:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/gameInfo.json")).name_3;
		var parsedcustomMenuConfirmJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuConfirm;
		var parsedcustomMenuScrollJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).customMenuScroll;
		var parsedcustomMenuScrollJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/sounds/custom_menu_sounds/custom_menu_sounds.json")).Menu;
		var parsedcustomFreakyMenuJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/music/custom_menu_music/custom_menu_music.json")).Menu;
		var parsedcustomOptionsMusicJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/music/custom_menu_music/custom_menu_music.json")).Options;
		var parsedcbgJson:Array<Array<String>> = CoolUtil.parseJson(File.getContent("assets/data/freeplaySongJson.json")).cbg;
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
