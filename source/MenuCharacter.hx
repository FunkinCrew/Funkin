package;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.system.System;
import lime.utils.Assets;
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
		// use assets it is less laggy
		trace("before assets");
		var parsedCharJson:Dynamic = Json.parse(Assets.getText("assets/images/campaign-ui-char/custom_ui_chars.json"));
		trace("after assets");
		if (!!Reflect.field(parsedCharJson,character).defaultGraphics) {
			// use assets, it is less laggy
			trace("before sparrow");
			var tex = FlxAtlasFrames.fromSparrow('assets/images/campaign-ui-char/default.png', 'assets/images/campaign-ui-char/default.xml');
			frames = tex;
			trace("after sparrow");
		} else {
			var rawPic:BitmapData = BitmapData.fromBytes(ByteArray.fromBytes(File.getBytes(Path.normalize(System.applicationDirectory+'/assets/images/campaign-ui-char/'+character+".png"))));
			var rawXml:String = File.getContent(Path.normalize(System.applicationDirectory+'/assets/images/campaign-ui-char/'+character+".xml"));
			var tex = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
			frames = tex;
		}

		// don't use assets because you can use custom like folders
		var animJson = Json.parse(File.getContent(Path.normalize(System.applicationDirectory+"assets/images/campaign-ui-char/"+Reflect.field(parsedCharJson,character).like+".json")));
		for (field in Reflect.fields(animJson)) {
			animation.addByPrefix(field, Reflect.field(animJson, field), 24, (field == "idle"));
		}
		this.like = Reflect.field(parsedCharJson,character).like;
		animation.play('idle');
		updateHitbox();
	}
}
