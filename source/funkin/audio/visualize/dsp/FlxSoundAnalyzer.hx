package funkin.audio.visualize.dsp;

import funkin.audio.FunkinSound;
import funkin.vis._internal.html5.AnalyzerNode;
import funkin.audio.visualize.audioclip.frontends.FlxAudioClip;
import funkin.vis.dsp.SpectralAnalyzer;
import flixel.sound.FlxSound;

class FlxSoundAnalyzer extends SpectralAnalyzer
{
  public var snd(default, set):FlxSound;

  public function new(snd:FlxSound, barCount:Int, maxDelta:Float = 0.01, peakHold:Int = 30)
  {
    // reloadChannel(snd);
    var isPlaying = snd.playing;
    var daTime = snd.time;
    snd.play(false);

    // If only I could get rid of the super
    @:privateAccess
    super(snd._channel.__audioSource, barCount, maxDelta, peakHold);
    if (!isPlaying)
    {
      snd.pause();
      snd.time = daTime;
    }

    this.snd = snd;

    #if desktop
    // On desktop it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
    // So we want to manually change it!
    fftN = 256;
    #end
  }

  override public function getLevels(?levels:Array<Bar>):Array<Bar>
  {
    if (levels == null) levels = new Array<Bar>();
    @:privateAccess
    if (snd?.time == 0 && snd?._channel == null)
    {
      levels.resize(barCount);
      for (i in 0...barCount)
      {
        var value = 0;
        var recentPeak = 1;

        if (levels[i] != null)
        {
          levels[i].value = value;
          levels[i].peak = recentPeak;
        }
        else
          levels[i] = {value: value, peak: recentPeak};
      }
      return levels;
    }
    super.getLevels(levels);
    return levels;
  }

  function set_snd(sndValue:FlxSound):FlxSound
  {
    this.snd = sndValue;
    var isPlaying = sndValue.playing;
    var daTime = sndValue.time;

    sndValue.play(false);

    @:privateAccess
    this.audioSource = sndValue._channel.__audioSource;
    @:privateAccess
    this.audioClip = new FlxAudioClip(sndValue);
    #if web
    htmlAnalyzer = new AnalyzerNode(this.audioClip);
    #end

    calcBars(barCount, peakHold);
    resizeBlackmanWindow(fftN);
    if (!isPlaying)
    {
      sndValue.pause();
      sndValue.time = daTime;
    }

    return sndValue;
  }
}
