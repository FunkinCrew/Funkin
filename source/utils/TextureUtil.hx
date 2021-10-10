package utils;

import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import sys.io.File;
import flixel.graphics.frames.FlxFrame;
import flixel.graphics.frames.FlxFramesCollection;
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
import utils.MaxRectsBinPack;

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
    // not working

    // todo
    // optimization (maybe)
    // cache
    // why all tex is so broken??
    public static function downsize2(source:FlxGraphicAsset, Description:String, ?prefix:Array<String>, option:Increaseoptions = EVERYEVEN):FlxAtlasFrames {
        var atlas = FlxAtlasFrames.fromSparrow(source, Description);
        var images:Map<String, Dynamic> = new Map();
        var anims:Array<String> = []; // aaaaaaaaa
        var somesh:Array<{// more aaaaaaaaaaaa
            xy:Array<Float>,
            flipX:Bool,
	        flipY:Bool,
            angle:FlxFrameAngle
        }> = [];
        // maybe unite somesh and anims??

        if (prefix == null)
            prefix = getprefix(atlas);

        for(frame in atlas.frames)
        {
            var bm = new BitmapData(Std.int(frame.frame.width), Std.int(frame.frame.height));
            bm.copyPixels(frame.parent.bitmap, new Rectangle(frame.frame.x, frame.frame.y, frame.frame.width, frame.frame.height), new Point());
            images.set(frame.name, bm);
            anims.push(frame.name);
            somesh.push({
                xy: [frame.offset.x, frame.offset.y],
                flipY: frame.flipY,
                flipX: frame.flipX,
                angle: frame.angle
                
            });
        }

        var todrawnames:Array<String> = everyeven(prefix, anims);
        var todrawimages:Array<{
            image:BitmapData,
            rect:Rectangle
        }>= [];

        var maxrect = new MaxRectsBinPack(16384, 16384);// dumb
        maxrect.init(16384, 16384);
        
        for (name in todrawnames)
        {
            var image:BitmapData = images.get(name);
            var rect = maxrect.quickInsert(image.width, image.height);
            todrawimages.push({image: image, rect: rect});
        }
        
        var maxhw:{width:Float, height:Float} = { width: 0, height: 0 };
        for (obj in todrawimages)
        {
            if (maxhw.width < obj.rect.x + obj.rect.width)
                maxhw.width = obj.rect.x + obj.rect.width;

            if (maxhw.height < obj.rect.y + obj.rect.height)
                maxhw.height = obj.rect.y + obj.rect.height;
        }

        var dafinalb:BitmapData = new BitmapData(Std.int(maxhw.width), Std.int(maxhw.height), true);

        for (image in todrawimages)
        {
            dafinalb.copyPixels(image.image, image.image.rect, new Point(image.rect.x, image.rect.y));
        }

        var graphic = FlxG.bitmap.add(dafinalb);
        var frames = new FlxAtlasFrames(graphic);
        // fix this plsplsplspslps
        // for (image in todrawimages)
        // {
        //     var rect = FlxRect.get(image.rect.x, image.rect.y, image.image.rect.width, image.image.rect.height);
        //     frames.addAtlasFrame(rect, FlxPoint.get(maxhw.width, maxhw.height), FlxPoint.get(0, 0), todrawnames[todrawimages.indexOf(image)]);
        // }

        for (anim in anims)
        {
            // 'GF Down Note' == animPrefix
            var animPrefix = prefix.filter(s -> anim.indexOf(s) != -1)[0];// maybe this can do error
            var animNum = parsePrefix(anim.substring(anim.indexOf(animPrefix), anim.length));
            // 'GF Down Note0001'
            var curdn:Array<String> = todrawnames.filter(s -> prefix.filter(a -> s.indexOf(a) != -1)[0] == animPrefix);
            curdn = curdn.filter(s -> {
                var pref = parsePrefix(s.substring(s.indexOf(animPrefix), s.length));
                if (animNum > parsePrefix(curdn[curdn.length - 1].substring(curdn[curdn.length - 1].indexOf(animPrefix), curdn[curdn.length - 1].length)))// uhhh, ok
                    return true;
                return pref >= animNum;
            });
            var animdraw = curdn[0];
            var image = todrawimages[todrawnames.indexOf(animdraw)];

            var rect = FlxRect.get(image.rect.x, image.rect.y, image.image.rect.width, image.image.rect.height);
            trace(atlas.frames.filter(f -> f.name == anim)[0].offset);
            trace('${atlas.frames.filter(f -> f.name == anim)[0].name} $anim'); // FlxPoint.get(somesh[anims.indexOf(anim)].xy[0], somesh[anims.indexOf(anim)].xy[1])
            frames.addAtlasFrame(rect, FlxPoint.get(maxhw.width, maxhw.height), FlxPoint.get(), anim, somesh[anims.indexOf(anim)].angle, somesh[anims.indexOf(anim)].flipX, somesh[anims.indexOf(anim)].flipY);
        }

        TextureCahce.set(dafinalb);

        return frames;
    }

    // every even
    // [gfDance0000,gfDance0002,gfDance0004,gfDance0006,gfDance0008,...]
    static function everyeven(prefix:Array<String>, anims:Array<String>) {
        var todrawnames:Array<String> = [];
        for (s in prefix) {
            var names = anims.filter(v -> v.indexOf(s) != -1);
            if (names.length == 0)
                return null;

            var fnum:Array<Int> = [];
            for (name in names)
                fnum.push(parsePrefix(name));

            var p:Array<Int> = [];
            if (!(fnum.length < 2))
                p = fnum.filter(num -> num % 2 == 0);

            for (a in p)
                todrawnames.push(names[fnum.indexOf(a)]);
        }

        return todrawnames;
    }

    static function getprefix(atlas:FlxAtlasFrames):Array<String> {
        var prefixarray:Array<String> = [];
        for (frame in atlas.frames)
        {
            var nums:Array<Int> = [];
            for (i in [0,1,2,3,4,5,6,7,8,9])
            {
                var index = frame.name.indexOf(Std.string(i));
                if (index != -1)
                    nums.push(index);
            }
            nums.sort(Reflect.compare);
            var dafinal = frame.name.substring(0, nums[0]);

            if (!prefixarray.contains(dafinal))
                prefixarray.push(dafinal);
        }
        return prefixarray;
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

class TextureCahce {
    public static function get(bitmap:BitmapData) {
        File.saveBytes(Sys.getCwd() + 'im.png', bitmap.encode(bitmap.rect, new PNGEncoderOptions()));
    }
    public static function set(bitmap:BitmapData) {
        
    }
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
