package animate;

import animateAtlasPlayer.assets.AssetManager;
import animateAtlasPlayer.core.Animation;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxAssets.FlxGraphicAsset;
import haxe.Json;
import openfl.Assets;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import openfl.geom.Point;
import openfl.geom.Rectangle;

class FlxAnimate extends FlxSprite
{
	var myAnim:Animation;
	var animBitmap:BitmapData;

	var loadedQueue:Bool = false;

	var swagFrames:Array<BitmapData> = [];

	public function new(x:Float, y:Float)
	{
		super(x, y);

		// get fromAnimate()
		// get every symbol / piece needed
		// animate them?

		var swagAssets:AssetManager = new AssetManager();
		swagAssets.enqueueSingle(Paths.file('images/picoShoot/spritemap1.png'));
		swagAssets.enqueueSingle(Paths.file('images/picoShoot/spritemap1.json'));
		swagAssets.enqueueSingle(Paths.file('images/picoShoot/Animation.json'));

		swagAssets.loadQueue(function(assetMgr:AssetManager)
		{
			myAnim = assetMgr.createAnimation("Pico Saves them sequence");
			myAnim.cacheAsBitmap = true;
			myAnim.opaqueBackground = null;
			// myAnim.root.x += 200;
			// myAnim.root.y += 200;
			// myAnim.x += 200;
			// myAnim.y += 200;

			var daAnim:BitmapData = new BitmapData(200, 200, true, 0x00000000);
			daAnim.draw(myAnim);
			animBitmap = new BitmapData(200, 200, true, 0x00000000);
			animBitmap.draw(myAnim);

			loadGraphic(animBitmap);
			// framePixels = animBitmap;

			loadedQueue = true;
		});
	}

	var pointZero:Point = new Point();

	private var lastFrame:Int = 0;

	override function draw()
	{
		super.draw();

		if (loadedQueue)
		{
			if (lastFrame != myAnim.currentFrame)
			{
				lastFrame = myAnim.currentFrame;
				// loadGraphic(animBitmap);

				animBitmap.draw(myAnim);
			}

			// animBitmap.draw(myAnim);
		}
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

		if (Assets.exists(json))
			json = Assets.getText(json);

		data = cast Json.parse(json).ATLAS;

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
