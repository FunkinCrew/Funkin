package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.Conductor;
import funkin.graphics.shaders.TimelineShader;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.EventTimeline.TimelinePlaybackAutoScrollMode;
import funkin.ui.haxeui.components.editors.timeline.TimelineEvent.EventMoveDelta;
import funkin.ui.haxeui.components.editors.timeline.TimelineEventBlock.TimelineBlockHitZone;
import funkin.ui.haxeui.components.editors.timeline.TimelineEventBlock.TimelineDragMode;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.components.Image;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.MouseEvent;
import haxe.ui.core.Screen;
import haxe.ui.layouts.AbsoluteLayout;
import haxe.ui.layouts.DefaultLayout;
#if FEATURE_MACOS_GESTURES
import lime.ui.Gesture;
import lime.ui.Gesture.GestureType;
import funkin.input.macos.FunkinGesture;
import funkin.util.HaxeUIUtil;
#end

@:composite(TimelineViewportEvents, TimelineViewportBuilder, TimelineViewportLayout)
class TimelineViewport extends Box
{
  public var timelineShader:TimelineShader;

  public static inline var TOP_BAR_HEIGHT:Int = 30;
  public static inline var LAYER_HEIGHT:Int = 48;
  public static inline var MIN_LAYER_HEIGHT:Float = 28.0;
  public static inline var MAX_LAYER_HEIGHT:Float = 96.0;
  public static inline var LAYER_HEIGHT_WHEEL_STEP:Float = 6.0;
  public static inline var BLOCK_INSET:Float = 3.0;
  public static inline var MIN_BLOCK_WIDTH:Float = 10.0;
  public static inline var PIXELS_PER_STEP_BASE:Float = 12.0;
  public static inline var MIN_ZOOM:Float = 0.1;
  public static inline var MAX_ZOOM:Float = 10.0;
  public static inline var ZOOM_WHEEL_IN:Float = 1.25;
  public static inline var ZOOM_WHEEL_OUT:Float = 0.8;

  // How long the view takes to close half the distance to where the wheel sent it.
  public static inline var VIEW_EASE_HALF_LIFE:Float = 0.045;

  // A drag held near either side carries the view along at one steady pace.
  public static inline var EDGE_AUTOSCROLL_ZONE_PX:Float = 28.0;

  public static inline var EDGE_AUTOSCROLL_PX_PER_SEC:Float = 900.0;
  // The least a wheel notch moves the view along the song, as a share of what is on screen.
  public static inline var SCROLL_STEP_MIN_SHARE:Float = 0.1;
  public static inline var TRACKPAD_TIME_SCROLL_MULT:Float = 100.0;
  public static inline var TRACKPAD_LAYER_SCROLL_MULT:Float = 48.0;

  @:clonable @:behaviour(DataBehaviour, 0.0)
  public var scrollOffsetMs:Float;
  @:clonable @:behaviour(DataBehaviour, 1.0)
  public var zoomLevel:Float;
  @:clonable @:behaviour(DataBehaviour, 0.0)
  public var songPositionMs:Float;
  public var eventBlocks:Array<TimelineEventBlock> = [];
  public var layers:Array<TimelineLayerData> = [];
  public var selectedLayerIndex:Int = 0;
  public var stepLengthMs:Float = 125.0;
  public var conductor:Null<Conductor> = null;
  public var songLengthMs:Float = 0;
  public var beatsPerGroup:Int = 1;
  public var playhead:Box;
  public var playheadTopper:Box;
  public var selectionBoxOverlay:Box;
  public var contentArea:Box;

  public static inline var PLAYHEAD_LINE_WIDTH:Int = 2;
  public static inline var PLAYHEAD_TOPPER_WIDTH:Int = 14;
  public static inline var PLAYHEAD_TOPPER_HEIGHT:Int = 22;
  public static inline var SELECTION_DRAG_THRESHOLD_PX:Float = 4.0;

  public var layerScrollOffsetPx:Float = 0;
  public var layerHeight:Float = LAYER_HEIGHT;

  // Where the view is easing to. The wheel moves these and the view follows a frame or two behind.
  public var aimScrollOffsetMs:Float = 0;
  public var aimZoomLevel:Float = 1.0;
  public var aimLayerHeight:Float = LAYER_HEIGHT;

  @:noCompletion
  public var _easingScroll:Bool = false;
  @:noCompletion
  public var _easingZoom:Bool = false;

  // Where the zoom holds the song still, in steps, and where that point is on screen
  var _zoomAnchorSteps:Float = 0;
  var _zoomAnchorX:Float = 0;
  var _zoomAnchorPlayhead:Bool = false;

  // The scroll position in steps is asked for by every block each layout.
  var _scrollStepsCacheMs:Float = Math.NaN;
  var _scrollStepsCache:Float = 0;

  @:noCompletion
  public var _easingLayerHeight:Bool = false;
  public var aimLayerScrollOffsetPx:Float = 0;
  @:noCompletion
  public var _easingLayerScroll:Bool = false;

  // Whether a zoom holds the playhead still rather than the cursor.
  public var zoomToPlayhead:Bool = false;

  // Whether the view keeps the playhead in front of it while the song runs.
  // Scrolling turns it off, and the song leaving the view turns it back on.
  public var chasing:Bool = true;

  public var onRefresh:Void->Void;
  @:noCompletion
  public var _eventsInstance:TimelineViewportEvents;
  @:noCompletion
  public var _autoScrollDragActive:Bool = false;
  @:noCompletion
  public var _autoScrollScreenX:Float = 0;
  @:noCompletion
  public var _autoScrollScreenY:Float = 0;
  public var blockHeight(get, never):Float;

  function get_blockHeight():Float
  {
    return layerHeight - BLOCK_INSET * 2;
  }

  /**
   * Pixels per step before zoom.
   */
  public var pixelsPerStep(get, never):Float;

  function get_pixelsPerStep():Float
  {
    return PIXELS_PER_STEP_BASE;
  }

  public var pixelsPerBeat(get, never):Float;

  function get_pixelsPerBeat():Float
  {
    return PIXELS_PER_STEP_BASE * Constants.STEPS_PER_BEAT;
  }

  /**
   * Whether the conductor has time changes to follow.
   */
  function hasTimeChanges():Bool
  {
    if (conductor == null) return false;
    return @:privateAccess conductor.timeChanges.length > 0;
  }

  public function msToSteps(ms:Float):Float
  {
    if (!hasTimeChanges()) return stepLengthMs > 0 ? ms / stepLengthMs : 0;
    return conductor.getTimeInSteps(ms);
  }

  public function stepsToMs(steps:Float):Float
  {
    if (!hasTimeChanges()) return steps * stepLengthMs;
    return conductor.getStepTimeInMs(steps);
  }

  /**
   * How long a step is at the given time.
   */
  public function stepLengthAtMs(ms:Float):Float
  {
    if (!hasTimeChanges()) return stepLengthMs;
    return conductor.getTypeLengthAtMs(ms, 'step');
  }

  /**
   * Where an event ends, in song time (time change variant)
   */
  public function eventEndMs(event:SongEventData):Float
  {
    return event.time + TimelineUtil.getEventDurationSteps(event) * stepLengthAtMs(event.time);
  }

  public function durationStepsBetween(startMs:Float, endMs:Float):Float
  {
    var stepMs:Float = stepLengthAtMs(startMs);
    return stepMs > 0 ? (endMs - startMs) / stepMs : 1.0;
  }

  public var scrollOffsetSteps(get, never):Float;

  function get_scrollOffsetSteps():Float
  {
    if (_scrollStepsCacheMs != scrollOffsetMs)
    {
      _scrollStepsCacheMs = scrollOffsetMs;
      _scrollStepsCache = msToSteps(scrollOffsetMs);
    }
    return _scrollStepsCache;
  }

  public function invalidateTimeCache():Void
  {
    _scrollStepsCacheMs = Math.NaN;
  }

  /**
   * A scroll offset in ms, plus a pixel offset, converted to a new scroll offset in ms.
   */
  public function offsetMsByPixels(ms:Float, px:Float, ?zoom:Float):Float
  {
    var pxPerStep:Float = pixelsPerStep * (zoom ?? zoomLevel);
    if (pxPerStep <= 0) return ms;
    return stepsToMs(msToSteps(ms) + px / pxPerStep);
  }

  public var totalLayerHeight(get, never):Float;

  function get_totalLayerHeight():Float
  {
    return layers.length * layerHeight;
  }

  public var viewableHeightPx(get, never):Float;

  function get_viewableHeightPx():Float
  {
    return Math.max(0, componentHeight - TOP_BAR_HEIGHT);
  }

  public var maxLayerScrollPx(get, never):Float;

