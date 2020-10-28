package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;

class FreeplayState extends MusicBeatState
{
	var songs:Array<String> = ["Bopeebo", "Dadbattle", "Fresh", "Tutorial", "Spookeez"];

	var selector:FlxText;
	var curSelected:Int = 0;

	override function create()
	{
		// LOAD MUSIC

		// LOAD CHARACTERS

		var bg:FlxSprite = FlxGridOverlay.create(20, 20);
		add(bg);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, songs[i], true, false);
			add(songText);
			songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}

		FlxG.sound.playMusic('assets/music/title' + TitleState.soundExt, 0);
		FlxG.sound.music.fadeIn(2, 0, 0.8);
		selector = new FlxText();

		selector.size = 40;
		selector.text = ">";
		add(selector);

		var swag:Alphabet = new Alphabet(1, 0, "swag");

		super.create();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;

		if (upP)
		{
			curSelected -= 1;
		}
		if (downP)
		{
			curSelected += 1;
		}

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		selector.y = (70 * curSelected) + 30;

		if (accepted)
		{
			PlayState.SONG = Song.loadFromJson(songs[curSelected].toLowerCase());
			FlxG.switchState(new PlayState());
		}
	}
}
