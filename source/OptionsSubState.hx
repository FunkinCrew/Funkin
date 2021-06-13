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
				if (textMenuItems[curSelected] != 'Muted' && textMenuItems[curSelected] != 'Old Title' && textMenuItems[curSelected] != 'Opponent Side Glow' && textMenuItems[curSelected] != 'VSync')
				{
					inMenu = true;
				}

				switch(textMenuItems[curSelected])
				{
					case 'Controls':
						add(controlsBox);

					case 'Mute':
						FlxG.sound.muted = true;
						textMenuItems = ["Back", "Unmute", "Volume"];
						spawnInTexts();

					case 'Unmute':
						FlxG.sound.muted = false;
						textMenuItems = ["Back", "Mute", "Volume"];
						spawnInTexts();

					case 'Back':
					{
						curSelected = 0;
						textMenuItems = ['Controls', 'Graphics', 'Sound', 'Misc'];
						spawnInTexts();
					}

					case 'Sound':
					{
						curSelected = 0;
						textMenuItems = ["Back", "Mute", "Volume"];
						spawnInTexts();
					}

					case 'Graphics':
					{
						curSelected = 0;
						textMenuItems = ["Back", "Opponent Side Glow", "Unlimited FPS"];
						spawnInTexts();
					}

					case 'Old Title':
					{
						if (FlxG.save.data.oldTitle == null)
						{
							FlxG.save.data.oldTitle = false;
						}
	
						FlxG.save.data.oldTitle = !FlxG.save.data.oldTitle;
						FlxG.save.flush();
					}

					case 'Opponent Side Glow':
					{
						FlxG.save.data.enemyGlow = !FlxG.save.data.enemyGlow;
						FlxG.save.flush();
					}

					case 'No-hit On':
					{
						FlxG.save.data.nohit = false;
						FlxG.save.flush();
						textMenuItems = ["Back", "Downscroll", "Old Title", "No-hit Off"];
						spawnInTexts();
					}

					case 'No-hit Off':
					{
						FlxG.save.data.nohit = true;
						FlxG.save.flush();
						textMenuItems = ["Back", "Downscroll", "Old Title", "No-hit On"];
						spawnInTexts();
					}

					case 'Downscroll':
					{
						if(FlxG.save.data.downscroll == null)
						{
							FlxG.save.data.downscroll = false;
						}

						FlxG.save.data.downscroll = !FlxG.save.data.downscroll;
						FlxG.save.flush();

						var option:Alphabet;

						if(FlxG.save.data.downscroll)
							option = new Alphabet(20, 20 + (2 * 100), "Downscroll", true, false);
						else
							option = new Alphabet(20, 20 + (2 * 100), "Upscroll", true, false);

						option.isMenuItem = true;
						option.targetY = 1;
						grpOptionsTexts.members[1] = option;
						inMenu = false;
					}

					case 'Misc':
					{
						curSelected = 0;
						textMenuItems = ["Back", "Downscroll", "Old Title"];

						if(!FlxG.save.data.nohit)
							textMenuItems.push("No-hit Off");
						else
							textMenuItems.push("No-hit On");
						
						spawnInTexts();
					}

					case 'Unlimited FPS':
					{
						inMenu = false;
						if(FlxG.save.data.unlimitedFPS != null)
						{
							FlxG.save.data.unlimitedFPS = false;
						}

						FlxG.save.data.unlimitedFPS = !FlxG.save.data.unlimitedFPS;
						FlxG.save.flush();

						if(FlxG.save.data.unlimitedFPS)
						{
							openfl.Lib.current.stage.frameRate = 10000;
						} else
						{
							openfl.Lib.current.stage.frameRate = 120;
						}
					}
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
