package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.FlxStrip;
import flixel.util.FlxColor;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.media.vorbis.VorbisFile;
import openfl.geom.Rectangle;
import openfl.media.Sound;
#if cpp
import sys.thread.Thread;
#end

class WaveformTestState extends FlxState
{
	var waveform:Waveform;

	override public function create()
	{
		super.create();

		// fuckin stupid ass bitch ass fucking waveform
		if (PlayState.isSM)
		{
      #if desktop
			waveform = new Waveform(0, 0, PlayState.pathToSm + "/" + PlayState.sm.header.MUSIC, 720);
      #end
		}
		else
		{
			if (PlayState.SONG.needsVoices)
				waveform = new Waveform(0, 0, Paths.voices(PlayState.SONG.song), 720);
			else
				waveform = new Waveform(0, 0, Paths.inst(PlayState.SONG.song), 720);
		}
		waveform.drawWaveform();
		add(waveform);
	}

	override public function update(elapsed:Float)
	{
		super.update(elapsed);

        if (FlxG.keys.pressed.W)
            FlxG.camera.y += 1;
        if (FlxG.keys.pressed.S)
            FlxG.camera.y -= 1;
        if (FlxG.keys.pressed.A)
            FlxG.camera.x += 1;
        if (FlxG.keys.pressed.D)
            FlxG.camera.x -= 1;
	}
}