  function get_maxLayerScrollPx():Float
  {
    var viewableHeight = componentHeight - TOP_BAR_HEIGHT;
    if (viewableHeight <= 0) return 0;
    // Reserve one row as a safety margin: componentHeight can over-report the
    // actually-rendered area when the timeline extends past the window edge.
    var safeViewable = viewableHeight - layerHeight;
    if (safeViewable < 0) safeViewable = 0;
    if (totalLayerHeight <= safeViewable) return 0;
    // Allow overshoot so the last row can scroll to the middle of the safe area.
    var max = totalLayerHeight - safeViewable / 2;
    return max > 0 ? max : 0;
  }

  public function msToPixelX(ms:Float):Float
  {
    return (msToSteps(ms) - scrollOffsetSteps) * pixelsPerStep * zoomLevel;
  }

  public function pixelXToMs(px:Float):Float
  {
    var denom = pixelsPerStep * zoomLevel;
    if (denom == 0) return scrollOffsetMs;
    return stepsToMs(scrollOffsetSteps + px / denom);
  }

  public function pixelYToLayerIndex(py:Float):Int
  {
    if (layers.length == 0) return 0;
    var idx = Std.int((py + layerScrollOffsetPx) / layerHeight);
    if (idx < 0) return 0;
    if (idx >= layers.length) return layers.length - 1;
    return idx;
  }

  public function ensureLayerVisible(layerIndex:Int):Void
  {
    if (layerIndex < 0 || layerIndex >= layers.length) return;
    var viewH = viewableHeightPx - layerHeight;
    if (viewH <= 0) return;

    var layerTop = layerIndex * layerHeight;
    var layerBottom = layerTop + layerHeight;
    var viewTop = layerScrollOffsetPx;
    var viewBottom = viewTop + viewH;

    if (layerTop < viewTop) layerScrollOffsetPx = layerTop;
    else if (layerBottom > viewBottom) layerScrollOffsetPx = layerBottom - viewH;

    refreshLayout();
  }

  public function tickEdgeAutoScroll(elapsed:Float):Void
  {
    _eventsInstance.tickEdgeAutoScroll(elapsed);
  }

  public function tick(elapsed:Float):Void
  {
    if (_easingScroll || _easingZoom || _easingLayerHeight || _easingLayerScroll)
    {
      var k:Float = Math.pow(0.5, elapsed / VIEW_EASE_HALF_LIFE);
      var changed:Bool = false;
      var zoomChanged:Bool = false;

      if (_easingZoom)
      {
        var newZoom:Float = aimZoomLevel + (zoomLevel - aimZoomLevel) * k;
        if (Math.abs(newZoom - aimZoomLevel) < 0.0001) newZoom = aimZoomLevel;
        if (newZoom != zoomLevel)
        {
          zoomLevel = newZoom;
          holdZoomAnchor();
          changed = true;
          zoomChanged = true;
        }
        if (newZoom == aimZoomLevel) _easingZoom = false;
      }

      if (_easingScroll)
      {
        var newScroll:Float = aimScrollOffsetMs + (scrollOffsetMs - aimScrollOffsetMs) * k;
        if (Math.abs(newScroll - aimScrollOffsetMs) < 0.01) newScroll = aimScrollOffsetMs;
        if (newScroll != scrollOffsetMs)
        {
          scrollOffsetMs = newScroll;
          changed = true;
        }
        if (newScroll == aimScrollOffsetMs) _easingScroll = false;
      }

      if (_easingLayerScroll)
      {
        var maxScroll:Float = maxLayerScrollPx;
        if (aimLayerScrollOffsetPx > maxScroll) aimLayerScrollOffsetPx = maxScroll;
        if (aimLayerScrollOffsetPx < 0) aimLayerScrollOffsetPx = 0;

        var newLayerScroll:Float = aimLayerScrollOffsetPx + (layerScrollOffsetPx - aimLayerScrollOffsetPx) * k;
        if (Math.abs(newLayerScroll - aimLayerScrollOffsetPx) < 0.01) newLayerScroll = aimLayerScrollOffsetPx;
        if (newLayerScroll != layerScrollOffsetPx)
        {
          layerScrollOffsetPx = newLayerScroll;
          changed = true;
        }
        if (newLayerScroll == aimLayerScrollOffsetPx) _easingLayerScroll = false;
      }

      if (_easingLayerHeight)
      {
        var newHeight:Float = aimLayerHeight + (layerHeight - aimLayerHeight) * k;
        if (Math.abs(newHeight - aimLayerHeight) < 0.01) newHeight = aimLayerHeight;
        if (newHeight != layerHeight)
        {
          // Refreshes the layout itself, so nothing is left for below.
          setLayerHeight(newHeight);
          changed = false;
        }
        if (newHeight == aimLayerHeight) _easingLayerHeight = false;
      }

      if (changed) refreshLayout();
      if (zoomChanged) dispatch(new TimelineEvent(TimelineEvent.ZOOM_CHANGED));
    }

    _eventsInstance.tickEdgeAutoScroll(elapsed);
  }

  /**
   * Stops a scroll ease in progress. Anything that puts the view somewhere directly calls this first.
   */
  public function cancelScrollEase():Void
  {
    _easingScroll = false;
  }

  public function cancelZoomEase():Void
  {
    _easingZoom = false;
  }

  /**
   * Sends the view along the song and lets `tick` carry it there.
   */
  public function easeScrollTo(scrollMs:Float):Void
  {
    if (scrollMs < 0) scrollMs = 0;
    if (songLengthMs > 0 && scrollMs > songLengthMs) scrollMs = songLengthMs;

    aimScrollOffsetMs = scrollMs;
    _easingScroll = true;
  }

  /**
   * The song time the zoom holds still, in steps.
   */
  function zoomAnchorSteps():Float
  {
    return _zoomAnchorPlayhead ? msToSteps(songPositionMs) : _zoomAnchorSteps;
  }

  /**
   * Where the view would be if it were to hold the zoom's anchor still, in steps.
   */
  function scrollStepsForAnchor(zoom:Float):Float
  {
    var pxPerStep:Float = pixelsPerStep * zoom;
    if (pxPerStep <= 0) return scrollOffsetSteps;
    return zoomAnchorSteps() - _zoomAnchorX / pxPerStep;
  }

  /**
   * Puts the view where the zoom's anchor stays under its screen x at the current zoom.
   */
  function holdZoomAnchor():Void
  {
    var scrollMs:Float = stepsToMs(scrollStepsForAnchor(zoomLevel));
    if (scrollMs < 0) scrollMs = 0;
    if (songLengthMs > 0 && scrollMs > songLengthMs) scrollMs = songLengthMs;
    scrollOffsetMs = scrollMs;
  }

  /**
   * Whether the song is running and the view is following the playhead.
   */
  function isFollowingPlayback():Bool
  {
    if (!chasing) return false;
    var timeline:Null<EventTimeline> = findAncestor(EventTimeline);
    if (timeline == null || !timeline.isPlaying) return false;
    return (timeline.autoScrollMode : TimelinePlaybackAutoScrollMode) != NONE;
  }

  public function cancelLayerScrollEase():Void
  {
    _easingLayerScroll = false;
  }

  /**
   * Sends the rows up or down and lets `tick` carry them there.
   */
  public function easeLayerScrollTo(px:Float):Void
  {
    var maxScroll:Float = maxLayerScrollPx;
    if (px > maxScroll) px = maxScroll;
    if (px < 0) px = 0;

    aimLayerScrollOffsetPx = px;
    _easingLayerScroll = true;
  }

  /**
   * A wheel's worth of rows, measured from where the rows are already headed.
   */
  public function easeLayerScrollBy(rows:Float):Void
  {
    var from:Float = _easingLayerScroll ? aimLayerScrollOffsetPx : layerScrollOffsetPx;
    easeLayerScrollTo(from - rows * layerHeight);
  }

  public function easeLayerHeightTo(h:Float):Void
  {
    if (h < MIN_LAYER_HEIGHT) h = MIN_LAYER_HEIGHT;
    if (h > MAX_LAYER_HEIGHT) h = MAX_LAYER_HEIGHT;

    aimLayerHeight = h;
    _easingLayerHeight = true;
  }

  /**
   * Taller or shorter rows, at once. The blocks, the names and the grid all follow.
   */
  public function setLayerHeight(h:Float):Void
  {
    if (h < MIN_LAYER_HEIGHT) h = MIN_LAYER_HEIGHT;
    if (h > MAX_LAYER_HEIGHT) h = MAX_LAYER_HEIGHT;
    if (h == layerHeight) return;

    layerHeight = h;
    for (block in eventBlocks) block.height = blockHeight;
    refreshLayout();
  }

  public function snapTime(ms:Float):Float
  {
    var timeline:Null<EventTimeline> = findAncestor(EventTimeline);
    return timeline == null ? ms : timeline.snapMs(ms);
  }

  public function snapGridSteps():Float
  {
    var timeline:Null<EventTimeline> = findAncestor(EventTimeline);
    var grid:Float = timeline == null ? 0 : timeline.snapGridSteps();
    return grid > 0 ? grid : 1.0;
  }

