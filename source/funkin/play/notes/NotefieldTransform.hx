package funkin.play.notes;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.graphics.tile.FlxDrawTrianglesItem.DrawData;

/**
 * Moves a strumline's receptors, notes and hold trails.
 */
class NotefieldTransform
{
  // max number of lanes supported by the notefield transform (eight strumlines)
  public static final LANE_COUNT:Int = 32;

  static final MAX_SEGMENTS:Int = 32;
  static final HOLD_ROWS:Int = MAX_SEGMENTS + 3;

  static final DEG_TO_RAD:Float = 0.017453292519943295;

  public static final STRAIGHT:Float = 1e9;

  public static final ALL_HOLDS:Float = -1e9;

  static var sharedIndices:Array<DrawData<Int>> = buildSharedIndices();

  static function buildSharedIndices():Array<DrawData<Int>>
  {
    var result:Array<DrawData<Int>> = [];
    for (rows in 0...(HOLD_ROWS + 1))
    {
      var indices:Array<Int> = [];
      for (quad in 0...(rows > 0 ? rows - 1 : 0))
      {
        var v:Int = quad * 2;
        indices.push(v);
        indices.push(v + 1);
        indices.push(v + 2);
        indices.push(v + 1);
        indices.push(v + 2);
        indices.push(v + 3);
      }
      result.push(new DrawData<Int>(indices.length, false, indices));
    }
    return result;
  }

  // The number of pixels a note moves per millisecond at a scroll speed of 1.0.
  // supports backwards scrolling!
  public static inline function scrollRate(scrollSpeed:Float, downscroll:Bool = false):Float
  {
    return Constants.PIXELS_PER_MS * scrollSpeed * (downscroll ? -1 : 1);
  }

  // The Y coordinate of a note, given its origin, distance from the strumline and scroll rate.
  public static inline function noteY(originY:Float, distance:Float, rate:Float, yOffset:Float):Float
  {
    return originY + distance * rate + yOffset;
  }

  // Lane geometry.

  public final laneOriginX:Array<Float>;

  public final laneOriginY:Array<Float>;

  public final laneReceptorX:Array<Float>;

  public final laneReceptorY:Array<Float>;

  public final laneHoldOriginX:Array<Float>;

  public final laneHoldOriginY:Array<Float>;

  public final lanePixelsPerMs:Array<Float>;

  public final laneYOffsetScale:Array<Float>;

  public final laneHoldScale:Array<Float>;

  public final laneHoldExtendMs:Array<Float>;

  public final laneHoldExtendTime:Array<Float>;

  public final laneHoldSegmentPx:Array<Float>;

  // Whole notefield.

  public var cameraEnabled:Bool = false;

  public var cameraAngle:Float = 0;

  public var cameraOffsetX:Float = 0;

  public var cameraOffsetY:Float = 0;

  public var pivotX:Float = 640;

  public var pivotY:Float = 360;

  var cameraCos:Float = 1;

  var cameraSin:Float = 0;

  public var cullPad:Float = 700;

  public var offsetSlack:Float = 0;

  public var holdTwist:Float = 0;

  public var fieldScale:Float = 1;

  public var maxTrailSegments:Int = 1;

  public var holdSmooth:Int = 1;

  public var count:Int = 0;
  public final lane:Array<Int>;

  public final distance:Array<Float>;

  public final baseX:Array<Float>;

  public final baseY:Array<Float>;

  public final offsetX:Array<Float>;

  public final offsetY:Array<Float>;

  // The angle to rotate the sprite by, in degrees. The camera's own rotation is added to this when applied.
  public final angle:Array<Float>;

  // The opacity of the sprite, 0 for invisible and 1 for fully visible.
  public final alpha:Array<Float>;

  // The color to blend the sprite towards, in 0xRRGGBB format. The sprite's own color is multiplied by this.
  public final tintColor:Array<Int>;

  // The color to apply to the sprite's vertices, in 0xRRGGBB format. A vertex is multiplied by this.
  public final vertexColor:Array<Int>;

  // The amount to blend the sprite towards its tint color, 0 for none and 1 for full. The sprite's own color is multiplied by 1 minus this.
  public final tintAmount:Array<Float>;

  public final scaleX:Array<Float>;

  public final scaleY:Array<Float>;

  public final skewX:Array<Float>;

  public final skewY:Array<Float>;

  public var baseNoteScaleX:Float = 1;
  public var baseNoteScaleY:Float = 1;
  var baseReceptorScaleX:Float = 1;
  var baseReceptorScaleY:Float = 1;
  public var readNoteScale:Bool = false;
  var readReceptorScale:Bool = false;

  var baseHoldOffsetX:Float = 0;
  var baseHoldOffsetY:Float = 0;
  var baseHoldScrollX:Float = 0;
  var baseHoldScrollY:Float = 0;
  var readHoldBase:Bool = false;

