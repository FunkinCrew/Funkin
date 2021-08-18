package utils;

import flixel.FlxSprite;
import openfl.geom.Rectangle;
import openfl.utils.ByteArray;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.PNGEncoderOptions;
import openfl.display.Bitmap;
import flixel.FlxG;
import lime.graphics.Image;
import haxe.xml.Access;
import openfl.utils.Assets;
import openfl.display.BitmapData;

// inline static public function getSparrowAtlas(key:String, ?library:String)
// 	{
// 		var ds:Output = TextureUtil.downsize(
// 			Assets.getBitmapData(image(key, library)), 	
// 			Assets.getText(file('images/$key.xml', library)));

// 		return FlxAtlasFrames.fromSparrow(ds.source, ds.Desc);
// 		//return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
// 	}    

class TextureUtil
{
    public static function downsize(source:BitmapData, Description:String, div:Int = 2):Output {
        var width = source.image.width;
        var height = source.image.height;

        if (width <= 4096 || FlxG.bitmap.maxTextureSize < 8096)
            return {source: source, Desc: Description};

        if (Assets.exists(Description))
			Description = Assets.getText(Description);

		var data:Access = new Access(Xml.parse(Description).firstElement());

        var image:Image = source.image;

        image.resize(Math.floor(width / div), Math.floor(height / div));
        source = BitmapData.fromImage(source.image);

        var preview = source.encode(source.rect, new PNGEncoderOptions());
        //FlxG.stage.addChild(new Bitmap(source));

        for (texture in data.nodes.SubTexture)
		{
            texture.att.x = Std.string(Math.floor(Std.parseInt(texture.att.x) / div));
            texture.att.y = Std.string(Math.floor(Std.parseInt(texture.att.y) / div));
            texture.att.height = Std.string(Math.floor(Std.parseInt(texture.att.height) / div));
            texture.att.width = Std.string(Math.floor(Std.parseInt(texture.att.width) / div));

			if (texture.has.frameX)
			{
                texture.att.frameX = Std.string(Math.floor(Std.parseInt(texture.att.frameX) / div));
                texture.att.frameY = Std.string(Math.floor(Std.parseInt(texture.att.frameY) / div));
                texture.att.frameHeight = Std.string(Math.floor(Std.parseInt(texture.att.frameHeight) / div));
                texture.att.frameWidth = Std.string(Math.floor(Std.parseInt(texture.att.frameWidth) / div));
			}
		}

        return cast {
            source: source,
            Desc: Std.string(data)

        }
    }


    /*public static function downsize2(source:BitmapData, Description:String, div:Int = 2):FlxAtlasFrames {
        var atlas = FlxAtlasFrames.fromSparrow(source, Description);

        var images:Map<String, ByteArray> = new Map();
        for (frame in [atlas.frames[0]])
        {
            var graphic = frame.parent;

            
            //var rect:Rectangle = cast Reflect.field(frame.frame, 'rect');
            var rect = new openfl.geom.Rectangle(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height);
            images.set(frame.name, graphic.bitmap.getPixels(rect));

            FlxG.state.add(new FlxSprite(0, 0, BitmapData.fromBytes(images.get(frame.name))));
            //FlxG.stage.addChild(new Bitmap(BitmapData.fromBytes(images.get(frame.name))));
        }
        return null;


    }*/
}

typedef Output = 
{
    var source:BitmapData;
    var Desc:String;
}