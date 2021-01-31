package;

import flixel.FlxSprite;
import lime.utils.Assets;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import flash.display.BitmapData;
#end
import haxe.Json;
import haxe.format.JsonParser;
using StringTools;
class HealthIcon extends FlxSprite
{
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		#if sys
		var charJson:Dynamic = Json.parse(File.getContent(Path.normalize(System.applicationDirectory+"assets/images/custom_chars/custom_chars.json")));
		#end
		antialiasing = true;
		switch (char) {
			case 'bf':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [0, 1], 0, false, isPlayer);
			case 'bf-car':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [0, 1], 0, false, isPlayer);
			case 'bf-christmas':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [0, 1], 0, false, isPlayer);
			case 'spooky':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [2, 3], 0, false, isPlayer);
			case 'pico':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [4, 5], 0, false, isPlayer);
			case 'mom':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [6, 7], 0, false, isPlayer);
			case 'mom-car':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [6, 7], 0, false, isPlayer);
			case 'tankman':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [8, 9], 0, false, isPlayer);
			case 'face':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [10, 11], 0, false, isPlayer);
			case 'dad':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [12, 13], 0, false, isPlayer);
			case 'bf-old':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [14, 15], 0, false, isPlayer);
			case 'gf':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [16, 16], 0, false, isPlayer);
			case 'parents-christmas':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [17,17], 0, false, isPlayer);
			case 'monster':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [19, 20], 0, false, isPlayer);
			case 'monster-christmas':
				loadGraphic('assets/images/iconGrid.png', true, 150, 150);
				animation.add('icon', [19, 20], 0, false, isPlayer);
			default:
				if (!!Reflect.field(charJson,char).uniqueicons) {
					var rawPic:BitmapData = BitmapData.fromBytes(ByteArray.fromBytes(File.getBytes(Path.normalize(System.applicationDirectory+'/assets/images/custom_chars/'+char+"_icons.png"))));
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
