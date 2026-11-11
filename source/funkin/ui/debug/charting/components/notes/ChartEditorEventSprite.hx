package funkin.ui.debug.charting.components.notes;

#if FEATURE_CHART_EDITOR
import funkin.data.event.SongEventRegistry;
import flixel.graphics.frames.FlxAtlasFrames;
import openfl.display.BitmapData;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFramesCollection;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.tooltips.ToolTipRegionOptions;
import funkin.util.HaxeUIUtil;

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

  public var overlappingEventDatas(default, set):Null<Array<SongEventData>> = null;

  function set_overlappingEventDatas(value:Null<Array<SongEventData>>):Null<Array<SongEventData>>
  {
    overlappingEventDatas = value;
    updateTooltipText();
    return value;
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
    var defaultFrames:FlxAtlasFrames = Paths.getSparrowAtlas('ui/editors/chart-editor/events/$DEFAULT_EVENT');
    defaultFrames.parent.persist = true;
    for (frame in defaultFrames.frames)
    {
      eventFrames.pushFrame(frame);
    }

    // Push all the other events as frames.
    for (eventName in SongEventRegistry.listEventIds())
    {
      var exists:Bool = Assets.exists(Paths.image('ui/editors/chart-editor/events/$eventName'));
      if (!exists) continue; // No graphic for this event.

      var frames:FlxAtlasFrames = Paths.getSparrowAtlas('ui/editors/chart-editor/events/$eventName');
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
    if (this.animation.name == correctedName) return;
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

    var overrideStep:Null<Float> = overrideStepTime;
    var posY:Float = (overrideStep != null) ? ChartEditorTimeScale.stepToPixels(overrideStep) : ChartEditorTimeScale.timeToPixels(eventData.time, eventData.getStepTime());
    this.y = posY - ChartEditorState.GRID_SIZE / 2;

    if (origin != null)
    {
      this.x += origin.x;
      this.y += origin.y;
    }
  }

  public function updateTooltipText():Void
  {
    if (this.eventData == null) return;
    if (this.isGhost) return;

    var tooltipText:String = '';
    if (overlappingEventDatas == null || overlappingEventDatas.length == 0)
    {
      tooltipText = this.eventData.buildTooltip();
    }
    else
    {
      var chain:Array<SongEventData> = overlappingEventDatas.copy();
      var self:Null<SongEventData> = this.eventData;
      if (self != null) chain.unshift(self);
      tooltipText = 'Event Chain (${chain.length} events)';
      static var MAX_EVENT_LIMIT = 8;
      for (i in 0...chain.length)
      {
        if (i >= MAX_EVENT_LIMIT)
        {
          tooltipText += '\n... and ${chain.length - MAX_EVENT_LIMIT} more';
          break;
        }
        tooltipText += '\n${i + 1}. ${chain[i].buildTooltip().split('\n')[0]}';
      }
    }
    this.tooltip.tipData = {
      text: tooltipText
    };
  }

  override public function kill()
  {
    super.kill();

    overlappingEventDatas = null;
  }

  /**
   * Shows how many events are in a chain, in the corner of the sprite.
   */
  var chainCountText:Null<FlxText> = null;

  /**
   * The tag drawn on Custom Events.
   */
  var customEventTagText:Null<FlxText> = null;

  override public function destroy():Void
  {
    chainCountText?.destroy();
    chainCountText = null;
    customEventTagText?.destroy();
    customEventTagText = null;
    super.destroy();
  }

  override public function draw():Void
  {
    super.draw();

    drawCustomEventTag();

    var count:Int = (overlappingEventDatas?.length ?? 0) + 1;
    if (count < 2 || isGhost) return;

    var text:Null<FlxText> = chainCountText;
    if (text == null)
    {
      text = new haxe.ui.backend.flixel.HiResFlxText(0, 0, 0, '', 16);
      text.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      chainCountText = text;
    }
    text.text = 'x$count';
    text.cameras = this.cameras;
    text.x = this.x + this.width - text.width + 4;
    text.y = this.y + this.height - text.height + 4;
    text.draw();
  }

  function drawCustomEventTag():Void
  {
    if (eventData?.eventKind != funkin.play.event.CustomSongEvent.KIND) return;
    var tag:String = funkin.play.event.CustomSongEvent.tagFor(eventData?.getString('name'));
    if (tag.length == 0) return;

    var text:Null<FlxText> = customEventTagText;
    if (text == null)
    {
      text = new haxe.ui.backend.flixel.HiResFlxText(0, 0, 0, '', 24);
      text.setFormat(funkin.assets.Paths.font('ui/fonts/VCR OSD Mono'), 24, FlxColor.WHITE, CENTER, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
      customEventTagText = text;
    }
    if (text.text != tag) text.text = tag;
    text.cameras = this.cameras;
    text.alpha = this.alpha;
    text.x = this.x + (this.width - text.width) / 2;
    text.y = this.y + (this.height - text.height) / 2;
    text.draw();
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
    var notePosY:Float = ChartEditorTimeScale.timeToPixels(eventData.time, eventData.getStepTime()) - noteHeight / 2;
    if (origin != null) notePosY += origin.y;

    // True if the note is above the view area.
    var aboveViewArea = (notePosY + noteHeight < viewAreaTop);

    // True if the note is below the view area.
    var belowViewArea = (notePosY > viewAreaBottom);

    return !aboveViewArea && !belowViewArea;
  }
}
#end
