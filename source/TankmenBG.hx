package;

import flixel.FlxG;
import flixel.FlxSprite;
import haxe.display.Display.Package;

class TankmenBG extends FlxSprite
{
	public var strumTime:Float = 0;
	public var goingRight:Bool = false;
	public var tankSpeed:Float = 0.7;

	public var endingOffset:Float;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		// makeGraphic(200, 200);

		frames = Paths.getSparrowAtlas('tankmanKilled1');
		antialiasing = true;
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John', 24, false);

		animation.play('run');

		y += FlxG.random.int(-40, 100);

		goingRight = FlxG.random.bool();
		endingOffset = FlxG.random.float(0, 120);

		tankSpeed = FlxG.random.float(0.65, 0.8);

		if (goingRight)
			flipX = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (animation.curAnim.name == 'run')
		{
			var endDirection:Float = (FlxG.width * 0.74) + endingOffset;

			if (goingRight)
			{
				endDirection = (FlxG.width * 0.02) - endingOffset;

				x = (endDirection + (Conductor.songPosition - strumTime) * tankSpeed);
			}
			else
			{
				x = (endDirection - (Conductor.songPosition - strumTime) * tankSpeed);
			}
		}

		if (Conductor.songPosition > strumTime)
		{
			// kill();
			animation.play('shot');

			if (goingRight)
			{
				offset.y = 200;
				offset.x = 300;
			}
		}

		if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= animation.curAnim.frames.length - 1)
		{
			kill();
		}
	}
}
