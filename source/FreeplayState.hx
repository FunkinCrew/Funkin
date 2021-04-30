package;

import Section.SwagSection;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import DifficultyIcons;
import lime.system.System;
#if sys
import sys.io.File;
import haxe.io.Path;
import openfl.utils.ByteArray;
import lime.media.AudioBuffer;
import flixel.system.FlxSound;
import sys.FileSystem;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
using StringTools;

class FreeplayState extends MusicBeatState
{
	public static var currentSongList:Array<String> = [];
	public static var soundTest:Bool = false;
	var vocals:FlxSound;
	var songs:Array<String> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;
	var soundTestSong:Song.SwagSong;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var intendedAccuracy:Float = 0;
	var lerpAccuracy:Int = 0;
	var usingCategoryScreen:Bool = false;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	override function create()
	{
		songs = currentSongList;

		curDifficulty = DifficultyIcons.getDefaultDiffFP();
		/*
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);
			}
		 */

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS
		if (soundTest) {
			// disable auto pause. I NEED MUSIC
			FlxG.autoPause = false;
		}
		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.62, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.4), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic('assets/music/title' + TitleState.soundExt, 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/*
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}
		// why the fuck does this exist
		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));
		lerpAccuracy = Std.int(Math.round(intendedAccuracy * 100));
		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (!soundTest)
			scoreText.text = "PERSONAL BEST:" + lerpScore + ", " + lerpAccuracy + "%";
		else
			scoreText.text = "Sound Test";
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		if (soundTest && soundTestSong != null) {
			Conductor.songPosition += FlxG.elapsed * 1000;
		}
		if (upP)
		{
			changeSelection(-1);
		}
		if (downP)
		{
			changeSelection(1);
		}
		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);
		

		if (controls.BACK)
		{
			// main menu or else we are cursed
			FlxG.autoPause = true;
			if (soundTest)
				FlxG.switchState(new SaveDataState());
			else {
				var epicCategoryJs:Array<Dynamic> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));
				if (epicCategoryJs.length > 1)
				{
					FlxG.switchState(new CategoryState());
				} else
					FlxG.switchState(new MainMenuState());
			}
				
		}

		if (accepted)
		{
			if (soundTest) {
				// play both the vocals and inst
				// bad music >:(
				FlxG.sound.music.stop();
				if (vocals != null && vocals.playing)
					vocals.stop();
				soundTestSong = Song.loadFromJson(songs[curSelected].toLowerCase(), songs[curSelected].toLowerCase());
				if (soundTestSong.needsVoices && curDifficulty != 1)
				{
					if (curDifficulty == 0) {
						var vocalSound = Sound.fromFile("assets/music/" + soundTestSong.song + "_Voices" + TitleState.soundExt);
						vocals = new FlxSound().loadEmbedded(vocalSound);
						FlxG.sound.list.add(vocals);
						vocals.play();
						vocals.pause();
						vocals.looped = true;
					} else {
						FlxG.sound.playMusic(Sound.fromFile("assets/music/" + soundTestSong.song + "_Voices" + TitleState.soundExt));
					}
					
				}
				if (curDifficulty != 2) {
					FlxG.sound.playMusic(Sound.fromFile("assets/music/" + soundTestSong.song + "_Inst" + TitleState.soundExt));
				}
				
				Conductor.mapBPMChanges(soundTestSong);
				Conductor.changeBPM(soundTestSong.bpm);
				if (soundTestSong.needsVoices && curDifficulty == 0) {
					resyncVocals();
				}

				
			} else {
				var poop:String = songs[curSelected].toLowerCase() + DifficultyIcons.getEndingFP(curDifficulty);
				trace(poop);
				if (!FileSystem.exists('assets/data/' + songs[curSelected].toLowerCase() + '/' + poop.toLowerCase() + '.json'))
				{
					// assume we pecked up the difficulty, return to default difficulty
					trace("UH OH SONG IN SPECIFIED DIFFICULTY DOESN'T EXIST\nUSING DEFAULT DIFFICULTY");
					poop = songs[curSelected];
					curDifficulty = DifficultyIcons.getDefaultDiffFP();
				}
				trace(poop);

				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].toLowerCase());
				PlayState.isStoryMode = false;
				ModifierState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
				if (!OptionsHandler.options.skipModifierMenu)
					FlxG.switchState(new ModifierState());
				else
				{
					if (FlxG.sound.music != null)
						FlxG.sound.music.stop();
					FlxG.switchState(new PlayState());
				}
			}
			

		}
	}

	function changeDiff(change:Int = 0)
	{
		trace("line 182 fp");
		if (!soundTest) {
			var difficultyObject:Dynamic = DifficultyIcons.changeDifficultyFreeplay(curDifficulty, change);
			curDifficulty = difficultyObject.difficulty;

			#if !switch
			intendedScore = Highscore.getScore(songs[curSelected], curDifficulty);
			intendedAccuracy = Highscore.getAccuracy(songs[curSelected], curDifficulty);
			#end

			diffText.text = difficultyObject.text;
		} else {
			curDifficulty += change;
			if (curDifficulty > 2) {
				curDifficulty = 0;
			}
			if (curDifficulty < 0) {
				curDifficulty = 2;
			}
			switch (curDifficulty) {
				case 0:
					diffText.text = "Both tracks";
				case 1:
					diffText.text = "Inst Only";
				case 2:
					diffText.text = "Vocals Only";
			}

		}
		
	}
	override function stepHit()
	{
		super.stepHit();
		if (soundTest && soundTestSong != null && soundTestSong.needsVoices && curDifficulty == 0)
		{
			if (vocals.time > Conductor.songPosition + 20 || vocals.time < Conductor.songPosition - 20)
			{
				resyncVocals();
			}
		}

	}

	function resyncVocals():Void
	{
		vocals.pause();

		FlxG.sound.music.play();
		Conductor.songPosition = FlxG.sound.music.time;
		vocals.time = Conductor.songPosition;
		vocals.play();
	}
	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected], curDifficulty);
		intendedAccuracy = Highscore.getAccuracy(songs[curSelected], curDifficulty);
		// lerpScore = 0;
		#end
		if (!soundTest)
		#if sys
			FlxG.sound.playMusic(Sound.fromFile("assets/music/"+songs[curSelected]+"_Inst"+TitleState.soundExt), 0);
		#else
			FlxG.sound.playMusic('assets/music/' + songs[curSelected] + "_Inst" + TitleState.soundExt, 0);
		#end
		var bullShit:Int = 0;

		for (item in grpSongs.members)
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