  // What the last gather picked up, revisited in the same order by its apply.
  var notes:Array<NoteSprite>;
  var receptors:Array<StrumlineNote>;
  var holds:Array<SustainTrail>;

  public var holdFirstRow:Array<Int>;

  public var holdBodyRows:Array<Int>;
  var holdDrawRows:Array<Int>;
  var holdColumn:Array<Int>;
  var holdHalfWidth:Array<Float>;
  var holdFromPixel:Array<Float>;
  var holdStep:Array<Float>;
  var holdBodyLength:Array<Float>;
  var holdInverseHeight:Array<Float>;
  var holdCapTopV:Array<Float>;
  var holdBottomClip:Array<Float>;

  var boundsMinX:Float = 0;
  var boundsMinY:Float = 0;
  var boundsMaxX:Float = 0;
  var boundsMaxY:Float = 0;

  // One trail's drawn rows, filled from its control rows every frame.
  var rowX:Array<Float>;
  var rowY:Array<Float>;
  var rowAlpha:Array<Float>;
  var rowScale:Array<Float>;
  var rowAngle:Array<Float>;
  var rowColor:Array<Int>;

  var vertexBuffer:Array<Float>;
  var uvBuffer:Array<Float>;
  var colorBuffer:Array<Int>;

  var screenX:Float = 0;
  var screenY:Float = 0;

  public function new()
  {
    laneOriginX = filled(LANE_COUNT, Math.NaN);
    laneOriginY = filled(LANE_COUNT, 0);
    laneReceptorX = filled(LANE_COUNT, 0);
    laneReceptorY = filled(LANE_COUNT, 0);
    laneHoldOriginX = filled(LANE_COUNT, Math.NaN);
    laneHoldOriginY = filled(LANE_COUNT, 0);
    lanePixelsPerMs = filled(LANE_COUNT, Constants.PIXELS_PER_MS);
    laneYOffsetScale = filled(LANE_COUNT, 1);
    laneHoldScale = filled(LANE_COUNT, 1);
    laneHoldExtendMs = filled(LANE_COUNT, 0);
    laneHoldExtendTime = filled(LANE_COUNT, ALL_HOLDS);
    laneHoldSegmentPx = filled(LANE_COUNT, STRAIGHT);

    lane = [];
    distance = [];
    baseX = [];
    baseY = [];
    offsetX = [];
    offsetY = [];
    angle = [];
    alpha = [];
    tintColor = [];
    tintAmount = [];
    vertexColor = [];
    scaleX = [];
    skewX = [];
    skewY = [];
    scaleY = [];

    notes = [];
    receptors = [];
    holds = [];

    holdFirstRow = [];
    holdBodyRows = [];
    holdDrawRows = [];
    holdColumn = [];
    holdHalfWidth = [];
    holdFromPixel = [];
    holdStep = [];
    holdBodyLength = [];
    holdInverseHeight = [];
    holdCapTopV = [];
    holdBottomClip = [];

    rowX = filled(HOLD_ROWS, 0);
    rowY = filled(HOLD_ROWS, 0);
    rowAlpha = filled(HOLD_ROWS, 0);
    rowScale = filled(HOLD_ROWS, 1);
    rowAngle = filled(HOLD_ROWS, 0);

    rowColor = [];
    for (i in 0...HOLD_ROWS)
      rowColor.push(0xFFFFFF);

    vertexBuffer = filled(HOLD_ROWS * 4, 0);
    uvBuffer = filled(HOLD_ROWS * 4, 0);

    colorBuffer = [];
    for (i in 0...(HOLD_ROWS * 2))
      colorBuffer.push(-1);

  }

  static inline function nextPowerOfTwo(value:Int):Int
  {
    var result:Int = 1;
    while (result < value)
      result <<= 1;
    return result;
  }

  static function filled(size:Int, value:Float):Array<Float>
  {
    var result:Array<Float> = [];
    for (i in 0...size)
      result.push(value);
    return result;
  }

  function startGather():Void
  {
    count = 0;
    notes.resize(0);
    receptors.resize(0);
    holds.resize(0);

    if (cameraEnabled)
    {
      var radians:Float = cameraAngle * DEG_TO_RAD;
      cameraCos = Math.cos(radians);
      cameraSin = Math.sin(radians);
    }
  }

  function push(forLane:Int, away:Float, x:Float, y:Float):Void
  {
    var at:Int = count++;

    if (at < lane.length)
    {
      lane[at] = forLane;
      distance[at] = away;
      baseX[at] = x;
      baseY[at] = y;
      offsetX[at] = 0;
      offsetY[at] = 0;
      angle[at] = 0;
      alpha[at] = 1;
      tintColor[at] = 0xFFFFFF;
      tintAmount[at] = 0;
      vertexColor[at] = 0xFFFFFF;
      scaleX[at] = 1;
      scaleY[at] = 1;
      skewX[at] = 0;
      skewY[at] = 0;
    }
    else
    {
      lane.push(forLane);
      distance.push(away);
      baseX.push(x);
      baseY.push(y);
      offsetX.push(0);
      offsetY.push(0);
      angle.push(0);
      alpha.push(1);
      tintColor.push(0xFFFFFF);
      tintAmount.push(0);
      vertexColor.push(0xFFFFFF);
      scaleX.push(1);
      scaleY.push(1);
      skewX.push(0);
      skewY.push(0);
    }
  }

