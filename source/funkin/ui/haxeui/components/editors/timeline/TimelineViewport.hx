package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.graphics.shaders.TimelineShader;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
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
import haxe.ui.layouts.DefaultLayout;

@:composite(TimelineViewportEvents, TimelineViewportBuilder, TimelineViewportLayout)
class TimelineViewport extends Box
{
  public var timelineShader:TimelineShader;

  public static inline var TOP_BAR_HEIGHT:Int = 30;
  public static inline var LAYER_HEIGHT:Int = 48;
  public static inline var MIN_BLOCK_WIDTH:Float = 10.0;
  public static inline var PIXELS_PER_STEP_BASE:Float = 12.0;

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
  public var songLengthMs:Float = 0;
  public var beatsPerGroup:Int = 1;
  public var playhead:Box;
  public var playheadTopper:Box;
  public var selectionBoxOverlay:Box;
  public static inline var PLAYHEAD_LINE_WIDTH:Int = 2;
  public static inline var PLAYHEAD_TOPPER_WIDTH:Int = 14;
  public static inline var PLAYHEAD_TOPPER_HEIGHT:Int = 22;
  public static inline var SELECTION_DRAG_THRESHOLD_PX:Float = 4.0;
  public var layerScrollOffsetPx:Float = 0;
  public var onRefresh:Void->Void;

  public var pixelsPerMs(get, never):Float;

  function get_pixelsPerMs():Float
  {
    if (stepLengthMs <= 0) return 0;
    return PIXELS_PER_STEP_BASE / stepLengthMs;
  }

  public var pixelsPerBeat(get, never):Float;

  function get_pixelsPerBeat():Float
  {
    if (stepLengthMs <= 0) return 0;
    return PIXELS_PER_STEP_BASE * 4;
  }

  public var totalLayerHeight(get, never):Float;

  function get_totalLayerHeight():Float
  {
    return layers.length * LAYER_HEIGHT;
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
    var safeViewable = viewableHeight - LAYER_HEIGHT;
    if (safeViewable < 0) safeViewable = 0;
    if (totalLayerHeight <= safeViewable) return 0;
    // Allow overshoot so the last row can scroll to the middle of the safe area.
    var max = totalLayerHeight - safeViewable / 2;
    return max > 0 ? max : 0;
  }

  public function msToPixelX(ms:Float):Float
  {
    return (ms - scrollOffsetMs) * pixelsPerMs * zoomLevel;
  }

  public function pixelXToMs(px:Float):Float
  {
    var denom = pixelsPerMs * zoomLevel;
    if (denom == 0) return scrollOffsetMs;
    return (px / denom) + scrollOffsetMs;
  }

  public function pixelYToLayerIndex(py:Float):Int
  {
    if (layers.length == 0) return 0;
    var idx = Std.int((py + layerScrollOffsetPx) / LAYER_HEIGHT);
    if (idx < 0) return 0;
    if (idx >= layers.length) return layers.length - 1;
    return idx;
  }

  public function ensureLayerVisible(layerIndex:Int):Void
  {
    if (layerIndex < 0 || layerIndex >= layers.length) return;
    var viewH = viewableHeightPx - LAYER_HEIGHT;
    if (viewH <= 0) return;

    var layerTop = layerIndex * LAYER_HEIGHT;
    var layerBottom = layerTop + LAYER_HEIGHT;
    var viewTop = layerScrollOffsetPx;
    var viewBottom = viewTop + viewH;

    if (layerTop < viewTop) layerScrollOffsetPx = layerTop;
    else if (layerBottom > viewBottom) layerScrollOffsetPx = layerBottom - viewH;

    refreshLayout();
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
    for (block in eventBlocks)
      removeComponent(block);
    eventBlocks = [];

    for (event in events) addEventBlock(event);

    refreshLayout();
  }

