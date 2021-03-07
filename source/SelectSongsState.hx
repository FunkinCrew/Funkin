package;

import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
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
import sys.FileSystem;
import flash.media.Sound;
#end
import haxe.Json;
import tjson.TJSON;
using StringTools;
typedef TCategory = {
	var name:String;
	var songs:Array<String>;
}
class SelectSongsState extends MusicBeatSubstate
{
	public static var currentSongList:Array<String> = [];
	public static var selectedSongs:Array<String> = [];
	var songs:Array<String> = [];
	var boolSongs:Array<Bool> = [];
	var selector:FlxText;
	var curSelected:Int = 0;
	var lerpScore:Int = 0;
	var intendedScore:Int = 0;
	var usingCategoryScreen:Bool = false;
	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var checkmarks:FlxTypedSpriteGroup<FlxSprite>;
	private var curPlaying:Bool = false;

	override function create()
	{
		var coolCategoryJson:Array<TCategory> = CoolUtil.parseJson(Assets.getText('assets/data/freeplaySongJson.jsonc'));


		for (coolCategory in coolCategoryJson) {
			for (coolSong in coolCategory.songs) {
				songs.push(coolSong);
			}
		}

		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = new FlxSprite().loadGraphic('assets/images/menuBGBlue.png');
		add(bg);

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			var checkmark = new FlxSprite(0, 0).loadGraphic('assets/images/checkmark.png');
			checkmark.visible = false;
			boolSongs[i] = false;
			grpSongs.add(songText);
			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}


		changeSelection();

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

		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, 0.4));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;


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

		if (controls.BACK)
		{
			close();
		}

		if (accepted)
		{
			// do shit
			if (!selectedSongs.contains(songs[curSelected])) {
				var coolNumber:FlxText = new FlxText(grpSongs.members[curSelected].x+ grpSongs.members[curSelected].width,0,0,Std.string(selectedSongs.length + 1));
				coolNumber.setFormat("VCR OSD Mono", 32, FlxColor.WHITE, RIGHT);
				grpSongs.members[curSelected].add(coolNumber);
				selectedSongs.push(songs[curSelected]);
			}
		}
	}


	function changeSelection(change:Int = 0)
	{

		FlxG.sound.play('assets/sounds/scrollMenu' + TitleState.soundExt, 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		var bullShit:Int = 0;

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
	}
}
