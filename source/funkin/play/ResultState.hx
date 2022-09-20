package funkin.play;

import flixel.FlxSprite;
import flixel.text.FlxText;

class ResultState extends MusicBeatSubstate
{
	var resultsVariation:ResultVariations;

	override function create()
	{
		if (Highscore.tallies.sick == Highscore.tallies.totalNotes && Highscore.tallies.maxCombo == Highscore.tallies.totalNotes)
			resultsVariation = PERFECT;
		else if (Highscore.tallies.missed + Highscore.tallies.bad + Highscore.tallies.shit >= Highscore.tallies.totalNotes * 0.50)
			resultsVariation = SHIT; // if more than half of your song was missed, bad, or shit notes, you get shit ending!
		else
			resultsVariation = NORMAL;

		FlxG.sound.playMusic(Paths.music("results" + resultsVariation));

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, 0xFF000000);
		bg.alpha = 0.8;
		bg.scrollFactor.set();
		add(bg);
		var results:FlxText = new FlxText(70, 70, 0, "RESULTS:", 32);

		results.text += "\nTOTAL NOTES: ";
		results.text += Highscore.tallies.totalNotes;
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

enum abstract ResultVariations(String)
{
	var PERFECT;
	var NORMAL;
	var SHIT;
}
