package funkin.audio.waveform;

import funkin.audio.waveform.WaveformData;
import funkin.audio.waveform.WaveformDataParser;
import funkin.graphics.rendering.MeshRender;
import flixel.util.FlxColor;

class WaveformSprite extends MeshRender
{
  static final DEFAULT_COLOR:FlxColor = FlxColor.WHITE;
  static final DEFAULT_DURATION:Float = 5.0;
  static final DEFAULT_ORIENTATION:WaveformOrientation = HORIZONTAL;
  static final DEFAULT_X:Float = 0.0;
  static final DEFAULT_Y:Float = 0.0;
  static final DEFAULT_WIDTH:Float = 100.0;
  static final DEFAULT_HEIGHT:Float = 100.0;

  /**
   * Set this to true to tell the waveform to rebuild itself.
   * Do this any time the data or drawable area of the waveform changes.
   * This often (but not always) needs to be done every frame.
   */
  var isWaveformDirty:Bool = true;

  public var waveformData:WaveformData;

  function set_waveformData(value:WaveformData):WaveformData
  {
    waveformData = value;
    isWaveformDirty = true;
    return waveformData;
  }

  /**
   * The color to render the waveform with.
   */
  public var waveformColor(default, set):FlxColor;

  function set_waveformColor(value:FlxColor):FlxColor
  {
    waveformColor = value;
    // We don't need to dirty the waveform geometry, just rebuild the texture.
    rebuildGraphic();
    return waveformColor;
  }

  public var orientation(default, set):WaveformOrientation;

  function set_orientation(value:WaveformOrientation):WaveformOrientation
  {
    orientation = value;
    isWaveformDirty = true;
    return orientation;
  }

  /**
   * Time, in seconds, at which the waveform starts.
   */
  public var time(default, set):Float;

  function set_time(value:Float)
  {
    time = value;
    isWaveformDirty = true;
    return time;
  }

  /**
   * The duration, in seconds, that the waveform represents.
   * The section of waveform from `time` to `time + duration` and `width` are used to determine how many samples each pixel represents.
   */
  public var duration(default, set):Float;

  function set_duration(value:Float)
  {
    duration = value;
    isWaveformDirty = true;
    return duration;
  }

  /**
   * Set the physical size of the waveform with `this.height = value`.
   */
  override function set_height(value:Float):Float
  {
    isWaveformDirty = true;
    return super.set_height(value);
  }

  /**
   * Set the physical size of the waveform with `this.width = value`.
   */
  override function set_width(value:Float):Float
  {
    isWaveformDirty = true;
    return super.set_width(value);
  }

  public function new(waveformData:WaveformData, ?orientation:WaveformOrientation, ?color:FlxColor, ?duration:Float)
  {
    super(DEFAULT_X, DEFAULT_Y, DEFAULT_COLOR);
    this.waveformColor = color ?? DEFAULT_COLOR;
    this.width = DEFAULT_WIDTH;
    this.height = DEFAULT_HEIGHT;

    this.waveformData = waveformData;
    this.orientation = orientation;
    this.time = 0.0;
    this.duration = duration;
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (isWaveformDirty)
    {
      // Recalculate the waveform vertices.
      drawWaveform();
      isWaveformDirty = false;
    }
  }

  function rebuildGraphic():Void
  {
    // The waveform is rendered using a single colored pixel as a texture.
    // If you want something more elaborate, make sure to modify `build_vertex` below to use the UVs you want.
    makeGraphic(1, 1, this.waveformColor);
  }