  /**
   * How far one wheel notch carries the view along the song: a step of the grid, but never so
   * little that a fine grid leaves the view standing still.
   */
  public function scrollStepSteps(zoom:Float):Float
  {
    var steps:Float = snapGridSteps();
    var pxPerStep:Float = pixelsPerStep * zoom;
    if (pxPerStep <= 0) return steps;

    var least:Float = (width / pxPerStep) * SCROLL_STEP_MIN_SHARE;
    return steps < least ? least : steps;
  }

  /**
   * Where a zoom holds the song still.
   */
  public function zoomAnchorX(fallbackX:Float):Float
  {
    if (!zoomToPlayhead) return fallbackX;

    var playheadX:Float = msToPixelX(songPositionMs);
    if (playheadX >= 0 && playheadX <= width) return playheadX;
    return fallbackX;
  }

  /**
   * Zooms the view, and sends it along the song as well so a point stays under the pointer.
   */
  public function zoomBy(factor:Float, pointerX:Float):Void
  {
    var fromZoom:Float = _easingZoom ? aimZoomLevel : zoomLevel;
    var pxFrom:Float = pixelsPerStep * fromZoom;
    if (pxFrom <= 0) return;

    // Where the view will be once whatever it is doing has finished.
    var fromScrollSteps:Float;
    if (_easingZoom) fromScrollSteps = scrollStepsForAnchor(fromZoom);
    else if (_easingScroll) fromScrollSteps = msToSteps(aimScrollOffsetMs);
    else
      fromScrollSteps = scrollOffsetSteps;

    var playheadSteps:Float = msToSteps(songPositionMs);
    var playheadX:Float = (playheadSteps - fromScrollSteps) * pxFrom;
    // While the song runs the view keeps the playhead put anyway.
    if ((zoomToPlayhead || isFollowingPlayback()) && playheadX >= 0 && playheadX <= width)
    {
      _zoomAnchorPlayhead = true;
      _zoomAnchorSteps = playheadSteps;
      _zoomAnchorX = playheadX;
    }
    else
    {
      _zoomAnchorPlayhead = false;
      _zoomAnchorSteps = fromScrollSteps + pointerX / pxFrom;
      _zoomAnchorX = pointerX;
    }

    var newZoom:Float = fromZoom * factor;
    if (newZoom < MIN_ZOOM) newZoom = MIN_ZOOM;
    if (newZoom > MAX_ZOOM) newZoom = MAX_ZOOM;

    // A zoom keeps the view on the song, or puts it back on it.
    chasing = true;
    cancelScrollEase();
    aimZoomLevel = newZoom;
    _easingZoom = true;
  }

  public function layerNameAt(layerIndex:Int):String
  {
    return layerIndex >= 0 && layerIndex < layers.length ? layers[layerIndex].name : "Default";
  }

  public function nudgeSelection(along:Int, down:Int):Void
  {
    if (_eventsInstance.isDragging()) return;

    var gridSteps:Float = snapGridSteps();
    var deltas:Array<EventMoveDelta> = [];

    for (block in eventBlocks)
    {
      if (!block.selected) continue;

      var oldTime:Float = block.eventData.time;
      var newTime:Float = oldTime;
      if (along != 0)
      {
        newTime = snapTime(stepsToMs(msToSteps(oldTime) + along * gridSteps));
        if (newTime < 0) newTime = 0;
      }

      var oldLayer:Int = block.layerIndex;
      var newLayer:Int = oldLayer + down;
      if (newLayer < 0) newLayer = 0;
      if (newLayer >= layers.length) newLayer = layers.length - 1;

      if (newTime == oldTime && newLayer == oldLayer) continue;

      var durationSteps:Float = TimelineUtil.getEventDurationSteps(block.eventData);
      deltas.push({
        event: block.eventData,
        oldTime: oldTime,
        newTime: newTime,
        oldDuration: durationSteps,
        newDuration: durationSteps,
        oldLayerName: layerNameAt(oldLayer),
        newLayerName: layerNameAt(newLayer)
      });
    }

    if (deltas.length == 0) return;

    var movedEvent:TimelineEvent = new TimelineEvent(TimelineEvent.EVENTS_MOVED);
    movedEvent.moveDeltas = deltas;
    dispatch(movedEvent);
  }

  /**
   * Wheel input that arrives as fractions of a notch: a trackpad, or a wheel that reports
   * fine steps. The bindings are the same as a whole notch's, scaled by the share of a notch.
   */
  public function handleTrackpadScroll():Void
  {
    var dx:Float = FlxG.mouse.deltaWheel.x;
    var dy:Float = FlxG.mouse.deltaWheel.y;

    if (FlxG.mouse.wheel != 0) dy = 0;
    if (dx == 0 && dy == 0) return;
    // HaxeUI's own pointer, in its own coordinates. The game's pointer moves with the stage camera.
    var mouseX:Float = Screen.instance.currentMouseX;
    var mouseY:Float = Screen.instance.currentMouseY;
    if (mouseX < screenLeft || mouseX > screenLeft + width || mouseY < screenTop || mouseY > screenTop + height) return;

    var fromScroll:Float = _easingScroll ? aimScrollOffsetMs : scrollOffsetMs;
    var fromZoom:Float = _easingZoom ? aimZoomLevel : zoomLevel;
    var fromHeight:Float = _easingLayerHeight ? aimLayerHeight : layerHeight;

    if (FlxG.keys.pressed.CONTROL)
    {
      // A share of a notch is a share of a notch's zoom.
      zoomBy(Math.pow(ZOOM_WHEEL_IN, dy), mouseX - screenLeft);
      return;
    }

    if (FlxG.keys.pressed.ALT)
    {
      easeLayerHeightTo(fromHeight + dy * LAYER_HEIGHT_WHEEL_STEP);
      return;
    }

    if (FlxG.keys.pressed.SHIFT)
    {
      var steps:Float = scrollStepSteps(fromZoom);

      chasing = false;
      easeScrollTo(stepsToMs(msToSteps(fromScroll) - dy * steps));
      return;
    }

    // Two fingers: along the song and up the rows.
    if (dx != 0)
    {
      cancelScrollEase();
      scrollOffsetMs = offsetMsByPixels(scrollOffsetMs, dx * TRACKPAD_TIME_SCROLL_MULT);
      if (scrollOffsetMs < 0) scrollOffsetMs = 0;
      chasing = false;
    }

    if (dy != 0)
    {
      easeLayerScrollBy((dy * TRACKPAD_LAYER_SCROLL_MULT) / layerHeight);
    }

    refreshLayout();
  }

  // Caller is responsible for `refreshLayout()` afterwards.

  public function scrollVertical(delta:Float):Void
  {
    var maxScroll:Float = maxLayerScrollPx;
    if (maxScroll <= 0)
    {
      layerScrollOffsetPx = 0;
      return;
    }
    var scrollPx:Float = delta * layerHeight;
    var newOffset:Float = layerScrollOffsetPx - scrollPx;
    if (newOffset < 0) newOffset = 0;
    if (newOffset > maxScroll) newOffset = maxScroll;
    layerScrollOffsetPx = newOffset;
  }

  public function refreshLayout():Void
  {
    if (songLengthMs > 0 && scrollOffsetMs > songLengthMs) scrollOffsetMs = songLengthMs;
    var maxScroll = maxLayerScrollPx;
    if (maxScroll <= 0) layerScrollOffsetPx = 0;
    else if (layerScrollOffsetPx > maxScroll) layerScrollOffsetPx = maxScroll;
    else if (layerScrollOffsetPx < 0) layerScrollOffsetPx = 0;
    invalidateComponentLayout();
    if (onRefresh != null) onRefresh();
  }

  /**
   * "cold load" path — tears down every block and rebuilds from scratch.
   * commands should use `addEventBlock` / `removeEventBlock` / `syncEventBlockLayer`
   * to avoid the flicker from the full teardown.
   */
  public function rebuildBlocks(events:Array<SongEventData>):Void
  {
    for (block in eventBlocks) contentArea.removeComponent(block);
    eventBlocks = [];

    for (event in events) addEventBlock(event);

    refreshLayout();
  }

  public function addEventBlock(event:SongEventData):TimelineEventBlock
  {
    if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera" && event.eventKind != "PlayAnimation") return null;

    var block = new TimelineEventBlock();
    block.eventData = event;

    var raw:SongEventDataRaw = event;
    var layerName = raw.editorLayer != null ? raw.editorLayer : "Default";
    block.layerIndex = getLayerIndex(layerName);

    if (block.layerIndex >= 0 && block.layerIndex < layers.length) block.applyColor(layers[block.layerIndex].color);

    contentArea.addComponent(block);

    var triangle = block.findComponent("block-instantTriangle", Image);
    if (triangle != null)
    {
      if (!block.isInstant()) triangle.opacity = 0;
      block._cachedTriangle = triangle;
    }

    var icon = block.findComponent("block-icon", Image);
    if (icon != null)
    {
      var iconRes = TimelineEventBlock.getIconResource(event.eventKind);
      if (iconRes != null) icon.resource = iconRes;
      block._cachedIcon = icon;
    }

    eventBlocks.push(block);
    return block;
  }

