package;

import openfl.media.Sound;
import sys.io.File;
import sys.FileSystem;
import lime.system.System;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
#if desktop
import Discord.DiscordClient;
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

	private var chars:Array<String> = [];
	private var colors:Array<Int> = [];
	var tcolor:FlxColor;

	var bg:FlxSprite;

	override function create()
	{
		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		var isDebug:Bool = false;

		#if debug
		isDebug = true;
		#end

		for (song in CoolUtil.coolTextFile(Paths.txt('freeplaySonglist', 'preload'))) {
			var tempArray = song.split(':');

			if (Std.parseInt(tempArray[2]) == 69420)
				tempArray[2] = "0";

			addSong(tempArray[0], Std.parseInt(tempArray[2]), tempArray[1]);
		}

		for (song in FileSystem.readDirectory("mods/data/")) {
			var tempArray = song.split(':');
			addSong(tempArray[0], 69420, "none"); //if the week is 69420, its a mod.
		}

		// LOAD MUSIC

		// LOAD CHARACTERS

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i].songName, true, false);
			
			/*
			var tcolor:FlxColor = 0;

			for (col in CoolUtil.coolTextFile(Paths.txt('healthcolors'))) {
				var eugh = col.split(':');

				if (songs[i].songCharacter.toLowerCase().startsWith(eugh[0])) {
					tcolor = new FlxColor(Std.parseInt(eugh[1]));
				}
			}

			songText.color = new FlxColor(tcolor);
			*/

			songText.isMenuItem = true;
			songText.targetY = i;
			grpSongs.add(songText);

			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			var array = CoolUtil.coolTextFile(Paths.txt('healthcolors'));

			/*for (i in 0...array.length) {
				var eugh = array[i].split(':');

				if (songs[i].songCharacter.toLowerCase().startsWith(eugh[0])) {
					colors.push(Std.parseInt(eugh[1]));
				}
			}*/

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			updateColor();

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

		diffText = new FlxText(scoreBG.x, scoreText.y + 36, scoreBG.width - 20, "", 24);
		diffText.font = scoreText.font;
		diffText.alignment = CENTER;
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

		switch (songs[curSelected].songName){
			case 'Ugh-Swagmix':
				setSwagmixDifficulty();
			case 'Roses-Swagmix':
				setSwagmixDifficulty();
			default:
				if (diffText.text == "< SWAGMIX >"){
					curDifficulty = 1;
					diffText.text = "< NORMAL >";
				}

				if (controls.LEFT_P)
					changeDiff(-1);
				if (controls.RIGHT_P)
					changeDiff(1);
		}

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
		var secret = controls.CHEAT;

		if (upP)
		{
			changeSelection(-1);
			if (!FlxG.save.data.epilepsyMode){
				updateColor();
			}
		}
		if (downP)
		{
			changeSelection(1);
			if (!FlxG.save.data.epilepsyMode){
				updateColor();
			}
		}

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}

		if (accepted)
			{
				FlxG.sound.music.fadeOut(1, 0);

				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				trace(poop);

				if (songs[curSelected].week == 69420){
					PlayState.SONG = Song.loadFromModJson(poop, songs[curSelected].songName.toLowerCase());
					PlayState.isMod = true;
				}
				else{
					PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				}

				if (secret){
					PlayState.secretMode = true;

					FlxG.sound.play(Paths.sound('GF_1', 'shared'));
					trace('Just because you heard the sound, doesn\'t mean you\'ve found the secret!');
				}
	
				PlayState.isStoryMode = false;
				PlayState.storyDifficulty = curDifficulty;
	
				PlayState.storyWeek = songs[curSelected].week;
				trace('CUR WEEK' + PlayState.storyWeek + '\nSecret Mode: ' + PlayState.secretMode);
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

		loadScoreData();

		switch (curDifficulty)
		{
			case 0:
				diffText.text = "< EASY >";
			case 1:
				diffText.text = '< NORMAL >';
			case 2:
				diffText.text = "< HARD >";
		}
	}

	function loadScoreData(){
		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		#end
	}

	function setSwagmixDifficulty(){
		if (diffText.text != "< SWAGMIX >"){
			curDifficulty = 2;
			loadScoreData();
			diffText.text = "< SWAGMIX >";
			trace("LETS SWAGMIX");
		}
		else{
			return;
		}
	} // i like putting stuff in functions xD

	function changeSelection(change:Int = 0)
	{
		/*
		#if !switch
		NGio.logEvent('Fresh');
		#end
		*/

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		loadScoreData();

		#if PRELOAD_ALL
		if (songs[curSelected].week == 69420){
			FlxG.sound.playMusic(Sound.fromFile("mods/songs/" + songs[curSelected].songName.toLowerCase() + "/Inst.ogg"), 0, true);
		}
		else
			FlxG.sound.playMusic(Paths.inst(songs[curSelected].songName), 0);
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
	}
	function updateColor() {
		for (bruh in CoolUtil.coolTextFile(Paths.txt('healthcolors'))) {
			if (!bruh.startsWith('#')) {
				var eugh = bruh.split(':');

				if (songs[curSelected].songCharacter.toLowerCase().startsWith(eugh[0])) {
					tcolor = new FlxColor(Std.parseInt(eugh[1]));
				}
			}
		}

		// FlxTween.tween(bg, {color: tcolor}, 0.5, {ease: FlxEase.quadInOut, type: ONESHOT});
		FlxTween.color(bg, 0.5, bg.color, tcolor, {ease: FlxEase.quadInOut, type: ONESHOT});
		// bg.color = tcolor;	
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
