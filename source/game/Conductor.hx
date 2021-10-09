package game;

import flixel.math.FlxMath;
import flixel.FlxG;
import states.PlayState;
import game.Song.SwagSong;

/**
 * ...
 * @author
 */

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	public static var bpm:Float = 100;
	public static var crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var stepCrochet:Float = crochet / 4; // steps in milliseconds
	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var offset:Float = 0;

	public static var safeFrames:Int = 10;
	public static var safeZoneOffset:Float = Math.floor((safeFrames / 60) * 1000); // is calculated in create(), is safeFrames in milliseconds

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public static var timeScale:Array<Int> = [4, 4];

	public static var nonmultilmao_crochet:Float = ((60 / bpm) * 1000); // beats in milliseconds
	public static var nonmultilmao_stepCrochet:Float = nonmultilmao_crochet / 4; // steps in milliseconds

	public function new()
	{
	}

	public static function recalculateStuff(?multi:Float = 1)
	{
		safeZoneOffset = Math.floor((safeFrames / 60) * 1000);

		crochet = ((60 / bpm) * 1000) / multi;
		stepCrochet = crochet / (16 / timeScale[1]);

		if(multi != 1)
		{
			nonmultilmao_crochet = ((60 / (bpm / multi)) * 1000);
			nonmultilmao_stepCrochet = nonmultilmao_crochet / (16 / timeScale[1]);
		}
		else
		{
			nonmultilmao_crochet = crochet;
			nonmultilmao_stepCrochet = stepCrochet;
		}
	}

	public static function mapBPMChanges(song:SwagSong, ?songMultiplier:Float = 1.0)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		
		for (i in 0...song.notes.length)
		{
			if(song.notes[i].changeBPM && song.notes[i].bpm != curBPM)
			{
				curBPM = song.notes[i].bpm;

				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM * songMultiplier
				};

				trace(totalPos);

				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;

			totalPos += FlxMath.roundDecimal(((60 / curBPM) * 1000 / 4) * deltaSteps, 4);
		}

		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function changeBPM(newBpm:Float, ?multi:Float = 1)
	{
		bpm = newBpm;

		recalculateStuff(multi);
	}
}
