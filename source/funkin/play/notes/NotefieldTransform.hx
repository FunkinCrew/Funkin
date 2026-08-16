package funkin.play.notes;

import flixel.FlxG;
import flixel.FlxSprite;

/**
 * Moves a strumline's receptors, notes and hold trails.
 */
class NotefieldTransform
{
  // The number of lanes a strumline can have.
  public static final LANE_COUNT:Int = 8;

  // The maximum number of segments a hold trail can be split into.
  static final MAX_SEGMENTS:Int = 32;
  static final BODY_ROWS:Int = 33;
  static final HOLD_ROWS:Int = 35;

  static final DEG_TO_RAD:Float = 0.017453292519943295;

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

  public var maxTrailSegments:Int = 1;
  public var trailSegmentMs:Float = 100;

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

  // The amount to blend the sprite towards its tint color, 0 for none and 1 for full. The sprite's own color is multiplied by 1 minus this.
  public final tintAmount:Array<Float>;

  public final scaleX:Array<Float>;

  public final scaleY:Array<Float>;

  var baseNoteScaleX:Float = 1;
  var baseNoteScaleY:Float = 1;
  var baseReceptorScaleX:Float = 1;
  var baseReceptorScaleY:Float = 1;
  var readNoteScale:Bool = false;
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

  // Per trail, alongside `holds`.
  var holdFirstRow:Array<Int>;
  var holdBodyRows:Array<Int>;
  var holdColumn:Array<Int>;
  var holdHalfWidth:Array<Float>;
  var holdFromPixel:Array<Float>;
  var holdToPixel:Array<Float>;
  var holdStep:Array<Float>;
  var holdBodyLength:Array<Float>;
  var holdInverseHeight:Array<Float>;
  var holdCapTopV:Array<Float>;
  var holdBottomClip:Array<Float>;

  var vertexBuffer:Array<Float>;
  var uvBuffer:Array<Float>;
  var indexBuffer:Array<Int>;
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
    scaleX = [];
    scaleY = [];

    notes = [];
    receptors = [];
    holds = [];

    holdFirstRow = [];
    holdBodyRows = [];
    holdColumn = [];
    holdHalfWidth = [];
    holdFromPixel = [];
    holdToPixel = [];
    holdStep = [];
    holdBodyLength = [];
    holdInverseHeight = [];
    holdCapTopV = [];
    holdBottomClip = [];

    vertexBuffer = filled(HOLD_ROWS * 4, 0);
    uvBuffer = filled(HOLD_ROWS * 4, 0);

    colorBuffer = [];
    for (i in 0...(HOLD_ROWS * 2))
      colorBuffer.push(-1);

