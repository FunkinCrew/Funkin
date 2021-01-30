package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import flash.display.BitmapData;
#end
import haxe.Json;
import haxe.format.JsonParser;

class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var like:String;
	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		this.character = character;

		var parsedCharJson = Json.parse(File.getContent(Path.normalize(System.applicationDirectory+"assets/images/campaign-ui-char/custom_ui_chars.json")));
		var rawPic:BitmapData = BitmapData.fromBytes(ByteArray.fromBytes(File.getBytes(Path.normalize(System.applicationDirectory+'/assets/images/campaign-ui-char/black-line-'+character+".png"))));
		var rawXml:String = File.getContent(Path.normalize(System.applicationDirectory+'/assets/images/campaign-ui-char/black-line-'+character+".xml"));
		var tex = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
		frames = tex;
		var animJson = Json.parse(File.getContent(Path.normalize(System.applicationDirectory+"assets/images/campaign-ui-char/"+Reflect.field(parsedCharJson,character)+".json")));
		for (field in Reflect.fields(animJson)) {
			animation.addByPrefix(field, Reflect.field(animJson, field), 24, (field == "idle"));
		}
		this.like = Reflect.field(parsedCharJson,character);
		animation.play('idle');
		updateHitbox();
	}
}
