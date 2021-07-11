package options;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import lime.utils.Assets;
import flixel.util.FlxTimer;
import flixel.tweens.FlxEase;

import flixel.tweens.FlxTween;

using StringTools;

class CreditState extends MusicBeatState{
    var selector:FlxText;
	var curSelected:Int = 0;
	var bg:FlxSprite;
	var defaultCamZoom:Float = 1;
	var songs:Array<SongMetadata> = [];
	var songWait:FlxTimer = new FlxTimer();
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;
	var notice:FlxText;
	private var iconArray:Array<CreditIcon> = [];
	override function create()
	{
	    addWeek(['FNF Android Creator', 'V2.8 Coder'], 1, ['lucky', 'zack']);
	    addWeek(['BetaTester1', 'BetaTester2'], 2, ['schepka', 'goldie']);
	    addWeek(['Icon Artist', 'Icon Set 2'], 3, ['idioticlucas', 'maskedpump']);
	    addWeek(['GF Animator', 'Freeplay Bumpin'], 4, ['mark', 'smokey']);
	    addWeek(['Builder', 'Save help + builder', 'NoteSplash + tankroll'], 5, ['peppy', 'klavier', 'gamerbros']);
	    addWeek(['Funkin Crew', 'Funkin Crew', 'Funkin Crew', 'Funkin Crew'], 6, ['muffin', 'phantom', 'kawaii', 'evil']);

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

			var icon:CreditIcon = new CreditIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		changeSelection();

		var noticebg = new FlxSprite(0, FlxG.height - 56).makeGraphic(FlxG.width, 30, FlxColor.BLACK);
		noticebg.alpha = 0.5;


		notice = new FlxText(0, 0, 0,"", 24);

		notice.x = (FlxG.width / 2) - (notice.width / 2);
		notice.screenCenter();
		notice.y = FlxG.height - 56;
		notice.alpha = 0.8;
		add(noticebg);
		add(notice);

		#if mobileC
		addVirtualPad(UP_DOWN, A_B);
		#end

		FlxG.sound.playMusic(Paths.inst('test'), 0);

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
		for (i in 0...iconArray.length)
			{
				iconArray[i].animation.curAnim.curFrame = 0;
			}

		var colorLog:Int = 0;

		FlxG.camera.zoom = FlxMath.lerp(defaultCamZoom, FlxG.camera.zoom, 0.95);

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		switch (curSelected)
		{
			case 0:
				bg.color = FlxColor.fromRGB(255, 255, 0);
				notice.text = "luckydog";
			case 1:
				bg.color = FlxColor.fromRGB(0, 255, 64);
				notice.text = "zackdroid";
			case 2:
				bg.color = FlxColor.fromRGB(255, 165, 31);
				notice.text = "goldie";
			case 3:
				bg.color = FlxColor.fromRGB(255, 0, 204);
				notice.text = "schepka";
			case 4:
				bg.color = FlxColor.fromRGB(255, 0, 0);
				notice.text = "idioticlucas";
			case 5:
				bg.color = FlxColor.fromRGB(255, 149, 0);
				notice.text = "maskedpump";
			/*case 'Logo Artist':
				bg.color = FlxColor.fromRGB(128, 255, 0);
				notice.text = "aarontal";*/
			case 6:
				bg.color = FlxColor.fromRGB(255, 0, 98);
				notice.text = "markmemarnie";
			case 8:
				bg.color = FlxColor.fromRGB(0, 238, 255);
				notice.text = "peppy";
			case 9:
				bg.color = FlxColor.fromRGB(170, 0, 255);
				notice.text = "klavier";
			case 10:
				bg.color = FlxColor.fromRGB(255, 170, 0);
				notice.text = "gamerbros";
			case 11:
				bg.color = FlxColor.fromRGB(0, 145, 255);
				notice.text = "Ninja, arcade, kawaii, sk8er";
			case 7:
				bg.color = FlxColor.fromRGB(0, 68, 255);
				notice.text = "smokey";
		}

		notice.x = (FlxG.width / 2) - (notice.width / 2);

		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			changeSelection(-1);
			colorLog += -1;
		}
		if (downP)
		{
			changeSelection(1);
			colorLog += 1;
		}

		if (controls.BACK)
		{
			FlxG.switchState(new MainMenuState());
		}
	}
	override function beatHit()
		{
			super.beatHit();
			// trace(curBeat);

			iconBop();

			if (FlxG.camera.zoom < 1.35 && songs[curSelected].songName.toLowerCase() == 'milf' && curBeat >= 8)
				{
					FlxG.camera.zoom += 0.030;
				}
			else if (FlxG.camera.zoom < 1.35 && songs[curSelected].songName.toLowerCase() != 'milf'){
				FlxG.camera.zoom += 0.020;
				trace('beat!');
			}
			//Sum extra detail
			if (FlxG.camera.zoom < 1.35 && songs[curSelected].songName.toLowerCase() == 'milf' && curBeat >= 168 && curBeat < 200)
				{
					FlxG.camera.zoom += 0.060;
				}
		}

	function changeSelection(change:Int = 0)
	{
		#if newgrounds
		#if !switch
		NGio.logEvent('Fresh');
		#end
		#end

		// NGio.logEvent('Fresh');
		FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		// selector.y = (70 * curSelected) + 30;

		/*#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		// lerpScore = 0;
		#end*/

		//FlxG.sound.playMusic(Paths.inst('test'), 0);

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
	function iconBop(?_scale:Float = 1.25, ?_time:Float = 0.2):Void {
		iconArray[curSelected].iconScale = iconArray[curSelected].defualtIconScale * _scale;

		FlxTween.tween(iconArray[curSelected], {iconScale: iconArray[curSelected].defualtIconScale}, _time, {ease: FlxEase.quintOut});
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