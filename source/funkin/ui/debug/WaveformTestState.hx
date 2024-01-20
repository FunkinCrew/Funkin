package funkin.ui.debug;

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

  var waveformAudio:FunkinSound;

  var meshRender:MeshRender;

  var timeMarker:FlxSprite;

  public override function create():Void
  {
    super.create();

    waveformData = WaveformDataParser.parseWaveformData(Paths.json("waveform/dadbattle-erect/dadbattle-erect.waveform"));

    waveformAudio = FunkinSound.load(Paths.music('dadbattle-erect/dadbattle-erect'));

    var lightBlue:FlxColor = FlxColor.fromString("#ADD8E6");
    meshRender = new MeshRender(0, 0, lightBlue);
    add(meshRender);

    timeMarker = new FlxSprite(0, FlxG.height * 1 / 6);
    timeMarker.makeGraphic(1, Std.int(FlxG.height * 2 / 3), FlxColor.RED);
    add(timeMarker);

    drawWaveform(time, duration);
  }

  /**
   * @param offsetX Horizontal offset to draw the waveform at, in samples.
   */
  function drawWaveform(timeSeconds:Float, duration:Float):Void
  {
    meshRender.clear();

    var offsetX:Int = waveformData.secondsToIndex(timeSeconds);

    var waveformHeight:Int = Std.int(FlxG.height * (2 / 3));
    var waveformWidth:Int = FlxG.width;
    var waveformCenterPos:Int = Std.int(FlxG.height / 2);

    var oneSecondInIndices:Int = waveformData.secondsToIndex(1);

    var startTime:Float = -1.0;
    var endTime:Float = startTime + duration;

    var startIndex:Int = Std.int(offsetX + (oneSecondInIndices * startTime));
    var endIndex:Int = Std.int(offsetX + (oneSecondInIndices * (startTime + duration)));

    var pixelsPerIndex:Float = waveformWidth / (endIndex - startIndex);
    var indexesPerPixel:Float = (endIndex - startIndex) / waveformWidth;

    if (pixelsPerIndex >= 1.0)
    {
      // Each index is at least one pixel wide, so we render each index.
      var prevVertexTopIndex:Int = -1;
      var prevVertexBottomIndex:Int = -1;
      for (i in startIndex...endIndex)
      {
        var pixelPos:Int = Std.int((i - startIndex) * pixelsPerIndex);

        var vertexTopY:Int = Std.int(waveformCenterPos - (waveformData.channel(0).maxSampleMapped(i) * waveformHeight / 2));
        var vertexBottomY:Int = Std.int(waveformCenterPos + (-waveformData.channel(0).minSampleMapped(i) * waveformHeight / 2));

        var vertexTopIndex:Int = meshRender.build_vertex(pixelPos, vertexTopY);
        var vertexBottomIndex:Int = meshRender.build_vertex(pixelPos, vertexBottomY);

        if (prevVertexTopIndex != -1 && prevVertexBottomIndex != -1)
        {
          meshRender.add_quad(prevVertexTopIndex, vertexTopIndex, vertexBottomIndex, prevVertexBottomIndex);
        }
        else
        {
          trace('Skipping quad at index ${i}');
        }

        prevVertexTopIndex = vertexTopIndex;
        prevVertexBottomIndex = vertexBottomIndex;
      }
    }
    else
    {
      // Indexes are less than one pixel wide, so for each pixel we render the maximum of the samples that fall within it.
      var prevVertexTopIndex:Int = -1;
      var prevVertexBottomIndex:Int = -1;
      for (i in 0...waveformWidth)
      {
        // Wrap Std.int around the whole range calculation, not just indexesPerPixel, otherwise you get weird issues with zooming.
        var rangeStart:Int = Std.int(i * indexesPerPixel + startIndex);
        var rangeEnd:Int = Std.int((i + 1) * indexesPerPixel + startIndex);

        var vertexTopY:Int = Std.int(waveformCenterPos - (waveformData.channel(0).maxSampleRangeMapped(rangeStart, rangeEnd) * waveformHeight / 2));
        var vertexBottomY:Int = Std.int(waveformCenterPos + (-waveformData.channel(0).minSampleRangeMapped(rangeStart, rangeEnd) * waveformHeight / 2));

        // trace('Drawing index ${rangeStart} at pixel ${i} with MAX ${vertexTopY} and MIN ${vertexBottomY}');

        var vertexTopIndex:Int = meshRender.build_vertex(i, vertexTopY);
        var vertexBottomIndex:Int = meshRender.build_vertex(i, vertexBottomY);

        if (prevVertexTopIndex != -1 && prevVertexBottomIndex != -1)
        {
          meshRender.add_quad(prevVertexTopIndex, vertexTopIndex, vertexBottomIndex, prevVertexBottomIndex);
        }
        else
        {
          trace('Skipping quad at index ${i}');
        }

        prevVertexTopIndex = vertexTopIndex;
        prevVertexBottomIndex = vertexBottomIndex;
      }
    }

    trace('Drawing ${duration} seconds of waveform with ${meshRender.vertex_count} vertices');

    var oneSecondInPixels:Float = waveformWidth / duration;

    timeMarker.x = Std.int(oneSecondInPixels);

    // For each sample in the waveform...
    // Add a MAX vertex and a MIN vertex.
    //   If previous MAX/MIN is empty, store.
    //   If previous MAX/MIN is not empty, draw a quad using current and previous MAX/MIN. Then store current MAX/MIN.
    // Continue until end of waveform.
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

    if (waveformAudio.isPlaying)
    {
      var songTimeSeconds:Float = waveformAudio.time / 1000;
      drawWaveform(songTimeSeconds, duration);
    }

    if (FlxG.keys.justPressed.UP)
    {
      trace('Zooming out');
      duration += 1.0;
      drawTheWaveform();
    }
    if (FlxG.keys.justPressed.DOWN)
    {
      trace('Zooming in');
      duration -= 1.0;
      drawTheWaveform();
    }
    if (FlxG.keys.justPressed.LEFT)
    {
      trace('Seeking back');
      time -= 1.0;
      drawTheWaveform();
    }
    if (FlxG.keys.justPressed.RIGHT)
    {
      trace('Seeking forward');
      time += 1.0;
      drawTheWaveform();
    }
  }

  var time:Float = 0.0;
  var duration:Float = 5.0;

  function drawTheWaveform():Void
  {
    drawWaveform(time, duration);
  }

  public override function destroy():Void
  {
    super.destroy();
  }
}
