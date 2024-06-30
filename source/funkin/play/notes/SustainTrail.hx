package funkin.play.notes;

import flixel.graphics.frames.FlxFrame;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.NoteDirection;
import funkin.data.song.SongData.SongNoteData;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;
import funkin.ui.options.PreferencesMenu;
import funkin.util.MathUtil;
import funkin.play.notes.modifier.NotePath;
import funkin.play.notes.modifier.DirectionalPathModifier;
import lime.math.Vector2;

/**
 * This is based heavily on the `FlxStrip` class. It uses `drawTriangles()` to clip a sustain note
 * trail at a certain time.
 * The whole `FlxGraphic` is used as a texture map. See the `NOTE_hold_assets.fla` file for specifics
 * on how it should be constructed.
 *
 * @author MtH
 */
@:allow(funkin.play.notes.Strumline)
class SustainTrail extends FlxSprite
{
  public var strumTime:Float = 0; // millis
  public var noteDirection:NoteDirection = 0;
  public var sustainLength(default, set):Float = 0; // millis
  public var fullSustainLength:Float = 0;
  public var noteData:Null<SongNoteData>;
  public var parentStrumline:Strumline;

  public var notePath(default, set):NotePath;

  function set_notePath(value:NotePath):NotePath
  {
    if (this.notePath == value)
    {
      return value;
    }

    this.notePath = value;
    this.updateDrawData();
    return value;
  }

  public var cover:NoteHoldCover = null;

  /**
   * Set to `true` if the user hit the note and is currently holding the sustain.
   * Should display associated effects.
   */
  public var hitNote:Bool = false;

  /**
   * Set to `true` if the user missed the note or released the sustain.
   * Should make the trail transparent.
   */
  public var missedNote:Bool = false;

  /**
   * Set to `true` after handling additional logic for missing notes.
   */
  public var handledMiss:Bool = false;

  // maybe BlendMode.MULTIPLY if missed somehow, drawTriangles does not support!

  /**
   *
   */
  private var zoom:Float = 1;

  /**
   * What part of the trail's end actually represents the end of the note.
   * This can be used to have a little bit sticking out.
   */
  public var endOffset:Float = 0.5; // 0.73 is roughly the bottom of the sprite in the normal graphic!

  /**
   * At what point the bottom for the trail's end should be clipped off.
   * Used in cases where there's an extra bit of the graphic on the bottom to avoid antialiasing issues with overflow.
   */
  public var bottomClip:Float = 0.9;

  public var isPixel:Bool;

  var graphicWidth:Float = 0;
  var graphicHeight:Float = 0;

