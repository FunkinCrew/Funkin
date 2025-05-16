package funkin.ui.debug.charting.components;

import funkin.data.event.SongEventRegistry;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.tooltips.ToolTipRegionOptions;
import funkin.util.HaxeUIUtil;
import haxe.ui.tooltips.ToolTipManager;

/**
 * A sprite that can be used to display a song event in a chart.
 * Designed to be used and reused efficiently. Has no gameplay functionality.
 */
@:nullSafety
class ChartEditorEventSprite extends FlxSprite
{
  public static final DEFAULT_EVENT = 'Default';

  public var parentState:ChartEditorState;

  /**
   * The note data that this sprite represents.
   * You can set this to null to kill the sprite and flag it for recycling.
   */
  public var eventData(default, set):Null<SongEventData> = null;

  /**
   * The image used for all song events. Cached for performance.
   */
  static var eventSpriteBasic:Null<BitmapData> = null;

  public var overrideStepTime(default, set):Null<Float> = null;

  public var tooltip:ToolTipRegionOptions;

  /**
   * Whether this sprite is a "ghost" sprite used when hovering to place a new event.
   */
  public var isGhost:Bool = false;

  function set_overrideStepTime(value:Null<Float>):Null<Float>
  {
    if (overrideStepTime == value) return overrideStepTime;

    overrideStepTime = value;
    updateEventPosition();
    return overrideStepTime;
  }

  public function new(parent:ChartEditorState, isGhost:Bool = false)
  {
    super();

    this.parentState = parent;
    this.isGhost = isGhost;

    this.tooltip = HaxeUIUtil.buildTooltip('N/A');
    this.frames = buildFrames();

    buildAnimations();
    refresh();
  }

  static var eventFrames:Null<FlxFramesCollection> = null;

  /**
   * Build a set of animations to allow displaying different types of chart events.
   * @param force `true` to force rebuilding the frames.
   */
  static function buildFrames(force:Bool = false):FlxFramesCollection
  {
    if (eventFrames != null && !force) return eventFrames;

    initEmptyEventFrames();
    if (eventFrames == null) throw 'Failed to initialize empty event frames.';

    // Push the default event as a frame.
    var defaultFrames:FlxAtlasFrames = Paths.getSparrowAtlas('ui/chart-editor/events/$DEFAULT_EVENT');
    defaultFrames.parent.persist = true;
    for (frame in defaultFrames.frames)
    {
      eventFrames.pushFrame(frame);
    }

    // Push all the other events as frames.
    for (eventName in SongEventRegistry.listEventIds())
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

  @:nullSafety(Off)
  static function initEmptyEventFrames():Void
  {
    eventFrames = new FlxAtlasFrames(null);
  }

  function buildAnimations():Void
  {
    var eventNames:Array<String> = [DEFAULT_EVENT].concat(SongEventRegistry.listEventIds());
    for (eventName in eventNames)
    {
      this.animation.addByPrefix(eventName, '${eventName}0', 24, false);
    }
  }

  public function correctAnimationName(name:String):String
  {
    if (this.animation.exists(name)) return name;
    return DEFAULT_EVENT;
  }

  public function playAnimation(?name:String):Void
  {
    if (name == null) name = eventData?.eventKind ?? DEFAULT_EVENT;

    var correctedName = correctAnimationName(name);
    this.animation.play(correctedName);
    refresh();
  }

  function refresh():Void
  {
    setGraphicSize(ChartEditorState.GRID_SIZE);
    this.updateHitbox();
  }

  function set_eventData(value:Null<SongEventData>):Null<SongEventData>
  {
    if (value == null)
    {
      this.eventData = null;
      // Disown parent. MAKE SURE TO REVIVE BEFORE REUSING
      this.kill();
      this.visible = false;
      updateTooltipPosition();
      return null;
    }
    else
    {
      this.visible = true;
      playAnimation(value.eventKind);
      this.eventData = value;
      // Update the position to match the note data.
      updateEventPosition();
      updateTooltipText();
      return this.eventData;
    }
  }

  public function updateEventPosition(?origin:FlxObject)
  {
    if (this.eventData == null) return;

    this.x = (ChartEditorState.STRUMLINE_SIZE * 2 + 1 - 1) * ChartEditorState.GRID_SIZE;

    var stepTime:Float = (overrideStepTime != null) ? overrideStepTime : eventData.getStepTime();
    this.y = stepTime * ChartEditorState.GRID_SIZE;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }

    this.updateTooltipPosition();
  }

  public function updateTooltipText():Void
  {
    if (this.eventData == null) return;
    if (this.isGhost) return;
    this.tooltip.tipData = {text: this.eventData.buildTooltip()};
  }

  public function updateTooltipPosition():Void
  {
    // No tooltip for ghost sprites.
    if (this.isGhost) return;

    if (this.eventData == null)
    {
      // Disable the tooltip.
      ToolTipManager.instance.unregisterTooltipRegion(this.tooltip);
    }
    else
    {
      // Update the position.
      this.tooltip.left = this.x;
      this.tooltip.top = this.y;
      this.tooltip.width = this.width;
      this.tooltip.height = this.height;

      // Enable the tooltip.
      ToolTipManager.instance.registerTooltipRegion(this.tooltip);
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
    var notePosY:Float = eventData.getStepTime() * ChartEditorState.GRID_SIZE;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }
}
