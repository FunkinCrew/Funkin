package animate;

// import animateAtlasPlayer.assets.AssetManager;
// import animateAtlasPlayer.core.Animation;
import animate.ParseAnimate.AnimJson;
import animate.ParseAnimate.Sprite;
import animate.ParseAnimate.Spritemap;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.format.JsonParser;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.geom.Rectangle;

class FlxAnimate extends FlxSymbol
{
	// var myAnim:Animation;
	// var animBitmap:BitmapData;
	var loadedQueue:Bool = false;

	var swagFrames:Array<BitmapData> = [];

	var jsonAnim:AnimJson;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		var folder:String = "tightBarsLol";

		frames = FlxAnimate.fromAnimate(Paths.file('images/' + folder + "/spritemap1.png"), Paths.file('images/$folder/spritemap1.json'));

		jsonAnim = cast CoolUtil.coolJSON(Assets.getText(Paths.file('images/$folder/Animation.json')));
		ParseAnimate.generateSymbolmap(jsonAnim.SD.S);
		ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, 0);

		/* var folder:String = 'tightestBars';
			coolParse = cast Json.parse(Assets.getText(Paths.file('images/' + folder + '/Animation.json')));

			// reverses the layers, for proper rendering!
			coolParse.AN.TL.L.reverse();
			super(x, y, coolParse);

			frames = FlxAnimate.fromAnimate(Paths.file('images/' + folder + '/spritemap1.png'), Paths.file('images/' + folder + '/spritemap1.json'));
		 */

		// frames
	}

	override function draw()
	{
		// having this commented out fixes some wacky scaling bullshit?
		// super.draw();

		// renderFrame(coolParse.AN.TL, coolParse, true);

		actualFrameRender();
	}

	function actualFrameRender()
	{
		for (i in ParseAnimate.frameList)
		{
			var spr:FlxSymbol = new FlxSymbol(0, 0); // redo this to recycle from a list later
			spr.frames = frames;
			spr.frame = spr.frames.getByName(i);

			if (FlxG.keys.justPressed.I)
			{
				trace('\n\n\nSPR OLD: ' + spr._matrix);
			}

			ParseAnimate.matrixMap.get(i).reverse();

			for (swagMatrix in ParseAnimate.matrixMap.get(i))
			{
				var alsoSwag:FlxMatrix = new FlxMatrix(swagMatrix[0], swagMatrix[1], swagMatrix[4], swagMatrix[5], swagMatrix[12], swagMatrix[13]);
				spr.matrixExposed = true;

				spr.transformMatrix.concat(alsoSwag);

				if (FlxG.keys.justPressed.I)
				{
					trace(i + ": " + swagMatrix);
				}
			}

			if (FlxG.keys.justPressed.I)
			{
				trace('SPR NEW: ' + spr._matrix);
			}

			// trace('MATRIX ' + spr._matrix);
			// spr

			spr.draw();
		}
	}

	// notes to self
	// account for different layers
	var playingAnim:Bool = false;
	var frameTickTypeShit:Float = 0;
	var animFrameRate:Int = 24;

	// redo all the matrix animation stuff

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
				ParseAnimate.resetFrameList();
				ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, daFrame);
			}
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			changeFrame(1);

			ParseAnimate.resetFrameList();
			ParseAnimate.parseTimeline(jsonAnim.AN.TL, 0, daFrame);
		}
		if (FlxG.keys.justPressed.LEFT)
			changeFrame(-1);
	}

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

		var data:Spritemap;

		var json:String = Description;

		// trace(json);

		var funnyJson:Dynamic = {};
		if (Assets.exists(json))
			funnyJson = JaySon.parseFile(json);

		// trace(json);

		// data = c

		data = cast funnyJson;

		for (sprite in data.ATLAS.SPRITES)
		{
			// probably nicer way to do this? Oh well
			var swagSprite:Sprite = sprite.SPRITE;

			var rect = FlxRect.get(swagSprite.x, swagSprite.y, swagSprite.w, swagSprite.h);

			var size = new Rectangle(0, 0, rect.width, rect.height);

			var offset = FlxPoint.get(-size.left, -size.top);
			var sourceSize = FlxPoint.get(size.width, size.height);

			frames.addAtlasFrame(rect, sourceSize, offset, swagSprite.name);
		}

		return frames;
	}
}

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
