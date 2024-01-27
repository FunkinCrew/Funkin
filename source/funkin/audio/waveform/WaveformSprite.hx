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

  /**
   * If true, force the waveform to redraw every frame.
   * Useful if the waveform's clipRect is constantly changing.
   */
  public var forceUpdate:Bool = false;

  public var waveformData(default, set):Null<WaveformData>;

  function set_waveformData(value:Null<WaveformData>):Null<WaveformData>
  {
    if (waveformData == value) return value;

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
    if (waveformColor == value) return value;

    waveformColor = value;
    // We don't need to dirty the waveform geometry, just rebuild the texture.
    rebuildGraphic();
    return waveformColor;
  }

  public var orientation(default, set):WaveformOrientation;

  function set_orientation(value:WaveformOrientation):WaveformOrientation
  {
    if (orientation == value) return value;

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
    if (time == value) return value;

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
    if (duration == value) return value;

    duration = value;
    isWaveformDirty = true;
    return duration;
  }

  /**
   * Set the physical size of the waveform with `this.height = value`.
   */
  override function set_height(value:Float):Float
  {
    if (height == value) return super.set_height(value);

    isWaveformDirty = true;
    return super.set_height(value);
  }

  /**
   * Set the physical size of the waveform with `this.width = value`.
   */
  override function set_width(value:Float):Float
  {
    if (width == value) return super.set_width(value);

    isWaveformDirty = true;
    return super.set_width(value);
  }

  /**
   * The minimum size, in pixels, that a waveform will display with.
   * Useful for preventing the waveform from becoming too small to see.
   *
   * NOTE: This is technically doubled since it's applied above and below the center of the waveform.
   */
  public var minWaveformSize:Int = 1;

  /**
   * A multiplier on the size of the waveform.
   * Still capped at the width and height set for the sprite.
   */
  public var amplitude:Float = 1.0;

  public function new(?waveformData:WaveformData, ?orientation:WaveformOrientation, ?color:FlxColor, ?duration:Float)
  {
    super(DEFAULT_X, DEFAULT_Y, DEFAULT_COLOR);
    this.waveformColor = color ?? DEFAULT_COLOR;
    this.width = DEFAULT_WIDTH;
    this.height = DEFAULT_HEIGHT;

    this.waveformData = waveformData;
    this.orientation = orientation ?? DEFAULT_ORIENTATION;
    this.time = 0.0;
    this.duration = duration ?? DEFAULT_DURATION;

    this.forceUpdate = false;
  }

  /**
   * Manually tell the waveform to rebuild itself, even if none of its properties have changed.
   */
  public function markDirty():Void
  {
    isWaveformDirty = true;
  }

  public override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (forceUpdate || isWaveformDirty)
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

    if (waveformData == null) return;

    // Center point of the waveform. When horizontal this is half the height, when vertical this is half the width.
    var waveformCenterPos:Int = orientation == HORIZONTAL ? Std.int(this.height / 2) : Std.int(this.width / 2);

    var oneSecondInIndices:Int = waveformData.secondsToIndex(1);

    var startTime:Float = time;
    var endTime:Float = time + duration;

    var startIndex:Int = waveformData.secondsToIndex(startTime);
    var endIndex:Int = waveformData.secondsToIndex(endTime);

    var pixelsPerIndex:Float = (orientation == HORIZONTAL ? this.width : this.height) / (endIndex - startIndex);
    var indexesPerPixel:Float = 1 / pixelsPerIndex;

    var topLeftVertexIndex:Int = -1;
    var topRightVertexIndex:Int = -1;
    var bottomLeftVertexIndex:Int = -1;
    var bottomRightVertexIndex:Int = -1;

    if (clipRect != null)
    {
      topLeftVertexIndex = this.build_vertex(clipRect.x, clipRect.y);
      topRightVertexIndex = this.build_vertex(clipRect.x + clipRect.width, clipRect.y);
      bottomLeftVertexIndex = this.build_vertex(clipRect.x, clipRect.y + clipRect.height);
      bottomRightVertexIndex = this.build_vertex(clipRect.x + clipRect.width, clipRect.y + clipRect.height);
    }

    if (pixelsPerIndex >= 1.0)
    {
      // Each index is at least one pixel wide, so we render each index.
      var prevVertexTopIndex:Int = -1;
      var prevVertexBottomIndex:Int = -1;
      for (i in startIndex...endIndex)
      {
        var pixelPos:Int = Std.int((i - startIndex) * pixelsPerIndex);

        var isBeforeClipRect:Bool = (clipRect != null) && ((orientation == HORIZONTAL) ? pixelPos < clipRect.x : pixelPos < clipRect.y);

        if (isBeforeClipRect) continue;

        var isAfterClipRect:Bool = (clipRect != null)
          && ((orientation == HORIZONTAL) ? pixelPos > (clipRect.x + clipRect.width) : pixelPos > (clipRect.y + clipRect.height));

        if (isAfterClipRect)
        {
          break;
        };

        var sampleMax:Float = Math.min(waveformData.channel(0).maxSampleMapped(i) * amplitude, 1.0);
        var sampleMin:Float = Math.max(waveformData.channel(0).minSampleMapped(i) * amplitude, -1.0);
        var sampleMaxSize:Float = sampleMax * (orientation == HORIZONTAL ? this.height : this.width) / 2;
        if (sampleMaxSize < minWaveformSize) sampleMaxSize = minWaveformSize;
        var sampleMinSize:Float = sampleMin * (orientation == HORIZONTAL ? this.height : this.width) / 2;
        if (sampleMinSize > -minWaveformSize) sampleMinSize = -minWaveformSize;
        var vertexTopY:Int = Std.int(waveformCenterPos - sampleMaxSize);
        var vertexBottomY:Int = Std.int(waveformCenterPos - sampleMinSize);

        if (vertexBottomY - vertexTopY < minWaveformSize) vertexTopY = vertexBottomY - minWaveformSize;

        var vertexTopIndex:Int = -1;
        var vertexBottomIndex:Int = -1;

        if (clipRect != null)
        {
          if (orientation == HORIZONTAL)
          {
            vertexTopIndex = buildClippedVertex(pixelPos, vertexTopY, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex, bottomRightVertexIndex);
            vertexBottomIndex = buildClippedVertex(pixelPos, vertexBottomY, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex,
              bottomRightVertexIndex);
          }
          else
          {
            vertexTopIndex = buildClippedVertex(vertexTopY, pixelPos, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex, bottomRightVertexIndex);
            vertexBottomIndex = buildClippedVertex(vertexBottomY, pixelPos, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex,
              bottomRightVertexIndex);
          }
        }
        else
        {
          if (orientation == HORIZONTAL)
          {
            vertexTopIndex = this.build_vertex(pixelPos, vertexTopY);
            vertexBottomIndex = this.build_vertex(pixelPos, vertexBottomY);
          }
          else
          {
            vertexTopIndex = this.build_vertex(vertexTopY, pixelPos);
            vertexBottomIndex = this.build_vertex(vertexBottomY, pixelPos);
          }
        }

        // Don't render if we don't have a previous different set of vertices to create a quad from.
        if (prevVertexTopIndex != -1
          && prevVertexBottomIndex != -1
          && prevVertexTopIndex != vertexTopIndex
          && prevVertexBottomIndex != vertexBottomIndex)
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
        var pixelPos:Int = i;

        var isBeforeClipRect:Bool = (clipRect != null) && ((orientation == HORIZONTAL) ? pixelPos < clipRect.x : pixelPos < clipRect.y);

        if (isBeforeClipRect) continue;

        var isAfterClipRect:Bool = (clipRect != null)
          && ((orientation == HORIZONTAL) ? pixelPos > (clipRect.x + clipRect.width) : pixelPos > (clipRect.y + clipRect.height));

        if (isAfterClipRect)
        {
          break;
        };

        // Wrap Std.int around the whole range calculation, not just indexesPerPixel, otherwise you get weird issues with zooming.
        var rangeStart:Int = Std.int(i * indexesPerPixel + startIndex);
        var rangeEnd:Int = Std.int((i + 1) * indexesPerPixel + startIndex);

        var sampleMax:Float = Math.min(waveformData.channel(0).maxSampleRangeMapped(rangeStart, rangeEnd) * amplitude, 1.0);
        var sampleMin:Float = Math.max(waveformData.channel(0).minSampleRangeMapped(rangeStart, rangeEnd) * amplitude, -1.0);
        var sampleMaxSize:Float = sampleMax * (orientation == HORIZONTAL ? this.height : this.width) / 2;
        if (sampleMaxSize < minWaveformSize) sampleMaxSize = minWaveformSize;
        var sampleMinSize:Float = sampleMin * (orientation == HORIZONTAL ? this.height : this.width) / 2;
        if (sampleMinSize > -minWaveformSize) sampleMinSize = -minWaveformSize;
        var vertexTopY:Int = Std.int(waveformCenterPos - sampleMaxSize);
        var vertexBottomY:Int = Std.int(waveformCenterPos - sampleMinSize);

        var vertexTopIndex:Int = -1;
        var vertexBottomIndex:Int = -1;

        if (clipRect != null)
        {
          if (orientation == HORIZONTAL)
          {
            vertexTopIndex = buildClippedVertex(pixelPos, vertexTopY, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex, bottomRightVertexIndex);
            vertexBottomIndex = buildClippedVertex(pixelPos, vertexBottomY, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex,
              bottomRightVertexIndex);
          }
          else
          {
            vertexTopIndex = buildClippedVertex(vertexTopY, pixelPos, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex, bottomRightVertexIndex);
            vertexBottomIndex = buildClippedVertex(vertexBottomY, pixelPos, topLeftVertexIndex, topRightVertexIndex, bottomLeftVertexIndex,
              bottomRightVertexIndex);
          }
        }
        else
        {
          if (orientation == HORIZONTAL)
          {
            vertexTopIndex = this.build_vertex(pixelPos, vertexTopY);
            vertexBottomIndex = this.build_vertex(pixelPos, vertexBottomY);
          }
          else
          {
            vertexTopIndex = this.build_vertex(vertexTopY, pixelPos);
            vertexBottomIndex = this.build_vertex(vertexBottomY, pixelPos);
          }
        }

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

  function buildClippedVertex(x:Int, y:Int, topLeftVertexIndex:Int, topRightVertexIndex:Int, bottomLeftVertexIndex:Int, bottomRightVertexIndex:Int):Int
  {
    var shouldClipXLeft = x < clipRect.x;
    var shouldClipXRight = x > (clipRect.x + clipRect.width);
    var shouldClipYTop = y < clipRect.y;
    var shouldClipYBottom = y > (clipRect.y + clipRect.height);

    // If the vertex is fully outside the clipRect, use a pre-existing vertex.
    // Else, if the vertex is outside the clipRect on one axis, create a new vertex constrained on that axis.
    // Else, create a whole new vertex.
    if (shouldClipXLeft && shouldClipYTop)
    {
      return topLeftVertexIndex;
    }
    else if (shouldClipXRight && shouldClipYTop)
    {
      return topRightVertexIndex;
    }
    else if (shouldClipXLeft && shouldClipYBottom)
    {
      return bottomLeftVertexIndex;
    }
    else if (shouldClipXRight && shouldClipYBottom)
    {
      return bottomRightVertexIndex;
    }
    else if (shouldClipXLeft)
    {
      return this.build_vertex(clipRect.x, y);
    }
    else if (shouldClipXRight)
    {
      return this.build_vertex(clipRect.x + clipRect.width, y);
    }
    else if (shouldClipYTop)
    {
      return this.build_vertex(x, clipRect.y);
    }
    else if (shouldClipYBottom)
    {
      return this.build_vertex(x, clipRect.y + clipRect.height);
    }
    else
    {
      return this.build_vertex(x, y);
    }
  }

  public static function buildFromWaveformData(data:WaveformData, ?orientation:WaveformOrientation, ?color:FlxColor, ?duration:Float)
  {
    return new WaveformSprite(data, orientation, color, duration);
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