  public function addEventBlock(event:SongEventData):TimelineEventBlock
  {
    if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera") return null;

    var block = new TimelineEventBlock();
    block.eventData = event;

    var raw:SongEventDataRaw = event;
    var layerName = raw.editorLayer != null ? raw.editorLayer : "Default";
    block.layerIndex = getLayerIndex(layerName);

    if (block.layerIndex >= 0 && block.layerIndex < layers.length) block.applyColor(layers[block.layerIndex].color);

    addComponent(block);

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
    for (block in eventBlocks)
      if (block.eventData == event) return block;
    return null;
  }

  public function removeEventBlock(event:SongEventData):Bool
  {
    var block = findBlockByEvent(event);
    if (block == null) return false;
    removeComponent(block);
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
    for (block in eventBlocks)
      if (block.layerIndex >= insertIndex) block.layerIndex++;
  }

  public function remapForRemove(removedLayerIndex:Int):Void
  {
    for (block in eventBlocks)
      if (block.layerIndex > removedLayerIndex) block.layerIndex--;
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
    for (block in eventBlocks)
      if (block.selected) out.push(block.eventData);
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
    for (block in eventBlocks)
      if (block.eventData == event) return block.selected;
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
    for (layer in layers)
      if (layer.name == layerName) return layer;
    return null;
  }

