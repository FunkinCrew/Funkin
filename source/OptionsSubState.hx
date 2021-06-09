package;

import flixel.util.FlxTimer;
import flixel.tile.FlxTile;
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
		} else {
			if (controls.UP_P)
			{
				if (textMenuItems[curSelected] == 'Volume')
				{
					if (FlxG.sound.volume < 1)
					{
						FlxG.sound.volume += 1;
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					}
				}
			}

			if (controls.DOWN_P)
			{
				if (textMenuItems[curSelected] == 'Volume')
				{
					if (FlxG.sound.volume > 0.1)
					{
						FlxG.sound.volume -= 0.1;
						FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
					}
				}
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
				}

				inMenu = false;
			} else {
				FlxG.switchState(new MainMenuState());
			}
		}

		if (controls.ACCEPT)
		{
			if (!inMenu)
			{
				// yes ik weird ordering, but if i dont do it this way then things kinda mess up (switching pages specifically)
				if (textMenuItems[curSelected] != 'Muted' && textMenuItems[curSelected] != 'Old Title')
				{
					inMenu = true;
				}

				// Controls Options things
				if (textMenuItems[curSelected] == 'Controls')
				{
					add(controlsBox);
				}

				// Sound Menu (goes before so that u dont leave it instantly lol)
				if (textMenuItems[curSelected] == 'Muted')
				{
					FlxG.sound.muted = !FlxG.sound.muted;
				}

				// Back Option
				if (textMenuItems[curSelected] == 'Back')
				{
					textMenuItems = ['Controls', 'Graphics', 'Sound', 'Misc'];
					spawnInTexts();
				}

				// Sound Options things
				if (textMenuItems[curSelected] == 'Sound')
				{
					textMenuItems = ["Back", "Muted", "Volume"];
					spawnInTexts();
				}

				// Old Title Thing
				if (textMenuItems[curSelected] == 'Old Title')
				{
					if (FlxG.save.data.oldTitle == null)
					{
						FlxG.save.data.oldTitle = false;
					}

					FlxG.save.data.oldTitle = !FlxG.save.data.oldTitle;
					FlxG.save.flush();
					FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);
				}

				// Cool Options things
				if (textMenuItems[curSelected] == 'Misc')
				{
					textMenuItems = ["Back", "Downscroll", "Old Title"];
					spawnInTexts();
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
		curSelected = 0;
		inMenu = false;

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
