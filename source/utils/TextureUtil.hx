package utils;

import openfl.geom.Point;
import flixel.system.FlxAssets.FlxGraphicAsset;
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

        //var preview = source.encode(source.rect, new PNGEncoderOptions());
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

    #if !js
    public static function downsize2(source:FlxGraphicAsset, Description:String, prefix:Array<String>, option:Increaseoptions = EVERYEVEN):FlxAtlasFrames {
        if (prefix.length == 0)
            return null;

        var atlas = FlxAtlasFrames.fromSparrow(source, Description);
        var images:Map<String, Dynamic> = new Map();
        var anims:Array<String> = []; // aaaaaaaaa

        var dafinalb:BitmapData = new BitmapData(4096, 4096, true);

        for(frame in atlas.frames)
        {
            var bm = new BitmapData(Std.int(frame.frame.width), Std.int(frame.frame.height));
            bm.copyPixels(frame.parent.bitmap, new Rectangle(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height), new Point());
            images.set(frame.name, bm);
            anims.push(frame.name);
        }

        var todrawnames:Array<String> = [];

        // every even
        // [gfDance0000,gfDance0002,gfDance0004,gfDance0006,gfDance0008,...]
        for (s in prefix) {
            var names = anims.filter(v -> v.indexOf(s) != -1);
            if (names.length == 0)
                return null;

            var fnum:Array<Int> = [];
            for (name in names)
                fnum.push(parsePrefix(name));

            var p:Array<Int> = [];
            if (!(fnum.length < 2))
                p = fnum.filter(even);

            for (a in p)
                todrawnames.push(names[fnum.indexOf(a)]);
        }

        // check later
        // for (name in todrawnames)
        // {
        //     var bitmap:BitmapData = images.get(name);

        //     dafinalb.copyPixels(bitmap, bitmap.rect, new Point(0, 0));
        // }

        return null;
    }
    static function even(num:Int):Bool {
        if (num % 2 == 0)
            return true;
        return false;
    }

    static function parsePrefix(str:String) {
        for (i in 0...str.length)
        {
            if (str.charAt(i) == '0' && str.indexOf(str.charAt(i)) != str.length)
            {
                str = str.substring(str.indexOf(str.charAt(i)), str.length);
            }
        }
        return Std.parseInt(str);
    }
    #end


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

enum Increaseoptions {
    EVERYEVEN;
    FIRST;
}