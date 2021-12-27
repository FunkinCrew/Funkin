package ui;

#if sys
import polymod.backends.PolymodAssets;
#end
import openfl.display.BitmapData;
import lime.utils.Assets;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.util.FlxColor;

class MenuItem extends FlxSpriteGroup
{
	public var targetY:Float = 0;
	public var week:FlxSprite;
	public var flashingInt:Int = 0;

	public function new(x:Float, y:Float, weekName:String = "tutorial", weekFolder:String = "default")
	{
		super(x, y);

		week = new FlxSprite().loadGraphic(Paths.image('campaign menu/weeks/' + weekFolder + "/" + weekName));

		add(week);
	}

	private var isFlashing:Bool = false;

	public function startFlashing():Void
	{
		isFlashing = true;
	}

	// if it runs at 60fps, fake framerate will be 6
	// if it runs at 144 fps, fake framerate will be like 14, and will update the graphic every 0.016666 * 3 seconds still???
	// so it runs basically every so many seconds, not dependant on framerate??
	// I'm still learning how math works thanks whoever is reading this lol
	var fakeFramerate:Int = Math.round((1 / FlxG.elapsed) / 10);

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		fakeFramerate = Math.round((1 / FlxG.elapsed) / 10);

		if(fakeFramerate <= 1)
			fakeFramerate = 1;

		y = FlxMath.lerp(y, (targetY * 120) + 480, 0.17 * (60 / Main.display.currentFPS));

		if (isFlashing)
			flashingInt += 1;

		if (flashingInt % fakeFramerate >= Math.floor(fakeFramerate / 2) && isFlashing)
			week.color = 0xFF33ffff;
		else
			week.color = FlxColor.WHITE;
	}
}
