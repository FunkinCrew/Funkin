package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.FlxSprite;

class DynamicSprite extends FlxSprite {
    override public function loadGraphic(Graphic:FlxGraphicAsset, Animated:Bool = false, Width:Int = 0, Height:Int = 0, Unique:Bool = false, ?Key:String) {
        if ((Graphic is String)) {
            // show time baby
            var data = FNFAssets.getBitmapData(Graphic);
            return super.loadGraphic(data, Animated, Width, Height, Unique, Key);
        }
        return super.loadGraphic(Graphic, Animated, Width, Height, Unique, Key);
    }
}

class DynamicAtlasFrames {
    public static function fromSparrow(png:FlxGraphicAsset, xml:String) {
        if (FNFAssets.exists(xml)) {
            xml = FNFAssets.getText(xml);
        }
        if ((png is String)) {
            // show time again
            png = FNFAssets.getBitmapData(png);
        }
        return FlxAtlasFrames.fromSparrow(png, xml);
    }
    public static function fromSpriteSheetPacker(png:FlxGraphicAsset, txt:String) {
		if (FNFAssets.exists(txt))
		{
			txt = FNFAssets.getText(txt);
		}
		if ((png is String))
		{
			// show time again
			png = FNFAssets.getBitmapData(png);
		}
        return FlxAtlasFrames.fromSpriteSheetPacker(png,txt);
    }
}