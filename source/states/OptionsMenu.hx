package states;

import debuggers.ChartingState;
import debuggers.StageMakingState;
import flixel.system.FlxSound;
import debuggers.AnimationDebug;
import utilities.Controls.Control;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import ui.Alphabet;
import ui.ControlsBox;
import game.Song;
import debuggers.StageMakingState;
import game.Highscore;

class OptionsMenu extends MusicBeatState
{
	var textMenuItems:Array<String> = ['Controls', 'Graphics', 'Sound', 'Tools', 'Misc'];
	var curSelected:Int = 0;
	var grpOptionsTexts:FlxTypedGroup<Alphabet>;

	var controlsBox = new ControlsBox();

	var inMenu = false;

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		menuBG.color = 0xFFea71fd;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = true;
		add(menuBG);

		super.create();

		//openSubState(new OptionsSubState());
		grpOptionsTexts = new FlxTypedGroup<Alphabet>();
		add(grpOptionsTexts);

		spawnInTexts();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (!inMenu)
		{
			// base menu hotkeys
			if (FlxG.keys.justPressed.ONE)
			{
				moveTo('Graphics');
			}

			if (FlxG.keys.justPressed.TWO)
			{
				moveTo('Sound');
			}

			if (FlxG.keys.justPressed.THREE)
			{
				moveTo('Tools');
			}

			if (FlxG.keys.justPressed.FOUR)
			{
				moveTo('Misc');
			}
			// tools
			if (FlxG.keys.justPressed.ONE)
			{
				moveTo('Charter');
			}

			if (FlxG.keys.justPressed.TWO)
			{
				moveTo('Animation Debug');
			}

			if (FlxG.keys.justPressed.THREE)
			{
				moveTo('Stage Editor');
			}

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
						textMenuItems = ['Controls', 'Graphics', 'Sound', 'Tools', 'Misc'];
						spawnInTexts();
					}

					case 'Tools':
					{
						curSelected = 0;
						textMenuItems = ["Back", "Charter", "Animation Debug", "Stage Editor"];
						spawnInTexts();
					}

					case 'Charter':
					{
						PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', 2), 'tutorial');
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = 2;
						PlayState.storyWeek = 0;
						
						LoadingState.loadAndSwitchState(new ChartingState());
					}

					case 'Animation Debug':
					{
						PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', 2), 'tutorial');
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = 2;
						PlayState.storyWeek = 0;
						FlxG.sound.music.stop();
						LoadingState.loadAndSwitchState(new AnimationDebug('dad'));
					}
					
					case 'Stage Editor':
					{
						PlayState.SONG = Song.loadFromJson(Highscore.formatSong('tutorial', 2), 'tutorial');
						PlayState.isStoryMode = false;
						PlayState.storyDifficulty = 2;
						PlayState.storyWeek = 0;

						LoadingState.loadAndSwitchState(new StageMakingState('stage'), true);
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
						textMenuItems = ["Back", "Opponent Side Glow", "Accuracy Text"];
						spawnInTexts();
					}