  var holdTrailData:TrailData;
  var endTrailData:TrailData;

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle)
  {
    super(-9999, -9999);

    var paths:Array<String> = noteStyle._data?.assets?.holdNote?.assetPath.split(Constants.LIBRARY_SEPARATOR);
    var key:String = "";
    var library:Null<String> = null;
    if (paths.length == 1)
    {
      key = paths[0];
    }
    else
    {
      key = paths[1];
      library = paths[0];
    }

    frames = Paths.getSparrowAtlas(key, library);
    animation.addByPrefix('${NoteDirection.LEFT.name} hold piece', 'purple hold piece', 0, false);
    animation.addByPrefix('${NoteDirection.LEFT.name} hold end', 'purple hold end', 0, false);
    animation.addByPrefix('${NoteDirection.DOWN.name} hold piece', 'blue hold piece', 0, false);
    animation.addByPrefix('${NoteDirection.DOWN.name} hold end', 'blue hold end', 0, false);
    animation.addByPrefix('${NoteDirection.UP.name} hold piece', 'green hold piece', 0, false);
    animation.addByPrefix('${NoteDirection.UP.name} hold end', 'green hold end', 0, false);
    animation.addByPrefix('${NoteDirection.RIGHT.name} hold piece', 'red hold piece', 0, false);
    animation.addByPrefix('${NoteDirection.RIGHT.name} hold end', 'red hold end', 0, false);

    antialiasing = true;

    this.isPixel = noteStyle.isHoldNotePixel();
    if (isPixel)
    {
      endOffset = bottomClip = 1;
      antialiasing = false;
    }
    zoom *= noteStyle.fetchHoldNoteScale();

    // BASIC SETUP
    this.sustainLength = sustainLength;
    this.fullSustainLength = sustainLength;
    this.noteDirection = noteDirection;

    zoom *= 0.7;

    // CALCULATE SIZE
    graphicWidth = graphic.width / 8 * zoom; // amount of notes * 2
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
    // instead of scrollSpeed, PlayState.SONG.speed

    flipY = Preferences.downscroll;

    // alpha = 0.6;
    alpha = 1.0;

    updateDrawData();

    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  function getBaseScrollSpeed():Float
  {
    return PlayState.instance?.currentChart?.scrollSpeed ?? 1.0;
  }

  var previousScrollSpeed:Float = 1;

  override function update(elapsed):Void
  {
    super.update(elapsed);
    if (previousScrollSpeed != (parentStrumline?.scrollSpeed ?? 1.0))
    {
      updateDrawData();
    }
    previousScrollSpeed = parentStrumline?.scrollSpeed ?? 1.0;
  }

  /**
   * Calculates height of a sustain note for a given length (milliseconds) and scroll speed.
   * @param	susLength	The length of the sustain note in milliseconds.
   * @param	scroll    The current scroll speed.
   */
  public static inline function sustainHeight(susLength:Float, scroll:Float):Float
  {
    return susLength * Constants.PIXELS_PER_MS * scroll;
  }

  function set_sustainLength(s:Float):Float
  {
    if (s < 0.0) s = 0.0;

    if (sustainLength == s) return s;
    this.sustainLength = s;
    updateDrawData();
    return this.sustainLength;
  }

  function updateDrawData():Void
  {
    updateClipping();
    updateHitbox();
  }

  public override function updateHitbox():Void
  {
    width = graphicWidth;
    height = graphicHeight;
    offset.set(0, 0);
    origin.set(width * 0.5, height * 0.5);
  }

  function wrap(value:Float, min:Float, max:Float):Float
  {
    var range:Float = max - min;
    return min + ((value - min) - (range * Math.floor((value - min) / range)));
  }

  /**
   * Sets up new vertex, uv and index data for drawing the trail.
   */
  public function updateClipping():Void
  {
    if (notePath == null)
    {
      visible = false;
      return;
    }

    final scrollSpeed:Float = parentStrumline?.scrollSpeed ?? 1.0;
    graphicHeight = sustainHeight(sustainLength, scrollSpeed);

    if (graphicHeight <= 0.1)
    {
      visible = false;
      return;
    }

    visible = true;

    var songTime:Float = Conductor.instance.songPosition;

    final frameIndex:Int = animation.getByName('${noteDirection.name} hold piece').frames[0];
    final holdTrailFrame:FlxFrame = frames.getByIndex(frameIndex);
    final holdTrailGraphic:FlxGraphic = FlxGraphic.fromFrame(holdTrailFrame);

    final frameIndex:Int = animation.getByName('${noteDirection.name} hold end').frames[0];
    final endTrailFrame:FlxFrame = frames.getByIndex(frameIndex);
    final endTrailGraphic:FlxGraphic = FlxGraphic.fromFrame(endTrailFrame);

    if (holdTrailGraphic == null || endTrailGraphic == null)
    {
      trace("FRAMES ARE NULL!");
      return;
    }

    graphicWidth = holdTrailGraphic.width * zoom;

    final sliceIntervalMs:Float = Conductor.instance.stepLengthMs * Preferences.trailQuality.getMultiplier() / scrollSpeed;

    final endTrailHeightCap:Float = Math.max(graphicHeight - endTrailGraphic.height * zoom, 0);

    final endTrailTime:Float = (strumTime - songTime) + (fullSustainLength - sustainLength) + sustainLength;
    final endTrailTimeCap:Float = endTrailTime - (graphicHeight - endTrailHeightCap) / Constants.PIXELS_PER_MS / scrollSpeed;

    endTrailData = sliceTrailPart(endTrailGraphic, graphicHeight, endTrailHeightCap, endTrailTime, endTrailTimeCap, sliceIntervalMs);

    final trailTimeCap:Float = (strumTime - songTime) + (fullSustainLength - sustainLength);

    holdTrailData = sliceTrailPart(holdTrailGraphic, endTrailHeightCap, 0, endTrailTimeCap, trailTimeCap, sliceIntervalMs);
  }

  function sliceTrailPart(graphic:FlxGraphic, trailHeight:Float, trailHeightCap:Float, trailTime:Float, trailTimeCap:Float, sliceIntervalMs:Float):TrailData
  {
    if (trailHeight <= trailHeightCap)
    {
      return null;
    }

    var data:TrailData =
      {
        vertices: new DrawData<Float>(),
        uvs: new DrawData<Float>(),
        indices: new DrawData<Int>(),
        graphic: graphic
      };

    final scrollSpeed:Float = parentStrumline?.scrollSpeed ?? 1.0;

    final sliceIntervalHeight:Float = sustainHeight(sliceIntervalMs, scrollSpeed);
    final receptor:Null<StrumlineNote> = parentStrumline?.getByDirection(noteDirection);
    final targetX:Float = (receptor != null ? (receptor.x + receptor.width / 2) : 0);
    final targetY:Float = (receptor != null ? (receptor.y + receptor.height / 2) : 0);

    var remainingTrailHeight:Float = trailHeight;

    final bruhTransform:NoteTransform = notePath.calculateTransform(trailTime + 0.1, scrollSpeed, targetX, targetY);
    var previousX:Float = bruhTransform.x;
    var previousY:Float = bruhTransform.y;
    while (true)
    {
      final vertexIndex:Int = data.vertices.length;
      final indicesIndex:Int = data.indices.length;

      final testOffset:Float = Math.sin(trailTime * 0.01) * 0;

      final transform:NoteTransform = notePath.calculateTransform(trailTime, scrollSpeed, targetX, targetY);
      var direction:Vector2 = new Vector2(transform.x - previousX, transform.y - previousY);
      direction.normalize(1);

      final offsetX:Float = -direction.y * (graphicWidth / 2);
      final offsetY:Float = direction.x * (graphicWidth / 2);

      previousX = transform.x;
      previousY = transform.y;

      // left vertex
      data.vertices[vertexIndex + 0] = transform.x - offsetX; // x
      data.vertices[vertexIndex + 1] = transform.y - offsetY; // y

      // right vertex
      data.vertices[vertexIndex + 2] = transform.x + offsetX; // x
      data.vertices[vertexIndex + 3] = transform.y + offsetY; // y

      // left uv
      data.uvs[vertexIndex + 0] = 0.0; // x
      data.uvs[vertexIndex + 1] = 1.0 - (trailHeight - remainingTrailHeight) / graphic.height / zoom; // y

      // right uv
      data.uvs[vertexIndex + 2] = 1.0; // x
      data.uvs[vertexIndex + 3] = data.uvs[vertexIndex + 1]; // y

      if (vertexIndex > 0)
      {
        final topVertexIndex:Int = Std.int(vertexIndex / 2);
        final bottomVertexIndex:Int = topVertexIndex - 2;

        data.indices[indicesIndex + 0] = topVertexIndex + 0; // top left
        data.indices[indicesIndex + 1] = topVertexIndex + 1; // top right
        data.indices[indicesIndex + 2] = bottomVertexIndex + 0; // bottom left

        data.indices[indicesIndex + 3] = topVertexIndex + 1; // top right
        data.indices[indicesIndex + 4] = bottomVertexIndex + 1; // bottom right
        data.indices[indicesIndex + 5] = bottomVertexIndex + 0; // bottom left
      }

      if (remainingTrailHeight == trailHeightCap)
      {
        break;
      }

      remainingTrailHeight = Math.max(remainingTrailHeight - sliceIntervalHeight, trailHeightCap);
      trailTime = Math.max(trailTime - sliceIntervalMs, trailTimeCap);
    }

    return data;
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || (holdTrailData == null && endTrailData == null)) return;

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      getScreenPosition(_point, camera).subtractPoint(offset);

      if (endTrailData != null)
      {
        camera.drawTriangles(endTrailData.graphic, endTrailData.vertices, endTrailData.indices, endTrailData.uvs, null, _point, blend, false, antialiasing,
          colorTransform, shader);
      }

      if (holdTrailData != null)
      {
        camera.drawTriangles(holdTrailData.graphic, holdTrailData.vertices, holdTrailData.indices, holdTrailData.uvs, null, _point, blend, true, antialiasing,
          colorTransform, shader);
      }
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  public override function kill():Void
  {
    super.kill();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
  }

  public override function revive():Void
  {
    super.revive();

    strumTime = 0;
    noteDirection = 0;
    sustainLength = 0;
    fullSustainLength = 0;
    noteData = null;

    hitNote = false;
    missedNote = false;
    handledMiss = false;
  }

  override public function destroy():Void
  {
    holdTrailData = null;
    endTrailData = null;

    super.destroy();
  }
}

typedef TrailData =
{
  var vertices:DrawData<Float>;
  var uvs:DrawData<Float>;
  var indices:DrawData<Int>;
  var graphic:FlxGraphic;
}

abstract TrailQuality(String) from String to String
{
  public static final LOW:String = 'Low';
  public static final MEDIUM:String = 'Medium';
  public static final HIGH:String = 'High';

  /**
   * Get the value to multiply the sliceIntervalMs with
   * @return Float
   */
  public function getMultiplier():Float
  {
    switch (this)
    {
      case TrailQuality.LOW:
        return 1.0;
      case TrailQuality.MEDIUM:
        return 0.5;
      case TrailQuality.HIGH:
        return 0.25;
    }

    return 0.25;
  }
}
