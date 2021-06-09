package;

import flixel.util.FlxAxes;
import flixel.group.FlxGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

class OptionsSubState extends MusicBeatSubstate
{
	var textMenuItems:Array<String> = ['Controls', 'Graphics', 'Sound', 'Misc'];
	var curSelected:Int = 0;
	var grpOptionsTexts:FlxTypedGroup<Alphabet>;

	var controlsBox = new ControlsBox();

	var inMenu = false;

	public function new()
	{
		super();

		grpOptionsTexts = new FlxTypedGroup<Alphabet>();
		add(grpOptionsTexts);

		spawnInTexts();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!inMenu)
		{
			if (controls.UP_P)
			{
				curSelected -= 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}

			if (controls.DOWN_P)
			{
				curSelected += 1;
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
			}
		}

		if (curSelected < 0)
			curSelected = textMenuItems.length - 1;

		if (curSelected >= textMenuItems.length)
			curSelected = 0;

		if (controls.BACK)
		{
			if (inMenu)
			{
				// Cool Options things
				if (textMenuItems[curSelected] == 'Controls')
				{
					remove(controlsBox);
					inMenu = false;
				}
			} else {
				FlxG.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT)
		{
			if (!inMenu)
			{
				// Cool Options things
				if (textMenuItems[curSelected] == 'Controls')
				{
					add(controlsBox);
					inMenu = true;
				}
			}
		}

		var bruh = 0;

		for (x in grpOptionsTexts.members)
		{
			x.targetY = bruh - curSelected;
			bruh++;
		}
	}

	function spawnInTexts()
	{
		grpOptionsTexts.clear();

		for (i in 0...textMenuItems.length)
		{
			var option = new Alphabet(20, 20 + (i * 100), textMenuItems[i], true, false);
			option.isMenuItem = true;
			option.targetY = i;
			grpOptionsTexts.add(option);
		}
	}
}
