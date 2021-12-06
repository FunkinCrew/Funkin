package freeplayStuff;

import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class FreeplayScore extends FlxTypedSpriteGroup<ScoreNum>
{
	public var scoreShit:Int = 0;

	public function new(x:Float, y:Float, scoreShit:Int = 100)
	{
		super(x, y);

		this.scoreShit = scoreShit;

		for (i in 0...7)
		{
			add(new ScoreNum(x + (45 * i), y, 0));
		}
	}

	public function updateScore(scoreNew:Int)
	{
		forEach(function(numScore)
		{
			numScore.digit = 8;
		});
	}
}

class ScoreNum extends FlxSprite
{
	public var digit(default, set):Int = 0;

	function set_digit(val):Int
	{
		animation.play(Std.string(FlxG.random.int(0, 9)), true, false, 0);

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