  // Takes in whatever movePoint just produced.
  inline function growBounds():Void
  {
    if (screenX < boundsMinX) boundsMinX = screenX;
    if (screenX > boundsMaxX) boundsMaxX = screenX;
    if (screenY < boundsMinY) boundsMinY = screenY;
    if (screenY > boundsMaxY) boundsMaxY = screenY;
  }

  function movePoint(x:Float, y:Float):Void
  {
    if (!cameraEnabled)
    {
      screenX = x;
      screenY = y;
      return;
    }

    var dx:Float = x - pivotX;
    var dy:Float = y - pivotY;
    screenX = pivotX + dx * cameraCos - dy * cameraSin + cameraOffsetX;
    screenY = pivotY + dx * cameraSin + dy * cameraCos + cameraOffsetY;
  }

  /**
   * Moves a sprite to a position, rotated around the camera pivot and offset by the camera's own position.
   * @param x
   * @param y
   * @param halfWidth
   * @param halfHeight
   */
  function moveSprite(x:Float, y:Float, halfWidth:Float, halfHeight:Float):Void
  {
    if (!cameraEnabled)
    {
      screenX = x;
      screenY = y;
      return;
    }

    var dx:Float = x + halfWidth - pivotX;
    var dy:Float = y + halfHeight - pivotY;
    screenX = pivotX + dx * cameraCos - dy * cameraSin + cameraOffsetX - halfWidth;
    screenY = pivotY + dx * cameraSin + dy * cameraCos + cameraOffsetY - halfHeight;
  }

  /**
   * Writes a sprite's opacity and blends it towards its tint color.
   */
  function tint(sprite:FlxSprite, at:Int):Void
  {
    tintAt(sprite, at, alpha[at]);
  }

  function tintAt(sprite:FlxSprite, at:Int, opacity:Float):Void
  {
    var amount:Float = tintAmount[at];

    if (amount > 0)
    {
      if (amount > 1) amount = 1;
      var keep:Float = 1 - amount;
      var color:Int = tintColor[at];
      sprite.setColorTransform(keep, keep, keep, opacity, ((color >> 16) & 0xFF) * amount, ((color >> 8) & 0xFF) * amount,
        (color & 0xFF) * amount, 0);
    }
    else
    {
      if (sprite.colorTransform.redMultiplier != 1 || sprite.colorTransform.redOffset != 0)
      {
        sprite.setColorTransform(1, 1, 1, sprite.alpha, 0, 0, 0, 0);
      }
      if (sprite.alpha != opacity) sprite.alpha = opacity;
    }
  }

  // Receptors.

  /**
   * Gathers a strumline's receptors, one entry each, at distance zero.
   * @param strumline The strumline to gather from.
   * @param laneBase The index of its first lane, so 0 or 4.
   */
  public function gatherReceptors(strumline:Strumline, laneBase:Int):Void
  {
    startGather();
    if (strumline == null) return;

    for (column in 0...Strumline.KEY_COUNT)
    {
      var receptor:StrumlineNote = strumline.getByIndex(column);
      if (receptor == null) continue;

      if (!readReceptorScale)
      {
        readReceptorScale = true;
        baseReceptorScaleX = receptor.scale.x;
        baseReceptorScaleY = receptor.scale.y;
      }

      var at:Int = laneBase + column;
      push(at, 0, laneReceptorX[at], laneReceptorY[at]);
      receptors.push(receptor);
    }
  }

  public function applyReceptors(strumline:Strumline, laneBase:Int):Void
  {
    for (i in 0...receptors.length)
    {
      var receptor:StrumlineNote = receptors[i];
      moveSprite(baseX[i] + offsetX[i], baseY[i] + offsetY[i], receptor.width * 0.5, receptor.height * 0.5);

      var sx:Float = scaleX[i] * fieldScale;
      var sy:Float = scaleY[i] * fieldScale;
      receptor.x = screenX;
      receptor.y = screenY;
      receptor.angle = angle[i] + cameraAngle;
      receptor.alpha = alpha[i];
      receptor.scale.set(baseReceptorScaleX * sx, baseReceptorScaleY * sy);
      receptor.skew.set(skewX[i], skewY[i]);
    }
  }

  // Notes.

