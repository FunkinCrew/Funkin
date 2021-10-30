package substates;

import game.Note;
import utilities.Difficulties;
import states.FreeplayState;
import states.StoryMenuState;
import states.LoadingState;
import states.PlayState;
import ui.Alphabet;
import utilities.Controls.Control;
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
import utilities.CoolUtil;
import states.MainMenuState;

class PauseSubState extends MusicBeatSubstate
{
	var grpMenuShit:FlxTypedGroup<Alphabet>;

	var curSelected:Int = 0;

	var menus:Map<String, Array<String>> = [
		"default" => ['Resume', 'Restart Song', 'Restart Song With Cutscenes', 'Options', 'Exit to menu'],
		"options" => ['Back', 'Bot', 'Auto Restart', 'No Miss', 'Ghost Tapping'],
	];

	var menu:String = "default";

	var pauseMusic:FlxSound;

	public function new(x:Float, y:Float)
	{
		super();

		pauseMusic = new FlxSound().loadEmbedded(Paths.music('breakfast'), true, true);
		pauseMusic.volume = 0;
		pauseMusic.play(false, FlxG.random.int(0, Std.int(pauseMusic.length / 2)));

		FlxG.sound.list.add(pauseMusic);

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0;
		bg.scrollFactor.set();
		add(bg);

		var levelInfo:FlxText = new FlxText(20, 15, 0, "", 32);
		levelInfo.text += PlayState.SONG.song;
		levelInfo.scrollFactor.set();
		levelInfo.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		levelInfo.updateHitbox();
		add(levelInfo);

		var levelDifficulty:FlxText = new FlxText(20, 15 + 32, 0, "", 32);
		levelDifficulty.text += PlayState.storyDifficultyStr.toUpperCase();
		levelDifficulty.scrollFactor.set();
		levelDifficulty.setFormat(Paths.font('vcr.ttf'), 32, FlxColor.WHITE, RIGHT);
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

		updateAlphabets();

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
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (accepted)
		{
			var daSelected:String = menus.get(menu)[curSelected];

			switch (daSelected)
			{
				case "Resume":
					close();
				case "Restart Song":
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
					PlayState.fromPauseMenu = true;
					FlxG.resetState();
				case "Restart Song With Cutscenes":
					PlayState.SONG.speed = PlayState.previousScrollSpeedLmao;
					FlxG.resetState();
				case "Bot":
					FlxG.save.data.bot = !FlxG.save.data.bot;
					FlxG.save.flush();

					@:privateAccess
					{
						PlayState.instance.infoTxt.text = PlayState.SONG.song + " - " + PlayState.storyDifficultyStr.toUpperCase() + (FlxG.save.data.bot ? " (BOT)" : "");
						PlayState.instance.infoTxt.screenCenter(X);
						PlayState.instance.hasUsedBot = true;
					}
				case "Auto Restart":
					FlxG.save.data.quickRestart = !FlxG.save.data.quickRestart;
					FlxG.save.flush();
				case "No Miss":
					FlxG.save.data.nohit = !FlxG.save.data.nohit;
					FlxG.save.flush();
				case "Ghost Tapping":
					FlxG.save.data.ghostTapping = !FlxG.save.data.ghostTapping;
					FlxG.save.flush();

					@:privateAccess
					if(FlxG.save.data.ghostTapping) // basically making it easier lmao
						PlayState.instance.hasUsedBot = true;
				case "Options":
					menu = "options";
					updateAlphabets();
				case "Back":
					menu = "default";
					updateAlphabets();
				case "Exit to menu":
					#if linc_luajit
					if (PlayState.luaModchart != null)
					{
						PlayState.luaModchart.die();
						PlayState.luaModchart = null;
					}
					#end
					
					if (PlayState.isStoryMode)
						FlxG.switchState(new StoryMenuState());
					else
						FlxG.switchState(new FreeplayState());
			}
		}
	}

	function updateAlphabets()
	{
		grpMenuShit.clear();

		for (i in 0...menus.get(menu).length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menus.get(menu)[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

		curSelected = 0;
		changeSelection();
	}

	override function destroy()
	{
		pauseMusic.destroy();

		super.destroy();
	}

	function changeSelection(change:Int = 0):Void
	{
		FlxG.sound.play(Paths.sound('scrollMenu'));
		
		curSelected += change;

		if (curSelected < 0)
			curSelected = menus.get(menu).length - 1;
		if (curSelected >= menus.get(menu).length)
			curSelected = 0;

		var bullShit:Int = 0;

		for (item in grpMenuShit.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
				item.alpha = 1;
		}
	}
}
