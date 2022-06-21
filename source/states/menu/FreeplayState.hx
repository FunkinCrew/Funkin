package states.menu;

import haxe.Json;
import engine.base.ModAPI.CharJSON;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import sys.FileSystem;
import sys.io.File;
import engine.io.Modding;
import engine.functions.Option;
import engine.functions.Conductor;
import engine.functions.Song;
import engine.util.Highscore;
import states.gameplay.PlayState;
import engine.io.Paths;
import engine.util.CoolUtil;
import engine.base.HealthIcon;
import engine.assets.Alphabet;
import engine.base.MusicBeatState;
#if desktop
import engine.io.Discord.DiscordClient;
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

	var modSongs:Map<String, String>;

	var bg:FlxSprite;

	override function create()
	{
		modSongs = new Map<String, String>();

		if (engine.functions.Option.recieveValue("GRAPHICS_globalAA") == 0)
		{
			FlxG.camera.antialiasing = true;
		}
		else
		{
			FlxG.camera.antialiasing = false;
		}

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));

		for (i in 1...initSonglist.length) // skip line 1 cause the help thingy is there
		{
			var thing = initSonglist[i].split(':');
			songs.push(new SongMetadata(thing[0], Std.parseInt(thing[3]), thing[1], Std.parseInt(thing[2])));
		}

		// mod shit
		for (mod in Modding.api.loaded)
		{
			var txtFile = File.getContent(mod.path + "/freeplay.txt").trim();
			var split = txtFile.split("\n");
			for (line in split)
			{
				modSongs.set(line.split(":")[0], mod.name);
				songs.push(new SongMetadata(line.split(":")[0], 0, line.split(":")[1], Std.parseInt(line.split(":")[2])));
			}
		}

		/* 
			if (FlxG.sound.music != null)
			{
				if (!FlxG.sound.music.playing)
					FlxG.sound.playMusic(Paths.music('freakyMenu'));
			}
		 */

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		// LOAD MUSIC

		// LOAD CHARACTERS

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

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		// scoreText.autoSize = false;
		scoreText.setFormat(Paths.font("vcr.ttf"), 32, FlxColor.WHITE, RIGHT);
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

		// FlxG.sound.playMusic(Paths.music('title'), 0);
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

	public function addSong(songName:String, weekNum:Int, songCharacter:String, bpm:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, bpm));
	}

	/*
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
	*/

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		camera.zoom = FlxMath.lerp(camera.zoom, camera.initialZoom, 0.1);
		bg.alpha = FlxMath.lerp(bg.alpha, 0.5, 0.1);

		super.update(elapsed);

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
			var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);

			trace(poop);

			PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase(), modSongs[poop] != null ? Modding.findModOfName(modSongs[poop]) : null);
			PlayState.isStoryMode = false;
			PlayState.storyDifficulty = curDifficulty;

			PlayState.storyWeek = songs[curSelected].week;
			trace('CUR WEEK' + PlayState.storyWeek);
			PlayState.startFrom = 0;
			LoadingState.loadAndSwitchState(new PlayState());
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
		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end

		#if PRELOAD_ALL
		Conductor.changeBPM(songs[curSelected].bpm);

		// new
		FlxG.sound.playMusic(Modding.getInst(songs[curSelected].songName, Modding.findModOfName(modSongs[songs[curSelected].songName])), 0);

		/* old
		if (FileSystem.exists(Paths.inst(songs[curSelected].songName)) || modSongs[songs[curSelected].songName] == null)
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
		else
		{
			trace("cursong " + songs[curSelected].songName);
			FlxG.sound.playMusic(Modding.api.getSoundShit("/songs/" + songs[curSelected].songName + "/Inst." + Paths.SOUND_EXT, modSongs[songs[curSelected].songName] != null ? Modding.findModOfName(modSongs[songs[curSelected].songName]) : null), 0);
		}
		*/
		#end

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
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}

		updateColor();
	}

	var tcolor:FlxColor;

	function updateColor() {
		var colorShit:Array<String> = CoolUtil.coolTextFile(Paths.txt("charcolors"));
		for (mod in Modding.api.loaded)
		{
			var shit:CharJSON = Json.parse(Modding.api.getTextShit("/chars.json", mod));
			for (char in shit.chars)
			{
				colorShit.push(char.name + ":" + char.color);
			}
		}

		for (bruh in colorShit) {
			if (!bruh.startsWith('#')) {
				var eugh = bruh.split(':');

				if (songs[curSelected].songCharacter.toLowerCase().startsWith(eugh[0])) {
					tcolor = new FlxColor(Std.parseInt(eugh[1]));
					trace(tcolor);
				}
			}
		}

		// FlxTween.tween(bg, {color: tcolor}, 0.5, {ease: FlxEase.quadInOut, type: ONESHOT});
		FlxTween.color(bg, 0.5, bg.color, tcolor, {ease: FlxEase.quadInOut, type: ONESHOT});
		// bg.color = tcolor;	
	}

	public override function beatHit() {
		camera.zoom += 0.01;
		if (curBeat % 8 == 0)
		{
			camera.zoom += 0.05;
			bg.alpha = 1;
		}


		super.beatHit();
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var bpm:Int = 0;

	public function new(song:String, week:Int, songCharacter:String, bpm:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.bpm = bpm;
	}
}
