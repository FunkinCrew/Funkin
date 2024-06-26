package funkin.play.notes;

import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.NoteDirection;
import funkin.data.song.SongData.SongNoteData;
import flixel.util.FlxDirectionFlags;
import flixel.FlxSprite;
import flixel.graphics.FlxGraphic;
import flixel.graphics.tile.FlxDrawTrianglesItem;
import flixel.math.FlxMath;
import funkin.ui.options.PreferencesMenu;

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
   * A `Vector` of floats where each pair of numbers is treated as a coordinate location (an x, y pair).
   */
  public var vertices:DrawData<Float> = new DrawData<Float>();

  /**
   * A `Vector` of integers or indexes, where every three indexes define a triangle.
   */
  public var indices:DrawData<Int> = new DrawData<Int>();

  /**
   * A `Vector` of normalized coordinates used to apply texture mapping.
   */
  public var uvtData:DrawData<Float> = new DrawData<Float>();

  private var processedGraphic:FlxGraphic;

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

  /**
   * Normally you would take strumTime:Float, noteData:Int, sustainLength:Float, parentNote:Note (?)
   * @param NoteData
   * @param SustainLength Length in milliseconds.
   * @param fileName
   */
  public function new(noteDirection:NoteDirection, sustainLength:Float, noteStyle:NoteStyle)
  {
    super(0, 0, noteStyle.getHoldNoteAssetPath());

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
    // calls updateColorTransform(), which initializes processedGraphic!
    updateColorTransform();

    updateClipping();
    // indices = new DrawData<Int>(12, true, TRIANGLE_VERTEX_INDICES);

    this.active = true; // This NEEDS to be true for the note to be drawn!
  }

  function getBaseScrollSpeed()
  {
    return (PlayState.instance?.currentChart?.scrollSpeed ?? 1.0);
  }

  var previousScrollSpeed:Float = 1;

  override function update(elapsed)
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
   * @param	scroll		The current scroll speed.
   */
  public static inline function sustainHeight(susLength:Float, scroll:Float)
  {
    return (susLength * 0.45 * scroll);
  }

  function set_sustainLength(s:Float):Float
  {
    if (s < 0.0) s = 0.0;

    if (sustainLength == s) return s;
    this.sustainLength = s;
    updateDrawData();
    return this.sustainLength;
  }

  function updateDrawData()
  {
    graphicHeight = sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0);
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

  /**
   * Sets up new vertex, uv and index data for drawing the trail.
   */
  public function updateClipping():Void
  {
    var songTime:Float = Conductor.instance.songPosition;

    var clipHeight:Float = FlxMath.bound(sustainHeight(sustainLength, parentStrumline?.scrollSpeed ?? 1.0), 0, graphicHeight);
    if (clipHeight <= 0.1)
    {
      visible = false;
      return;
    }
    else
    {
      visible = true;
    }

    var segmentIntervalMs:Float = Conductor.instance.stepLengthMs / 4 / (parentStrumline?.scrollSpeed ?? 1.0);
    var segmentIntervalHeight:Float = sustainHeight(segmentIntervalMs, parentStrumline?.scrollSpeed ?? 1.0);
    var remainingSusHeight:Float = graphicHeight;
    var index:Int = 0;
    var indicesIndex:Int = 0;

    var newSegment:Bool = true;

    vertices.splice(0, vertices.length);
    uvtData.splice(0, uvtData.length);
    indices.splice(0, indices.length);

    var sustainTime:Float = songTime - strumTime - (fullSustainLength - sustainLength);

    while (true)
    {
      var testOffset:Float = Math.sin(sustainTime * 0.01) * 30;

      // left vertex
      vertices[index + 0] = 0.0 + testOffset; // x
      vertices[index + 1] = graphicHeight - remainingSusHeight; // y

      // right vertex
      vertices[index + 2] = graphicWidth + testOffset; // x
      vertices[index + 3] = vertices[index + 1]; // y

      // left uv
      uvtData[index + 0] = 1 / 4 * (noteDirection % 4); // x
      uvtData[index + 1] = ((graphicHeight - remainingSusHeight - clipHeight) / graphic.height) / zoom; // y

      // right uv
      uvtData[index + 2] = uvtData[index + 0] + (1 / 8); // x
      uvtData[index + 3] = uvtData[index + 1]; // y

      if (!newSegment)
      {
        var vertexIndex:Int = Std.int(index / 2);
        indices[indicesIndex + 0] = vertexIndex - 2; // top left
        indices[indicesIndex + 1] = vertexIndex - 1; // top right
        indices[indicesIndex + 2] = vertexIndex; // bottom left

        indices[indicesIndex + 3] = vertexIndex - 1; // top right
        indices[indicesIndex + 4] = vertexIndex; // bottom left
        indices[indicesIndex + 5] = vertexIndex + 1; // bottom right

        indicesIndex += 6;
      }

      if (remainingSusHeight == 0)
      {
        break;
      }

      newSegment = false;

      index += 4;
      remainingSusHeight = Math.max(remainingSusHeight - segmentIntervalHeight, 0);
      sustainTime = Math.max(sustainTime - segmentIntervalMs, songTime - strumTime - (fullSustainLength - sustainLength) - sustainLength);
    }
  }

  @:access(flixel.FlxCamera)
  override public function draw():Void
  {
    if (alpha == 0 || graphic == null || vertices == null) return;

    for (camera in cameras)
    {
      if (!camera.visible || !camera.exists) continue;
      // if (!isOnScreen(camera)) continue; // TODO: Update this code to make it work properly.

      getScreenPosition(_point, camera).subtractPoint(offset);
      camera.drawTriangles(processedGraphic, vertices, indices, uvtData, null, _point, blend, true, antialiasing);
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
    vertices = null;
    indices = null;
    uvtData = null;
    processedGraphic.destroy();

    super.destroy();
  }

  override function updateColorTransform():Void
  {
    super.updateColorTransform();
    if (processedGraphic != null) processedGraphic.destroy();
    processedGraphic = FlxGraphic.fromGraphic(graphic, true);
    processedGraphic.bitmap.colorTransform(processedGraphic.bitmap.rect, colorTransform);
  }
}
