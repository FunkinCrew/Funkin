package funkin;

import funkin.SongLoad.SwagSong;

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
	/**
	 * Beats per minute of the song.
	 */
	public static var bpm:Float = 100;

	/**
	 * Duration of a beat in millisecond.
	 */
	public static var crochet(get, null):Float;

	static function get_crochet():Float
	{
		return ((60 / bpm) * 1000);
	}

	/**
	 * Duration of a step in milliseconds.
	 */
	public static var stepCrochet(get, null):Float;

	static function get_stepCrochet():Float
	{
		return crochet / 4;
	}

	public static var songPosition:Float;
	public static var lastSongPos:Float;
	public static var visualOffset:Float = 0;
	public static var audioOffset:Float = 0;
	public static var offset:Float = 0;

	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	public function new() {}

	public static function mapBPMChanges(song:SwagSong)
	{
		bpmChangeMap = [];

		var curBPM:Float = song.bpm;
		var totalSteps:Int = 0;
		var totalPos:Float = 0;
		for (i in 0...SongLoad.getSong().length)
		{
			if (SongLoad.getSong()[i].changeBPM && SongLoad.getSong()[i].bpm != curBPM)
			{
				curBPM = SongLoad.getSong()[i].bpm;
				var event:BPMChangeEvent = {
					stepTime: totalSteps,
					songTime: totalPos,
					bpm: curBPM
				};
				bpmChangeMap.push(event);
			}

			var deltaSteps:Int = SongLoad.getSong()[i].lengthInSteps;
			totalSteps += deltaSteps;
			totalPos += ((60 / curBPM) * 1000 / 4) * deltaSteps;
		}
		trace("new BPM map BUDDY " + bpmChangeMap);
	}
}
