package;

import haxe.DynamicAccess;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import lime.system.System;
import lime.utils.Assets;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;

#end
import haxe.Json;
import flash.display.BitmapData;
import haxe.format.JsonParser;
import tjson.TJSON;
typedef TMenuCharacterRef = {
	var like:String;
	var defaultGraphics:Bool;
}
typedef TMenuCharAnimation = {
	var animation:Dynamic;
	var ?scale:Float;
	var ?offset:Array<Int>;
	var ?flipX:Bool;
}
class MenuCharacter extends FlxSprite
{
	public var character:String;
	public var like:String;
	public var jsonScale:Float = 1.0;
	public var offsetX:Float = 0.0;
	public var offsetY:Float = 0.0; 
	public var jsonFlipX:Bool = false;
	public function new(x:Float, character:String = 'bf')
	{
		super(x);

		this.character = character;
		// use assets it is less laggy
		var parsedCharJson:DynamicAccess<TMenuCharacterRef> = CoolUtil.parseJson(Assets.getText("assets/images/campaign-ui-char/custom_ui_chars.json"));
		if (parsedCharJson[character].defaultGraphics) {
			// use assets, it is less laggy
			var tex = FlxAtlasFrames.fromSparrow('assets/images/campaign-ui-char/default.png', 'assets/images/campaign-ui-char/default.xml');
			frames = tex;
		} else {
			var rawPic:BitmapData = FNFAssets.getBitmapData('assets/images/campaign-ui-char/'+character+".png");
			var rawXml:String = FNFAssets.getText('assets/images/campaign-ui-char/'+character+".xml");
			var tex = FlxAtlasFrames.fromSparrow(rawPic, rawXml);
			frames = tex;
		}

		// don't use assets because you can use custom like folders
		var animJson:TMenuCharAnimation = CoolUtil.parseJson(FNFAssets.getText("assets/images/campaign-ui-char/"+parsedCharJson[character].like+".json"));
		for (field in Reflect.fields(animJson.animation)) {
			animation.addByPrefix(field, Reflect.field(animJson.animation, field), 24, (field == "idle"));
		}
		jsonScale = Reflect.hasField(animJson, "scale") ? animJson.scale : 1.0;
		if (Reflect.hasField(animJson, "offset")) {
			offsetX = animJson.offset[0];
			offsetY = animJson.offset[1];
		}
		jsonFlipX = Reflect.hasField(animJson, "flipX") ? animJson.flipX : false;
		this.like = Reflect.field(parsedCharJson,character).like;
		animation.play('idle');
		updateHitbox();
	}
}