  /**
   * Gathers every live note on a strumline that could be on screen.
   */
  public function gatherNotes(strumline:Strumline, laneBase:Int, songTime:Float):Void
  {
    startGather();
    if (strumline == null) return;

    var members = strumline.notes.members;
    var top:Float = -cullPad - offsetSlack;
    var bottom:Float = FlxG.height + cullPad + offsetSlack;

    for (index in 0...members.length)
    {
      var note:NoteSprite = members[index];
      if (note == null || !note.alive) continue;

      if (!readNoteScale)
      {
        readNoteScale = true;
        baseNoteScaleX = note.scale.x;
        baseNoteScaleY = note.scale.y;
      }

      var at:Int = laneBase + (note.direction % Strumline.KEY_COUNT);
      var originX:Float = laneOriginX[at];
      if (Math.isNaN(originX)) continue;

      var away:Float = note.strumTime - songTime;
      var y:Float = noteY(laneOriginY[at], away, lanePixelsPerMs[at], note.yOffset * laneYOffsetScale[at]);

      note.y = y;

      if (y < top || y > bottom)
      {
        if (note.visible) note.visible = false;
        continue;
      }

      push(at, away, originX, y);
      notes.push(note);
    }
  }

  /**
   * Writes the offsets back to the notes `gatherNotes` picked up. An entry left
   * at zero opacity is hidden rather than placed.
   */
  public function applyNotes(strumline:Strumline, laneBase:Int):Void
  {
    for (i in 0...notes.length)
    {
      var note:NoteSprite = notes[i];

      if (alpha[i] <= 0)
      {
        if (note.visible) note.visible = false;
        continue;
      }

      if (!note.visible) note.visible = true;
      moveSprite(baseX[i] + offsetX[i], baseY[i] + offsetY[i], note.width * 0.5, note.height * 0.5);

      var sx:Float = scaleX[i] * fieldScale;
      var sy:Float = scaleY[i] * fieldScale;

      note.x = screenX;
      note.y = screenY;
      note.angle = angle[i] + cameraAngle;
      note.scale.set(baseNoteScaleX * sx, baseNoteScaleY * sy);
      note.skew.set(skewX[i], skewY[i]);
      tint(note, i);
    }
  }

  // Hold trails.

