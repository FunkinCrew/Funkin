package play;

import flixel.FlxSprite;

class PicoFight extends MusicBeatState
{
	var picoHealth:Float = 1;
	var darnellHealth:Float = 1;

	override function create()
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height);
		bg.scrollFactor.set();
		add(bg);

		// fuk u, hardcoded bullshit bitch
		FlxG.sound.playMusic(Paths.inst("blazin"));
		Conductor.bpm = 180;

		super.create();
	}

	override function update(elapsed:Float)
	{
		Conductor.songPosition = FlxG.sound.music.time;

		super.update(elapsed);
	}

	override function beatHit()
	{
		picoHealth += 1;
		trace(picoHealth);
		super.beatHit();
	}
}
