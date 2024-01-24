package funkin.ui.debug;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformSprite;
import funkin.audio.waveform.WaveformDataParser;
import funkin.graphics.rendering.MeshRender;

class WaveformTestState extends MusicBeatState
{
  public function new()
  {
    super();
  }

  var waveformData:WaveformData;
  var waveformData2:WaveformData;

  var waveformAudio:FunkinSound;

  var waveformSprite:WaveformSprite;

  // var waveformSprite2:WaveformSprite;
  var timeMarker:FlxSprite;

  public override function create():Void
  {
    super.create();

    var testSprite = new FlxSprite(0, 0);
    testSprite.loadGraphic(Paths.image('funkay'));
    testSprite.updateHitbox();
    testSprite.clipRect = new FlxRect(0, 0, FlxG.width * 9 / 16, FlxG.height);
    add(testSprite);

    waveformAudio = FunkinSound.load(Paths.inst('bopeebo', '-erect'));

    // waveformData = WaveformDataParser.parseWaveformData(Paths.json('waveform/dadbattle-erect/dadbattle-erect.waveform'));
    waveformData = WaveformDataParser.interpretFlxSound(waveformAudio);

    waveformSprite = WaveformSprite.buildFromWaveformData(waveformData, HORIZONTAL, FlxColor.fromString("#ADD8E6"), 2.5);
    waveformSprite.width = FlxG.width;
    waveformSprite.height = FlxG.height; // / 2;
    waveformSprite.clipRect = new FlxRect(0, 0, FlxG.width * 9 / 16, FlxG.height);
    // waveformSprite.clipRect = new FlxRect(FlxG.width * 1 / 3, FlxG.height * 3 / 8, FlxG.width * 1 / 3, FlxG.height * 2 / 8);
    add(waveformSprite);

    // waveformSprite2 = WaveformSprite.buildFromWaveformData(waveformData2, HORIZONTAL, FlxColor.fromString("#FF0000"), 5.0);
    // waveformSprite2.width = FlxG.width;
    // waveformSprite2.height = FlxG.height / 2;
    // waveformSprite2.y = FlxG.height / 2;
    // add(waveformSprite2);

    timeMarker = new FlxSprite(0, FlxG.height * 1 / 6);
    timeMarker.makeGraphic(1, Std.int(FlxG.height * 2 / 3), FlxColor.RED);
    add(timeMarker);

    // drawWaveform(time, duration);
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.SPACE)
    {
      if (waveformAudio.isPlaying)
      {
        waveformAudio.stop();
      }
      else
      {
        waveformAudio.play();
      }
    }

    if (FlxG.keys.justPressed.ENTER)
    {
      if (waveformSprite.orientation == HORIZONTAL)
      {
        waveformSprite.orientation = VERTICAL;
        // waveformSprite2.orientation = VERTICAL;
      }
      else
      {
        waveformSprite.orientation = HORIZONTAL;
        // waveformSprite2.orientation = HORIZONTAL;
      }
    }

    if (waveformAudio.isPlaying)
    {
      // waveformSprite takes a time in fractional seconds, not milliseconds.
      var timeSeconds = waveformAudio.time / 1000;
      waveformSprite.time = timeSeconds;
      // waveformSprite2.time = timeSeconds;
    }

    if (FlxG.keys.justPressed.UP)
    {
      waveformSprite.duration += 1.0;
      // waveformSprite2.duration += 1.0;
    }
    if (FlxG.keys.justPressed.DOWN)
    {
      waveformSprite.duration -= 1.0;
      // waveformSprite2.duration -= 1.0;
    }
    if (FlxG.keys.justPressed.LEFT)
    {
      waveformSprite.time -= 1.0;
      // waveformSprite2.time -= 1.0;
    }
    if (FlxG.keys.justPressed.RIGHT)
    {
      waveformSprite.time += 1.0;
      // waveformSprite2.time += 1.0;
    }
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