  /**
   * Gathers points along every live hold trail that could be on screen.
   * @param strumline The strumline to gather from.
   * @param laneBase The index of its first lane, so 0 or 4.
   * @param songTime The song position to gather against, in milliseconds.
   */
  public function gatherHolds(strumline:Strumline, laneBase:Int, songTime:Float):Void
  {
    startGather();
    holdFirstRow.resize(0);
    holdBodyRows.resize(0);
    holdDrawRows.resize(0);
    holdColumn.resize(0);
    holdHalfWidth.resize(0);
    holdFromPixel.resize(0);
    holdStep.resize(0);
    holdBodyLength.resize(0);
    holdInverseHeight.resize(0);
    holdCapTopV.resize(0);
    holdBottomClip.resize(0);
    if (strumline == null) return;

    var members = strumline.holdNotes.members;
    var top:Float = -cullPad - offsetSlack;
    var bottom:Float = FlxG.height + cullPad + offsetSlack;

    for (index in 0...members.length)
    {
      var hold:SustainTrail = members[index];
      if (hold == null || !hold.alive) continue;

      if (!readHoldBase)
      {
        readHoldBase = true;
        baseHoldOffsetX = hold.offset.x;
        baseHoldOffsetY = hold.offset.y;
        baseHoldScrollX = hold.scrollFactor.x;
        baseHoldScrollY = hold.scrollFactor.y;
      }

      hold.customVertexData = true;

      var column:Int = hold.noteDirection % Strumline.KEY_COUNT;
      var at:Int = laneBase + column;

      var centerX:Float = laneHoldOriginX[at];
      if (Math.isNaN(centerX))
      {
        hold.visible = false;
        continue;
      }

      var speed:Float = lanePixelsPerMs[at];
      var rate:Float = (speed < 0) ? -speed : speed;

      // early release check for holds
      var released:Bool = hold.missedNote && hold.fullSustainLength > hold.sustainLength;
      if (rate < 0.0001 || hold.sustainLength <= 10 || released)
      {
        hold.visible = false;
        continue;
      }

      var startTime:Float = hold.strumTime + (hold.fullSustainLength - hold.sustainLength);

      // Only the trail the lane names, so the ones queued behind it are left alone.
      var extend:Float = laneHoldExtendMs[at];
      if (extend != 0)
      {
        var only:Float = laneHoldExtendTime[at];
        if (only > ALL_HOLDS * 0.5)
        {
          var apart:Float = hold.strumTime - only;
          if (apart < 0) apart = -apart;
          if (apart >= 1) extend = 0;
        }
      }

      var span:Float = (hold.strumTime + hold.fullSustainLength - startTime) * laneHoldScale[at] + extend;
      if (span <= 1)
      {
        hold.visible = false;
        continue;
      }

      var graphic = hold.graphic;
      if (graphic == null || graphic.width <= 0 || graphic.height <= 0)
      {
        hold.visible = false;
        continue;
      }

      var width:Float = hold.width;
      var zoom:Float = width * 8 / graphic.width;
      var textureHeight:Float = graphic.height * zoom;
      if (textureHeight <= 0)
      {
        hold.visible = false;
        continue;
      }

      var msPerPixel:Float = 1 / rate;
      var capHead:Float = textureHeight * hold.endOffset;
      var capTail:Float = textureHeight * (hold.bottomClip - hold.endOffset);

      var shown:Float = span * rate;
      var bodyLength:Float = shown - capHead;
      var capTopV:Float = 0;
      if (bodyLength <= 0)
      {
        bodyLength = 0;
        capTopV = (capHead - shown) / textureHeight;
      }

      var sign:Float = (speed < 0) ? -1 : 1;
      var headY:Float = noteY(laneHoldOriginY[at], startTime - songTime, speed, hold.yOffset * laneYOffsetScale[at]);

      var trailLength:Float = shown + capTail;
      var tailY:Float = headY + trailLength * sign;

      if ((headY < top && tailY < top) || (headY > bottom && tailY > bottom))
      {
        hold.visible = false;
        continue;
      }

      var fromPixel:Float = 0;
      var toPixel:Float = 0;
      if (sign > 0)
      {
        fromPixel = top - headY;
        toPixel = bottom - headY;
      }
      else
      {
        fromPixel = headY - bottom;
        toPixel = headY - top;
      }
      if (fromPixel < 0) fromPixel = 0;
      if (toPixel > bodyLength) toPixel = bodyLength;
      if (toPixel < fromPixel) toPixel = fromPixel;

      var drawn:Float = toPixel - fromPixel;
      var segmentPx:Float = laneHoldSegmentPx[at];
      var wanted:Int = 1;
      if (segmentPx < STRAIGHT && drawn > segmentPx) wanted = Math.ceil(drawn / segmentPx);

      var segments:Int = hold.trailSegments;
      if (segments < 1 || wanted > segments || wanted * 3 < segments * 2) segments = nextPowerOfTwo(wanted);
      if (segments > maxTrailSegments) segments = maxTrailSegments;
      if (segments > MAX_SEGMENTS) segments = MAX_SEGMENTS;
      hold.trailSegments = segments;

      var smooth:Int = holdSmooth;
      if (smooth < 1) smooth = 1;

      var control:Int = Math.ceil(segments / smooth);
      if (control < 1) control = 1;
      if (control * smooth > MAX_SEGMENTS) control = Std.int(MAX_SEGMENTS / smooth);

      var drawSegments:Int = (control > 1) ? control * smooth : 1;
      var controlStep:Float = drawn / control;
      var step:Float = drawn / drawSegments;

      holds.push(hold);
      holdFirstRow.push(count);
      holdBodyRows.push(control + 1);
      holdDrawRows.push(drawSegments + 1);
      holdColumn.push(column);
      holdHalfWidth.push(width * 0.5);
      holdFromPixel.push(fromPixel);
      holdStep.push(step);
      holdBodyLength.push(bodyLength);
      holdInverseHeight.push(1 / textureHeight);
      holdCapTopV.push(capTopV);
      holdBottomClip.push(hold.bottomClip);

      for (row in 0...(control + 1))
      {
        var along:Float = fromPixel + controlStep * row;
        push(at, startTime + along * msPerPixel - songTime, centerX, headY + along * sign);
      }
      push(at, startTime + bodyLength * msPerPixel - songTime, centerX, headY + bodyLength * sign);
      push(at, startTime + trailLength * msPerPixel - songTime, centerX, tailY);
    }
  }

