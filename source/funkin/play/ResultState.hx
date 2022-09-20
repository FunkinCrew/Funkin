package funkin.play;

import flixel.FlxSprite;
import flixel.text.FlxText;

class ResultState extends MusicBeatSubstate
{
	override function create()
	{
		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.scrollFactor.set();
		add(bg);
		var results:FlxText = new FlxText(0, 0, 0, "RESULTS:", 32);

		results.text += "\nMISSED: ";
		results.text += Highscore.tallies.missed;
		results.text += "\nSHIT: ";
		results.text += Highscore.tallies.shit;
		results.text += "\nBAD: ";
		results.text += Highscore.tallies.bad;
		results.text += "\nGOOD: ";
		results.text += Highscore.tallies.good;
		results.text += "\nSICK: ";
		results.text += Highscore.tallies.sick;
		results.text += "\nMAX COMBO: ";
		results.text += Highscore.tallies.maxCombo;
		add(results);
		results.scrollFactor.set();

		super.create();
	}

	override function update(elapsed:Float)
	{
		if (controls.PAUSE)
			FlxG.switchState(new FreeplayState());

		super.update(elapsed);
	}
}
