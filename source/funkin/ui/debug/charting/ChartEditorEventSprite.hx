package funkin.ui.debug.charting;

import funkin.play.event.SongEventData.SongEventParser;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import openfl.utils.Assets;
import flixel.FlxObject;
import flixel.FlxBasic;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxTileFrames;
import flixel.math.FlxPoint;
import funkin.play.song.SongData.SongEventData;

/**
 * A event sprite that can be used to display a song event in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
class ChartEditorEventSprite extends FlxSprite
{
  public static final DEFAULT_EVENT = 'Default';

  public var parentState:ChartEditorState;

  /**
   * The note data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var eventData(default, set):SongEventData;

  /**
   * The image used for all song events. Cached for performance.
   */
  static var eventSpriteBasic:BitmapData;

  public function new(parent:ChartEditorState)
  {
    super();

    this.parentState = parent;

    this.frames = buildFrames();

    buildAnimations();
    refresh();
  }

  /**
   * Build a set of animations to allow displaying different types of chart events.
   * @param force `true` to force rebuilding the frames.
   */
  static function buildFrames(?force:Bool = false):FlxFramesCollection
  {
    static var eventFrames:FlxFramesCollection = null;

    if (eventFrames != null && !force) return eventFrames;
    eventFrames = new FlxAtlasFrames(null);

    // Push the default event as a frame.
    var defaultFrames:FlxAtlasFrames = Paths.getSparrowAtlas('ui/chart-editor/events/$DEFAULT_EVENT');
    defaultFrames.parent.persist = true;
    for (frame in defaultFrames.frames)
    {
      eventFrames.pushFrame(frame);
    }

    // Push all the other events as frames.
    for (eventName in SongEventParser.listEventIds())
    {
      var exists:Bool = Assets.exists(Paths.image('ui/chart-editor/events/$eventName'));
      if (!exists) continue; // No graphic for this event.

      var frames:FlxAtlasFrames = Paths.getSparrowAtlas('ui/chart-editor/events/$eventName');
      if (frames == null) continue; // Could not load graphic for this event.

      frames.parent.persist = true;
      for (frame in frames.frames)
      {
        eventFrames.pushFrame(frame);
      }
    }

    return eventFrames;
  }

  function buildAnimations():Void
  {
    var eventNames:Array<String> = [DEFAULT_EVENT].concat(SongEventParser.listEventIds());
    for (eventName in eventNames)
    {
      this.animation.addByPrefix(eventName, '${eventName}0', 24, false);
    }
  }

  public function correctAnimationName(name:String):String
  {
    if (this.animation.exists(name)) return name;
    trace('Warning: Invalid animation name "' + name + '" for song event. Using "${DEFAULT_EVENT}"');
    return DEFAULT_EVENT;
  }

  public function playAnimation(name:String):Void
  {
    var correctedName = correctAnimationName(name);
    this.animation.play(correctedName);
    refresh();
  }

  function refresh():Void
  {
    setGraphicSize(ChartEditorState.GRID_SIZE);
    this.updateHitbox();
  }

  function set_eventData(value:SongEventData):SongEventData
  {
    this.eventData = value;

    if (this.eventData == null)
    {
      // Disown parent. MAKE SURE TO REVIVE BEFORE REUSING
      this.kill();
      return this.eventData;
    }

    this.visible = true;
    playAnimation(this.eventData.event);
    // Update the position to match the note data.
    updateEventPosition();

    return this.eventData;
  }

  public function updateEventPosition(?origin:FlxObject)
  {
    this.x = (ChartEditorState.STRUMLINE_SIZE * 2 + 1 - 1) * ChartEditorState.GRID_SIZE;
    if (this.eventData.stepTime >= 0) this.y = this.eventData.stepTime * ChartEditorState.GRID_SIZE;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  /**
   * Return whether this event is currently visible.
   */
  public function isEventVisible(viewAreaBottom:Float, viewAreaTop:Float):Bool
  {
    // True if the note is above the view area.
    var aboveViewArea = (this.y + this.height < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (this.y > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }

  /**
   * Return whether an event, if placed in the scene, would be visible.
   */
  public static function wouldEventBeVisible(viewAreaBottom:Float, viewAreaTop:Float, eventData:SongEventData, ?origin:FlxObject):Bool
  {
    var noteHeight:Float = ChartEditorState.GRID_SIZE;
    var notePosY:Float = eventData.stepTime * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }
}
