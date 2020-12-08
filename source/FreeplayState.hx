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
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;

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

	private var musicDemos:FlxTypedGroup<FlxSound>;

	override function create()
	{
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

		var lockedMusic:Array<SongMetadata> = [];
		// LOAD UNLOCKED MUSIC
		for (i in 0...SongLoader.instance.weeks.length)
			if (StoryMenuState.weekUnlocked[i] || isDebug)
				for (song in SongLoader.instance.weeks[i].songs)
				{
					if (!songs.contains(song))
					{
						songs.push(song);
					}
				}
			else
				for (song in SongLoader.instance.weeks[i].songs)
					if (!lockedMusic.contains(song))
						lockedMusic.push(song);

		for (song in SongLoader.instance.songs)
			if (!lockedMusic.contains(song) && !songs.contains(song))
				songs.push(song);

		musicDemos = new FlxTypedGroup<FlxSound>();

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

		changeSelection();
		changeDiff();

		// FlxG.sound.playMusic('assets/music/title' + TitleState.soundExt, 0);
		// FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		// add(selector);

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
		FlxG.watch.addQuick("musicDemoState", musicDemos.members);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

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
			curSelected = grpSongs.length - 1;
		if (curSelected >= grpSongs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].name, curDifficulty);
		// lerpScore = 0;
		#end

		if (FlxG.sound.music.playing)
			FlxG.sound.music.fadeOut(1.5, 0, function(tween) FlxG.sound.music.pause());
		else
		{
			if (musicDemos.length > 2)
			{
				for (i in 0...musicDemos.length - 3)
				{
					var song = musicDemos.members[i];
					song.onComplete = null;
					song.stop();
					musicDemos.members.remove(song);
				};
			}

			var first = musicDemos.getFirstExisting();
			first.fadeOut(1.5, 0, function(tween)
			{
				first.onComplete = null;
				first.stop();
				musicDemos.members.remove(first);
			});
		}

		var song = FlxG.sound.play('songs/' + songs[curSelected].folder + "/" + songs[curSelected].instrumental + TitleState.soundExt, 0);
		song.onComplete = function()
		{
			musicDemos.members.remove(song);
			FlxG.sound.music.play();
			FlxG.sound.music.fadeIn(2);
		};
		musicDemos.add(song);
		song.fadeIn(1.5, 0, 0.7);
		// FlxG.sound.playMusic('songs/' + songs[curSelected].folder + "/" + songs[curSelected].instrumental + TitleState.soundExt, 0);
		// FlxG.sound.music.fadeIn(4, 0, 1);

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

	private function stopAndPop(song:FlxSound)
	{
		song.stop();
		musicDemos.remove(song);
	}
}