  /**
   * Writes the offsets back to the hold trails `gatherHolds` picked up.
   * @param strumline The strumline to apply to.
   * @param laneBase The base lane to apply to.
   */
  public function applyHolds(strumline:Strumline, laneBase:Int):Void
  {
    var gradient:Bool = false;
    for (h in 0...holds.length)
    {
      var from:Int = holdFirstRow[h];
      var to:Int = from + holdBodyRows[h] + 2;
      var low:Float = 1;
      var high:Float = 0;
      var colored:Bool = false;
      for (at in from...to)
      {
        var a:Float = alpha[at];
        if (a < low) low = a;
        if (a > high) high = a;
        if (vertexColor[at] != 0xFFFFFF) colored = true;
      }
      if (colored || high - low >= 1 / 255)
      {
        gradient = true;
        break;
      }
    }

    for (h in 0...holds.length)
    {
      var hold:SustainTrail = holds[h];
      var first:Int = holdFirstRow[h];
      var ctrlRows:Int = holdBodyRows[h];
      var drawRows:Int = holdDrawRows[h];
      var last:Int = first + ctrlRows - 1;
      var halfWidth:Float = holdHalfWidth[h] * fieldScale;

      var capTop:Int = first + ctrlRows;
      var capBottom:Int = capTop + 1;

      // Opacity check. If the whole trail is invisible, don't bother writing vertices.
      var peak:Float = 0;
      for (at in first...(capBottom + 1))
      {
        if (alpha[at] > peak) peak = alpha[at];
      }
      if (peak <= 0)
      {
        hold.visible = false;
        continue;
      }

      boundsMinX = boundsMinY = 1e9;
      boundsMaxX = boundsMaxY = -1e9;

      if (drawRows == ctrlRows)
      {
        // Nothing was left out, so the rows are taken as they are, the way they always were.
        for (row in 0...drawRows)
        {
          var here:Int = first + row;
          widenRow(row, here, (here == first) ? here : here - 1, (here == last) ? here : here + 1, halfWidth);
          if (gradient) colorRow(row, here);
        }
      }
      else
      {
        expandRows(first, ctrlRows, drawRows);

        for (row in 0...drawRows)
        {
          widenDrawn(row, drawRows, halfWidth);
          if (gradient) colorDrawn(row);
        }
      }

      var capTopRow:Int = drawRows;
      var capBottomRow:Int = drawRows + 1;
      widenRow(capTopRow, capTop, last, capBottom, halfWidth);
      widenRow(capBottomRow, capBottom, last, capBottom, halfWidth);
      if (gradient)
      {
        colorRow(capTopRow, capTop);
        colorRow(capBottomRow, capBottom);
      }

      var rows:Int = drawRows + 2;

      writeTrailUVs(h, drawRows);

      hold.meshMinX = boundsMinX;
      hold.meshMinY = boundsMinY;
      hold.meshMaxX = boundsMaxX;
      hold.meshMaxY = boundsMaxY;

      hold.writeVertices(vertexBuffer, rows * 4);
      hold.writeUVTData(uvBuffer, rows * 4);
      hold.writeVertexColors(colorBuffer, gradient ? rows * 2 : 0);
      hold.indices = sharedIndices[rows];

      hold.visible = true;
      // With a gradient the opacity is already carried per vertex, so the transform only tints.
      tintAt(hold, first, gradient ? 1 : peak);
    }
  }

  /**
   * Lays the drawn rows on a curve through the control rows, four at a time, so a bent trail comes
   * out round rather than as a run of straight pieces. Only the control rows went through the mods.
   */
  function expandRows(first:Int, ctrlRows:Int, drawRows:Int):Void
  {
    if (drawRows == ctrlRows)
    {
      for (row in 0...ctrlRows)
      {
        var at:Int = first + row;
        rowX[row] = baseX[at] + offsetX[at];
        rowY[row] = baseY[at] + offsetY[at];
        rowAlpha[row] = alpha[at];
        rowScale[row] = scaleX[at];
        rowAngle[row] = angle[at];
        rowColor[row] = vertexColor[at];
      }
      return;
    }

    var sub:Int = Std.int((drawRows - 1) / (ctrlRows - 1));
    var out:Int = 0;

    for (i in 0...(ctrlRows - 1))
    {
      // The piece from i to i+1, with the row either side of it steering the ends.
      var i0:Int = first + ((i > 0) ? i - 1 : i);
      var i1:Int = first + i;
      var i2:Int = first + i + 1;
      var i3:Int = first + ((i + 2 < ctrlRows) ? i + 2 : i + 1);

      var x0:Float = baseX[i0] + offsetX[i0];
      var y0:Float = baseY[i0] + offsetY[i0];
      var x1:Float = baseX[i1] + offsetX[i1];
      var y1:Float = baseY[i1] + offsetY[i1];
      var x2:Float = baseX[i2] + offsetX[i2];
      var y2:Float = baseY[i2] + offsetY[i2];
      var x3:Float = baseX[i3] + offsetX[i3];
      var y3:Float = baseY[i3] + offsetY[i3];

      var ax:Float = 2 * x1;
      var bx:Float = x2 - x0;
      var cx:Float = 2 * x0 - 5 * x1 + 4 * x2 - x3;
      var dx:Float = 3 * x1 - 3 * x2 + x3 - x0;

      var ay:Float = 2 * y1;
      var by:Float = y2 - y0;
      var cy:Float = 2 * y0 - 5 * y1 + 4 * y2 - y3;
      var dy:Float = 3 * y1 - 3 * y2 + y3 - y0;

      // Opacity, width and twist are gentle enough down a trail to walk straight across.
      var a1:Float = alpha[i1];
      var da:Float = alpha[i2] - a1;
      var s1:Float = scaleX[i1];
      var ds:Float = scaleX[i2] - s1;
      var g1:Float = angle[i1];
      var dg:Float = angle[i2] - g1;
      var c1:Int = vertexColor[i1];
      var c2:Int = vertexColor[i2];
      var cr:Float = (c1 >> 16) & 0xFF;
      var cg:Float = (c1 >> 8) & 0xFF;
      var cb:Float = c1 & 0xFF;
      var dcr:Float = ((c2 >> 16) & 0xFF) - cr;
      var dcg:Float = ((c2 >> 8) & 0xFF) - cg;
      var dcb:Float = (c2 & 0xFF) - cb;

      for (j in 0...sub)
      {
        var t:Float = j / sub;
        var t2:Float = t * t;
        var t3:Float = t2 * t;

        rowX[out] = 0.5 * (ax + bx * t + cx * t2 + dx * t3);
        rowY[out] = 0.5 * (ay + by * t + cy * t2 + dy * t3);
        rowAlpha[out] = a1 + da * t;
        rowScale[out] = s1 + ds * t;
        rowAngle[out] = g1 + dg * t;
        // optimization for white
        rowColor[out] = (c1 == c2) ? c1 : (Std.int(cr + dcr * t) << 16) | (Std.int(cg + dcg * t) << 8) | Std.int(cb + dcb * t);
        out++;
      }
    }

    var end:Int = first + ctrlRows - 1;
    rowX[out] = baseX[end] + offsetX[end];
    rowY[out] = baseY[end] + offsetY[end];
    rowAlpha[out] = alpha[end];
    rowScale[out] = scaleX[end];
    rowAngle[out] = angle[end];
    rowColor[out] = vertexColor[end];
  }