  public function findBlockByEvent(event:SongEventData):Null<TimelineEventBlock>
  {
    for (block in eventBlocks) if (block.eventData == event) return block;
    return null;
  }

  public function removeEventBlock(event:SongEventData):Bool
  {
    var block = findBlockByEvent(event);
    if (block == null) return false;
    contentArea.removeComponent(block);
    eventBlocks.remove(block);
    return true;
  }

  public function syncEventBlockLayer(block:TimelineEventBlock, layerName:String):Void
  {
    block.layerIndex = getLayerIndex(layerName);
    if (block.layerIndex >= 0 && block.layerIndex < layers.length) block.applyColor(layers[block.layerIndex].color);
    block.updateVisuals();
  }

  public function remapForInsert(insertIndex:Int):Void
  {
    for (block in eventBlocks) if (block.layerIndex >= insertIndex) block.layerIndex++;
  }

  public function remapForRemove(removedLayerIndex:Int):Void
  {
    for (block in eventBlocks) if (block.layerIndex > removedLayerIndex) block.layerIndex--;
  }

  public function refreshBlockVisuals(targetSelected:Bool = false):Void
  {
    for (block in eventBlocks)
    {
      if (targetSelected && !block.selected) continue;
      block.updateVisuals();
    }
  }

  public function getSelectedEvents():Array<SongEventData>
  {
    var out:Array<SongEventData> = [];
    for (block in eventBlocks) if (block.selected) out.push(block.eventData);
    return out;
  }

  public function setSelectedEvents(target:Array<SongEventData>):Void
  {
    for (block in eventBlocks)
    {
      var isSel:Bool = target.indexOf(block.eventData) != -1;
      if (block.selected != isSel)
      {
        block.selected = isSel;
        if (block.layerIndex >= 0 && block.layerIndex < layers.length) block.applyColor(layers[block.layerIndex].color);
        block.updateVisuals();
      }
    }
  }

  public function isEventSelected(event:SongEventData):Bool
  {
    for (block in eventBlocks) if (block.eventData == event) return block.selected;
    return false;
  }

  public function getLayerIndex(layerName:String):Int
  {
    for (i in 0...layers.length)
    {
      if (layers[i].name == layerName) return i;
    }
    return -1;
  }

  public function findLayerByName(layerName:String):Null<TimelineLayerData>
  {
    for (layer in layers) if (layer.name == layerName) return layer;
    return null;
  }

  public function getBlockTopPositionFromLayerIndex(layerIndex:Int):Float
  {
    return (layerIndex * layerHeight + (layerHeight - blockHeight) / 2) - layerScrollOffsetPx;
  }

  override public function onDestroy():Void
  {
    if (selectionBoxOverlay != null)
    {
      if (selectionBoxOverlay.parentComponent != null) selectionBoxOverlay.parentComponent.removeComponent(selectionBoxOverlay);
      selectionBoxOverlay = null;
    }
    super.onDestroy();
  }
}

@:dox(hide)
@:noCompletion
private class TimelineViewportBuilder extends CompositeBuilder
{
  var _viewport:TimelineViewport;

  public function new(viewport:TimelineViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function create():Void
  {
    _viewport.addClass("timeline-viewport");

    // is this the best place to put this????? sorry if it isnt
    _viewport.timelineShader = new TimelineShader(1);
    // also there HAS to be a better way to do this. i REFUSE to believe its this stupid. let me put shaders on haxeui!!!!!!!!!!!!!!!!!!!!
    @:privateAccess _viewport._surface.shader = _viewport.timelineShader;

    var playhead = new Box();
    playhead.id = "timeline-playhead";
    playhead.addClass("timeline-playhead");
    playhead.width = TimelineViewport.PLAYHEAD_LINE_WIDTH;
    _viewport.addComponent(playhead);
    _viewport.playhead = playhead;

    var topper = new Box();
    topper.id = "timeline-playhead-topper";
    topper.addClass("timeline-playhead-topper");
    topper.width = TimelineViewport.PLAYHEAD_TOPPER_WIDTH;
    topper.height = TimelineViewport.PLAYHEAD_TOPPER_HEIGHT;
    _viewport.addComponent(topper);
    _viewport.playheadTopper = topper;

    var contentArea:Box = new Box();
    contentArea.id = "timeline-content-area";
    contentArea.layout = new AbsoluteLayout();
    contentArea.left = 0;
    contentArea.top = TimelineViewport.TOP_BAR_HEIGHT;
    contentArea.customStyle.clip = true;
    contentArea.customStyle.pointerEvents = "none";
    _viewport.addComponent(contentArea);
    _viewport.contentArea = contentArea;

    var overlay:Box = new Box();
    overlay.id = "timeline-selection-box";
    overlay.addClass("timeline-selection-box");
    overlay.customStyle.pointerEvents = "none";
    overlay.customStyle.backgroundColor = 0x5BA3FF;
    overlay.customStyle.backgroundOpacity = 0.18;
    overlay.customStyle.borderColor = 0x5BA3FF;
    overlay.customStyle.borderSize = 1;
    overlay.hidden = true;
    overlay.includeInLayout = false;
    overlay.zIndex = 100000;
    _viewport.selectionBoxOverlay = overlay;
  }
}

@:dox(hide)
@:noCompletion
private class TimelineViewportLayout extends DefaultLayout
{
  override public function repositionChildren():Void
  {
    super.repositionChildren();

    var vp = cast(component, TimelineViewport);
    if (vp == null || vp.pixelsPerStep <= 0) return;

    var w = vp.componentWidth;
    var h = vp.componentHeight;
    if (w <= 0 || h <= 0) return;

    if (vp.playhead != null)
    {
      var phCenter = vp.msToPixelX(vp.songPositionMs);
      var offscreen = (phCenter < -2 || phCenter > w);
      var topperTop = (TimelineViewport.TOP_BAR_HEIGHT - TimelineViewport.PLAYHEAD_TOPPER_HEIGHT) / 2;
      var lineTop = topperTop + TimelineViewport.PLAYHEAD_TOPPER_HEIGHT;
      vp.playhead.left = phCenter - TimelineViewport.PLAYHEAD_LINE_WIDTH / 2;
      vp.playhead.top = lineTop;
      vp.playhead.height = Math.max(0, h - lineTop);
      vp.playhead.hidden = offscreen;
      if (vp.playheadTopper != null)
      {
        vp.playheadTopper.left = phCenter - TimelineViewport.PLAYHEAD_TOPPER_WIDTH / 2;
        vp.playheadTopper.top = topperTop;
        vp.playheadTopper.hidden = offscreen;
      }
    }

    var caHeight:Float = Math.max(0, h - TimelineViewport.TOP_BAR_HEIGHT);
    if (vp.contentArea != null)
    {
      if (vp.contentArea.left != 0) vp.contentArea.left = 0;
      if (vp.contentArea.top != TimelineViewport.TOP_BAR_HEIGHT) vp.contentArea.top = TimelineViewport.TOP_BAR_HEIGHT;
      if (vp.contentArea.width != w) vp.contentArea.width = w;
      if (vp.contentArea.height != caHeight) vp.contentArea.height = caHeight;
    }

    for (block in vp.eventBlocks)
    {
      var blockLeftPos = vp.msToPixelX(block.eventData.time);
      var blockWidthVal = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, vp.msToPixelX(vp.eventEndMs(block.eventData)) - blockLeftPos);
      var blockTopPos = vp.getBlockTopPositionFromLayerIndex(block.layerIndex);

      var isOffscreen =
        (blockLeftPos + blockWidthVal < 0)
          || (blockLeftPos > w)
          || (blockTopPos + vp.blockHeight < 0)
          || (blockTopPos > caHeight);

      if (isOffscreen != block.hidden) block.hidden = isOffscreen;

      if (isOffscreen) continue;
      if (block.left != blockLeftPos) block.left = blockLeftPos;
      if (block.top != blockTopPos) block.top = blockTopPos;
      if (block.width != blockWidthVal) block.width = blockWidthVal;
      if (block.height != vp.blockHeight) block.height = vp.blockHeight;

      block.blockLeft = blockLeftPos;
      block.blockTop = blockTopPos;
      block.blockWidth = blockWidthVal;

      if (block._cachedIcon == null) block._cachedIcon = block.findComponent("block-icon", Image);
      if (block._cachedTriangle == null) block._cachedTriangle = block.findComponent("block-instantTriangle", Image);

      var icon = block._cachedIcon;
      var triangle = block._cachedTriangle;
      if (icon != null && triangle != null)
      {
        var maxIconSize = vp.blockHeight - 4;
        var preferredPadding = maxIconSize * 0.05;
        var iconSize:Float;
        var iconLeft:Float;

        if (blockWidthVal >= maxIconSize + preferredPadding * 2)
        {
          // Block is wide enough: full-size icon with padding
          iconSize = maxIconSize;
          iconLeft = preferredPadding;

          // size triangle
          if (triangle.width != iconSize / 2) triangle.width = iconSize / 2;
        }
        else
        {
          // Block is too narrow: fill the block and center
          iconSize = Math.max(16, blockWidthVal);
          iconLeft = (blockWidthVal - iconSize) / 2;

          if (triangle.width != blockWidthVal) triangle.width = blockWidthVal;
        }

        var triangleColor:Null<Int> = triangle.color;
        var blockColor:Null<Int> = block.backgroundColor;
        if (triangleColor != blockColor) triangle.color = block.backgroundColor;
        if (triangle.height != vp.blockHeight) triangle.height = vp.blockHeight;

        if (icon.width != iconSize) icon.width = iconSize;
        if (icon.height != iconSize) icon.height = iconSize;
        var iconTop = (vp.blockHeight - iconSize) / 2;
        if (icon.top != iconTop) icon.top = iconTop;
        if (icon.left != iconLeft) icon.left = iconLeft;
      }
    }
  }
}

