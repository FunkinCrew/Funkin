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
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		var charJson:Dynamic = CoolUtil.parseJson(FNFAssets.getText("assets/images/custom_chars/custom_chars.jsonc"));
		antialiasing = true;
		switch (char) {
			case 'face':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [10, 11], 0, false, isPlayer);
			case 'bf-old':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [14, 15], 0, false, isPlayer);
			default:
				// check if there is an icon file
				if (FNFAssets.exists('assets/images/custom_chars/'+char+"/icons.png")) {
					var rawPic:BitmapData =FNFAssets.getBitmapData('assets/images/custom_chars/'+char+"/icons.png");
					loadGraphic(rawPic, true, 150, 150);
					animation.add('icon', Reflect.field(charJson,char).icons, false, isPlayer);
				} else {
					loadGraphic('assets/images/iconGrid.png', true, 150, 150);
					animation.add('icon', Reflect.field(charJson,char).icons, false, isPlayer);
				}
		}
		animation.play('icon');
		scrollFactor.set();

	}
}