  /**
   * @param offsetX Horizontal offset to draw the waveform at, in samples.
   */
  function drawWaveform():Void
  {
    // For each sample in the waveform...
    // Add a MAX vertex and a MIN vertex.
    //   If previous MAX/MIN is empty, store.
    //   If previous MAX/MIN is not empty, draw a quad using current and previous MAX/MIN. Then store current MAX/MIN.
    // Continue until end of waveform.

    this.clear();

    // Center point of the waveform. When horizontal this is half the height, when vertical this is half the width.
    var waveformCenterPos:Int = orientation == HORIZONTAL ? Std.int(this.height / 2) : Std.int(this.width / 2);

    var oneSecondInIndices:Int = waveformData.secondsToIndex(1);

    var startTime:Float = time;
    var endTime:Float = time + duration;

    var startIndex:Int = waveformData.secondsToIndex(startTime);
    var endIndex:Int = waveformData.secondsToIndex(endTime);

    var pixelsPerIndex:Float = (orientation == HORIZONTAL ? this.width : this.height) / (endIndex - startIndex);
    var indexesPerPixel:Float = 1 / pixelsPerIndex;

    if (pixelsPerIndex >= 1.0)
    {
      // Each index is at least one pixel wide, so we render each index.
      var prevVertexTopIndex:Int = -1;
      var prevVertexBottomIndex:Int = -1;
      for (i in startIndex...endIndex)
      {
        var pixelPos:Int = Std.int((i - startIndex) * pixelsPerIndex);

        var vertexTopY:Int = Std.int(waveformCenterPos
          - (waveformData.channel(0).maxSampleMapped(i) * (orientation == HORIZONTAL ? this.height : this.width) / 2));
        var vertexBottomY:Int = Std.int(waveformCenterPos
          + (-waveformData.channel(0).minSampleMapped(i) * (orientation == HORIZONTAL ? this.height : this.width) / 2));

        var vertexTopIndex:Int = (orientation == HORIZONTAL) ? this.build_vertex(pixelPos, vertexTopY) : this.build_vertex(vertexTopY, pixelPos);
        var vertexBottomIndex:Int = (orientation == HORIZONTAL) ? this.build_vertex(pixelPos, vertexBottomY) : this.build_vertex(vertexBottomY, pixelPos);

        if (prevVertexTopIndex != -1 && prevVertexBottomIndex != -1)
        {
          switch (orientation) // the line of code that makes you gay
          {
            case HORIZONTAL:
              this.add_quad(prevVertexTopIndex, vertexTopIndex, vertexBottomIndex, prevVertexBottomIndex);
            case VERTICAL:
              this.add_quad(prevVertexBottomIndex, prevVertexTopIndex, vertexTopIndex, vertexBottomIndex);
          }
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
      var waveformLengthPixels:Int = orientation == HORIZONTAL ? Std.int(this.width) : Std.int(this.height);
      for (i in 0...waveformLengthPixels)
      {
        // Wrap Std.int around the whole range calculation, not just indexesPerPixel, otherwise you get weird issues with zooming.
        var rangeStart:Int = Std.int(i * indexesPerPixel + startIndex);
        var rangeEnd:Int = Std.int((i + 1) * indexesPerPixel + startIndex);

        var vertexTopY:Int = Std.int(waveformCenterPos
          - (waveformData.channel(0).maxSampleRangeMapped(rangeStart, rangeEnd) * (orientation == HORIZONTAL ? this.height : this.width) / 2));
        var vertexBottomY:Int = Std.int(waveformCenterPos
          + (-waveformData.channel(0).minSampleRangeMapped(rangeStart, rangeEnd) * (orientation == HORIZONTAL ? this.height : this.width) / 2));

        var vertexTopIndex:Int = (orientation == HORIZONTAL) ? this.build_vertex(i, vertexTopY) : this.build_vertex(vertexTopY, i);
        var vertexBottomIndex:Int = (orientation == HORIZONTAL) ? this.build_vertex(i, vertexBottomY) : this.build_vertex(vertexBottomY, i);

        if (prevVertexTopIndex != -1 && prevVertexBottomIndex != -1)
        {
          switch (orientation)
          {
            case HORIZONTAL:
              this.add_quad(prevVertexTopIndex, vertexTopIndex, vertexBottomIndex, prevVertexBottomIndex);
            case VERTICAL:
              this.add_quad(prevVertexBottomIndex, prevVertexTopIndex, vertexTopIndex, vertexBottomIndex);
          }
        }
        prevVertexTopIndex = vertexTopIndex;
        prevVertexBottomIndex = vertexBottomIndex;
      }
    }
  }

  public static function buildFromWaveformData(data:WaveformData, ?orientation:WaveformOrientation, ?color:FlxColor, ?duration:Float)
  {
    return new WaveformSprite(data, orientation, duration);
  }

  public static function buildFromFunkinSound(sound:FunkinSound, ?orientation:WaveformOrientation, ?color:FlxColor, ?duration:Float)
  {
    // TODO: Build waveform data from FunkinSound.
    var data = null;

    return buildFromWaveformData(data, orientation, color, duration);
  }
}

enum WaveformOrientation
{
  HORIZONTAL;
  VERTICAL;
}
