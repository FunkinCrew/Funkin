package audiovis;

import audiovis.VisShit.CurAudioInfo;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.system.FlxSound;
import flixel.util.FlxColor;
import lime.utils.Int16Array;
import rendering.MeshRender;

class PolygonSpectogram extends MeshRender
{
	var sampleRate:Int;

	public var vis:VisShit;
	public var daHeight:Float = FlxG.height;

	var numSamples:Int = 0;
	var setBuffer:Bool = false;

	public var audioData:Int16Array;
	public var detail:Float = 1;

	public function new(daSound:FlxSound, ?col:FlxColor = FlxColor.WHITE, ?height:Float = 720, ?detail:Float = 1)
	{
		super(0, 0);

		vis = new VisShit(daSound);

		if (height != null)
			this.daHeight = height;

		this.detail = detail;

		// col not in yet
	}

	/**
	 * Generates and draws a section of the audio data to a visual waveform
	 * @param start start of the song in milliseconds
	 * @param seconds how long to generate (also in milliseconds)
	 */
	public function generateSection(start:Float = 0, seconds:Float = 1):Void
	{
		checkAndSetBuffer();

		if (setBuffer)
		{
			clear();

			var samplesToGen:Int = Std.int(sampleRate * seconds);
			// gets which sample to start at
			var startSample:Int = Std.int(FlxMath.remapToRange(start, 0, vis.snd.length, 0, numSamples));

			var prevPoint:FlxPoint = new FlxPoint();

			for (i in 0...500)
			{
				var sampleApprox:Int = Std.int(FlxMath.remapToRange(i, 0, 500, startSample, startSample + samplesToGen));
				var curAud:CurAudioInfo = VisShit.getCurAud(audioData, sampleApprox);

				var waveAmplitude:Int = 200;

				var coolPoint:FlxPoint = new FlxPoint();
				coolPoint.x = (curAud.balanced * waveAmplitude / 2 + waveAmplitude / 2);
				coolPoint.y = (i / 500 * daHeight);

				add_quad(prevPoint.x, prevPoint.y, prevPoint.x + 1, prevPoint.y, coolPoint.x, coolPoint.y, coolPoint.x + 1, coolPoint.y + 1);

				prevPoint.x = coolPoint.x;
				prevPoint.y = coolPoint.y;
			}
		}
	}

	public function checkAndSetBuffer()
	{
		vis.checkAndSetBuffer();

		if (vis.setBuffer)
		{
			audioData = vis.audioData;
			sampleRate = vis.sampleRate;
			setBuffer = vis.setBuffer;
			numSamples = Std.int(audioData.length / 2);
		}
	}
}