  public function getBlockTopPositionFromLayerIndex(layerIndex:Int):Float
  {
    return (layerIndex * TimelineViewport.LAYER_HEIGHT
      + (TimelineViewport.LAYER_HEIGHT - TimelineEventBlock.BLOCK_HEIGHT) / 2)
      + TimelineViewport.TOP_BAR_HEIGHT
      - layerScrollOffsetPx;
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

@:dox(hide) @:noCompletion
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

@:dox(hide) @:noCompletion
private class TimelineViewportLayout extends DefaultLayout
{
  override public function repositionChildren():Void
  {
    super.repositionChildren();

    var vp = cast(component, TimelineViewport);
    if (vp == null || vp.pixelsPerMs <= 0) return;

    var w = vp.componentWidth;
    var h = vp.componentHeight;
    if (w <= 0 || h <= 0) return;

    if (vp.playhead != null)
    {
      var phCenter = (vp.songPositionMs - vp.scrollOffsetMs) * vp.pixelsPerMs * vp.zoomLevel;
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

    for (block in vp.eventBlocks)
    {
      var durationSteps = TimelineUtil.getEventDurationSteps(block.eventData);
      var durationMs = durationSteps * vp.stepLengthMs;

      var blockLeftPos = (block.eventData.time - vp.scrollOffsetMs) * vp.pixelsPerMs * vp.zoomLevel;
      var blockWidthVal = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, durationMs * vp.pixelsPerMs * vp.zoomLevel);
      var blockTopPos = vp.getBlockTopPositionFromLayerIndex(block.layerIndex);

      var isOffscreen = (blockLeftPos + blockWidthVal < 0)
        || (blockLeftPos > w)
        || (blockTopPos + TimelineEventBlock.BLOCK_HEIGHT < TimelineViewport.TOP_BAR_HEIGHT)
        || (blockTopPos > h);

      if (isOffscreen != block.hidden) block.hidden = isOffscreen;

      if (isOffscreen) continue;
      if (block.left != blockLeftPos) block.left = blockLeftPos;
      if (block.top != blockTopPos) block.top = blockTopPos;
      if (block.width != blockWidthVal) block.width = blockWidthVal;

      block.blockLeft = blockLeftPos;
      block.blockTop = blockTopPos;
      block.blockWidth = blockWidthVal;

      if (block._cachedIcon == null) block._cachedIcon = block.findComponent("block-icon", Image);
      if (block._cachedTriangle == null) block._cachedTriangle = block.findComponent("block-instantTriangle", Image);

      var icon = block._cachedIcon;
      var triangle = block._cachedTriangle;
      if (icon != null && triangle != null)
      {
        var maxIconSize = TimelineEventBlock.BLOCK_HEIGHT - 4;
        var preferredPadding = maxIconSize * 0.05;
        var iconSize:Float;
        var iconLeft:Float;

        if (blockWidthVal >= maxIconSize + preferredPadding * 2)
        {
          // Block is wide enough: full-size icon with padding
          iconSize = maxIconSize;
          iconLeft = preferredPadding;

          // size triangle
          triangle.width = iconSize / 2;
        }
        else
        {
          // Block is too narrow: fill the block and center
          iconSize = Math.max(16, blockWidthVal);
          iconLeft = (blockWidthVal - iconSize) / 2;

          triangle.width = blockWidthVal;
        }

        triangle.color = block.backgroundColor;
        triangle.height = block.componentHeight;

        if (icon.width != iconSize) icon.width = iconSize;
        if (icon.height != iconSize) icon.height = iconSize;
        var iconTop = (TimelineEventBlock.BLOCK_HEIGHT - iconSize) / 2;
        if (icon.top != iconTop) icon.top = iconTop;
        if (icon.left != iconLeft) icon.left = iconLeft;
      }
    }
  }
}

@:dox(hide) @:noCompletion
private class TimelineViewportEvents extends haxe.ui.events.Events
{
  static inline var PLAYHEAD_GRAB_TOLERANCE_PX:Float = 5.0;
  static inline var DOUBLE_CLICK_MAX_DELAY:Float = 0.4;
  static inline var DOUBLE_CLICK_MAX_DIST_PX:Float = 4.0;

  var _viewport:TimelineViewport;

  var _dragMode:TimelineDragMode = NONE;
  var _dragTarget:TimelineEventBlock;
  var _dragOffsetMs:Float = 0;
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
  var _selectionBoxAdditive:Bool = false;
  var _selectionBoxArmed:Bool = false;
  var _selectionBoxStartSelection:Array<SongEventData> = [];

  var _dragGroupEvents:Array<TimelineEventBlock> = [];
  var _dragGroupOriginalTimes:Array<Float> = [];
  var _dragGroupOriginalLayerIndices:Array<Int> = [];
  var _dragGhosts:Array<Box> = [];

  public function new(viewport:TimelineViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_DOWN, _onMouseDown)) registerEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    if (!hasEvent(MouseEvent.MOUSE_MOVE, _onMouseMove)) registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
    if (!hasEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown)) registerEvent(MouseEvent.MIDDLE_MOUSE_DOWN, _onMiddleMouseDown);
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
  }

  function _hitTestBlocks(localX:Float, localY:Float):TimelineEventBlock
  {
    var i = _viewport.eventBlocks.length;
    while (i-- > 0)
    {
      var block = _viewport.eventBlocks[i];
      if (block.hidden) continue;
      if (localX >= block.blockLeft
        && localX <= block.blockLeft + block.blockWidth
        && localY >= block.blockTop
        && localY <= block.blockTop + TimelineEventBlock.BLOCK_HEIGHT)
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
        if (fixed) _dragOffsetMs = _viewport.pixelXToMs(mouseX) - block.eventData.time;
      case RIGHT_EDGE:
        _dragMode = fixed ? MOVE : RESIZE_RIGHT;
        if (fixed) _dragOffsetMs = _viewport.pixelXToMs(mouseX) - block.eventData.time;
      case BODY:
        _dragMode = MOVE;
        _dragOffsetMs = _viewport.pixelXToMs(mouseX) - block.eventData.time;
    }

    if (_dragMode == MOVE)
    {
      _dragGroupEvents = [];
      _dragGroupOriginalTimes = [];
      _dragGroupOriginalLayerIndices = [];
      for (b in _viewport.eventBlocks)
      {
        if (!b.selected) continue;
        _dragGroupEvents.push(b);
        _dragGroupOriginalTimes.push(b.eventData.time);
        _dragGroupOriginalLayerIndices.push(b.layerIndex);
      }
      if (_dragGroupEvents.length == 0)
      {
        _dragGroupEvents.push(block);
        _dragGroupOriginalTimes.push(block.eventData.time);
        _dragGroupOriginalLayerIndices.push(block.layerIndex);
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
      ghost.addClass("timeline-ghost");
      ghost.height = TimelineEventBlock.BLOCK_HEIGHT;
      ghost.customStyle.borderRadius = 3;
      ghost.customStyle.pointerEvents = "none";
      _viewport.addComponent(ghost);
      _dragGhosts.push(ghost);
      _applyGhostStyle(ghost, _dragGroupOriginalLayerIndices[i]);
    }
  }

  function _removeGhosts():Void
  {
    if (_dragGhosts == null) return;
    for (ghost in _dragGhosts)
    {
      if (ghost != null) _viewport.removeComponent(ghost);
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
    var durationMs:Float = durationSteps * _viewport.stepLengthMs;
    var ghostLeft:Float = (timeMs - _viewport.scrollOffsetMs) * _viewport.pixelsPerMs * _viewport.zoomLevel;
    var ghostTop:Float = _viewport.getBlockTopPositionFromLayerIndex(layerIndex);
    var ghostWidth:Float = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, durationMs * _viewport.pixelsPerMs * _viewport.zoomLevel);
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
      var deltaMs:Float = _ghostTimeMs - _dragOriginalTime;
      var deltaLayer:Int = _ghostLayerIndex - _dragOriginalLayerIndex;
      var deltas:Array<EventMoveDelta> = [];
      var anyMoved:Bool = false;

      for (i in 0..._dragGroupEvents.length)
      {
        var block:TimelineEventBlock = _dragGroupEvents[i];
        var origTime:Float = _dragGroupOriginalTimes[i];
        var origLayer:Int = _dragGroupOriginalLayerIndices[i];

        var newTime:Float = origTime + deltaMs;
        if (newTime < 0) newTime = 0;
        var newLayer:Int = origLayer + deltaLayer;
        if (newLayer < 0) newLayer = 0;
        if (newLayer >= _viewport.layers.length) newLayer = _viewport.layers.length - 1;

        var moved:Bool = Math.abs(newTime - origTime) > 0.5 || newLayer != origLayer;
        if (moved) anyMoved = true;

        var origLayerName:String = origLayer < _viewport.layers.length ? _viewport.layers[origLayer].name : "Default";
        var newLayerName:String = newLayer < _viewport.layers.length ? _viewport.layers[newLayer].name : "Default";
        var durationSteps:Float = TimelineUtil.getEventDurationSteps(block.eventData);

        deltas.push(
          {
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
    _viewport.refreshLayout();

    _dragMode = NONE;
    _dragTarget = null;
  }

  function _isOnPlayhead(localX:Float):Bool
  {
    var playheadX = _viewport.msToPixelX(_viewport.songPositionMs);
    return Math.abs(localX - playheadX) <= PLAYHEAD_GRAB_TOLERANCE_PX;
  }

  function _dispatchClampedSeek(clickMs:Float):Void
  {
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
    var additive:Bool = e.ctrlKey;

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
        var isDoubleClick:Bool = (now - _lastClickTime) <= DOUBLE_CLICK_MAX_DELAY
          && Math.abs(localX - _lastClickX) <= DOUBLE_CLICK_MAX_DIST_PX
          && Math.abs(localY - _lastClickY) <= DOUBLE_CLICK_MAX_DIST_PX;

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
        _handleDragMove(localX, localY - TimelineViewport.TOP_BAR_HEIGHT, _snapEnabled() != e.shiftKey);
      case RESIZE_LEFT:
        _handleDragResizeLeft(localX, _snapEnabled() != e.shiftKey);
      case RESIZE_RIGHT:
        _handleDragResizeRight(localX, _snapEnabled() != e.shiftKey);
      case SEEKING:
        Screen.instance.setCursor("grabbing");
        var seekMs = _viewport.pixelXToMs(localX);
        if (seekMs < 0) seekMs = 0;
        if (seekMs > _viewport.songLengthMs) seekMs = _viewport.songLengthMs;
        var seekEvent = new TimelineEvent(TimelineEvent.SEEK);
        seekEvent.seekPositionMs = seekMs;
        _viewport.dispatch(seekEvent);
      case PANNING:
        Screen.instance.setCursor("grabbing");
        var dx = e.screenX - _panLastScreenX;
        var dy = e.screenY - _panLastScreenY;
        _panLastScreenX = e.screenX;
        _panLastScreenY = e.screenY;

        var pxPerMs = _viewport.pixelsPerMs * _viewport.zoomLevel;
        if (pxPerMs > 0) _viewport.scrollOffsetMs = _viewport.scrollOffsetMs - dx / pxPerMs;
        if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;

        _viewport.layerScrollOffsetPx = _viewport.layerScrollOffsetPx - dy;
        _viewport.refreshLayout();
      case BOX_SELECTING:
        _updateSelectionBoxOverlay(e.screenX, e.screenY);
        _viewport.setSelectedEvents(_computeBoxSelection(localX, localY));
        Screen.instance.setCursor("crosshair");
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
      var by1:Float = block.blockTop;
      var by2:Float = block.blockTop + TimelineEventBlock.BLOCK_HEIGHT;
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
    if (e.shiftKey)
    {
      var localX = e.screenX - _viewport.screenLeft;
      var mouseMs = _viewport.pixelXToMs(localX);
      var newZoom = _viewport.zoomLevel * (1.0 + e.delta * 0.1);
      if (newZoom < 0.1) newZoom = 0.1;
      if (newZoom > 10.0) newZoom = 10.0;
      _viewport.zoomLevel = newZoom;

      var pxPerMs = _viewport.pixelsPerMs * newZoom;
      if (pxPerMs > 0) _viewport.scrollOffsetMs = mouseMs - (localX / pxPerMs);
      if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;
    }
    else if (e.ctrlKey)
    {
      var maxScroll = _viewport.maxLayerScrollPx;
      if (maxScroll <= 0)
      {
        _viewport.layerScrollOffsetPx = 0;
      }
      else
      {
        var scrollPx = e.delta * TimelineViewport.LAYER_HEIGHT;
        var newOffset = _viewport.layerScrollOffsetPx - scrollPx;
        if (newOffset < 0) newOffset = 0;
        if (newOffset > maxScroll) newOffset = maxScroll;
        _viewport.layerScrollOffsetPx = newOffset;
      }
    }
    else
    {
      var pxPerMs = _viewport.pixelsPerMs * _viewport.zoomLevel;
      var scrollMs = pxPerMs > 0 ? (e.delta * 100) / pxPerMs : 0;
      _viewport.scrollOffsetMs = _viewport.scrollOffsetMs - scrollMs;
      if (_viewport.scrollOffsetMs < 0) _viewport.scrollOffsetMs = 0;
    }

    _viewport.refreshLayout();

    var zoomEvent = new TimelineEvent(TimelineEvent.ZOOM_CHANGED);
    _viewport.dispatch(zoomEvent);
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
          desiredCursor = "move";
          if (!fixed)
          {
            hitBlock.addClass("resize-left");
            _hoverBlock = hitBlock;
          }
        case RIGHT_EDGE:
          desiredCursor = "move";
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

  function _handleDragMove(mouseX:Float, mouseY:Float, snapToGrid:Bool):Void
  {
    if (_dragTarget == null) return;

    var newTimeMs:Float = _viewport.pixelXToMs(mouseX) - _dragOffsetMs;
    if (newTimeMs < 0) newTimeMs = 0;

    if (snapToGrid && _viewport.stepLengthMs > 0)
    {
      var stepMs:Float = _viewport.stepLengthMs;
      newTimeMs = Math.fround(newTimeMs / stepMs) * stepMs;
    }

    var newLayerIndex:Int = _viewport.pixelYToLayerIndex(mouseY);
    var moved:Bool = Math.abs(newTimeMs - _dragOriginalTime) > 0.5 || newLayerIndex != _dragOriginalLayerIndex;

    _ghostTimeMs = newTimeMs;

    if (newLayerIndex != _ghostLayerIndex && newLayerIndex < _viewport.layers.length) _ghostLayerIndex = newLayerIndex;

    if (moved && _dragGhosts.length == 0) _createGhosts();

    if (_dragGhosts.length > 0)
    {
      var deltaMs:Float = _ghostTimeMs - _dragOriginalTime;
      var deltaLayer:Int = _ghostLayerIndex - _dragOriginalLayerIndex;
      for (i in 0..._dragGroupEvents.length)
      {
        var ghost:Box = _dragGhosts[i];
        if (ghost == null) continue;
        var block:TimelineEventBlock = _dragGroupEvents[i];
        var origTime:Float = _dragGroupOriginalTimes[i];
        var origLayer:Int = _dragGroupOriginalLayerIndices[i];
        var gTime:Float = origTime + deltaMs;
        if (gTime < 0) gTime = 0;
        var gLayer:Int = origLayer + deltaLayer;
        if (gLayer < 0) gLayer = 0;
        if (gLayer >= _viewport.layers.length) gLayer = _viewport.layers.length - 1;

        var durationSteps:Float = TimelineUtil.getEventDurationSteps(block.eventData);
        _applyGhostStyle(ghost, gLayer);
        _positionGhost(ghost, gTime, durationSteps, gLayer);
      }
    }
  }

  function _handleDragResizeRight(mouseX:Float, snapToGrid:Bool):Void
  {
    if (_dragTarget == null) return;

    var mouseMs = _viewport.pixelXToMs(mouseX);
    var newDurationMs = mouseMs - _dragTarget.eventData.time;
    var newDurationSteps = _viewport.stepLengthMs > 0 ? newDurationMs / _viewport.stepLengthMs : 1.0;

    var minSteps = TimelineUtil.getMinDurationSteps(_dragTarget.eventData);
    if (newDurationSteps < minSteps) newDurationSteps = minSteps;

    if (snapToGrid) newDurationSteps = Math.fround(newDurationSteps);

    TimelineUtil.setEventDurationSteps(_dragTarget.eventData, newDurationSteps);
    _viewport.refreshLayout();
  }

  function _handleDragResizeLeft(mouseX:Float, snapToGrid:Bool):Void
  {
    if (_dragTarget == null) return;

    var minSteps = TimelineUtil.getMinDurationSteps(_dragTarget.eventData);
    var mouseMs = _viewport.pixelXToMs(mouseX);
    var originalEndMs = _dragOriginalTime + (_dragOriginalDuration * _viewport.stepLengthMs);

    var newStartMs = mouseMs;
    var maxStart = originalEndMs - (minSteps * _viewport.stepLengthMs);
    if (newStartMs > maxStart) newStartMs = maxStart;
    if (newStartMs < 0) newStartMs = 0;

    if (snapToGrid && _viewport.stepLengthMs > 0)
    {
      var stepMs = _viewport.stepLengthMs;
      newStartMs = Math.fround(newStartMs / stepMs) * stepMs;
    }

    var newDurationMs = originalEndMs - newStartMs;
    var newDurationSteps = _viewport.stepLengthMs > 0 ? newDurationMs / _viewport.stepLengthMs : 1.0;

    _dragTarget.eventData.time = newStartMs;
    TimelineUtil.setEventDurationSteps(_dragTarget.eventData, newDurationSteps);
    _viewport.refreshLayout();
  }

  function _snapEnabled():Bool
  {
    var timeline = _viewport.findAncestor(EventTimeline);
    return timeline == null ? true : timeline.snapEnabled;
  }
}
#end
