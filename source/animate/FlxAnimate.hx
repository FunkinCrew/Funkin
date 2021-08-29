package animate;

// import animateAtlasPlayer.assets.AssetManager;
// import animateAtlasPlayer.core.Animation;
import animate.FlxSymbol.Parsed;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.Json;
import haxe.Utf8;
import haxe.format.JsonParser;
import lime.text.UTF8String;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class FlxAnimate extends FlxSymbol
{
	// var myAnim:Animation;
	// var animBitmap:BitmapData;
	var loadedQueue:Bool = false;

	var swagFrames:Array<BitmapData> = [];

	public function new(x:Float, y:Float)
	{
		var folder:String = 'tightBarsLol';
		coolParse = cast Json.parse(Assets.getText(Paths.file('images/' + folder + '/Animation.json')));

		// reverses the layers, for proper rendering!
		coolParse.AN.TL.L.reverse();
		super(x, y, coolParse);

		frames = FlxAnimate.fromAnimate(Paths.file('images/' + folder + '/spritemap1.png'), Paths.file('images/' + folder + '/spritemap1.json'));
		// frames
	}

	override function draw()
	{
		// having this commented out fixes some wacky scaling bullshit?
		// super.draw();

		if (FlxG.keys.justPressed.ONE)
		{
			trace("-------------------------------------");
			trace('CUR FRAME: ' + daFrame);
			trace('--------------');
		}

		renderFrame(coolParse.AN.TL, coolParse, true);

		if (FlxG.keys.justPressed.E)
		{
			for (shit in FlxSymbol.nestedShit.keys())
			{
				for (spr in FlxSymbol.nestedShit.get(shit))
				{
					trace(shit);
					spr.draw();
				}
			}

			FlxSymbol.nestedShit.clear();
		}
	}

	// notes to self
	// account for different layers
	var playingAnim:Bool = false;
	var frameTickTypeShit:Float = 0;
	var animFrameRate:Int = 24;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
			playingAnim = !playingAnim;

		if (playingAnim)
		{
			frameTickTypeShit += elapsed;

			// prob fix this framerate thing for higher framerates?
			if (frameTickTypeShit >= 1 / 24)
			{
				changeFrame(1);
				frameTickTypeShit = 0;
			}
		}

		if (FlxG.keys.justPressed.RIGHT)
			changeFrame(1);
		if (FlxG.keys.justPressed.LEFT)
			changeFrame(-1);
	}

	// This stuff is u
	public static function fromAnimate(Source:FlxGraphicAsset, Description:String):FlxAtlasFrames
	{
		var graphic:FlxGraphic = FlxG.bitmap.add(Source);
		if (graphic == null)
			return null;

		var frames:FlxAtlasFrames = FlxAtlasFrames.findFrame(graphic);
		if (frames != null)
			return frames;

		if (graphic == null || Description == null)
			return null;

		frames = new FlxAtlasFrames(graphic);

		var data:AnimateObject;

		var json:String = Description;

		trace(json);

		var funnyJson:Dynamic = {};
		if (Assets.exists(json))
			funnyJson = JaySon.parseFile(json);

		// trace(json);

		data = cast funnyJson.ATLAS;

		for (sprite in data.SPRITES)
		{
			// probably nicer way to do this? Oh well
			var swagSprite:AnimateSprite = sprite.SPRITE;

			var rect = FlxRect.get(swagSprite.x, swagSprite.y, swagSprite.w, swagSprite.h);

			var size = new Rectangle(0, 0, rect.width, rect.height);

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			frames.addAtlasFrame(rect, sourceSize, offset, swagSprite.name);
		}

		return frames;
	}
}

/**
 * HL json encoding fix for some wacky bullshit
 * https://github.com/HaxeFoundation/haxe/issues/6930#issuecomment-384570392
 */
class JaySon
{
	public static function parseFile(name:String)
	{
		var cont = Assets.getText(name);
		function is(n:Int, what:Int)
			return cont.charCodeAt(n) == what;
		return JsonParser.parse(cont.substr(if (is(0, 65279)) /// looks like a HL target, skipping only first character here:
			1 else if (is(0, 239) && is(1, 187) && is(2, 191)) /// it seems to be Neko or PHP, start from position 3:
			3 else /// all other targets, that prepare the UTF string correctly
			0));
	}
}

typedef AnimateObject =
{
	SPRITES:Array<Dynamic>
}

typedef AnimateSprite =
{
	var name:String;
	var x:Int;
	var y:Int;
	var w:Int;
	var h:Int;
	var rotated:Bool;
}