					case 'Accuracy Text':
					{
						inMenu = false;
						
						if(FlxG.save.data.msText == null)
						{
							FlxG.save.data.msText = false;
						}

						FlxG.save.data.msText = !FlxG.save.data.msText;
						FlxG.save.flush();
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

					case 'No Hit On':
					{
						FlxG.save.data.nohit = false;
						FlxG.save.flush();

						var option:Alphabet;

						if(FlxG.save.data.nohit)
							option = new Alphabet(20, 20 + (3 * 100), "No Hit On", true, false);
						else
							option = new Alphabet(20, 20 + (3 * 100), "No Hit Off", true, false);

						option.isMenuItem = true;
						option.targetY = 3;
						grpOptionsTexts.members[3] = option;
						textMenuItems[3] = "No Hit Off";
						inMenu = false;
					}

					case 'No Hit Off':
					{
						FlxG.save.data.nohit = true;
						FlxG.save.flush();

						var option:Alphabet;

						if(FlxG.save.data.nohit)
							option = new Alphabet(20, 320, "No Hit On", true, false);
						else
							option = new Alphabet(20, 320, "No Hit Off", true, false);

						option.isMenuItem = true;
						option.targetY = 3;
						grpOptionsTexts.members[3] = option;
						textMenuItems[3] = "No Hit On";
						inMenu = false;
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
							option = new Alphabet(20, 220, "Downscroll", true, false);
						else
							option = new Alphabet(20, 220, "Upscroll", true, false);

						option.isMenuItem = true;
						option.targetY = 1;
						grpOptionsTexts.members[1] = option;
						inMenu = false;
					}

					case "Reset Button On":
					{
						inMenu = false;
						FlxG.save.data.resetButtonOn = false;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Reset Button Off", true, false);
						option.isMenuItem = true;
						option.targetY = 4;
						grpOptionsTexts.members[4] = option;
						textMenuItems[4] = "Reset Button Off";
						inMenu = false;
					}

					case "Reset Button Off":
					{
						inMenu = false;
						FlxG.save.data.resetButtonOn = true;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Reset Button On", true, false);
						option.isMenuItem = true;
						option.targetY = 4;
						grpOptionsTexts.members[4] = option;
						textMenuItems[4] = "Reset Button On";
						inMenu = false;
					}

					case "Debug Songs On":
					{
						inMenu = false;
						FlxG.save.data.debugSongs = false;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Debug Songs Off", true, false);
						option.isMenuItem = true;
						option.targetY = 5;
						grpOptionsTexts.members[5] = option;
						textMenuItems[5] = "Debug Songs Off";
						inMenu = false;
					}

					case "Debug Songs Off":
					{
						inMenu = false;
						FlxG.save.data.debugSongs = true;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Debug Songs On", true, false);
						option.isMenuItem = true;
						option.targetY = 5;
						grpOptionsTexts.members[5] = option;
						textMenuItems[5] = "Debug Songs On";
						inMenu = false;
					}

					case "Week Progression On":
					{
						inMenu = false;
						FlxG.save.data.weekProgression = false;
						FlxG.save.flush();
						StoryMenuState.weekProgression = FlxG.save.data.weekProgression;

						var option = new Alphabet(20, 420, "Week Progression Off", true, false);
						option.isMenuItem = true;
						option.targetY = 6;
						grpOptionsTexts.members[6] = option;
						textMenuItems[6] = "Week Progression Off";
						inMenu = false;
					}

					case "Week Progression Off":
					{
						inMenu = false;
						FlxG.save.data.weekProgression = true;
						FlxG.save.flush();
						StoryMenuState.weekProgression = FlxG.save.data.weekProgression;

						var option = new Alphabet(20, 420, "Week Progression On", true, false);
						option.isMenuItem = true;
						option.targetY = 6;
						grpOptionsTexts.members[6] = option;
						textMenuItems[6] = "Week Progression On";
						inMenu = false;
					}

					case "Anti-Mash On":
					{
						inMenu = false;
						FlxG.save.data.antiMash = false;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Anti-Mash Off", true, false);
						option.isMenuItem = true;
						option.targetY = 7;
						grpOptionsTexts.members[7] = option;
						textMenuItems[7] = "Anti-Mash Off";
						inMenu = false;
					}

					case "Anti-Mash Off":
					{
						inMenu = false;
						FlxG.save.data.antiMash = true;
						FlxG.save.flush();

						var option = new Alphabet(20, 420, "Anti-Mash On", true, false);
						option.isMenuItem = true;
						option.targetY = 7;
						grpOptionsTexts.members[7] = option;
						textMenuItems[7] = "Anti-Mash On";
						inMenu = false;
					}

					case 'Misc':
					{
						curSelected = 0;
						textMenuItems = ["Back", "Downscroll", "Old Title"];

						if(!FlxG.save.data.nohit)
							textMenuItems.push("No Hit Off");
						else
							textMenuItems.push("No Hit On");

						if(!FlxG.save.data.resetButtonOn)
							textMenuItems.push("Reset Button Off");
						else
							textMenuItems.push("Reset Button On");

						if(!FlxG.save.data.debugSongs)
							textMenuItems.push("Debug Songs Off");
						else
							textMenuItems.push("Debug Songs On");

						if(!FlxG.save.data.weekProgression)
							textMenuItems.push("Week Progression Off");
						else
							textMenuItems.push("Week Progression On");

						if(!FlxG.save.data.antiMash)
							textMenuItems.push("Anti-Mash Off");
						else
							textMenuItems.push("Anti-Mash On");
						
						spawnInTexts();
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

	function moveTo(?option:String = 'Graphics')
	{
		for (i in 0...textMenuItems.length)
		{
			if (textMenuItems[i] == option)
			{
				curSelected = i;
			}
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
