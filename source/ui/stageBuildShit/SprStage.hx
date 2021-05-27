package ui.stageBuildShit;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;

class SprStage extends FlxSprite
{
	public function new(?x:Float = 0, ?y:Float = 0)
	{
		super(x, y);

		FlxMouseEventManager.add(this, dragShit, null, function(spr:SprStage)
		{
			alpha = 0.5;
		}, function(spr:SprStage)
		{
			alpha = 1;
		}, false, true, true);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (mousePressing)
		{
			this.x = FlxG.mouse.x - mouseOffset.x;
			this.y = FlxG.mouse.y - mouseOffset.y;
		}

		if (FlxG.mouse.justReleased)
		{
			mousePressing = false;
		}
	}

	public var mousePressing:Bool = false;

	private var mouseOffset:FlxPoint = FlxPoint.get(0, 0);

	function dragShit(spr:SprStage)
	{
		mousePressing = true;
		mouseOffset.set(FlxG.mouse.x - this.x, FlxG.mouse.y - this.y);
	}
}
