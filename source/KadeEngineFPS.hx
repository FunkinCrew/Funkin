import flixel.math.FlxMath;
import flixel.util.FlxColor;
import openfl.Lib;
import openfl.display.Bitmap;
import openfl.display.BitmapData;
import flixel.FlxG;
import haxe.Timer;
import openfl.events.Event;
import openfl.text.TextField;
import openfl.text.TextFormat;
#if gl_stats
import openfl.display._internal.stats.Context3DStats;
import openfl.display._internal.stats.DrawCallContext;
#end
#if flash
import openfl.Lib;
#end

/**
	The FPS class provides an easy-to-use monitor to display
	the current frame rate of an OpenFL project
**/
#if !openfl_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class KadeEngineFPS extends TextField
{
	/**
		The current frame rate, expressed using frames-per-second
	**/
	public var currentFPS(default, null):Int;

	public var bitmap:Bitmap;

	@:noCompletion private var cacheCount:Int;
	@:noCompletion private var currentTime:Float;
	@:noCompletion private var times:Array<Float>;

	public function new(x:Float = 10, y:Float = 10, color:Int = 0x000000)
	{
		super();

		this.x = x;
		this.y = y;

		currentFPS = 0;
		selectable = false;
		mouseEnabled = false;
		defaultTextFormat = new TextFormat(openfl.utils.Assets.getFont("assets/fonts/vcr.ttf").fontName, 14, color);
		text = "FPS: ";
		width += 200;

		cacheCount = 0;
		currentTime = 0;
		times = [];

		#if flash
		addEventListener(Event.ENTER_FRAME, function(e)
		{
			var time = Lib.getTimer();
			__enterFrame(time - currentTime);
		});
		#end

		bitmap = ImageOutline.renderImage(this, 1, 0x000000, 1, true);
		(cast(Lib.current.getChildAt(0), Main)).addChild(bitmap);
	}

	var array:Array<FlxColor> = [
		FlxColor.fromRGB(148, 0, 211),
		FlxColor.fromRGB(75, 0, 130),
		FlxColor.fromRGB(0, 0, 255),
		FlxColor.fromRGB(0, 255, 0),
		FlxColor.fromRGB(255, 255, 0),
		FlxColor.fromRGB(255, 127, 0),
		FlxColor.fromRGB(255, 0, 0)
	];

	var skippedFrames = 0;

	public static var currentColor = 0;

	// Event Handlers
	@:noCompletion
	private #if !flash override #end function __enterFrame(deltaTime:Float):Void
	{
		if (MusicBeatState.initSave)
			if (FlxG.save.data.fpsRain)
			{
				if (currentColor >= array.length)
					currentColor = 0;
				currentColor = Math.round(FlxMath.lerp(0, array.length, skippedFrames / (FlxG.save.data.fpsCap / 3)));
				(cast(Lib.current.getChildAt(0), Main)).changeFPSColor(array[currentColor]);
				currentColor++;
				skippedFrames++;
				if (skippedFrames > (FlxG.save.data.fpsCap / 3))
					skippedFrames = 0;
			}

		currentTime += deltaTime;
		times.push(currentTime);

		while (times[0] < currentTime - 1000)
		{
			times.shift();
		}

		var currentCount = times.length;
		currentFPS = Math.round((currentCount + cacheCount) / 2);

		if (currentCount != cacheCount /*&& visible*/)
		{
			text = (FlxG.save.data.fps ? "FPS: "
				+ currentFPS
				+ (Main.watermarks ? "\nKE " + "v" + MainMenuState.kadeEngineVer : "") : (Main.watermarks ? "KE " + "v" + MainMenuState.kadeEngineVer : ""));

			#if (gl_stats && !disable_cffi && (!html5 || !canvas))
			text += "\ntotalDC: " + Context3DStats.totalDrawCalls();

			text += "\nstageDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE);
			text += "\nstage3DDC: " + Context3DStats.contextDrawCalls(DrawCallContext.STAGE3D);
			#end
		}

		visible = true;

		Main.instance.removeChild(bitmap);

		bitmap = ImageOutline.renderImage(this, 2, 0x000000, 1);

		Main.instance.addChild(bitmap);

		visible = false;

		cacheCount = currentCount;
	}
}