@:dox(hide)
@:noCompletion
private class TimelineViewportEvents extends haxe.ui.events.Events
{
  static inline var PLAYHEAD_GRAB_TOLERANCE_PX:Float = 5.0;
  static inline var DOUBLE_CLICK_MAX_DELAY:Float = 0.4;
  static inline var DOUBLE_CLICK_MAX_DIST_PX:Float = 4.0;

  #if FEATURE_MACOS_GESTURES
  static inline var GESTURE_PAN_SCALE_X:Float = 1.0;
  static inline var GESTURE_PAN_SCALE_Y:Float = 1.0;

  var gesture:FunkinGesture;
  #end
  var _viewport:TimelineViewport;
  var _dragMode:TimelineDragMode = NONE;
  var _dragTarget:TimelineEventBlock;
  var _dragOffsetSteps:Float = 0;
  var _dragOriginalTime:Float = 0;
  var _dragOriginalDuration:Float = 0;
  var _dragOriginalLayerIndex:Int = 0;
  var _hoverBlock:TimelineEventBlock;
  var _ghostTimeMs:Float = 0;
  var _ghostDurationSteps:Float = 0;
  var _ghostLayerIndex:Int = 0;
  var _lastClickTime:Float = 0;
  var _lastClickX:Float = 0;
  var _lastClickY:Float = 0;
  var _panLastScreenX:Float = 0;
  var _panLastScreenY:Float = 0;
  var _selectionBoxStartX:Float = 0;
  var _selectionBoxStartY:Float = 0;

  // Where the box began in song time, so a view carried along under it leaves its corner put.
  var _selectionBoxStartMs:Float = 0;

  var _selectionBoxAdditive:Bool = false;
  var _selectionBoxArmed:Bool = false;
  var _selectionBoxStartSelection:Array<SongEventData> = [];
  var _dragGroupEvents:Array<TimelineEventBlock> = [];
  var _dragGroupOriginalTimes:Array<Float> = [];
  var _dragGroupOriginalLayerIndices:Array<Int> = [];

  // Where each dragged event is headed, each snapped from its own start.
  var _dragGroupGhostTimes:Array<Float> = [];
  var _dragGhosts:Array<Box> = [];

