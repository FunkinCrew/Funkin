package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.graphics.shaders.TimelineShader;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineEventBlock.TimelineBlockHitZone;
import funkin.ui.haxeui.components.editors.timeline.TimelineEventBlock.TimelineDragMode;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.components.Image;
import haxe.ui.containers.Box;
import haxe.ui.core.Component;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.MouseEvent;
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
  public var stepLengthMs:Float = 125.0;
  public var songLengthMs:Float = 0;
  public var beatsPerGroup:Int = 1;
  public var playhead:Box;
  public var layerTopOffset:Float = 0;
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
    var idx = Std.int((py - layerTopOffset) / LAYER_HEIGHT);
    if (idx < 0) return 0;
    if (idx >= layers.length) return layers.length - 1;
    return idx;
  }

  public function refreshLayout():Void
  {
    if (songLengthMs > 0 && scrollOffsetMs > songLengthMs) scrollOffsetMs = songLengthMs;
    invalidateComponentLayout();
    if (onRefresh != null) onRefresh();
  }

  public function rebuildBlocks(events:Array<SongEventData>):Void
  {
    for (block in eventBlocks)
      removeComponent(block);
    eventBlocks = [];

    for (event in events)
    {
      if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera") continue;

      var block = new TimelineEventBlock();
      block.eventData = event;

      var raw:SongEventDataRaw = event;
      var layerName = raw.editorLayer != null ? raw.editorLayer : "Default";
      block.layerIndex = getLayerIndex(layerName);

      if (block.layerIndex >= 0 && block.layerIndex < layers.length) block.applyColor(layers[block.layerIndex].color);

      addComponent(block);

      var icon = block.findComponent("block-icon", Image);
      if (icon != null)
      {
        var iconRes = TimelineEventBlock.getIconResource(event.eventKind);
        if (iconRes != null) icon.resource = iconRes;
        block._cachedIcon = icon;
      }

      eventBlocks.push(block);
    }

    refreshLayout();
  }

  public function getLayerIndex(layerName:String):Int
  {
    for (i in 0...layers.length)
    {
      if (layers[i].name == layerName) return i;
    }
    return 0;
  }

  public static function getBlockTopPositionFromLayerIndex(layerIndex:Int):Float
  {
    return (layerIndex * TimelineViewport.LAYER_HEIGHT
      + (TimelineViewport.LAYER_HEIGHT - TimelineEventBlock.BLOCK_HEIGHT) / 2)
      + TimelineViewport.TOP_BAR_HEIGHT;
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
    playhead.width = 2;
    _viewport.addComponent(playhead);
    _viewport.playhead = playhead;
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
      var phLeft = (vp.songPositionMs - vp.scrollOffsetMs) * vp.pixelsPerMs * vp.zoomLevel;
      vp.playhead.left = phLeft;
      vp.playhead.top = 0;
      vp.playhead.height = h;
      vp.playhead.hidden = (phLeft < -2 || phLeft > w);
    }

    for (block in vp.eventBlocks)
    {
      var durationSteps = TimelineUtil.getEventDurationSteps(block.eventData);
      var durationMs = durationSteps * vp.stepLengthMs;

      var blockLeftPos = (block.eventData.time - vp.scrollOffsetMs) * vp.pixelsPerMs * vp.zoomLevel;
      var blockWidthVal = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, durationMs * vp.pixelsPerMs * vp.zoomLevel);

      var isOffscreen = (blockLeftPos + blockWidthVal < 0) || (blockLeftPos > w);

      if (isOffscreen != block.hidden) block.hidden = isOffscreen;

      if (isOffscreen) continue;

      var blockTopPos = TimelineViewport.getBlockTopPositionFromLayerIndex(block.layerIndex);
      if (block.left != blockLeftPos) block.left = blockLeftPos;
      if (block.top != blockTopPos) block.top = blockTopPos;
      if (block.width != blockWidthVal) block.width = blockWidthVal;

      block.blockLeft = blockLeftPos;
      block.blockTop = blockTopPos;
      block.blockWidth = blockWidthVal;

      if (block._cachedIcon == null) block._cachedIcon = block.findComponent("block-icon", Image);

      var icon = block._cachedIcon;
      if (icon != null)
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
        }
        else
        {
          // Block is too narrow: fill the block and center
          iconSize = Math.max(16, blockWidthVal);
          iconLeft = (blockWidthVal - iconSize) / 2;
        }

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
  var _viewport:TimelineViewport;

  var _dragMode:TimelineDragMode = NONE;
  var _dragTarget:TimelineEventBlock;
  var _dragOffsetMs:Float = 0;
  var _dragOriginalTime:Float = 0;
  var _dragOriginalDuration:Float = 0;
  var _dragOriginalLayerIndex:Int = 0;
  var _hoverBlock:TimelineEventBlock;

  var _ghost:Box;
  var _ghostTimeMs:Float = 0;
  var _ghostDurationSteps:Float = 0;
  var _ghostLayerIndex:Int = 0;

  public function new(viewport:TimelineViewport)
  {
    super(viewport);
    _viewport = viewport;
  }

  override public function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_DOWN, _onMouseDown)) registerEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    if (!hasEvent(MouseEvent.MOUSE_MOVE, _onMouseMove)) registerEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    if (!hasEvent(MouseEvent.MOUSE_UP, _onMouseUp)) registerEvent(MouseEvent.MOUSE_UP, _onMouseUp);
    if (!hasEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel)) registerEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
  }

  override public function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_DOWN, _onMouseDown);
    unregisterEvent(MouseEvent.MOUSE_MOVE, _onMouseMove);
    unregisterEvent(MouseEvent.MOUSE_UP, _onMouseUp);
    unregisterEvent(MouseEvent.MOUSE_WHEEL, _onMouseWheel);
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

  function _selectBlock(block:TimelineEventBlock):Void
  {
    _deselectAll();
    block.selected = true;
    if (block.layerIndex >= 0 && block.layerIndex < _viewport.layers.length) block.applyColor(_viewport.layers[block.layerIndex].color);

    var selectEvent = new TimelineEvent(TimelineEvent.EVENT_SELECTED);
    selectEvent.eventData = block.eventData;
    _viewport.dispatch(selectEvent);
  }

  function _deselectAll():Void
  {
    for (block in _viewport.eventBlocks)
    {
      if (block.selected)
      {
        block.selected = false;
        if (block.layerIndex >= 0
          && block.layerIndex < _viewport.layers.length) block.applyColor(_viewport.layers[block.layerIndex].color);
      }
    }
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

    var fixed = TimelineUtil.isFixedDuration(block.eventData);

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
  }

  function _createGhost():Void
  {
    _removeGhost();
    _ghost = new Box();
    _ghost.addClass("timeline-ghost");
    _ghost.height = TimelineEventBlock.BLOCK_HEIGHT;
    _ghost.customStyle.borderRadius = 3;
    _ghost.customStyle.pointerEvents = "none";
    _updateGhostColor();
    _viewport.addComponent(_ghost);
    _positionGhost();
  }

  function _removeGhost():Void
  {
    if (_ghost != null)
    {
      _viewport.removeComponent(_ghost);
      _ghost = null;
    }
  }

  function _updateGhostColor():Void
  {
    if (_ghost == null) return;
    var color = 0x888888;
    if (_ghostLayerIndex >= 0 && _ghostLayerIndex < _viewport.layers.length) color = _viewport.layers[_ghostLayerIndex].color;
    _ghost.customStyle.backgroundColor = color;
    _ghost.customStyle.backgroundOpacity = 0.4;
    _ghost.customStyle.borderColor = color;
    _ghost.customStyle.borderSize = 1;
    _ghost.invalidateComponentStyle();
  }

  function _positionGhost():Void
  {
    if (_ghost == null) return;
    var durationMs = _ghostDurationSteps * _viewport.stepLengthMs;
    var ghostLeft = (_ghostTimeMs - _viewport.scrollOffsetMs) * _viewport.pixelsPerMs * _viewport.zoomLevel;
    var ghostTop = TimelineViewport.getBlockTopPositionFromLayerIndex(_ghostLayerIndex);
    var ghostWidth = Math.max(TimelineViewport.MIN_BLOCK_WIDTH, durationMs * _viewport.pixelsPerMs * _viewport.zoomLevel);
    _ghost.left = ghostLeft;
    _ghost.top = ghostTop;
    _ghost.width = ghostWidth;
  }

  function _endDrag():Void
  {
    if (_dragTarget == null || _dragMode == NONE) return;

    var isMove = _dragMode == MOVE;

    if (isMove)
    {
      var timeMoved = Math.abs(_ghostTimeMs - _dragOriginalTime) > 0.5;
      var layerChanged = _dragOriginalLayerIndex != _ghostLayerIndex;

      if (timeMoved || layerChanged)
      {
        _dragTarget.eventData.time = _ghostTimeMs;
        _dragTarget.layerIndex = _ghostLayerIndex;
        if (_ghostLayerIndex < _viewport.layers.length)
        {
          var raw:SongEventDataRaw = _dragTarget.eventData;
          raw.editorLayer = _viewport.layers[_ghostLayerIndex].name;
          _dragTarget.applyColor(_viewport.layers[_ghostLayerIndex].color);
        }

        var moveEvent = new TimelineEvent(TimelineEvent.EVENT_MOVED);
        moveEvent.eventData = _dragTarget.eventData;
        moveEvent.oldTime = _dragOriginalTime;
        moveEvent.newTime = _ghostTimeMs;
        if (_dragOriginalLayerIndex < _viewport.layers.length) moveEvent.oldLayerName = _viewport.layers[_dragOriginalLayerIndex].name;
        if (_ghostLayerIndex < _viewport.layers.length) moveEvent.newLayerName = _viewport.layers[_ghostLayerIndex].name;
        _viewport.dispatch(moveEvent);
      }
    }
    else
    {
      var newDuration = TimelineUtil.getEventDurationSteps(_dragTarget.eventData);
      var durationChanged = Math.abs(newDuration - _dragOriginalDuration) > 0.01;

      if (durationChanged)
      {
        var resizeEvent = new TimelineEvent(TimelineEvent.EVENT_RESIZED);
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

    _removeGhost();
    _viewport.refreshLayout();

    _dragMode = NONE;
    _dragTarget = null;
  }

  function _onMouseDown(e:MouseEvent):Void
  {
    var localX = e.screenX - _viewport.screenLeft;
    var localY = e.screenY - _viewport.screenTop;

    var hitBlock = _hitTestBlocks(localX, localY);

    if (hitBlock != null)
    {
      var hitZone = hitBlock.getHitZone(localX - hitBlock.blockLeft);
      _beginDrag(hitBlock, hitZone, localX);
      _selectBlock(hitBlock);
    }
    else
    {
      _deselectAll();
      var deselectEvent = new TimelineEvent(TimelineEvent.EVENT_SELECTED);
      deselectEvent.eventData = null;
      _viewport.dispatch(deselectEvent);
      _dragMode = SEEKING;
      var clickMs = _viewport.pixelXToMs(localX);
      if (clickMs >= 0 && clickMs <= _viewport.songLengthMs)
      {
        var seekEvent = new TimelineEvent(TimelineEvent.SEEK);
        seekEvent.seekPositionMs = clickMs;
        _viewport.dispatch(seekEvent);
      }
    }
  }

  function _onMouseMove(e:MouseEvent):Void
  {
    var localX = e.screenX - _viewport.screenLeft;
    var localY = e.screenY - _viewport.screenTop - TimelineViewport.TOP_BAR_HEIGHT;

    switch (_dragMode)
    {
      case NONE:
        _updateHoverCursor(localX, localY);
      case MOVE:
        _handleDragMove(localX, localY, e.shiftKey);
      case RESIZE_LEFT:
        _handleDragResizeLeft(localX, e.shiftKey);
      case RESIZE_RIGHT:
        _handleDragResizeRight(localX, e.shiftKey);
      case SEEKING:
        var seekMs = _viewport.pixelXToMs(localX);
        if (seekMs < 0) seekMs = 0;
        if (seekMs > _viewport.songLengthMs) seekMs = _viewport.songLengthMs;
        var seekEvent = new TimelineEvent(TimelineEvent.SEEK);
        seekEvent.seekPositionMs = seekMs;
        _viewport.dispatch(seekEvent);
    }
  }

  function _onMouseUp(e:MouseEvent):Void
  {
    if (_dragMode == SEEKING) _dragMode = NONE;
    else if (_dragMode != NONE) _endDrag();
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

    var hitBlock = _hitTestBlocks(localX, localY);
    if (hitBlock != null)
    {
      var hitZone = hitBlock.getHitZone(localX - hitBlock.blockLeft);
      var fixed = TimelineUtil.isFixedDuration(hitBlock.eventData);
      switch (hitZone)
      {
        case LEFT_EDGE:
          _viewport.customStyle.cursor = fixed ? "move" : "col-resize";
          _viewport.invalidateComponentStyle();
          if (!fixed)
          {
            hitBlock.addClass("resize-left");
            _hoverBlock = hitBlock;
          }
        case RIGHT_EDGE:
          _viewport.customStyle.cursor = fixed ? "move" : "col-resize";
          _viewport.invalidateComponentStyle();
          if (!fixed)
          {
            hitBlock.addClass("resize-right");
            _hoverBlock = hitBlock;
          }
        case BODY:
          _viewport.customStyle.cursor = "move";
          _viewport.invalidateComponentStyle();
      }
    }
    else
    {
      _viewport.customStyle.cursor = "default";
      _viewport.invalidateComponentStyle();
    }
  }

  function _handleDragMove(mouseX:Float, mouseY:Float, snapToGrid:Bool):Void
  {
    if (_dragTarget == null) return;

    var newTimeMs = _viewport.pixelXToMs(mouseX) - _dragOffsetMs;
    if (newTimeMs < 0) newTimeMs = 0;

    if (snapToGrid && _viewport.stepLengthMs > 0)
    {
      var stepMs = _viewport.stepLengthMs;
      newTimeMs = Math.fround(newTimeMs / stepMs) * stepMs;
    }

    var newLayerIndex = _viewport.pixelYToLayerIndex(mouseY);
    var moved = Math.abs(newTimeMs - _dragOriginalTime) > 0.5 || newLayerIndex != _dragOriginalLayerIndex;

    _ghostTimeMs = newTimeMs;

    if (newLayerIndex != _ghostLayerIndex && newLayerIndex < _viewport.layers.length)
    {
      _ghostLayerIndex = newLayerIndex;
      if (_ghost != null) _updateGhostColor();
    }

    if (moved && _ghost == null) _createGhost();

    if (_ghost != null) _positionGhost();
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
}
#end
