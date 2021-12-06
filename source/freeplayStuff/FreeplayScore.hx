package freeplayStuff;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

using StringTools;

class FreeplayScore extends FlxTypedSpriteGroup<ScoreNum>
{
	public var scoreShit(default, set):Int = 0;

	function set_scoreShit(val):Int
	{
		var loopNum:Int = group.members.length - 1;
		var dumbNumb = Std.parseInt(Std.string(val));

		while (dumbNumb > 0)
		{
			trace(dumbNumb);
			group.members[loopNum].digit = dumbNumb % 10;

			dumbNumb = Math.floor(dumbNumb / 10);
			loopNum--;
		}

		while (loopNum > 0)
		{
			group.members[loopNum].digit = 0;
			loopNum--;
		}

		trace(val);

		return val;
	}

	public function new(x:Float, y:Float, scoreShit:Int = 100)
	{
		super(x, y);

		for (i in 0...7)
		{
			add(new ScoreNum(x + (45 * i), y, 0));
		}

		this.scoreShit = scoreShit;
	}

	public function updateScore(scoreNew:Int)
	{
		scoreShit = scoreNew;
	}
}

class ScoreNum extends FlxSprite
{
	public var digit(default, set):Int = 0;

	function set_digit(val):Int
	{
		if (animation.curAnim != null && animation.curAnim.name != Std.string(val))
		{
			animation.play(Std.string(val), true, false, 0);
		}

		return val;
	}

	public function new(x:Float, y:Float, ?initDigit:Int = 0)
	{
		super(x, y);

		frames = Paths.getSparrowAtlas('noteComboNumbers');

		for (i in 0...10)
		{
			var stringNum:String = Std.string(i);
			animation.addByPrefix(stringNum, stringNum, 24, false);
		}

		this.digit = initDigit;

		animation.play(Std.string(digit), true);
		antialiasing = true;

		setGraphicSize(Std.int(width * 0.3));
		updateHitbox();
	}
}
