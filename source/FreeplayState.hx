package;

import Song;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.system.FlxAssets.FlxSoundAsset;
import flixel.system.FlxSound;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import haxe.Timer;
import lime.utils.Assets;
#if sys
import sys.FileSystem;
import sys.io.File;
#end

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	var curSelected:Int = 0;
	var curDifficulty:Int = 1;

	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var musicDemos:Array<FlxSound>;
	private var currentlyPlayingDemo:FlxSound;

	override function create()
	{
		if (FlxG.sound.music != null)
			if (!FlxG.sound.music.playing)
				FlxG.sound.playMusic('assets/music/freakyMenu' + TitleState.soundExt);

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		musicDemos = new Array<FlxSound>();

		var lockedMusic:Array<SongMetadata> = [];
		// LOAD UNLOCKED MUSIC
		for (i in 0...SongLoader.instance.weeks.length)
			if (StoryMenuState.weekUnlocked[i] || isDebug)
				for (song in SongLoader.instance.weeks[i].songs)
				{
					if (!songs.contains(song))
						songs.push(song);
				}
			else
				for (song in SongLoader.instance.weeks[i].songs)
					if (!lockedMusic.contains(song))
						lockedMusic.push(song);

		if (isDebug)
			for (song in SongLoader.instance.songs)
				if (!lockedMusic.contains(song) && !songs.contains(song))
					songs.push(song);

		// LOAD CHARACTERS
		var bg:FlxSprite = new FlxSprite().loadGraphic(AssetPaths.menuBGBlue__png);
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].name, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat("assets/fonts/vcr.ttf", 32, FlxColor.WHITE, RIGHT);
		// scoreText.alignment = RIGHT;

		var scoreBG:FlxSprite = new FlxSprite(scoreText.x - 6, 0).makeGraphic(Std.int(FlxG.width * 0.35), 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		add(diffText);

		add(scoreText);

		// LOAD MUSIC TO PLAY IN THE BACKGROUND
		for (song in songs)
			musicDemos.push(new FlxSound().loadStream('songs/${song.folder}/${song.instrumental}${TitleState.soundExt}'));

		for (demo in musicDemos)
			FlxG.sound.list.add(demo);

		changeDiff(0);
		// Playing the first song here makes it not play for some reason, I have no fucking clue
		Timer.delay(function() changeSelection(0), 1000);

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		FlxG.watch.addQuick("musicDemoState", musicDemos);
		FlxG.watch.addQuick("demoPlaying", currentlyPlayingDemo);

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreText.text = "PERSONAL BEST:" + lerpScore;

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

		if (controls.LEFT_P)
			changeDiff(-1);
		if (controls.RIGHT_P)
			changeDiff(1);

		if (controls.BACK)
		{
			if(currentlyPlayingDemo != null)
				currentlyPlayingDemo.fadeOut();
			if(FlxG.sound.music != null)
				FlxG.sound.music.fadeIn();
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
		{
			var song = SongLoader.instance.LoadSongData(songs[curSelected], curDifficulty);
			if (song == null)
			{
				accepted = false;
				trace("No difficulty " + curDifficulty + " for song " + songs[curSelected].name + ".");
				return;
			}
			if (currentlyPlayingDemo != null)
				currentlyPlayingDemo.fadeOut(0.5, 0, function(tween) currentlyPlayingDemo.stop());
			PlayState.SONG = song;
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;
			FlxG.switchState(new PlayState());
			if (FlxG.sound.music != null)
				FlxG.sound.music.stop();
		}
	}

	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = 2;
		if (curDifficulty > 2)
			curDifficulty = 0;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].name, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "EASY";
			case 1:
				diffText.text = 'NORMAL';
			case 2:
				diffText.text = "HARD";
		}
	}

	function changeSelection(change:Int = 0)
	{
		#if !switch
		NGio.logEvent('Fresh');
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].name, curDifficulty);
		// lerpScore = 0;
		#end

		var toPlay = musicDemos[curSelected];

		if (FlxG.sound.music != null)
			if (FlxG.sound.music.playing)
				FlxG.sound.music.fadeOut();

		if (currentlyPlayingDemo != null)
		{
			var prevSong = currentlyPlayingDemo;
			currentlyPlayingDemo.fadeOut(1, 0, function(tween) prevSong.pause());
		}

		toPlay.play(true, 0);
		toPlay.fadeIn().onComplete = function()
		{
			FlxG.sound.music.fadeIn(2.5);
		}
		currentlyPlayingDemo = toPlay;

		var i:Int = 0;
		for (item in grpSongs.members)
		{
			item.targetY = i - curSelected;
			i++;

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
