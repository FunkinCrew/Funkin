package;

import Song.SwagSong;
import flixel.FlxG;

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
	public static var timeScale:Float = Conductor.safeZoneOffset / 166;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new()
	{
	}

	public static function recalculateTimings()
	{
		Conductor.safeFrames = FlxG.save.data.frames;
		Conductor.safeZoneOffset = Math.floor((Conductor.safeFrames / 60) * 1000);
		Conductor.timeScale = Conductor.safeZoneOffset / 166;
	}

	public static function mapBPMChanges(song:SwagSong)
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
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = song.notes[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}

	public static function recalculateTimingStruct(SONG:Song)
	{
		for(i in SONG.eventObjects)
		{
			/*TimingStruct.addTiming(beat,bpm,endBeat, Std.parseFloat(OFFSET));

            if (changeEvents.length != 0)
            {
                var data = TimingStruct.AllTimings[currentIndex - 1];
                data.endBeat = beat;
                data.length = (data.endBeat - data.startBeat) / (data.bpm / 60);
                TimingStruct.AllTimings[currentIndex].startTime = data.startTime + data.length;
            }*/
		}
	}

	public static function changeBPM(newBpm:Float, ?recalcLength = true)
	{
		bpm = newBpm;

		crochet = ((60 / bpm) * 1000);
		stepCrochet = crochet / 4;
	}
}