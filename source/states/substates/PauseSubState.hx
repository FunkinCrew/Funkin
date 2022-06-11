package states.substates;

import engine.functions.Conductor;
import flixel.util.FlxTimer;
import states.menu.MainMenuState;
import engine.util.CoolUtil;
import states.gameplay.PlayState;
import engine.io.Paths;
import engine.assets.Alphabet;
import engine.base.MusicBeatSubstate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxSubState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.input.keyboard.FlxKey;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['Resume', 'Restart Song', 'Exit to menu'];
	var curSelected:Int = 0;

	var pauseMusic:FlxSound;

	var noSpam:Bool = false;

	var bg:FlxSprite;
	var levelInfo:FlxText;
	var levelDifficulty:FlxText;

	public function new(x:Float, y:Float)
	{
		super();

		/* github is high and doesn't recognize the comment alone as a change so here's this text.
		if (engine.functions.Option.recieveValue("GRAPHICS_globalAA") == 0)
			{
				FlxG.camera.antialiasing = true;
			}
			else
			{
				FlxG.camera.antialiasing = false;
			}
		*/


		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		levelInfo = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32);
		levelInfo.updateHitbox();
		add(levelInfo);

		levelDifficulty = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += CoolUtil.difficultyString();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32);
		levelDifficulty.updateHitbox();
		add(levelDifficulty);

		levelDifficulty.alpha = 0;
		levelInfo.alpha = 0;

		levelInfo.x = FlxG.width - (levelInfo.width + 20);
		levelDifficulty.x = FlxG.width - (levelDifficulty.width + 20);

		FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});
		FlxTween.tween(levelInfo, {alpha: 1, y: 20}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.3});
		FlxTween.tween(levelDifficulty, {alpha: 1, y: levelDifficulty.y + 5}, 0.4, {ease: FlxEase.quartInOut, startDelay: 0.5});

		grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
	}

	override function update(elapsed:Float)
	{
		if (pauseMusic.volume < 0.5)
			pauseMusic.volume += 0.01 * elapsed;

		super.update(elapsed);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}

		if (accepted && !noSpam)
		{
			var daSelected:String = menuItems[curSelected];

			switch (daSelected)
			{
				case "Resume":
					returnToGame();
				case "Restart Song":
					PlayState.resetShit();
					FlxG.resetState();
				case "Exit to menu":
					PlayState.resetShit();
					FlxG.switchState(new MainMenuState());
			}
		}

		if (FlxG.keys.justPressed.J)
		{
			// for reference later!
			// PlayerSettings.player1.controls.replaceBinding(Control.LEFT, Keys, FlxKey.J, null);
		}
	}

	function returnToGame()
	{
		noSpam = true;

		var swagCounter:Int = 0;

		new FlxTimer().start(Conductor.crochet / 1000, function(tmr:FlxTimer)
		{
			var introAssets:Map<String, Array<String>> = new Map<String, Array<String>>();
			introAssets.set('default', ['ready', "set", "go"]);

			var introAlts:Array<String> = introAssets.get('default');
			var altSuffix:String = "";

			switch (swagCounter)

			{
				case 0:
					FlxG.sound.play(Paths.sound('intro3'), 0.6);
					var ready:FlxText = new FlxText(0, 0, FlxG.width, "3", 32);
					ready.setFormat("assets/fonts/PhantomMuff.ttf", 64, FlxColor.WHITE, CENTER);
					ready.scrollFactor.set();
					ready.updateHitbox();

					ready.screenCenter();
					ready.y -= 100;
					add(ready);
					FlxTween.tween(ready, {y: ready.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							ready.destroy();
						}
					});
				case 1:
					FlxG.sound.play(Paths.sound('intro2'), 0.6);
					var set:FlxText = new FlxText(0, 0, FlxG.width, "2", 32);
					set.setFormat("assets/fonts/PhantomMuff.ttf", 64, FlxColor.WHITE, CENTER);
					set.scrollFactor.set();

					set.screenCenter();
					set.y -= 100;
					add(set);
					FlxTween.tween(set, {y: set.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							set.destroy();
						}
					});
				case 2:
					FlxG.sound.play(Paths.sound('intro1'), 0.6);
					var go:FlxText = new FlxText(0, 0, FlxG.width, "1", 32);
					go.setFormat("assets/fonts/PhantomMuff.ttf", 64, FlxColor.WHITE, CENTER);
					go.scrollFactor.set();

					go.updateHitbox();

					go.screenCenter();
					go.y -= 100;
					add(go);
					FlxTween.tween(go, {y: go.y += 100, alpha: 0}, Conductor.crochet / 1000, {
						ease: FlxEase.cubeInOut,
						onComplete: function(twn:FlxTween)
						{
							go.destroy();
						}
					});
				case 3:
					FlxG.sound.play(Paths.sound('introGo'), 0.6);
					for (object in this.members)
					{
						if (Std.isOfType(object, FlxSprite) || Std.isOfType(object, FlxText))
						{
							FlxTween.tween(object, {alpha: 0}, 0.2, {
								ease: FlxEase.cubeInOut,
								onComplete: function(twn:FlxTween)
								{
									close();
								}});
						}
					}
					// close();
			}

			swagCounter += 1;
			// generateSong('fresh');
		}, 5);
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		if (curSelected >= menuItems.length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
	}
}
