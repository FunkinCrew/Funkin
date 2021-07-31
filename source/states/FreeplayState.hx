package states;

import lime.app.Application;
import utilities.Ratings.SongRank;
import openfl.utils.ByteArray;
import modding.ModdingSound;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import game.Song;
import game.Highscore;
import utilities.CoolUtil;
import ui.HealthIcon;
import ui.Alphabet;
#if discord_rpc
import utilities.Discord.DiscordClient;
#end
#if sys
import polymod.Polymod;
import polymod.backends.PolymodAssets;
#end
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import openfl.utils.Assets as OpenFLAssets;

using StringTools;

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

	private var iconArray:Array<HealthIcon> = [];

	public static var songsReady:Bool = false;

	private var coolColors:Array<Int> = [0xFF7F1833, 0xFF7C689E, -14535868, 0xFFA8E060, 0xFFFF87FF, 0xFF8EE8FF, 0xFFFF8CCD, 0xFFFF9900];
	private var bg:FlxSprite;
	private var selectedColor:Int = 0xFF7F1833;
	private var interpolation:Float = 0.0;
	private var scoreBG:FlxSprite;

	private var rankText:FlxText;
	private var curRank:String = "N/A";

	override function create()
	{
		Application.current.window.title = Application.current.meta.get('name');
		
		var black = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);

		if(!songsReady)
		{
			Assets.loadLibrary("songs").onComplete(function (_) {
				FlxTween.tween(black, {alpha: 0}, 0.5, {
					ease: FlxEase.quadOut,
					onComplete: function(twn:FlxTween)
					{
						remove(black);
						black.kill();
						black.destroy();
					}
				});
	
				songsReady = true;
			});
		}

		#if sys
		var initSonglist = CoolUtil.coolTextFilePolymod(Paths.txt('freeplaySonglist'));
		#else
		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		#end

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// Loops through all songs in freeplaySonglist.txt
		for (i in 0...initSonglist.length)
		{
			// Creates an array of their strings
			var listArray = initSonglist[i].split(":");

			// Variables I like yes mmmm tasty
			var week = Std.parseInt(listArray[2]);
			var icon = listArray[1];
			var song = listArray[0];

			// If you've unlocked the week after this one, then yes
			if (
				listArray[3] == null && 
				(StoryMenuState.weekUnlocked[week + 1]
					|| isDebug
					|| !StoryMenuState.weekProgression
					|| (
						week == StoryMenuState.weekUnlocked.length
						&& StoryMenuState.weekUnlocked[week]
					)
				)
			)
			{
				// Creates new song data accordingly
				songs.push(new SongMetadata(song, week, icon));
			} else if(listArray[3] != null && FlxG.save.data.debugSongs == true)
			{
				// Creates new song data accordingly
				songs.push(new SongMetadata(song, week, icon));
			}
		}

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			iconArray.push(icon);
			add(icon);
		}

		scoreText = new FlxText(FlxG.width, 5, 0, "", 32);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 1, 0xFF000000);
		scoreBG.alpha = 0.6;
		add(scoreBG);

		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
		add(scoreText);

		diffText = new FlxText(scoreText.x + 100, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		diffText.alignment = CENTER;
		add(diffText);

		rankText = new FlxText(FlxG.width, diffText.y + 36, 0, "", 24);
		rankText.font = scoreText.font;
		rankText.alignment = CENTER;
		add(rankText);

		changeSelection();
		changeDiff();

		selector = new FlxText();

		selector.size = 40;
		selector.text = "<";

		if(!songsReady)
		{
			add(black);
		} else {
			remove(black);
			black.kill();
			black.destroy();
		}

		selectedColor = coolColors[songs[curSelected].week];
		bg.color = selectedColor;

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

		bg.color = FlxColor.interpolate(bg.color, selectedColor, interpolation);

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;

		scoreBG.x = scoreText.x - 6;

		if(Std.int(scoreBG.width) != Std.int(scoreText.width + 6))
			scoreBG.makeGraphic(Std.int(scoreText.width + 6), 102, FlxColor.BLACK);

		scoreText.x = FlxG.width - scoreText.width;
		scoreText.text = "PERSONAL BEST:" + lerpScore;

		diffText.x = scoreText.x + (scoreText.width / 2) - (diffText.width / 2);
		rankText.x = diffText.x + (diffText.width / 2) - (rankText.width / 2);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if(songsReady)
		{
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
				FlxG.sound.music.stop();
				FlxG.sound.music.destroy();
	
				FlxG.switchState(new MainMenuState());
			}

			if (accepted)
			{
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
	
				trace(poop);
	
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
				PlayState.storyWeek = songs[curSelected].week;
				trace('CUR WEEK' + PlayState.storyWeek);
				LoadingState.loadAndSwitchState(new PlayState());
			}
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
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDifficulty);
		#end

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "<  EASY  >";
			case 1:
				diffText.text = '< NORMAL >';
			case 2:
				diffText.text = "<  HARD  >";
		}

		rankText.text = "< " + curRank + " >";
	}

	function changeSelection(change:Int = 0)
	{
		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// Sounds

		// Scroll Sound
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		// Song Inst
		if(FlxG.save.data.freeplayMusic)
		{
			#if sys
			if(Assets.exists(Paths.inst(songs[curSelected].songName)))
			{
				FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName));
			}
			else
			{
				var array = PolymodAssets.getBytes(Paths.instSYS(songs[curSelected].songName));

				if(FlxG.sound.music.active)
					FlxG.sound.music.stop();

				FlxG.sound.music = new ModdingSound().loadByteArray(array);

				FlxG.sound.music.persist = true;
				FlxG.sound.music.play();
			}
			#else
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName));
			#end
		}

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		curRank = Highscore.getSongRank(songs[curSelected].songName, curDifficulty);
		#end

		rankText.text = "< " + curRank + " >";

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;

			if (item.targetY == 0)
			{
				item.alpha = 1;
			}
		}

		interpolation = 0.0;
		selectedColor = coolColors[songs[curSelected].week];

		for(i in 0...100)
		{
			new FlxTimer().start(i / 100, function(t:FlxTimer){
				interpolation += 0.01;
			});
		}
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