    indexBuffer = [];
    for (quad in 0...(HOLD_ROWS - 1))
    {
      var v:Int = quad * 2;
      indexBuffer.push(v);
      indexBuffer.push(v + 1);
      indexBuffer.push(v + 2);
      indexBuffer.push(v + 1);
      indexBuffer.push(v + 2);
      indexBuffer.push(v + 3);
    }
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
      scaleX[at] = 1;
      scaleY[at] = 1;
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
      scaleX.push(1);
      scaleY.push(1);
    }
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
    else if (sprite.colorTransform.redMultiplier != 1)
    {
      sprite.setColorTransform(1, 1, 1, opacity, 0, 0, 0, 0);
    }
    else if (sprite.alpha != opacity)
    {
      sprite.alpha = opacity;
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

      receptor.x = screenX;
      receptor.y = screenY;
      receptor.angle = angle[i] + cameraAngle;
      receptor.alpha = alpha[i];
      receptor.scale.set(baseReceptorScaleX * scaleX[i], baseReceptorScaleY * scaleY[i]);
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

      note.x = screenX;
      note.y = screenY;
      note.angle = angle[i] + cameraAngle;
      note.scale.set(baseNoteScaleX * scaleX[i], baseNoteScaleY * scaleY[i]);
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
    holdColumn.resize(0);
    holdHalfWidth.resize(0);
    holdFromPixel.resize(0);
    holdToPixel.resize(0);
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
      var span:Float = hold.strumTime + hold.fullSustainLength - startTime;
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
      var headY:Float = noteY(laneHoldOriginY[at], startTime - songTime, speed, 0);

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

      var segments:Int = Math.ceil(hold.fullSustainLength / trailSegmentMs);
      if (segments < 1) segments = 1;
      if (segments > maxTrailSegments) segments = maxTrailSegments;
      if (segments > MAX_SEGMENTS) segments = MAX_SEGMENTS;
      var step:Float = (toPixel - fromPixel) / segments;

      holds.push(hold);
      holdFirstRow.push(count);
      holdBodyRows.push(segments + 1);
      holdColumn.push(column);
      holdHalfWidth.push(width * 0.5);
      holdFromPixel.push(fromPixel);
      holdToPixel.push(toPixel);
      holdStep.push(step);
      holdBodyLength.push(bodyLength);
      holdInverseHeight.push(1 / textureHeight);
      holdCapTopV.push(capTopV);
      holdBottomClip.push(hold.bottomClip);

      for (row in 0...(segments + 1))
      {
        var along:Float = fromPixel + step * row;
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
    for (h in 0...holds.length)
    {
      var hold:SustainTrail = holds[h];
      var first:Int = holdFirstRow[h];
      var bodyRows:Int = holdBodyRows[h];
      var last:Int = first + bodyRows - 1;
      // A trail is one mesh, so it takes its width from the head rather than
      // narrowing partway down.
      var halfWidth:Float = holdHalfWidth[h] * scaleX[first];

      var capTop:Int = first + bodyRows;
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

      for (row in 0...bodyRows)
      {
        var here:Int = first + row;
        widenRow(row, here, (here == first) ? here : here - 1, (here == last) ? here : here + 1, halfWidth);
        colorRow(row, here);
      }
      for (row in bodyRows...BODY_ROWS)
        colorRow(row, last);

      widenRow(BODY_ROWS, capTop, last, capBottom, halfWidth);
      widenRow(BODY_ROWS + 1, capBottom, last, capBottom, halfWidth);
      colorRow(BODY_ROWS, capTop);
      colorRow(BODY_ROWS + 1, capBottom);

      writeTrailUVs(h, bodyRows);

      hold.x = 0;
      hold.y = 0;
      hold.offset.set(0, 0);
      hold.scrollFactor.set(0, 0);

      if (hold.vertices.length != vertexBuffer.length) hold.setVertices(vertexBuffer.copy());
      else hold.setVertices(vertexBuffer);

      if (hold.uvtData.length != uvBuffer.length) hold.setUVTData(uvBuffer.copy());
      else hold.setUVTData(uvBuffer);

      if (hold.indices.length != indexBuffer.length) hold.setIndices(indexBuffer.copy());

      if (hold.vertexColors == null || hold.vertexColors.length != colorBuffer.length) hold.setVertexColors(colorBuffer.copy());
      else hold.setVertexColors(colorBuffer);

      hold.visible = true;
      // Opacity is already carried per vertex, so the transform only tints.
      tintAt(hold, first, 1);
    }
  }

  /**
   * Moves the two vertices of a trail row outwards by halfWidth, along the normal to the line between the previous and next row.
   */
  function colorRow(row:Int, at:Int):Void
  {
    var opacity:Float = alpha[at];
    if (opacity < 0) opacity = 0;
    else if (opacity > 1) opacity = 1;

    var packed:Int = (Std.int(opacity * 255) << 24) | 0xFFFFFF;
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

    var at:Int = row * 4;
    movePoint(x + normalX * halfWidth, y + normalY * halfWidth);
    vertexBuffer[at] = screenX;
    vertexBuffer[at + 1] = screenY;
    movePoint(x - normalX * halfWidth, y - normalY * halfWidth);
    vertexBuffer[at + 2] = screenX;
    vertexBuffer[at + 3] = screenY;
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

    var lastV:Float = (holdToPixel[h] - bodyLength) * inverseHeight;
    var last:Int = (bodyRows - 1) * 4;
    for (row in bodyRows...BODY_ROWS)
    {
      var at:Int = row * 4;
      vertexBuffer[at] = vertexBuffer[last];
      vertexBuffer[at + 1] = vertexBuffer[last + 1];
      vertexBuffer[at + 2] = vertexBuffer[last + 2];
      vertexBuffer[at + 3] = vertexBuffer[last + 3];
      uvBuffer[at] = left;
      uvBuffer[at + 1] = lastV;
      uvBuffer[at + 2] = right;
      uvBuffer[at + 3] = lastV;
    }

    var capLeft:Float = right;
    var capRight:Float = right + 0.125;

    var capTop:Int = BODY_ROWS * 4;
    uvBuffer[capTop] = capLeft;
    uvBuffer[capTop + 1] = holdCapTopV[h];
    uvBuffer[capTop + 2] = capRight;
    uvBuffer[capTop + 3] = holdCapTopV[h];

    var capBottom:Int = (BODY_ROWS + 1) * 4;
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
      receptor.scale.set(baseReceptorScaleX, baseReceptorScaleY);
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
      note.scale.set(baseNoteScaleX, baseNoteScaleY);
      clearTint(note);
    }

    var holdMembers = strumline.holdNotes.members;
    for (index in 0...holdMembers.length)
    {
      var hold:SustainTrail = holdMembers[index];
      if (hold == null) continue;

      // Handing the mesh back rebuilds its vertices from the sustain again.
      hold.customVertexData = false;
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
