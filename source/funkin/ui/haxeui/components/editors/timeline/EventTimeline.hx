package funkin.ui.haxeui.components.editors.timeline;

#if FEATURE_CAMERA_EDITOR
import funkin.graphics.shaders.TimelineShader;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.behaviours.DefaultBehaviour;
import haxe.ui.components.HorizontalScroll;
import haxe.ui.components.VerticalScroll;
import haxe.ui.components.Slider;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.Events;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;

@:composite(EventTimelineEvents, TimelineBuilder)
@:xml('
<vbox width="100%" height="100%" style="background-color: #2A2A2A;" />
')
class EventTimeline extends VBox
{
  public static inline var LAYER_PANEL_WIDTH:Int = 120;

  public var toolbar:TimelineToolbar;
  public var layerPanel:TimelineLayerPanel;
  public var viewport:TimelineViewport;
  public var scrollbar:HorizontalScroll;
  public var vscrollbar:VerticalScroll;
  public var scrollbarPlayhead:Box;
  @:clonable @:behaviour(SongPositionBehaviour, 0)
  public var songPosition:Float;
  @:clonable @:behaviour(SongLengthBehaviour, 0)
  public var songLength:Float;
  @:clonable @:behaviour(DefaultBehaviour, false)
  public var isPlaying:Bool;
  @:clonable @:behaviour(DefaultBehaviour, 2)
  public var autoScrollMode:Int;
  @:clonable @:behaviour(DefaultBehaviour, true)
  public var snapEnabled:Bool;
  public static final SNAP_GRIDS:Array<Float> = [1, 0.5, 1 / 3, 0.25, 1 / 6, 0.125, 1 / 12, 0.0625, 1 / 24, 1 / 48, 0];
  public static final SNAP_NAMES:Array<String> = ['1/4', '1/8', '1/12', '1/16', '1/24', '1/32', '1/48', '1/64', '1/96', '1/192', 'free'];

  public var snapIndex(default, set):Int = 3;

  function set_snapIndex(value:Int):Int
  {
    snapIndex = value;
    if (toolbar != null && toolbar.btnSnapGrid != null) toolbar.btnSnapGrid.text = 'Snap ' + snapName();
    if (viewport != null) viewport.refreshLayout();
    return value;
  }

  public function new()
  {
    super();
    percentWidth = 100;
    percentHeight = 100;
  }

  public function snapName():String
  {
    return SNAP_NAMES[snapIndex];
  }

  /**
   * The grid in ms, or zero for none.
   */
  public function snapGridMs():Float
  {
    var beats:Float = SNAP_GRIDS[snapIndex];
    if (beats <= 0 || viewport == null) return 0;
    return beats * viewport.stepLengthMs * Constants.STEPS_PER_BEAT;
  }

  /**
   * Walks the grid list, wrapping at either end.
   */
  public function stepSnap(by:Int):Void
  {
    var n:Int = SNAP_GRIDS.length;
    snapIndex = ((snapIndex + by) % n + n) % n;
  }

  /**
   * The grid as the lanes draw it, in lines per bar. A grid finer than a few pixels is drawn a
   * beat at a time instead, and finer than that a bar at a time.
   */
  public function gridLinesPerBar():Float
  {
    if (viewport == null) return Constants.STEPS_PER_BEAT;

    var beats:Float = SNAP_GRIDS[snapIndex];
    if (beats <= 0) beats = 1;

    var pxPerBeat:Float = viewport.pixelsPerBeat * viewport.zoomLevel;
    if (beats * pxPerBeat < GRID_TIGHT_PX) beats = 1;
    if (beats * pxPerBeat < GRID_TIGHT_PX) beats = Constants.STEPS_PER_BEAT;

    return Constants.STEPS_PER_BEAT / beats;
  }

  // Under this and a gridline is closer to its neighbor than it is wide.
  static inline var GRID_TIGHT_PX:Float = 6;

  /**
   * A time put on the grid. ALT is the way past it, held rather than set, for one placement.
   */
  public function snapMs(ms:Float):Float
  {
    // ALT does the opposite of the toggle for as long as it is held.
    if (snapEnabled == FlxG.keys.pressed.ALT) return ms;

    var grid:Float = snapGridMs();
    if (grid <= 0) return ms;

    return Math.fround(ms / grid) * grid;
  }

  public function loadTimelineStyles():Void
  {
    haxe.ui.Toolkit.styleSheet.parse(
      '
      .timeline-viewport {
        background-color: #FFFFFF;
        clip: true;
        overflow: hidden;
      }
      .timeline-playhead {
        background-color: #5BA3FF;
        pointer-events: none;
      }
      .timeline-playhead-topper {
        background-color: #5BA3FF;
        background-opacity: 0.6;
        border: 1px solid #5BA3FF;
        border-radius: 3px;
        pointer-events: none;
      }
      .resize-left {
        border-left-color: #FFFFFF;
        border-left-width: 2px;
      }
      .resize-right {
        border-right-color: #FFFFFF;
        border-right-width: 2px;
      }
      .layer-name-field {
        background-color: none;
        border: none;
        filter: none;
        padding-left: 4px;
      }
      .layer-name-field:disabled {
        background-color: none;
        color: #CCCCCC;
        filter: none;
        border: none;
      }
      .layer-name-field:active {
        background-color: #1F1F1F;
        border: none;
        filter: none;
      }
      .layer-name-field.invalid {
        background-color: #5A1F1F;
        color: #FF9999;
        border: none;
        filter: none;
      }
      .timeline-selection-box {
        background-color: #5BA3FF;
        background-opacity: 0.18;
        border: 1px solid #5BA3FF;
      }
    '
    );
  }

  /**
   * "cold path" — only called from `CameraEditorState.loadTimeline()` (initial load and variation switches).
   * Rebuilds every row and block from scratch via `rebuildLayers` / `rebuildBlocks`.
   * Commands must use the surgical methods on `viewport` / `layerPanel` (`addEventBlock`, `insertLayerRow`, etc.)
   * rather than calling this — otherwise every edit flickers the whole timeline.
   */
  public function setEvents(events:Array<SongEventData>):Void
  {
    var newLayers = TimelineLayerData.buildLayersFromEvents(events);

    if (viewport.layers.length == 0)
    {
      viewport.layers = newLayers;
    }
    else
    {
      for (nl in newLayers)
      {
        var found = false;
        for (existing in viewport.layers)
        {
          if (existing.name == nl.name)
          {
            found = true;
            break;
          }
        }
        if (!found) viewport.layers.push(nl);
      }
    }

    layerPanel.rebuildLayers(viewport.layers);
    viewport.rebuildBlocks(events);
  }

  public function setStepLengthMs(stepMs:Float):Void
  {
    viewport.stepLengthMs = stepMs;
    viewport.refreshLayout();
  }
}

@:dox(hide)
@:noCompletion
private class TimelineBuilder extends CompositeBuilder
{
  var _timeline:EventTimeline;

  public function new(timeline:EventTimeline)
  {
    super(timeline);
    _timeline = timeline;
  }

  override public function create():Void
  {
    _timeline.loadTimelineStyles();

    _timeline.layerPanel = new TimelineLayerPanel();

    var topRow = new HBox();
    topRow.id = "timeline-top-row";
    topRow.percentWidth = 100;
    topRow.customStyle.backgroundColor = 0x3A3A3A;

    _timeline.toolbar = new TimelineToolbar();
    _timeline.toolbar.percentWidth = 100;
    topRow.addComponent(_timeline.toolbar);

    _timeline.addComponent(topRow);

    var scrollRow = new HBox();
    scrollRow.id = "timeline-scroll-row";
    scrollRow.percentWidth = 100;
    var scrollSpacer = new Box();
    scrollSpacer.width = EventTimeline.LAYER_PANEL_WIDTH;
    scrollRow.addComponent(scrollSpacer);

    var scrollWrapper = new Box();
    scrollWrapper.id = "timeline-scroll-wrapper";
    scrollWrapper.percentWidth = 100;
    scrollWrapper.height = 14;
    scrollWrapper.customStyle.clip = true;

    _timeline.scrollbar = new HorizontalScroll();
    _timeline.scrollbar.id = "timeline-scrollbar";
    _timeline.scrollbar.percentWidth = 100;
    _timeline.scrollbar.min = 0;
    _timeline.scrollbar.max = 0;
    _timeline.scrollbar.pos = 0;
    _timeline.scrollbar.height = 14;
    scrollWrapper.addComponent(_timeline.scrollbar);

    _timeline.scrollbarPlayhead = new Box();
    _timeline.scrollbarPlayhead.id = "timeline-scrollbar-playhead";
    _timeline.scrollbarPlayhead.width = 3;
    _timeline.scrollbarPlayhead.height = 10;
    _timeline.scrollbarPlayhead.customStyle.backgroundColor = 0xFFFFFF;
    _timeline.scrollbarPlayhead.customStyle.borderRadius = 1;
    _timeline.scrollbarPlayhead.customStyle.pointerEvents = "none";
    scrollWrapper.addComponent(_timeline.scrollbarPlayhead);

    scrollRow.addComponent(scrollWrapper);
    _timeline.addComponent(scrollRow);

    var contentRow = new HBox();
    contentRow.id = "timeline-content-row";
    contentRow.percentWidth = 100;
    contentRow.percentHeight = 100;

    _timeline.layerPanel.percentHeight = 100;
    contentRow.addComponent(_timeline.layerPanel);

    _timeline.viewport = new TimelineViewport();
    _timeline.viewport.percentWidth = 100;
    _timeline.viewport.percentHeight = 100;
    contentRow.addComponent(_timeline.viewport);

    _timeline.vscrollbar = new VerticalScroll();
    _timeline.vscrollbar.id = "timeline-vscrollbar";
    _timeline.vscrollbar.percentHeight = 100;
    _timeline.vscrollbar.width = 14;
    _timeline.vscrollbar.min = 0;
    _timeline.vscrollbar.max = 0;
    _timeline.vscrollbar.pos = 0;
    contentRow.addComponent(_timeline.vscrollbar);

    _timeline.layerPanel.viewport = _timeline.viewport;

    _timeline.addComponent(contentRow);
  }
}

@:dox(hide)
@:noCompletion
private class EventTimelineEvents extends Events
{
  var _timeline:EventTimeline;
  var _updatingScrollbar:Bool = false;

  static inline var PUSH_HISTORY:Int = 4;
  var _pushedScroll:Array<Float> = [];
  var _pushedVScroll:Array<Float> = [];
  var _pushedZoom:Array<Float> = [];

  function _push(list:Array<Float>, value:Float):Void
  {
    list.push(value);
    while (list.length > PUSH_HISTORY) list.shift();
  }

  function _isEcho(list:Array<Float>, value:Float):Bool
  {
    for (pushed in list) if (Math.abs(pushed - value) < 0.0001) return true;
    return false;
  }

  public function new(timeline:EventTimeline)
  {
    super(timeline);
    _timeline = timeline;
  }

  override public function register():Void
  {
    if (!_timeline.layerPanel.btnAddLayer.hasEvent(
      MouseEvent.CLICK,
      _onAddLayer
    )) _timeline.layerPanel.btnAddLayer.registerEvent(MouseEvent.CLICK, _onAddLayer);
    if (!_timeline.layerPanel.btnRemoveLayer.hasEvent(
      MouseEvent.CLICK,
      _onRemoveLayer
    )) _timeline.layerPanel.btnRemoveLayer.registerEvent(MouseEvent.CLICK, _onRemoveLayer);
    if (!_timeline.layerPanel.hasEvent(
      MouseEvent.MOUSE_WHEEL,
      _onLayerPanelWheel
    )) _timeline.layerPanel.registerEvent(MouseEvent.MOUSE_WHEEL, _onLayerPanelWheel);
    if (!_timeline.scrollbar.hasEvent(UIEvent.CHANGE, _onScrollbarChange)) _timeline.scrollbar.registerEvent(UIEvent.CHANGE, _onScrollbarChange);
    if (!_timeline.vscrollbar.hasEvent(UIEvent.CHANGE, _onVScrollbarChange)) _timeline.vscrollbar.registerEvent(UIEvent.CHANGE, _onVScrollbarChange);
    if (!_timeline.toolbar.ddAutoScroll.hasEvent(
      UIEvent.CHANGE,
      _onAutoScrollChange
    )) _timeline.toolbar.ddAutoScroll.registerEvent(UIEvent.CHANGE, _onAutoScrollChange);
    if (!_timeline.toolbar.btnSnapGrid.hasEvent(MouseEvent.CLICK, _onSnapGridClick)) _timeline.toolbar.btnSnapGrid.registerEvent(MouseEvent.CLICK, _onSnapGridClick);
    if (!_timeline.toolbar.chkSnap.hasEvent(UIEvent.CHANGE, _onSnapChange)) _timeline.toolbar.chkSnap.registerEvent(UIEvent.CHANGE, _onSnapChange);
    if (!_timeline.viewport.hasEvent(UIEvent.RESIZE, _onViewportResized)) _timeline.viewport.registerEvent(UIEvent.RESIZE, _onViewportResized);

    _timeline.viewport.onRefresh = _updateScrollbar;

    var zoomSlider = _timeline.toolbar.findComponent("zoomSlider");
    if (zoomSlider != null && !zoomSlider.hasEvent(UIEvent.CHANGE, _onZoomChange)) zoomSlider.registerEvent(UIEvent.CHANGE, _onZoomChange);
  }

  override public function unregister():Void
  {
    _timeline.layerPanel.btnAddLayer.unregisterEvent(MouseEvent.CLICK, _onAddLayer);
    _timeline.layerPanel.btnRemoveLayer.unregisterEvent(MouseEvent.CLICK, _onRemoveLayer);
    _timeline.layerPanel.unregisterEvent(MouseEvent.MOUSE_WHEEL, _onLayerPanelWheel);
    _timeline.scrollbar.unregisterEvent(UIEvent.CHANGE, _onScrollbarChange);
    _timeline.vscrollbar.unregisterEvent(UIEvent.CHANGE, _onVScrollbarChange);
    _timeline.toolbar.ddAutoScroll.unregisterEvent(UIEvent.CHANGE, _onAutoScrollChange);
    _timeline.toolbar.btnSnapGrid.unregisterEvent(MouseEvent.CLICK, _onSnapGridClick);
    _timeline.toolbar.chkSnap.unregisterEvent(UIEvent.CHANGE, _onSnapChange);
    _timeline.viewport.unregisterEvent(UIEvent.RESIZE, _onViewportResized);

    var zoomSlider = _timeline.toolbar.findComponent("zoomSlider");
    if (zoomSlider != null) zoomSlider.unregisterEvent(UIEvent.CHANGE, _onZoomChange);
  }

  function _onAddLayer(_:MouseEvent):Void
  {
    var colorIdx = _timeline.viewport.layers.length % TimelineLayerData.DEFAULT_LAYER_COLORS.length;
    var newLayer = new TimelineLayerData('Layer ${_timeline.viewport.layers.length + 1}', TimelineLayerData.DEFAULT_LAYER_COLORS[colorIdx]);
    var insertIdx = _timeline.viewport.selectedLayerIndex + 1;

    var addEvent = new TimelineEvent(TimelineEvent.LAYER_ADDED);
    addEvent.layerData = newLayer;
    addEvent.layerIndex = insertIdx;
    _timeline.dispatch(addEvent);
  }

  function _onRemoveLayer(_:MouseEvent):Void
  {
    var selectedIdx:Int = _timeline.viewport.selectedLayerIndex;
    if (selectedIdx < 0 || selectedIdx >= _timeline.viewport.layers.length) return;

    var layer:TimelineLayerData = _timeline.viewport.layers[selectedIdx];
    if (layer.name == "Default")
    {
      _timeline.dispatch(new TimelineEvent(TimelineEvent.DEFAULT_LAYER_PROTECTED));
      return;
    }

    if (_timeline.viewport.layers.length <= 1) return;

    var removeEvent = new TimelineEvent(TimelineEvent.LAYER_REMOVED);
    removeEvent.layerData = layer;
    removeEvent.layerIndex = selectedIdx;
    _timeline.dispatch(removeEvent);
  }

  function _onLayerPanelWheel(e:MouseEvent):Void
  {
    _timeline.viewport.easeLayerScrollBy(e.delta);
  }

  function _onZoomChange(_:UIEvent):Void
  {
    if (_updatingScrollbar) return;

    var slider:Slider = _timeline.toolbar.findComponent("zoomSlider", Slider);
    if (slider == null) return;
    if (_isEcho(_pushedZoom, slider.pos)) return;

    var viewport:TimelineViewport = _timeline.viewport;
    var anchorX:Float = viewport.width / 2;
    var anchorMs:Float = viewport.pixelXToMs(anchorX);

    viewport.cancelScrollEase();
    viewport.cancelZoomEase();
    viewport.chasing = true;
    viewport.zoomLevel = slider.pos;

    var pxPerMs:Float = viewport.pixelsPerMs * viewport.zoomLevel;
    if (pxPerMs > 0) viewport.scrollOffsetMs = anchorMs - (anchorX / pxPerMs);
    if (viewport.scrollOffsetMs < 0) viewport.scrollOffsetMs = 0;

    viewport.refreshLayout();
  }

  function _onAutoScrollChange(_:UIEvent):Void
  {
    _timeline.autoScrollMode = _timeline.toolbar.ddAutoScroll.selectedIndex;
  }

  function _onSnapGridClick(_:MouseEvent):Void
  {
    _timeline.stepSnap(1);
  }

  function _onSnapChange(_:UIEvent):Void
  {
    _timeline.snapEnabled = _timeline.toolbar.chkSnap.selected;
  }

  function _onViewportResized(_:UIEvent):Void
  {
    _updateScrollbar();
  }

  function _onScrollbarChange(_:UIEvent):Void
  {
    if (_updatingScrollbar) return;
    if (_isEcho(_pushedScroll, _timeline.scrollbar.pos)) return;
    _timeline.viewport.cancelScrollEase();
    _timeline.viewport.chasing = false;
    _timeline.viewport.scrollOffsetMs = _timeline.scrollbar.pos;
    _timeline.viewport.refreshLayout();
  }

  function _onVScrollbarChange(_:UIEvent):Void
  {
    if (_updatingScrollbar) return;
    if (_isEcho(_pushedVScroll, _timeline.vscrollbar.pos)) return;
    _timeline.viewport.cancelLayerScrollEase();
    _timeline.viewport.layerScrollOffsetPx = _timeline.vscrollbar.pos;
    _timeline.viewport.refreshLayout();
  }

  function _updateScrollbar():Void
  {
    _updatingScrollbar = true;

    var pxPerMs = _timeline.viewport.pixelsPerMs * _timeline.viewport.zoomLevel;
    if (_timeline.viewport.songLengthMs > 0 && pxPerMs > 0)
    {
      var viewWidthMs = _timeline.viewport.width / pxPerMs;
      _timeline.scrollbar.max = _timeline.viewport.songLengthMs;
      _timeline.scrollbar.pageSize = viewWidthMs;
      _timeline.scrollbar.pos = _timeline.viewport.scrollOffsetMs;
      _push(_pushedScroll, _timeline.scrollbar.pos);
    }

    if (_timeline.scrollbarPlayhead != null && _timeline.viewport.songLengthMs > 0)
    {
      var scrollWidth = _timeline.scrollbar.width;
      var ratio = _timeline.viewport.songPositionMs / _timeline.viewport.songLengthMs;
      _timeline.scrollbarPlayhead.left = ratio * scrollWidth - 1;
      _timeline.scrollbarPlayhead.top = 2;
      _timeline.scrollbarPlayhead.hidden = ratio < 0 || ratio > 1;
    }

    var zoomSlider = _timeline.toolbar.findComponent("zoomSlider", Slider);
    if (zoomSlider != null && zoomSlider.pos != _timeline.viewport.zoomLevel)
    {
      zoomSlider.pos = _timeline.viewport.zoomLevel;
      _push(_pushedZoom, zoomSlider.pos);
    }

    var maxVScroll = _timeline.viewport.maxLayerScrollPx;
    if (maxVScroll > 0)
    {
      var viewableHeight = _timeline.viewport.viewableHeightPx;
      // HaxeUI: thumbHeight = (pageSize / (max - min)) * usableHeight.
      // virtualTotal = maxScroll + visible (the full span of content that passes
      // through the viewport across scroll range [0, max]).
      var virtualTotal = maxVScroll + viewableHeight;
      _timeline.vscrollbar.max = maxVScroll;
      _timeline.vscrollbar.pageSize = (viewableHeight / virtualTotal) * maxVScroll;
      _timeline.vscrollbar.pos = _timeline.viewport.layerScrollOffsetPx;
      _push(_pushedVScroll, _timeline.vscrollbar.pos);
      _timeline.vscrollbar.hidden = false;
    }
    else
    {
      _timeline.vscrollbar.max = 0;
      _timeline.vscrollbar.pos = 0;
      _push(_pushedVScroll, 0);
      _timeline.vscrollbar.hidden = true;
    }

    _timeline.layerPanel.setLayerHeight(_timeline.viewport.layerHeight);
    _timeline.layerPanel.setScrollOffset(_timeline.viewport.layerScrollOffsetPx);

    _updateTimelineVisuals();

    _updatingScrollbar = false;
  }

  function _updateTimelineVisuals():Void
  {
    // i dont wanna be doing this every time but checking the width/height fucked up for me when i tried doing it after creating the timeline
    _timeline.viewport.timelineShader.setViewSize(_timeline.viewport.width, _timeline.viewport.height);

    var pxPerBeat = _timeline.viewport.pixelsPerBeat * _timeline.viewport.zoomLevel;
    _timeline.viewport.timelineShader.beatLength = pxPerBeat;

    var correctedOffset = _timeline.viewport.scrollOffsetMs * _timeline.viewport.pixelsPerMs * _timeline.viewport.zoomLevel;
    _timeline.viewport.timelineShader.setOffset(correctedOffset, _timeline.viewport.layerScrollOffsetPx);

    var lengthInBeats = (_timeline.viewport.songLengthMs / _timeline.viewport.stepLengthMs) / 4;
    _timeline.viewport.timelineShader.beatCount = lengthInBeats;

    _timeline.viewport.timelineShader.layerCount = _timeline.viewport.layers.length;

    var gridLines:Float = _timeline.gridLinesPerBar();
    if (_timeline.viewport.timelineShader.gridLinesPerBar != gridLines) _timeline.viewport.timelineShader.gridLinesPerBar = gridLines;

    if (_timeline.viewport.timelineShader.layerHeight != _timeline.viewport.layerHeight)
    {
      _timeline.viewport.timelineShader.layerHeight = _timeline.viewport.layerHeight;
    }
  }
}

@:dox(hide)
@:noCompletion
private class SongPositionBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var tl:EventTimeline = cast(_component, EventTimeline);

    var pos:Float = _value;
    tl.viewport.songPositionMs = pos;
    tl.toolbar.songPosition = pos;

    // Suppress playback auto-scroll while the user is actively dragging
    // (SEEKING/MOVE) — their drag-driven edge scroll wins.
    if (!tl.isPlaying)
    {
      tl.viewport.chasing = true;
    }
    else if (!tl.viewport._autoScrollDragActive && (tl.autoScrollMode : TimelinePlaybackAutoScrollMode) != NONE)
    {
      var viewWidth = tl.viewport.width;
      var pxPerMs = tl.viewport.pixelsPerMs * tl.viewport.zoomLevel;
      var playheadPx = tl.viewport.msToPixelX(pos);

      if (!tl.viewport.chasing && playheadPx >= 0 && playheadPx <= viewWidth)
      {
        tl.viewport.refreshLayout();
        return;
      }
      tl.viewport.chasing = true;

      switch ((tl.autoScrollMode : TimelinePlaybackAutoScrollMode))
      {
        case NONE:
        case PAGE:
          if (viewWidth > 0 && pxPerMs > 0)
          {
            if (playheadPx > viewWidth * 0.95 || playheadPx < 0)
            {
              tl.viewport.cancelScrollEase();
              tl.viewport.scrollOffsetMs = pos - (viewWidth * 0.05 / pxPerMs);
              if (tl.viewport.scrollOffsetMs < 0) tl.viewport.scrollOffsetMs = 0;
            }
          }
        case SMOOTH:
          if (viewWidth > 0 && pxPerMs > 0)
          {
            tl.viewport.cancelScrollEase();
            tl.viewport.scrollOffsetMs = pos - (viewWidth * 0.5 / pxPerMs);
            if (tl.viewport.scrollOffsetMs < 0) tl.viewport.scrollOffsetMs = 0;
          }
      }
    }

    tl.viewport.refreshLayout();
  }
}

@:dox(hide)
@:noCompletion
private class SongLengthBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var tl:EventTimeline = cast(_component, EventTimeline);
    tl.viewport.songLengthMs = _value;
    tl.toolbar.songLength = _value;
  }
}

enum abstract TimelinePlaybackAutoScrollMode(Int) from Int to Int
{
  var NONE = 0;
  var PAGE = 1;
  var SMOOTH = 2;
}
#end
