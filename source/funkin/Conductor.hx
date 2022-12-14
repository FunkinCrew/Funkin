package funkin;

import flixel.util.FlxSignal;
import funkin.SongLoad.SwagSong;
import funkin.play.song.Song.SongDifficulty;
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
	private static var timeChanges:Array<SongTimeChange> = [];

	/**
	 * The current time change.
	 */
	private static var currentTimeChange:SongTimeChange;

	/**
	 * The current position in the song in milliseconds.
	 * Updated every frame based on the audio position.
	 */
	public static var songPosition:Float;

	/**
	 * Beats per minute of the current song at the current time.
	 */
	public static var bpm(get, null):Float;

	static function get_bpm():Float
	{
		if (bpmOverride != null)
			return bpmOverride;

		if (currentTimeChange == null)
			return 100;

		return currentTimeChange.bpm;
	}

	static var bpmOverride:Null<Float> = null;

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
	 * Duration of a step (quarter) in milliseconds. Calculated based on bpm.
	 */
	public static var stepCrochet(get, null):Float;

	static function get_stepCrochet():Float
	{
		return crochet / timeSignatureNumerator;
	}

	public static var timeSignatureNumerator(get, null):Int;

	static function get_timeSignatureNumerator():Int
	{
		if (currentTimeChange == null)
			return 4;

		return currentTimeChange.timeSignatureNum;
	}

	public static var timeSignatureDenominator(get, null):Int;

	static function get_timeSignatureDenominator():Int
	{
		if (currentTimeChange == null)
			return 4;

		return currentTimeChange.timeSignatureDen;
	}

	/**
	 * Current position in the song, in beats.
	**/
	public static var currentBeat(default, null):Int;

	/**
	 * Current position in the song, in steps.
	 */
	public static var currentStep(default, null):Int;

	/**
	 * Current position in the song, in steps and fractions of a step.
	 */
	public static var currentStepTime(default, null):Float;

	public static var beatHit(default, null):FlxSignal = new FlxSignal();
	public static var stepHit(default, null):FlxSignal = new FlxSignal();

	public static var lastSongPos:Float;
	public static var visualOffset:Float = 0;
	public static var audioOffset:Float = 0;
	public static var offset:Float = 0;

	// TODO: Add code to update this.
	public static var beatsPerMeasure:Int = 4;

	private function new()
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

	/**
	 * Forcibly defines the current BPM of the song.
	 * Useful for things like the chart editor that need to manipulate BPM in real time.
	 * 
	 * Set to null to reset to the BPM defined by the timeChanges.
	 * 
	 * WARNING: Avoid this for things like setting the BPM of the title screen music,
	 * you should have a metadata file for it instead.
	 */
	public static function forceBPM(?bpm:Float = null)
	{
		trace('[CONDUCTOR] Forcing BPM to ' + bpm);
		Conductor.bpmOverride = bpm;
	}

	/**
	 * Update the conductor with the current song position.
	 * BPM, current step, etc. will be re-calculated based on the song position.
	 * 
	 * @param	songPosition The current position in the song in milliseconds.
	 *        Leave blank to use the FlxG.sound.music position.
	 */
	public static function update(songPosition:Float = null)
	{
		if (songPosition == null)
			songPosition = (FlxG.sound.music != null) ? (FlxG.sound.music.time + Conductor.offset) : 0;

		var oldBeat = currentBeat;
		var oldStep = currentStep;

		Conductor.songPosition = songPosition;
		// Conductor.bpm = Conductor.getLastBPMChange().bpm;

		currentTimeChange = timeChanges[0];
		for (i in 0...timeChanges.length)
		{
			if (songPosition >= timeChanges[i].timeStamp)
				currentTimeChange = timeChanges[i];

			if (songPosition < timeChanges[i].timeStamp)
				break;
		}

		if (currentTimeChange == null && bpmOverride == null)
		{
			trace('WARNING: Conductor is broken, timeChanges is empty.');
		}
		else if (currentTimeChange != null)
		{
			currentStepTime = (currentTimeChange.beatTime * 4) + (songPosition - currentTimeChange.timeStamp) / stepCrochet;
			currentStep = Math.floor(currentStepTime);
			currentBeat = Math.floor(currentStep / 4);
		}
		else
		{
			// Assume a constant BPM equal to the forced value.
			currentStepTime = (songPosition / stepCrochet);
			currentStep = Math.floor(currentStepTime);
			currentBeat = Math.floor(currentStep / 4);
		}

		// FlxSignals are really cool.
		if (currentStep != oldStep)
			stepHit.dispatch();

		if (currentBeat != oldBeat)
			beatHit.dispatch();
	}

	@:deprecated // Switch to TimeChanges instead.
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
	}

	public static function mapTimeChanges(songTimeChanges:Array<SongTimeChange>)
	{
		timeChanges = [];

		for (currentTimeChange in songTimeChanges)
		{
			timeChanges.push(currentTimeChange);
		}

		trace('Done mapping time changes: ' + timeChanges);

		// Done.
	}

	/**
	 * Given a time in milliseconds, return a time in steps.
	 */
	public static function getTimeInSteps(ms:Float):Int
	{
		if (timeChanges.length == 0)
		{
			// Assume a constant BPM equal to the forced value.
			return Math.floor(ms / stepCrochet);
		}
		else
		{
			var resultStep:Int = 0;

			var lastTimeChange:SongTimeChange = timeChanges[0];
			for (timeChange in timeChanges)
			{
				if (ms >= timeChange.timeStamp)
				{
					lastTimeChange = timeChange;
					resultStep = lastTimeChange.beatTime * 4;
				}
				else
				{
					// This time change is after the requested time.
					break;
				}
			}

			resultStep += Math.floor((ms - lastTimeChange.timeStamp) / stepCrochet);

			return resultStep;
		}
	}
}
