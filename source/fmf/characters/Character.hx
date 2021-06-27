package fmf.characters;

import flixel.util.FlxTimer;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.animation.FlxBaseAnimation;
import flixel.graphics.frames.FlxAtlasFrames;

using StringTools;

//the character class holding behaviour 
class Character extends FlxSprite
{
	public var animOffsets:Map<String, Array<Dynamic>>;
	public var debugMode:Bool = false;
	public var holdTimer:Float = 0;
	public var stunned:Bool;

	public function new(x:Float, y:Float)
	{
		super(x, y);
		animOffsets = new Map<String, Array<Dynamic>>();
		var tex:FlxAtlasFrames;
		antialiasing = true;
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	private var danced:Bool = false;

	private var isLockAnim:Bool;

	public function lockAnim(duration:Float)
	{
		if (isLockAnim)
			return;

		isLockAnim = true;
		new FlxTimer().start(duration, function(tmr:FlxTimer)
		{
			isLockAnim = false;
		});
	}


	public function dance():Void
	{
		if (!debugMode)
		{
			playAnim('idle');
		}
	}

	public function playAnimForce(anim:String, lockDuration:Float)
	{
		if(isLockAnim) return;
		
		playAnim(anim, true);
		lockAnim(lockDuration);
	}

	public function playAnim(AnimName:String, Force:Bool = false, Reversed:Bool = false, Frame:Int = 0):Void
	{
		if (isLockAnim)
			return;

		animation.play(AnimName, Force, Reversed, Frame);

		var daOffset = animOffsets.get(AnimName);
		if (animOffsets.exists(AnimName))
		{
			offset.set(daOffset[0], daOffset[1]);
		}
		else
			offset.set(0, 0);
	}

	public function addOffset(name:String, x:Float = 0, y:Float = 0)
	{
		animOffsets[name] = [x, y];
	}
}
