package funkin;

import funkin.SongLoad.SwagSong;
import funkin.play.song.Song.SongDifficulty;
import funkin.play.song.SongData.ConductorTimeChange;
import funkin.play.song.SongData.SongTimeChange;

typedef BPMChangeEvent =
{
	var stepTime:Int;
	var songTime:Float;
	var bpm:Float;
}

class Conductor
{
	/**
	 * The list of time changes in the song.
	 * There should be at least one time change (at the beginning of the song) to define the BPM.
	 */
	private static var timeChanges:Array<ConductorTimeChange> = [];

	/**
	 * The current time change.
	 */
	private static var currentTimeChange:ConductorTimeChange;

	/**
	 * The current position in the song in milliseconds.
	 * Updated every frame based on the audio position.
	 */
	public static var songPosition:Float;

	/**
	 * Beats per minute of the current song at the current time.
	 */
	public static var bpm(get, null):Float = 100;

	static function get_bpm():Float
	{
		if (currentTimeChange == null)
			return 100;

		return currentTimeChange.bpm;
	}

	// OLD, replaced with timeChanges.
	public static var bpmChangeMap:Array<BPMChangeEvent> = [];

	/**
	 * Duration of a beat in millisecond. Calculated based on bpm.
	 */
	public static var crochet(get, null):Float;

	static function get_crochet():Float
	{
		return ((60 / bpm) * 1000);
	}

	/**
	 * Duration of a step in milliseconds. Calculated based on bpm.
	 */
	public static var stepCrochet(get, null):Float;

	static function get_stepCrochet():Float
	{
		return crochet / 4;
	}

	public static var currentBeat(get, null):Float;

	static function get_currentBeat():Float
	{
		return currentBeat;
	}

	public static var currentStep(get, null):Int;

	static function get_currentStep():Int
	{
		return currentStep;
	}

	public static var lastSongPos:Float;
	public static var visualOffset:Float = 0;
	public static var audioOffset:Float = 0;
	public static var offset:Float = 0;

	public function new()
	{
	}

	public static function getLastBPMChange()
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];

			if (Conductor.songPosition < Conductor.bpmChangeMap[i].songTime)
				break;
		}
		return lastChange;
	}

	public static function forceBPM(bpm:Float)
	{
		// TODO: Get rid of this and use song metadata instead.
		Conductor.bpm = bpm;
	}

	/**
	 * Update the conductor with the current song position.
	 * BPM, current step, etc. will be re-calculated based on the song position.
	 */
	public static function update(songPosition:Float)
	{
		Conductor.songPosition = songPosition;
		Conductor.bpm = Conductor.getLastBPMChange().bpm;
	}

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

	public static function mapTimeChanges(currentChart:SongDifficulty)
	{
		var songTimeChanges:Array<SongTimeChange> = currentChart.timeChanges;

		timeChanges = [];

		for (songTimeChange in timeChanges)
		{
			var prevTimeChange:ConductorTimeChange = timeChanges.length == 0 ? null : timeChanges[timeChanges.length - 1];
			var currentTimeChange:ConductorTimeChange = cast songTimeChange;

			if (prevTimeChange != null)
			{
				var deltaTime:Float = currentTimeChange.timeStamp - prevTimeChange.timeStamp;
				var deltaSteps:Int = Math.round(deltaTime / (60 / prevTimeChange.bpm) * 1000 / 4);

				currentTimeChange.stepTime = prevTimeChange.stepTime + deltaSteps;
			}
			else
			{
				// We know the time and steps of this time change is 0, since this is the first time change.
				currentTimeChange.stepTime = 0;
			}

			timeChanges.push(currentTimeChange);
		}

		// Done.
	}
}
