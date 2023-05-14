package game.state.menus;

#if discord_rpc
import game.data.backend.Discord.DiscordClient;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.util.FlxColor;
import lime.utils.Assets;

import game.ui.AtlasMenuList.AtlasMenuItem;
import game.ui.MenuList.MenuTypedList;
import game.ui.*;
import game.ui.gameplay.*;
import game.data.backend.*;

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	// var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Float = 0;
	var intendedScore:Int = 0;

	var coolColors:Array<Int> = [
		0xff9271fd,
		0xff9271fd,
		0xff223344,
		0xFF941653,
		0xFFfc96d7,
		0xFFa0d1ff,
		0xffff78bf,
		0xfff6b604
	];

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];
	var bg:FlxSprite;
	var scoreBG:FlxSprite;
	var difficulty:FlxSprite;
	var grpArrows:FlxTypedGroup<FlxSprite>;

	override function create()
	{
		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 0...initSonglist.length)
		{
			songs.push(new SongMetadata(initSonglist[i], 1, 'gf'));
		}

		if (FlxG.sound.music != null)
		{
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Bopeebo', 'Fresh', 'Dadbattle'], 1, ['dad']);

		if (StoryMenuState.weekUnlocked[2] || isDebug)
			addWeek(['Spookeez', 'South', 'Monster'], 2, ['spooky', 'spooky', 'monster']);

		if (StoryMenuState.weekUnlocked[3] || isDebug)
			addWeek(['Pico', 'Philly', 'Blammed'], 3, ['pico']);

		if (StoryMenuState.weekUnlocked[4] || isDebug)
			addWeek(['Satin-Panties', 'High', 'Milf'], 4, ['mom']);

		if (StoryMenuState.weekUnlocked[5] || isDebug)
			addWeek(['Cocoa', 'Eggnog', 'Winter-Horrorland'], 5, ['parents-christmas', 'parents-christmas', 'monster-christmas']);

		if (StoryMenuState.weekUnlocked[6] || isDebug)
			addWeek(['Senpai', 'Roses', 'Thorns'], 6, ['senpai', 'senpai', 'spirit']);

		if (StoryMenuState.weekUnlocked[7] || isDebug)
			addWeek(['Ugh', 'Guns', 'Stress'], 7, ['tankman']);

		addSong('Test', 1, 'bf-pixel');

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		var songListBG:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, 150, FlxColor.BLACK);
		songListBG.screenCenter(Y);
		add(songListBG);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			// songText.isMenuItem = true;
			// songText.targetY = i;
			songText.screenCenter(XY);
			songText.visible = false;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreBG = new FlxSprite(0, songListBG.y + 210).makeGraphic(FlxG.width, 100, 0x99000000);
		scoreBG.antialiasing = false;
		scoreBG.screenCenter(X);
		add(scoreBG);

		scoreText = new FlxText(0, scoreBG.y + 30, 0, "", 40);
		scoreText.setFormat(Paths.font("vcr.ttf"), 40, FlxColor.WHITE, CENTER);
		scoreText.screenCenter(X);
		scoreText.x -= 140;

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		// add(diffText);

		var menuUITex = Paths.getSparrowAtlas('campaign_menu_UI_assets');

		difficulty = new FlxSprite(0, scoreBG.y + 140);
		difficulty.frames = menuUITex;
		difficulty.animation.addByPrefix('easy', 'EASY');
		difficulty.animation.addByPrefix('normal', 'NORMAL');
		difficulty.animation.addByPrefix('hard', 'HARD');
		difficulty.animation.play('easy');
		difficulty.screenCenter(X);
		difficulty.x += 40;
		add(difficulty);

		grpArrows = new FlxTypedGroup<FlxSprite>();
		add(grpArrows);

		var arrowNames:Array<String> = ['left', 'right'];
		for (i in 0...arrowNames.length)
		{
			var xmlEndName:String = (i == 0 ? 'left' : 'right');
			var arrow:FlxSprite = new FlxSprite(0, difficulty.y - 10);
			arrow.frames = menuUITex;
			arrow.animation.addByPrefix('idle', 'arrow $xmlEndName');
			arrow.animation.addByPrefix('press', 'arrow push $xmlEndName', 24, false);
			arrow.animation.play('idle');
			grpArrows.ID = i;
			grpArrows.add(arrow);
			arrow.x = (i == 0 ? difficulty.x - 180 : difficulty.x + 300);
			FlxTween.tween(arrow, {x: (i == 0 ? arrow.x + 10 : arrow.x - 10)}, 1, {ease: FlxEase.sineInOut, type: PINGPONG});
		}

		add(scoreText);

		changeSelection();
		changeDiff();

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		super.create();
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter));
	}

	public function addWeek(songs:Array<String>, weekNum:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);

			if (songCharacters.length != 1)
				num++;
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.sound.music != null)
		{
			if (FlxG.sound.music.volume < 0.7)
			{
				FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			}
		}

		if (FlxG.sound.music != null) Conductor.songPosition = FlxG.sound.music.time;

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 4), 0, 1));

		lerpScore = CoolUtil.coolLerp(lerpScore, intendedScore, 0.4);
		bg.color = FlxColor.interpolate(bg.color, coolColors[songs[curSelected].week % coolColors.length], CoolUtil.camLerpShit(0.045));

		scoreText.text = "PERSONAL BEST:" + Math.round(lerpScore);

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
			changeSelection(-1);
		if (downP)
			changeSelection(1);

		if (FlxG.mouse.wheel != 0)
			changeSelection(-Math.round(FlxG.mouse.wheel / 4));

		if (controls.UI_RIGHT)
			grpArrows.members[1].animation.play('press');
		else
			grpArrows.members[1].animation.play('idle');

		if (controls.UI_LEFT)
			grpArrows.members[0].animation.play('press');
		else
			grpArrows.members[0].animation.play('idle');

		if (controls.UI_LEFT_P) {
			changeDiff(-1);
		}
		if (controls.UI_RIGHT_P) {
			changeDiff(1);
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			LoadingState.loadAndSwitchState(new PlayState());
		}
	}

	override function beatHit()
	{
		if (curBeat % 1 == 0) FlxG.camera.zoom += 0.015;
		super.beatHit();
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		PlayState.storyDifficulty = curDifficulty;

		difficulty.offset.x = 0;
		switch (curDifficulty) {case 1: difficulty.offset.x = 70; case 0 | 2: difficulty.offset.x = 20;}
		difficulty.animation.play(CoolUtil.difficultyString().toLowerCase());
	}

	function changeSelection(change:Int = 0)
	{
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);

		#if PRELOAD_ALL
		var song = Song.loadFromJson(songs[curSelected].songName, songs[curSelected].songName);
		FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		Conductor.changeBPM(song.bpm);
		#end

		for (i in 0...iconArray.length) iconArray[i].visible = false;
		iconArray[curSelected].visible = true;

		for (item in grpSongs.members) item.visible = false;
		grpSongs.members[curSelected].visible = true;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";

	public function new(song:String, week:Int, songCharacter:String)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
	}
}
