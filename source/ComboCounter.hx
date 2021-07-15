package;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;

class ComboCounter extends FlxTypedSpriteGroup<FlxSprite>
{
	var effectStuff:FlxSprite;

	var wasComboSetup:Bool = false;
	var daCombo:Int = 0;

	var grpNumbers:FlxTypedGroup<ComboNumber>;

	public function new(x:Float, y:Float, daCombo:Int = 0)
	{
		super(x, y);

		this.daCombo = daCombo;

		effectStuff = new FlxSprite(0, 0);
		effectStuff.frames = Paths.getSparrowAtlas('noteCombo');
		effectStuff.animation.addByPrefix('funny', 'NOTE COMBO animation', 24, false);
		effectStuff.animation.play('funny');
		effectStuff.antialiasing = true;
		effectStuff.animation.finishCallback = function(nameThing)
		{
			kill();
		};
		add(effectStuff);

		grpNumbers = new FlxTypedGroup<ComboNumber>();
		// add(grpNumbers);
	}

	override function update(elapsed:Float)
	{
		if (effectStuff.animation.curAnim.curFrame == 2 && !wasComboSetup)
		{
			setupCombo(daCombo);
		}

		if (effectStuff.animation.curAnim.curFrame == 18)
		{
			grpNumbers.forEach(function(spr:ComboNumber)
			{
				spr.animation.reset();
			});
		}

		if (effectStuff.animation.curAnim.curFrame == 20)
		{
			grpNumbers.forEach(function(spr:ComboNumber)
			{
				spr.kill();
			});
		}

		super.update(elapsed);
	}

	function setupCombo(daCombo:Int)
	{
		FlxG.sound.play(Paths.sound('comboSound'));

		wasComboSetup = true;
		var loopNum:Int = 0;

		while (daCombo > 0)
		{
			var comboNumber:ComboNumber = new ComboNumber(420 - (130 * loopNum), 44 * loopNum, daCombo % 10);
			grpNumbers.add(comboNumber);
			add(comboNumber);

			loopNum += 1;

			daCombo = Math.floor(daCombo / 10);
		}

		// var comboNumber:ComboNumber = new ComboNumber(420, 0, 0);

		// add to both, in the group just for ez organize/accessing
		// grpNumbers.add(comboNumber);
		// add(comboNumber);

		// var comboNumber2:ComboNumber = new ComboNumber(420 - 134, 44, 0);
		// grpNumbers.add(comboNumber2);
		// add(comboNumber2);
	}
}

class ComboNumber extends FlxSprite
{
	public function new(x:Float, y:Float, digit:Int)
	{
		super(x - 20, y);

		var stringNum:String = Std.string(digit);
		frames = Paths.getSparrowAtlas('noteComboNumbers');
		animation.addByPrefix(stringNum, stringNum, 24, false);
		animation.play(stringNum);
		antialiasing = true;
		updateHitbox();
	}

	var shiftedX:Bool = false;

	override function update(elapsed:Float)
	{
		if (animation.curAnim.curFrame == 2 && !shiftedX)
		{
			shiftedX = true;
			x += 20;
		}

		super.update(elapsed);
	}
}
