package;

import flixel.FlxSprite;
import lime.utils.Assets;
import haxe.Json;
#if sys
import sys.io.File;
import haxe.io.Path;
import lime.system.System;
#end
import haxe.format.JsonParser;
using StringTools;
class HealthIcon extends FlxSprite
{
	public function new(char:String = 'bf', isPlayer:Bool = false)
	{
		super();
		loadGraphic('assets/images/iconGrid.png', true, 150, 150);
		#if sys
		var charJson:Dynamic = Json.parse(File.getContent(Path.normalize(System.applicationDirectory+"assets/images/custom_chars/custom_chars.json")));
		#end
		var rawCharList = Assets.getText('assets/images/custom_chars/charlist.txt').trim();
		var splitCharList = rawCharList.split("\n");
		antialiasing = true;
		animation.add('bf', [0, 1], 0, false, isPlayer);
		animation.add('bf-car', [0, 1], 0, false, isPlayer);
		animation.add('bf-christmas', [0, 1], 0, false, isPlayer);
		animation.add('spooky', [2, 3], 0, false, isPlayer);
		animation.add('pico', [4, 5], 0, false, isPlayer);
		animation.add('mom', [6, 7], 0, false, isPlayer);
		animation.add('mom-car', [6, 7], 0, false, isPlayer);
		animation.add('tankman', [8, 9], 0, false, isPlayer);
		animation.add('face', [10, 11], 0, false, isPlayer);
		animation.add('dad', [12, 13], 0, false, isPlayer);
		animation.add('bf-old', [14, 15], 0, false, isPlayer);
		animation.add('gf', [16], 0, false, isPlayer);
		animation.add('parents-christmas', [17], 0, false, isPlayer);
		animation.add('monster', [19, 20], 0, false, isPlayer);
		animation.add('monster-christmas', [19, 20], 0, false, isPlayer);
		#if sys
		for (field in Reflect.fields(charJson)) {
			animation.add(field, Reflect.field(charJson,field).icons, 0, false, isPlayer);
		}
		#end
		animation.play(char);
		scrollFactor.set();

	}
}
