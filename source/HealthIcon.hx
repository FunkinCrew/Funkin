package;

import flixel.FlxSprite;
import lime.utils.Assets;
import lime.system.System;
import flash.display.BitmapData;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;

import sys.FileSystem;
#end
import haxe.Json;
import haxe.format.JsonParser;
import tjson.TJSON;
using StringTools;
class HealthIcon extends FlxSprite
{
	var player:Bool = false;
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		player = isPlayer;
		super();
		antialiasing = true;
		switchAnim(char);
		scrollFactor.set();

	}
	public function switchAnim(char:String = 'bf') {
		var charJson:Dynamic = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_chars/custom_chars.jsonc"));
		var iconJson:Dynamic = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_chars/icon_only_chars.json"));
		var iconFrames:Array<Int> = [];
		if (Reflect.hasField(charJson, char))
		{
			iconFrames = Reflect.field(charJson, char).icons;
		}
		else if (Reflect.hasField(iconJson, char))
		{
			iconFrames = Reflect.field(iconJson, char);
		}
		else
		{
			iconFrames = [0, 0, 0];
		}
		if (FNFAssets.exists('assets/images/custom_chars/' + char + "/icons.png"))
		{
			var rawPic:BitmapData = FNFAssets.getBitmapData('assets/images/custom_chars/' + char + "/icons.png");
			loadGraphic(rawPic, true, 150, 150);
			animation.add('icon', iconFrames, false, player);
		}
		else
		{
			loadGraphic('assets/images/iconGrid.png', true, 150, 150);
			animation.add('icon', iconFrames, false, player);
		}
		animation.play('icon');
	}
}
