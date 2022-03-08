package funkin;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawBaseItem;
import openfl.display.MovieClip;

class FlxSwf extends FlxSprite
{
	public var swf:MovieClip;

	public function new()
	{
		super();
	}

	override function draw()
	{
		for (camera in cameras)
		{
			if (!camera.visible || !camera.exists)
				continue;

			getScreenPosition(_point, camera).subtractPoint(offset);
			// assume no render blit for now
			// use camera.canvas
			// camera.canvas.graphics.
		}
	}
}

class FlxDrawSwfItem extends FlxDrawBaseItem<FlxDrawSwfItem>
{
	public function new()
	{
		super();
		type = FlxDrawItemType.TILES;
	}

	override function render(camera:FlxCamera)
	{
		super.render(camera);
	}
}