  public function new(viewport:TimelineViewport)
  {
    super(viewport);
    _viewport = viewport;
    _viewport._eventsInstance = this;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_DOWN, _onMouseDown)) registerEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    if (!hasEvent(MouseEvent.MOUSE_MOVE, _onMouseMove)) registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    if (!hasEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown)) registerEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);

    #if FEATURE_MACOS_GESTURES
    if (gesture == null)
    {
      var gestureParams:FunkinGestureParams = {};
      gestureParams.preGestureStart = preGestureStart;
      gestureParams.onGestureStart = onGestureStart;
      gestureParams.onGestureEnd = onGestureEnd;
      gestureParams.onMagnificationGesture = onMagnificationGesture;
      gestureParams.onScrollGesture = onScrollGesture;
      gestureParams.onMomentumScrollGesture = onScrollGesture;

      gesture = new FunkinGesture(gestureParams);
    }
    #end
  }

  override public function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    unregisterEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, _onMouseUp);
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);

    #if FEATURE_MACOS_GESTURES
    if (gesture != null)
    {
      gesture.destroy();
      gesture = null;
    }
    #end
  }

  function _hitTestBlocks(localX:Float, localY:Float):TimelineEventBlock
  {
    var contentY:Float = localY - TimelineViewport.TOP_BAR_HEIGHT;
    if (contentY < 0) return null;

    var i:Int = _viewport.eventBlocks.length;
    while (i-- > 0)
    {
      var block:TimelineEventBlock = _viewport.eventBlocks[i];
      if (block.hidden) continue;
      if (
        localX >= block.blockLeft
        && localX <= block.blockLeft + block.blockWidth
        && contentY >= block.blockTop
        && contentY <= block.blockTop + _viewport.blockHeight
      )
      {
        return block;
      }
    }
    return null;
  }

  function _beginDrag(block:TimelineEventBlock, hitZone:TimelineBlockHitZone, mouseX:Float):Void
  {
    _dragTarget = block;
    _dragOriginalTime = block.eventData.time;
    _dragOriginalDuration = TimelineUtil.getEventDurationSteps(block.eventData);
    _dragOriginalLayerIndex = block.layerIndex;

    _ghostTimeMs = _dragOriginalTime;
    _ghostDurationSteps = _dragOriginalDuration;
    _ghostLayerIndex = _dragOriginalLayerIndex;

    var fixed:Bool = TimelineUtil.isFixedDuration(block.eventData);

    switch (hitZone)
    {
      case LEFT_EDGE:
        _dragMode = fixed ? MOVE : RESIZE_LEFT;
        if (fixed) _dragOffsetSteps = _viewport.msToSteps(_viewport.pixelXToMs(mouseX)) - _viewport.msToSteps(block.eventData.time);
      case RIGHT_EDGE:
        _dragMode = fixed ? MOVE : RESIZE_RIGHT;
        if (fixed) _dragOffsetSteps = _viewport.msToSteps(_viewport.pixelXToMs(mouseX)) - _viewport.msToSteps(block.eventData.time);
      case BODY:
        _dragMode = MOVE;
        _dragOffsetSteps = _viewport.msToSteps(_viewport.pixelXToMs(mouseX)) - _viewport.msToSteps(block.eventData.time);
    }

    if (_dragMode == MOVE)
    {
      _dragGroupEvents = [];
      _dragGroupOriginalTimes = [];
      _dragGroupOriginalLayerIndices = [];
      _dragGroupGhostTimes = [];
      for (b in _viewport.eventBlocks)
      {
        if (!b.selected) continue;
        _dragGroupEvents.push(b);
        _dragGroupOriginalTimes.push(b.eventData.time);
        _dragGroupOriginalLayerIndices.push(b.layerIndex);
        _dragGroupGhostTimes.push(b.eventData.time);
      }
      if (_dragGroupEvents.length == 0)
      {
        _dragGroupEvents.push(block);
        _dragGroupOriginalTimes.push(block.eventData.time);
        _dragGroupOriginalLayerIndices.push(block.layerIndex);
        _dragGroupGhostTimes.push(block.eventData.time);
      }
    }
  }

  function _createGhosts():Void
  {
    _removeGhosts();
    _dragGhosts = [];
    for (i in 0..._dragGroupEvents.length)
    {
      var block:TimelineEventBlock = _dragGroupEvents[i];
      var ghost:Box = new Box();
      ghost.includeInLayout = false;
      ghost.addClass("timeline-ghost");
      ghost.height = _viewport.blockHeight;
      ghost.customStyle.borderRadius = 3;
      ghost.customStyle.pointerEvents = "none";
      _viewport.contentArea.addComponent(ghost);
      _dragGhosts.push(ghost);
      _applyGhostStyle(ghost, _dragGroupOriginalLayerIndices[i]);
    }
  }

  function _removeGhosts():Void
  {
    if (_dragGhosts == null) return;
    for (ghost in _dragGhosts)
    {
      if (ghost != null) _viewport.contentArea.removeComponent(ghost);
    }
    _dragGhosts = [];
  }

  function _applyGhostStyle(ghost:Box, layerIndex:Int):Void
  {
    var color:Int = 0x888888;
    if (layerIndex >= 0 && layerIndex < _viewport.layers.length) color = _viewport.layers[layerIndex].color;
    ghost.customStyle.backgroundColor = color;
    ghost.customStyle.backgroundOpacity = 0.4;
    ghost.customStyle.borderColor = color;
    ghost.customStyle.borderSize = 1;
    ghost.invalidateComponentStyle();
  }

  function _positionGhost(ghost:Box, timeMs:Float, durationSteps:Float, layerIndex:Int):Void
  {
    var endMs:Float = timeMs + durationSteps * _viewport.stepLengthAtMs(timeMs);
    var ghostLeft:Float = _viewport.msToPixelX(timeMs);
    var ghostTop:Float = _viewport.getBlockTopPositionFromLayerIndex(layerIndex);
    var ghostWidth:Float = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, _viewport.msToPixelX(endMs) - ghostLeft);
    ghost.left = ghostLeft;
    ghost.top = ghostTop;
    ghost.width = ghostWidth;
  }

  function _endDrag():Void
  {
    if (_dragTarget == null || _dragMode == NONE) return;

    var isMove:Bool = _dragMode == MOVE;

    if (isMove)
    {
      var deltaLayer:Int = _ghostLayerIndex - _dragOriginalLayerIndex;
      var deltas:Array<EventMoveDelta> = [];
      var anyMoved:Bool = false;

      for (i in 0..._dragGroupEvents.length)
      {
        var block:TimelineEventBlock = _dragGroupEvents[i];
        var origTime:Float = _dragGroupOriginalTimes[i];
        var origLayer:Int = _dragGroupOriginalLayerIndices[i];

        var newTime:Float = i < _dragGroupGhostTimes.length ? _dragGroupGhostTimes[i] : origTime;
        if (newTime < 0) newTime = 0;
        var newLayer:Int = origLayer + deltaLayer;
        if (newLayer < 0) newLayer = 0;
        if (newLayer >= _viewport.layers.length) newLayer = _viewport.layers.length - 1;

        var moved:Bool = Math.abs(newTime - origTime) > 0.5 || newLayer != origLayer;
        if (moved) anyMoved = true;

        var origLayerName:String = origLayer < _viewport.layers.length ? _viewport.layers[origLayer].name : "Default";
        var newLayerName:String = newLayer < _viewport.layers.length ? _viewport.layers[newLayer].name : "Default";
        var durationSteps:Float = TimelineUtil.getEventDurationSteps(block.eventData);

        deltas.push({
          event: block.eventData,
          oldTime: origTime,
          newTime: newTime,
          oldDuration: durationSteps,
          newDuration: durationSteps,
          oldLayerName: origLayerName,
          newLayerName: newLayerName
        });
      }

      if (anyMoved)
      {
        var movedEvent:TimelineEvent = new TimelineEvent(TimelineEvent.EVENTS_MOVED);
        movedEvent.moveDeltas = deltas;
        _viewport.dispatch(movedEvent);
      }
    }
    else
    {
      var newDuration:Float = TimelineUtil.getEventDurationSteps(_dragTarget.eventData);
      var durationChanged:Bool = Math.abs(newDuration - _dragOriginalDuration) > 0.01;

      if (durationChanged)
      {
        var resizeEvent:TimelineEvent = new TimelineEvent(TimelineEvent.EVENT_RESIZED);
        resizeEvent.eventData = _dragTarget.eventData;
        resizeEvent.oldTime = _dragOriginalTime;
        resizeEvent.newTime = _dragTarget.eventData.time;
        resizeEvent.oldDuration = _dragOriginalDuration;
        resizeEvent.newDuration = newDuration;
        _viewport.dispatch(resizeEvent);
      }
      else
      {
        _dragTarget.eventData.time = _dragOriginalTime;
        TimelineUtil.setEventDurationSteps(_dragTarget.eventData, _dragOriginalDuration);
      }
    }

    _removeGhosts();
    _dragGroupEvents = [];
    _dragGroupOriginalTimes = [];
    _dragGroupOriginalLayerIndices = [];
    _dragGroupGhostTimes = [];
    _viewport.refreshLayout();

    _dragMode = NONE;
    _dragTarget = null;
  }

  function _isOnPlayhead(localX:Float):Bool
  {
    var playheadX = _viewport.msToPixelX(_viewport.songPositionMs);
    return Math.abs(localX - playheadX) <= PLAYHEAD_GRAB_TOLERANCE_PX;
  }

  public function isDragging():Bool
  {
    return _dragMode != NONE;
  }

  function _dispatchClampedSeek(clickMs:Float):Void
  {
    clickMs = _viewport.snapTime(clickMs);
    if (clickMs < 0) clickMs = 0;
    if (clickMs > _viewport.songLengthMs) clickMs = _viewport.songLengthMs;
    var seekEvent = new TimelineEvent(TimelineEvent.SEEK);
    seekEvent.seekPositionMs = clickMs;
    _viewport.dispatch(seekEvent);
  }

  function _onMouseDown(e:MouseEvent):Void
  {
    var localX:Float = e.screenX - _viewport.screenLeft;
    var localY:Float = e.screenY - _viewport.screenTop;

    var additive:Bool = FlxG.keys.pressed.CONTROL;

    var hitBlock:Null<TimelineEventBlock> = _hitTestBlocks(localX, localY);
    if (hitBlock != null)
    {
      var hitZone:TimelineBlockHitZone = hitBlock.getHitZone(localX - hitBlock.blockLeft);
      if (additive)
      {
        var newSelection:Array<SongEventData> = _viewport.getSelectedEvents();
        if (_viewport.isEventSelected(hitBlock.eventData)) newSelection.remove(hitBlock.eventData);
        else
          newSelection.push(hitBlock.eventData);
        _applySelection(newSelection);
      }
      else
      {
        if (!_viewport.isEventSelected(hitBlock.eventData)) _applySelection([hitBlock.eventData]);
        _beginDrag(hitBlock, hitZone, localX);
      }
      _lastClickTime = 0;
    }
    else
    {
      var inTopBar:Bool = localY < TimelineViewport.TOP_BAR_HEIGHT;
      var onPlayhead:Bool = _isOnPlayhead(localX);

      var clickedLayer:Int = _viewport.pixelYToLayerIndex(localY - TimelineViewport.TOP_BAR_HEIGHT);
      if (!inTopBar && clickedLayer != _viewport.selectedLayerIndex)
      {
        _viewport.selectedLayerIndex = clickedLayer;
        var timeline:Null<EventTimeline> = _viewport.findAncestor(EventTimeline);
        if (timeline != null) timeline.layerPanel.refreshSelectedHighlight();
      }

      if (inTopBar || onPlayhead)
      {
        _dragMode = SEEKING;
        Screen.instance.setCursor("grabbing");
        _dispatchClampedSeek(_viewport.pixelXToMs(localX));
        _lastClickTime = 0;
      }
      else
      {
        // note: we do double click this way since haxeui's double click dispatches on mouse up,
        // while we want to get it on mouse down, so we can drag right after hitting the second click
        var now:Float = haxe.Timer.stamp();
        var isDoubleClick:Bool = (
          now
          - _lastClickTime) <= DOUBLE_CLICK_MAX_DELAY && Math.abs(
            localX - _lastClickX
          ) <= DOUBLE_CLICK_MAX_DIST_PX && Math.abs(localY - _lastClickY) <= DOUBLE_CLICK_MAX_DIST_PX;

        if (isDoubleClick)
        {
          _dragMode = SEEKING;
          Screen.instance.setCursor("grabbing");
          _dispatchClampedSeek(_viewport.pixelXToMs(localX));
          _lastClickTime = 0;
        }
        else
        {
          _lastClickTime = now;
          _lastClickX = localX;
          _lastClickY = localY;

          _selectionBoxArmed = true;
          _selectionBoxStartX = localX;
          _selectionBoxStartY = localY;
          _selectionBoxStartMs = _viewport.pixelXToMs(localX);
          _selectionBoxAdditive = additive;
        }
      }
    }

    // Promote move/up to screen-level so dragging continues outside viewport bounds
    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.registerEvent(MouseEvent.MOUSE_UP, _onMouseUp);
  }

  function _onMouseMove(e:MouseEvent):Void
  {
    var localX:Float = e.screenX - _viewport.screenLeft;
    var localY:Float = e.screenY - _viewport.screenTop;

    if (_selectionBoxArmed && _dragMode == NONE)
    {
      var dx:Float = localX - _selectionBoxStartX;
      var dy:Float = localY - _selectionBoxStartY;
      if (Math.abs(dx) > TimelineViewport.SELECTION_DRAG_THRESHOLD_PX || Math.abs(dy) > TimelineViewport.SELECTION_DRAG_THRESHOLD_PX)
      {
        _dragMode = BOX_SELECTING;
        _selectionBoxArmed = false;
        _selectionBoxStartSelection = _viewport.getSelectedEvents();
        if (_viewport.selectionBoxOverlay != null)
        {
          _attachSelectionBoxIfNeeded();
          _updateSelectionBoxOverlay(e.screenX, e.screenY);
          _viewport.selectionBoxOverlay.hidden = false;
        }
      }
    }

    switch (_dragMode)
    {
      case NONE:
        _updateHoverCursor(localX, localY);
      case MOVE:
        _handleDragMove(localX, localY - TimelineViewport.TOP_BAR_HEIGHT);
      case RESIZE_LEFT:
        _handleDragResizeLeft(localX);
      case RESIZE_RIGHT:
        _handleDragResizeRight(localX);
      case SEEKING:
        Screen.instance.setCursor("grabbing");
        _dispatchClampedSeek(_viewport.pixelXToMs(localX));
      case PANNING:
        Screen.instance.setCursor("grabbing");
        var dx = e.screenX - _panLastScreenX;
        var dy = e.screenY - _panLastScreenY;
        _panLastScreenX = e.screenX;
        _panLastScreenY = e.screenY;

        _viewport.cancelScrollEase();
        _viewport.scrollOffsetMs = _viewport.offsetMsByPixels(_viewport.scrollOffsetMs, -dx);
        if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;
        _viewport.chasing = false;

        _viewport.cancelLayerScrollEase();
        _viewport.layerScrollOffsetPx = _viewport.layerScrollOffsetPx - dy;
        _viewport.refreshLayout();
      case BOX_SELECTING:
        _updateSelectionBoxOverlay(e.screenX, e.screenY);
        _viewport.setSelectedEvents(_computeBoxSelection(localX, localY));
        Screen.instance.setCursor("crosshair");
    }

    if (_dragMode != NONE && _dragMode != PANNING)
    {
      _viewport._autoScrollDragActive = true;
      _viewport._autoScrollScreenX = e.screenX;
      _viewport._autoScrollScreenY = e.screenY;
    }
  }

  function _computeBoxSelection(endX:Float, endY:Float):Array<SongEventData>
  {
    var minX:Float = Math.min(_selectionBoxStartX, endX);
    var maxX:Float = Math.max(_selectionBoxStartX, endX);
    var minY:Float = Math.min(_selectionBoxStartY, endY);
    var maxY:Float = Math.max(_selectionBoxStartY, endY);

    var hits:Array<SongEventData> = [];
    for (block in _viewport.eventBlocks)
    {
      if (block.hidden) continue;
      var bx1:Float = block.blockLeft;
      var bx2:Float = block.blockLeft + block.blockWidth;
      var by1:Float = block.blockTop + TimelineViewport.TOP_BAR_HEIGHT;
      var by2:Float = by1 + _viewport.blockHeight;
      var intersects:Bool = bx1 < maxX && bx2 > minX && by1 < maxY && by2 > minY;
      if (intersects) hits.push(block.eventData);
    }

    if (_selectionBoxAdditive)
    {
      var combined:Array<SongEventData> = _selectionBoxStartSelection.copy();
      for (ev in hits)
      {
        if (combined.indexOf(ev) == -1) combined.push(ev);
        else
          combined.remove(ev);
      }
      return combined;
    }
    return hits;
  }

  function _attachSelectionBoxIfNeeded():Void
  {
    var overlay:Box = _viewport.selectionBoxOverlay;
    if (overlay == null || overlay.parentComponent != null) return;
    var timeline:Null<EventTimeline> = _viewport.findAncestor(EventTimeline);
    if (timeline != null) timeline.addComponent(overlay);
  }

  function _updateSelectionBoxOverlay(screenX:Float, screenY:Float):Void
  {
    var overlay:Box = _viewport.selectionBoxOverlay;
    if (overlay == null) return;
    var parent:haxe.ui.core.Component = overlay.parentComponent;
    var originX:Float = parent != null ? parent.screenLeft : 0;
    var originY:Float = parent != null ? parent.screenTop : 0;
    var startScreenX:Float = _viewport.screenLeft + _selectionBoxStartX;
    var startScreenY:Float = _viewport.screenTop + _selectionBoxStartY;
    var minX:Float = Math.min(startScreenX, screenX);
    var maxX:Float = Math.max(startScreenX, screenX);
    var minY:Float = Math.min(startScreenY, screenY);
    var maxY:Float = Math.max(startScreenY, screenY);
    overlay.left = minX - originX;
    overlay.top = minY - originY;
    overlay.width = maxX - minX;
    overlay.height = maxY - minY;
  }

  function _onMouseUp(e:MouseEvent):Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_UP, _onMouseUp);

    _viewport._autoScrollDragActive = false;

    var wasMode:TimelineDragMode = _dragMode;

    switch (wasMode)
    {
      case BOX_SELECTING:
        _finishBoxSelection(e);
        if (_viewport.selectionBoxOverlay != null) _viewport.selectionBoxOverlay.hidden = true;
        _dragMode = NONE;
      case SEEKING:
        _dragMode = NONE;
      case MOVE | RESIZE_LEFT | RESIZE_RIGHT:
        _endDrag();
      case NONE:
        if (_selectionBoxArmed)
        {
          _selectionBoxArmed = false;
          if (!_selectionBoxAdditive) _applySelection([]);
        }
      case PANNING:
    }

    var localX:Float = e.screenX - _viewport.screenLeft;
    var localY:Float = e.screenY - _viewport.screenTop;
    if (wasMode == SEEKING || wasMode == BOX_SELECTING) _updateHoverCursor(localX, localY);
  }

  function _finishBoxSelection(e:MouseEvent):Void
  {
    var endX:Float = e.screenX - _viewport.screenLeft;
    var endY:Float = e.screenY - _viewport.screenTop;
    _applySelection(_computeBoxSelection(endX, endY));
    _selectionBoxStartSelection = [];
  }

  function _applySelection(selected:Array<SongEventData>):Void
  {
    _viewport.setSelectedEvents(selected);
    var ev:TimelineEvent = new TimelineEvent(TimelineEvent.EVENT_SELECTED);
    ev.eventsData = selected;
    ev.eventData = selected.length == 1 ? selected[0] : null;
    _viewport.dispatch(ev);
  }

  function _onMiddleMouseDown(e:MouseEvent):Void
  {
    if (_dragMode != NONE) return;

    _dragMode = PANNING;
    _panLastScreenX = e.screenX;
    _panLastScreenY = e.screenY;
    Screen.instance.setCursor("grabbing");

    Screen.instance.registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.registerEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);
  }

  function _onMiddleMouseUp(e:MouseEvent):Void
  {
    Screen.instance.unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    Screen.instance.unregisterEvent(MouseEvent.MIDDLE_MOUSE_UP, _onMiddleMouseUp);

    if (_dragMode == PANNING) _dragMode = NONE;

    var localX = e.screenX - _viewport.screenLeft;
    var localY = e.screenY - _viewport.screenTop;
    _updateHoverCursor(localX, localY);
  }

  function _onMouseWheel(e:MouseEvent):Void
  {
    if (e.delta == 0) return;

    var fromScroll:Float = _viewport._easingScroll ? _viewport.aimScrollOffsetMs : _viewport.scrollOffsetMs;
    var fromZoom:Float = _viewport._easingZoom ? _viewport.aimZoomLevel : _viewport.zoomLevel;
    var fromHeight:Float = _viewport._easingLayerHeight ? _viewport.aimLayerHeight : _viewport.layerHeight;

    if (e.ctrlKey)
    {
      _viewport.zoomBy(e.delta > 0 ? TimelineViewport.ZOOM_WHEEL_IN : TimelineViewport.ZOOM_WHEEL_OUT, e.screenX - _viewport.screenLeft);
      return;
    }

    if (FlxG.keys.pressed.ALT)
    {
      _viewport.easeLayerHeightTo(fromHeight + (e.delta > 0 ? TimelineViewport.LAYER_HEIGHT_WHEEL_STEP : -TimelineViewport.LAYER_HEIGHT_WHEEL_STEP));
      return;
    }

    // Along the song, a step of the grid at a time.
    if (e.shiftKey)
    {
      var steps:Float = _viewport.scrollStepSteps(fromZoom);

      _viewport.chasing = false;
      _viewport.easeScrollTo(_viewport.stepsToMs(_viewport.msToSteps(fromScroll) - e.delta * steps));
      return;
    }

    _viewport.easeLayerScrollBy(e.delta);
  }

  function _updateHoverCursor(localX:Float, localY:Float):Void
  {
    if (_hoverBlock != null)
    {
      _hoverBlock.removeClass("resize-left");
      _hoverBlock.removeClass("resize-right");
      _hoverBlock = null;
    }

    var desiredCursor:String = "default";

    var hitBlock = _hitTestBlocks(localX, localY);
    if (hitBlock != null)
    {
      var hitZone = hitBlock.getHitZone(localX - hitBlock.blockLeft);
      var fixed = TimelineUtil.isFixedDuration(hitBlock.eventData);
      switch (hitZone)
      {
        case LEFT_EDGE:
          desiredCursor = fixed ? "move" : "col-resize";
          if (!fixed)
          {
            hitBlock.addClass("resize-left");
            _hoverBlock = hitBlock;
          }
        case RIGHT_EDGE:
          desiredCursor = fixed ? "move" : "col-resize";
          if (!fixed)
          {
            hitBlock.addClass("resize-right");
            _hoverBlock = hitBlock;
          }
        case BODY:
          desiredCursor = "move";
      }
    }
    else if (localY < TimelineViewport.TOP_BAR_HEIGHT)
    {
      desiredCursor = "pointer";
    }
    else if (_isOnPlayhead(localX))
    {
      desiredCursor = "pointer";
    }

    _viewport.customStyle.cursor = desiredCursor;
    _viewport.invalidateComponentStyle();
    Screen.instance.setCursor(desiredCursor);
  }

  function _handleDragMove(mouseX:Float, mouseY:Float):Void
  {
    if (_dragTarget == null) return;

    var rawDeltaSteps:Float = _viewport.msToSteps(_viewport.pixelXToMs(mouseX)) - _dragOffsetSteps - _viewport.msToSteps(_dragOriginalTime);
    var newTimeMs:Float = _viewport.snapTime(_viewport.stepsToMs(_viewport.msToSteps(_dragOriginalTime) + rawDeltaSteps));
    if (newTimeMs < 0) newTimeMs = 0;

    var newLayerIndex:Int = _viewport.pixelYToLayerIndex(mouseY);
    var moved:Bool = Math.abs(newTimeMs - _dragOriginalTime) > 0.5 || newLayerIndex != _dragOriginalLayerIndex;

    _ghostTimeMs = newTimeMs;

    if (newLayerIndex != _ghostLayerIndex && newLayerIndex < _viewport.layers.length) _ghostLayerIndex = newLayerIndex;

    if (moved && _dragGhosts.length == 0) _createGhosts();

    if (_dragGhosts.length > 0)
    {
      var deltaLayer:Int = _ghostLayerIndex - _dragOriginalLayerIndex;
      for (i in 0..._dragGroupEvents.length)
      {
        var ghost:Box = _dragGhosts[i];
        if (ghost == null) continue;
        var block:TimelineEventBlock = _dragGroupEvents[i];
        var origTime:Float = _dragGroupOriginalTimes[i];
        var origLayer:Int = _dragGroupOriginalLayerIndices[i];
        var gTime:Float = _viewport.snapTime(_viewport.stepsToMs(_viewport.msToSteps(origTime) + rawDeltaSteps));
        if (gTime < 0) gTime = 0;
        _dragGroupGhostTimes[i] = gTime;
        var gLayer:Int = origLayer + deltaLayer;
        if (gLayer < 0) gLayer = 0;
        if (gLayer >= _viewport.layers.length) gLayer = _viewport.layers.length - 1;

        var durationSteps:Float = TimelineUtil.getEventDurationSteps(block.eventData);
        _applyGhostStyle(ghost, gLayer);
        _positionGhost(ghost, gTime, durationSteps, gLayer);
      }
    }
  }

  function _handleDragResizeRight(mouseX:Float):Void
  {
    if (_dragTarget == null) return;

    var endMs = _viewport.snapTime(_viewport.pixelXToMs(mouseX));
    var newDurationSteps = _viewport.durationStepsBetween(_dragTarget.eventData.time, endMs);

    var minSteps = TimelineUtil.getMinDurationSteps(_dragTarget.eventData);
    if (newDurationSteps < minSteps) newDurationSteps = minSteps;

    TimelineUtil.setEventDurationSteps(_dragTarget.eventData, newDurationSteps);
    _viewport.refreshLayout();
  }

  function _handleDragResizeLeft(mouseX:Float):Void
  {
    if (_dragTarget == null) return;

    var minSteps = TimelineUtil.getMinDurationSteps(_dragTarget.eventData);
    var originalEndMs = _dragOriginalTime + (_dragOriginalDuration * _viewport.stepLengthAtMs(_dragOriginalTime));

    var newStartMs = _viewport.snapTime(_viewport.pixelXToMs(mouseX));
    var maxStart = originalEndMs - (minSteps * _viewport.stepLengthAtMs(newStartMs));
    if (newStartMs > maxStart) newStartMs = maxStart;
    if (newStartMs < 0) newStartMs = 0;

    var newDurationSteps = _viewport.durationStepsBetween(newStartMs, originalEndMs);

    _dragTarget.eventData.time = newStartMs;
    TimelineUtil.setEventDurationSteps(_dragTarget.eventData, newDurationSteps);
    _viewport.refreshLayout();
  }

  public function tickEdgeAutoScroll(elapsed:Float):Void
  {
    if (!_viewport._autoScrollDragActive) return;

    var modeEligible:Bool = _dragMode == SEEKING || _dragMode == MOVE || _dragMode == RESIZE_LEFT || _dragMode == RESIZE_RIGHT
      || _dragMode == BOX_SELECTING;
    if (!modeEligible) return;

    if (_viewport.pixelsPerStep <= 0) return;
    var w:Float = _viewport.width;
    if (w <= 0) return;

    var localX:Float = _viewport._autoScrollScreenX - _viewport.screenLeft;
    var zonePx:Float = TimelineViewport.EDGE_AUTOSCROLL_ZONE_PX;

    var dir:Float = 0;
    if (localX < zonePx) dir = -1;
    else if (localX > w - zonePx) dir = 1;
    if (dir == 0) return;

    var prevScroll:Float = _viewport.scrollOffsetMs;
    _viewport.cancelScrollEase();
    _viewport.scrollOffsetMs = _viewport.offsetMsByPixels(_viewport.scrollOffsetMs, dir * TimelineViewport.EDGE_AUTOSCROLL_PX_PER_SEC * elapsed);
    if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;
    if (_viewport.songLengthMs > 0 && _viewport.scrollOffsetMs > _viewport.songLengthMs) _viewport.scrollOffsetMs = _viewport.songLengthMs;
    if (_viewport.scrollOffsetMs == prevScroll) return;

    _viewport.refreshLayout();

    var localY:Float = _viewport._autoScrollScreenY - _viewport.screenTop;

    switch (_dragMode)
    {
      case SEEKING:
        _dispatchClampedSeek(_viewport.pixelXToMs(localX));
      case MOVE:
        _handleDragMove(localX, localY - TimelineViewport.TOP_BAR_HEIGHT);
      case RESIZE_LEFT:
        _handleDragResizeLeft(localX);
      case RESIZE_RIGHT:
        _handleDragResizeRight(localX);
      case BOX_SELECTING:
        // The corner stays on its beat while the view slides under the box.
        _selectionBoxStartX = _viewport.msToPixelX(_selectionBoxStartMs);
        _updateSelectionBoxOverlay(_viewport._autoScrollScreenX, _viewport._autoScrollScreenY);
        _viewport.setSelectedEvents(_computeBoxSelection(localX, localY));
      case _:
    }
  }

  #if FEATURE_MACOS_GESTURES
  function _hitTest(x:Float, y:Float):Bool
  {
    return x >= _viewport.screenLeft && x <= _viewport.screenLeft + _viewport.width && y >= _viewport.screenTop && y <= _viewport.screenTop + _viewport.height;
  }

  function preGestureStart(g:Gesture):Bool
  {
    if (HaxeUIUtil.isModalDialogOpen()) return false;
    return _hitTest(FlxG.mouse.gameX, FlxG.mouse.gameY);
  }

  function onGestureStart(g:Gesture):Void
  {
    if (hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
  }

  function onGestureEnd(g:Gesture):Void
  {
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
  }

  function onMagnificationGesture(delta:Float, x:Float, y:Float):Void
  {
    var localX:Float = x - _viewport.screenLeft;
    var mouseMs:Float = _viewport.pixelXToMs(localX);

    var newZoom:Float = _viewport.zoomLevel * (1.0 + delta);
    if (newZoom < TimelineViewport.MIN_ZOOM) newZoom = TimelineViewport.MIN_ZOOM;
    if (newZoom > TimelineViewport.MAX_ZOOM) newZoom = TimelineViewport.MAX_ZOOM;
    _viewport.cancelScrollEase();
    _viewport.chasing = true;
    _viewport.zoomLevel = newZoom;

    var pxPerStep:Float = _viewport.pixelsPerStep * newZoom;
    if (pxPerStep > 0) _viewport.scrollOffsetMs = _viewport.stepsToMs(_viewport.msToSteps(mouseMs) - (localX / pxPerStep));
    if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;

    _viewport.refreshLayout();
    _viewport.dispatch(new TimelineEvent(TimelineEvent.ZOOM_CHANGED));
  }

  function onScrollGesture(delta:Array<Float>):Void
  {
    var scrollPx:Float = delta[0] * GESTURE_PAN_SCALE_X;
    _viewport.cancelScrollEase();
    _viewport.scrollOffsetMs = _viewport.offsetMsByPixels(_viewport.scrollOffsetMs, -scrollPx);
    if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;
    if (scrollPx != 0) _viewport.chasing = false;

    if (delta[1] != 0) _viewport.scrollVertical((delta[1] * GESTURE_PAN_SCALE_Y) / TimelineViewport.LAYER_HEIGHT);

    _viewport.refreshLayout();

    var zoomEvent:TimelineEvent = new TimelineEvent(TimelineEvent.ZOOM_CHANGED);
    _viewport.dispatch(zoomEvent);
  }
  #end
}
#end