  /**
   * The same as widenRow, off the drawn rows, and mitred so a bend holds its width rather than
   * pinching on the inside of the turn.
   */
  function widenDrawn(row:Int, rows:Int, halfWidth:Float):Void
  {
    var x:Float = rowX[row];
    var y:Float = rowY[row];

    var before:Int = (row > 0) ? row - 1 : row;
    var after:Int = (row < rows - 1) ? row + 1 : row;

    var inX:Float = x - rowX[before];
    var inY:Float = y - rowY[before];
    var inLength:Float = Math.sqrt(inX * inX + inY * inY);

    var outX:Float = rowX[after] - x;
    var outY:Float = rowY[after] - y;
    var outLength:Float = Math.sqrt(outX * outX + outY * outY);

    if (inLength < 0.0001)
    {
      inX = outX;
      inY = outY;
      inLength = outLength;
    }
    if (outLength < 0.0001)
    {
      outX = inX;
      outY = inY;
      outLength = inLength;
    }

    var normalX:Float = -1;
    var normalY:Float = 0;
    var fit:Float = 1;

    if (inLength >= 0.0001 && outLength >= 0.0001)
    {
      inX /= inLength;
      inY /= inLength;
      outX /= outLength;
      outY /= outLength;

      var mitreX:Float = -(inY + outY);
      var mitreY:Float = inX + outX;
      var mitreLength:Float = Math.sqrt(mitreX * mitreX + mitreY * mitreY);
      if (mitreLength >= 0.0001)
      {
        normalX = mitreX / mitreLength;
        normalY = mitreY / mitreLength;
        // How much wider the mitre has to run to keep the edges parallel, held back so a hairpin
        // cannot throw a spike across the screen.
        fit = normalX * -inY + normalY * inX;
        if (fit < 0.25) fit = 0.25;
      }
      else
      {
        normalX = -inY;
        normalY = inX;
      }
    }

    var twist:Float = holdTwist * rowAngle[row];
    if (twist != 0)
    {
      var radians:Float = twist * DEG_TO_RAD;
      var twistCos:Float = Math.cos(radians);
      var twistSin:Float = Math.sin(radians);
      var turned:Float = normalX * twistCos - normalY * twistSin;
      normalY = normalX * twistSin + normalY * twistCos;
      normalX = turned;
    }

    var reach:Float = halfWidth * rowScale[row] / fit;

    var at:Int = row * 4;
    movePoint(x + normalX * reach, y + normalY * reach);
    vertexBuffer[at] = screenX;
    vertexBuffer[at + 1] = screenY;
    growBounds();
    movePoint(x - normalX * reach, y - normalY * reach);
    vertexBuffer[at + 2] = screenX;
    vertexBuffer[at + 3] = screenY;
    growBounds();
  }

  /**
   * The same as colorRow, off the drawn rows.
   */
  function colorDrawn(row:Int):Void
  {
    var opacity:Float = rowAlpha[row];
    if (opacity < 0) opacity = 0;
    else if (opacity > 1) opacity = 1;

    var packed:Int = (Std.int(opacity * 255) << 24) | (rowColor[row] & 0xFFFFFF);
    var k:Int = row * 2;
    colorBuffer[k] = packed;
    colorBuffer[k + 1] = packed;
  }

  /**
   * Writes one control row's opacity and color into both of its vertices.
   */
  function colorRow(row:Int, at:Int):Void
  {
    var opacity:Float = alpha[at];
    if (opacity < 0) opacity = 0;
    else if (opacity > 1) opacity = 1;

    var packed:Int = (Std.int(opacity * 255) << 24) | (vertexColor[at] & 0xFFFFFF);
    var k:Int = row * 2;
    colorBuffer[k] = packed;
    colorBuffer[k + 1] = packed;
  }

