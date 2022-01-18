package;

import flixel.FlxG;
import flixel.FlxSprite;

using StringTools;

class TankmenBG extends FlxSprite
{
	public static var animationNotes:Array<Dynamic> = [];

	public var strumTime = 0;
	public var goingRight = false;
	public var tankSpeed = 0.7;

	var endingOffset:Float;

	override public function new(X:Float, Y:Float, uhh:Bool)
	{
		super(X, Y);
		frames = Paths.getSparrowAtlas('tankmanKilled1');
		antialiasing = true;
		animation.addByPrefix('run', 'tankman running', 24, true);
		animation.addByPrefix('shot', 'John Shot ' + FlxG.random.int(1, 2), 24, false);
		animation.play('run');
		animation.curAnim.curFrame = FlxG.random.int(0, animation.curAnim.frames.length - 1);
		updateHitbox();
		setGraphicSize(Std.int(width * 0.8));
		updateHitbox();
	}

	public function resetShit(X:Float, Y:Float, goRight:Bool)
	{
		setPosition(X, Y);
		goingRight = goRight;
		endingOffset = FlxG.random.float(50, 200);
		tankSpeed = FlxG.random.float(0.6, 1);
		if (goingRight)
			flipX = true;
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);
		
		if (x >= FlxG.width * 1.2 || x <= FlxG.width * -0.5)
		{
			visible = false;
		}
		else
		{
			visible = true;
		}

		if (animation.curAnim.name == 'run')
		{
			var wackyShit = FlxG.width * 0.74 + endingOffset;
			if (goingRight)
			{
				wackyShit = FlxG.width * 0.02 - endingOffset;
				x = wackyShit + (Conductor.songPosition - strumTime) * tankSpeed;
			}
			else
			{
				x = wackyShit - (Conductor.songPosition - strumTime) * tankSpeed;
			}
		}
		
		if (Conductor.songPosition > strumTime)
		{
			animation.play('shot');
			if (goingRight)
			{
				offset.y = 200;
				offset.x = 300;
			}
		}
		
		if (animation.curAnim.name == 'shot' && animation.curAnim.curFrame >= animation.curAnim.frames.length - 1)
			kill();
	}
}