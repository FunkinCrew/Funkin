package funkin.ui.debug;

import flixel.math.FlxRect;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.audio.waveform.WaveformData;
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

  // var waveformSprite:WaveformSprite;
  // var waveformSprite2:WaveformSprite;
  var timeMarker:FlxSprite;

  var polygonSprite:MeshRender;
  var vertexCount:Int = 3;

  public override function create():Void
  {
    super.create();

    var testSprite = new FlxSprite(0, 0);
    testSprite.loadGraphic(Paths.image('funkay'));
    testSprite.updateHitbox();
    testSprite.clipRect = new FlxRect(0, 0, FlxG.width, FlxG.height);
    // add(testSprite);

    waveformAudio = FunkinSound.load(Paths.inst('bopeebo', '-erect'));

    waveformData = WaveformDataParser.interpretFlxSound(waveformAudio);

    polygonSprite = new MeshRender(FlxG.width / 2, FlxG.height / 2, FlxColor.WHITE);

    setPolygonVertices(vertexCount);
    add(polygonSprite);

    // waveformSprite = WaveformSprite.buildFromWaveformData(waveformData, HORIZONTAL, FlxColor.fromString("#ADD8E6"));
    // waveformSprite.duration = 5.0 * 160;
    // waveformSprite.width = FlxG.width * 160;
    // waveformSprite.height = FlxG.height; // / 2;
    // waveformSprite.amplitude = 2.0;
    // waveformSprite.minWaveformSize = 25;
    // waveformSprite.clipRect = new FlxRect(0, 0, FlxG.width, FlxG.height);
    // add(waveformSprite);
    //
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
      // if (waveformSprite.orientation == HORIZONTAL)
      // {
      //   // waveformSprite.orientation = VERTICAL;
      //   // waveformSprite2.orientation = VERTICAL;
      // }
      // else
      // {
      //   // waveformSprite.orientation = HORIZONTAL;
      //   // waveformSprite2.orientation = HORIZONTAL;
      // }
    }

    if (waveformAudio.isPlaying)
    {
      // waveformSprite takes a time in fractional seconds, not milliseconds.
      var timeSeconds = waveformAudio.time / 1000;
      // waveformSprite.time = timeSeconds;
      // waveformSprite2.time = timeSeconds;
    }

    if (FlxG.keys.justPressed.UP)
    {
      vertexCount += 1;
      setPolygonVertices(vertexCount);
      // waveformSprite.duration += 1.0;
      // waveformSprite2.duration += 1.0;
    }
    if (FlxG.keys.justPressed.DOWN)
    {
      vertexCount -= 1;
      setPolygonVertices(vertexCount);
      // waveformSprite.duration -= 1.0;
      // waveformSprite2.duration -= 1.0;
    }
    if (FlxG.keys.justPressed.LEFT)
    {
      // waveformSprite.time -= 1.0;
      // waveformSprite2.time -= 1.0;
    }
    if (FlxG.keys.justPressed.RIGHT)
    {
      // waveformSprite.time += 1.0;
      // waveformSprite2.time += 1.0;
    }
  }

  function setPolygonVertices(count:Int)
  {
    polygonSprite.clear();

    var size = 100.0;

    // Build a polygon with count vertices.

    var vertices:Array<Array<Float>> = [];

    var angle = 0.0;

    for (i in 0...count)
    {
      var x = Math.cos(angle) * size;
      var y = Math.sin(angle) * size;

      vertices.push([x, y]);

      angle += 2 * Math.PI / count;
    }

    trace('vertices: ${vertices}');

    var centerVertex = polygonSprite.build_vertex(0, 0);
    var firstVertex = -1;
    var lastVertex = -1;

    for (vertex in vertices)
    {
      var x = vertex[0];
      var y = vertex[1];

      var newVertex = polygonSprite.build_vertex(x, y);

      if (firstVertex == -1)
      {
        firstVertex = newVertex;
      }

      if (lastVertex != -1)
      {
        polygonSprite.add_tri(centerVertex, lastVertex, newVertex);
      }

      lastVertex = newVertex;
    }

    polygonSprite.add_tri(centerVertex, lastVertex, firstVertex);
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