  /**
   * Moves the two vertices of a trail row outwards by halfWidth, along the normal to the line between the previous and next row.
   */
  function widenRow(row:Int, here:Int, before:Int, after:Int, halfWidth:Float):Void
  {
    var x:Float = baseX[here] + offsetX[here];
    var y:Float = baseY[here] + offsetY[here];
    var dx:Float = (baseX[after] + offsetX[after]) - (baseX[before] + offsetX[before]);
    var dy:Float = (baseY[after] + offsetY[after]) - (baseY[before] + offsetY[before]);

    var length:Float = Math.sqrt(dx * dx + dy * dy);
    var normalX:Float = -1;
    var normalY:Float = 0;
    if (length >= 0.0001)
    {
      normalX = -dy / length;
      normalY = dx / length;
    }

    var twist:Float = holdTwist * angle[here];
    if (twist != 0)
    {
      var radians:Float = twist * DEG_TO_RAD;
      var twistCos:Float = Math.cos(radians);
      var twistSin:Float = Math.sin(radians);
      var turned:Float = normalX * twistCos - normalY * twistSin;
      normalY = normalX * twistSin + normalY * twistCos;
      normalX = turned;
    }

    var reach:Float = halfWidth * scaleX[here];

    var at:Int = row * 4;
    movePoint(x + normalX * reach, y + normalY * reach);
    vertexBuffer[at] = screenX;
    vertexBuffer[at + 1] = screenY;
    growBounds();
    movePoint(x - normalX * reach, y - normalY * reach);
    vertexBuffer[at + 2] = screenX;
    vertexBuffer[at + 3] = screenY;
    growBounds();
  }

  /**
   * The body tiles by running its V coordinate negative above zero, so the UVs are written to match.
   */
  function writeTrailUVs(h:Int, bodyRows:Int):Void
  {
    var left:Float = 0.25 * holdColumn[h];
    var right:Float = left + 0.125;
    var fromPixel:Float = holdFromPixel[h];
    var step:Float = holdStep[h];
    var bodyLength:Float = holdBodyLength[h];
    var inverseHeight:Float = holdInverseHeight[h];

    for (row in 0...bodyRows)
    {
      var at:Int = row * 4;
      var v:Float = (fromPixel + step * row - bodyLength) * inverseHeight;
      uvBuffer[at] = left;
      uvBuffer[at + 1] = v;
      uvBuffer[at + 2] = right;
      uvBuffer[at + 3] = v;
    }

    var capLeft:Float = right;
    var capRight:Float = right + 0.125;

    var capTop:Int = bodyRows * 4;
    uvBuffer[capTop] = capLeft;
    uvBuffer[capTop + 1] = holdCapTopV[h];
    uvBuffer[capTop + 2] = capRight;
    uvBuffer[capTop + 3] = holdCapTopV[h];

    var capBottom:Int = (bodyRows + 1) * 4;
    uvBuffer[capBottom] = capLeft;
    uvBuffer[capBottom + 1] = holdBottomClip[h];
    uvBuffer[capBottom + 2] = capRight;
    uvBuffer[capBottom + 3] = holdBottomClip[h];
  }

  /**
   * Hands a strumline's sprites back the way they were found. Notes and trails
   * are pooled and revived rather than rebuilt, and reviving restores neither
   * visibility nor scale nor color, so whatever was left on one would carry
   * into the next run of the song. Dead members are walked too, since those are
   * exactly the ones waiting to be handed out again.
   * @param strumline The strumline to hand back.
   */
  public function release(strumline:Strumline):Void
  {
    if (strumline == null) return;

    for (column in 0...Strumline.KEY_COUNT)
    {
      var receptor:StrumlineNote = strumline.getByIndex(column);
      if (receptor == null) continue;

      receptor.angle = 0;
      receptor.alpha = 1;
      if (readReceptorScale) receptor.scale.set(baseReceptorScaleX, baseReceptorScaleY);
      clearTint(receptor);
    }

    var noteMembers = strumline.notes.members;
    for (index in 0...noteMembers.length)
    {
      var note:NoteSprite = noteMembers[index];
      if (note == null) continue;

      note.visible = true;
      note.alpha = 1;
      note.angle = 0;
      if (readNoteScale) note.scale.set(baseNoteScaleX, baseNoteScaleY);
      clearTint(note);
    }

    var holdMembers = strumline.holdNotes.members;
    for (index in 0...holdMembers.length)
    {
      var hold:SustainTrail = holdMembers[index];
      if (hold == null) continue;

      hold.customVertexData = false;
      hold.restoreDefaultMesh();
      hold.visible = true;
      hold.alpha = 1;
      clearTint(hold);

      if (readHoldBase)
      {
        hold.offset.set(baseHoldOffsetX, baseHoldOffsetY);
        hold.scrollFactor.set(baseHoldScrollX, baseHoldScrollY);
      }
    }
  }

  function clearTint(sprite:FlxSprite):Void
  {
    if (sprite.colorTransform.redMultiplier != 1 || sprite.colorTransform.redOffset != 0)
    {
      sprite.setColorTransform(1, 1, 1, 1, 0, 0, 0, 0);
    }
  }
}
