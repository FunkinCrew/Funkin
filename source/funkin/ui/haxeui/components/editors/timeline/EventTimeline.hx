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

  @:clonable @:behaviour(DefaultBehaviour, 1)
  public var autoScrollMode:Int;

  public function new()
  {
    super();
    percentWidth = 100;
    percentHeight = 100;
  }

  public function loadTimelineStyles():Void
  {
    haxe.ui.Toolkit.styleSheet.parse('
      .timeline-viewport {
        background-color: #FFFFFF;
        clip: true;
        overflow: hidden;
      }
      .timeline-playhead {
        background-color: #FFFFFF;
        width: 2px;
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
      .layer-name-field:active {
        background-color: none;
        border: none;
        filter: none;
      }
    ');
  }

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

@:dox(hide) @:noCompletion
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

@:dox(hide) @:noCompletion
private class EventTimelineEvents extends Events
{
  var _timeline:EventTimeline;
  var _updatingScrollbar:Bool = false;

  public function new(timeline:EventTimeline)
  {
    super(timeline);
    _timeline = timeline;
  }

  override public function register():Void
  {
    if (!_timeline.layerPanel.btnAddLayer.hasEvent(MouseEvent.CLICK,
      _onAddLayer)) _timeline.layerPanel.btnAddLayer.registerEvent(MouseEvent.CLICK, _onAddLayer);
    if (!_timeline.layerPanel.btnRemoveLayer.hasEvent(MouseEvent.CLICK,
      _onRemoveLayer)) _timeline.layerPanel.btnRemoveLayer.registerEvent(MouseEvent.CLICK, _onRemoveLayer);
    if (!_timeline.scrollbar.hasEvent(UIEvent.CHANGE, _onScrollbarChange)) _timeline.scrollbar.registerEvent(UIEvent.CHANGE, _onScrollbarChange);
    if (!_timeline.vscrollbar.hasEvent(UIEvent.CHANGE, _onVScrollbarChange)) _timeline.vscrollbar.registerEvent(UIEvent.CHANGE, _onVScrollbarChange);
    if (!_timeline.toolbar.ddAutoScroll.hasEvent(UIEvent.CHANGE,
      _onAutoScrollChange)) _timeline.toolbar.ddAutoScroll.registerEvent(UIEvent.CHANGE, _onAutoScrollChange);

    _timeline.viewport.onRefresh = _updateScrollbar;

    var zoomSlider = _timeline.toolbar.findComponent("zoomSlider");
    if (zoomSlider != null && !zoomSlider.hasEvent(UIEvent.CHANGE, _onZoomChange)) zoomSlider.registerEvent(UIEvent.CHANGE, _onZoomChange);
  }

  override public function unregister():Void
  {
    _timeline.layerPanel.btnAddLayer.unregisterEvent(MouseEvent.CLICK, _onAddLayer);
    _timeline.layerPanel.btnRemoveLayer.unregisterEvent(MouseEvent.CLICK, _onRemoveLayer);
    _timeline.scrollbar.unregisterEvent(UIEvent.CHANGE, _onScrollbarChange);
    _timeline.vscrollbar.unregisterEvent(UIEvent.CHANGE, _onVScrollbarChange);
    _timeline.toolbar.ddAutoScroll.unregisterEvent(UIEvent.CHANGE, _onAutoScrollChange);

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
    if (_timeline.viewport.layers.length <= 1) return;

    var selectedIdx = _timeline.viewport.selectedLayerIndex;
    var layer = _timeline.viewport.layers[selectedIdx];
    if (layer.name == "Default") return;

    var removeEvent = new TimelineEvent(TimelineEvent.LAYER_REMOVED);
    removeEvent.layerData = layer;
    removeEvent.layerIndex = selectedIdx;
    _timeline.dispatch(removeEvent);
  }

  function _onZoomChange(_:UIEvent):Void
  {
    var slider = _timeline.toolbar.findComponent("zoomSlider", Slider);
    if (slider != null)
    {
      _timeline.viewport.zoomLevel = slider.pos;
      _timeline.viewport.refreshLayout();
    }
  }

  function _onAutoScrollChange(_:UIEvent):Void
  {
    _timeline.autoScrollMode = _timeline.toolbar.ddAutoScroll.selectedIndex;
  }

  function _onScrollbarChange(_:UIEvent):Void
  {
    if (_updatingScrollbar) return;
    _timeline.viewport.scrollOffsetMs = _timeline.scrollbar.pos;
    _timeline.viewport.refreshLayout();
  }

  function _onVScrollbarChange(_:UIEvent):Void
  {
    if (_updatingScrollbar) return;
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
    if (zoomSlider != null && zoomSlider.pos != _timeline.viewport.zoomLevel) zoomSlider.pos = _timeline.viewport.zoomLevel;

    var maxVScroll = _timeline.viewport.maxLayerScrollPx;
    if (maxVScroll > 0)
    {
      var viewableHeight = _timeline.viewport.viewableHeightPx;
      var halfOvershoot = viewableHeight / 2;
      _timeline.vscrollbar.max = _timeline.viewport.totalLayerHeight - halfOvershoot;
      if (viewableHeight > 0) _timeline.vscrollbar.pageSize = viewableHeight;
      _timeline.vscrollbar.pos = _timeline.viewport.layerScrollOffsetPx;
      _timeline.vscrollbar.hidden = false;
    }
    else
    {
      _timeline.vscrollbar.max = 0;
      _timeline.vscrollbar.pos = 0;
      _timeline.vscrollbar.hidden = true;
    }

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
  }
}

@:dox(hide) @:noCompletion
private class SongPositionBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var tl:EventTimeline = cast(_component, EventTimeline);

    var pos:Float = _value;
    tl.viewport.songPositionMs = pos;
    tl.toolbar.songPosition = pos;

    if (tl.isPlaying)
    {
      var viewWidth = tl.viewport.width;
      var pxPerMs = tl.viewport.pixelsPerMs * tl.viewport.zoomLevel;

      switch (tl.autoScrollMode)
      {
        case 0: // No Scroll
        case 1: // Page Scroll
          if (viewWidth > 0 && pxPerMs > 0)
          {
            var playheadPx = tl.viewport.msToPixelX(pos);
            if (playheadPx > viewWidth * 0.95 || playheadPx < 0)
            {
              tl.viewport.scrollOffsetMs = pos - (viewWidth * 0.05 / pxPerMs);
              if (tl.viewport.scrollOffsetMs < 0) tl.viewport.scrollOffsetMs = 0;
            }
          }
        case 2: // Smooth Scroll
          if (viewWidth > 0 && pxPerMs > 0)
          {
            tl.viewport.scrollOffsetMs = pos - (viewWidth * 0.5 / pxPerMs);
            if (tl.viewport.scrollOffsetMs < 0) tl.viewport.scrollOffsetMs = 0;
          }
        default:
      }
    }

    tl.viewport.refreshLayout();
  }
}

@:dox(hide) @:noCompletion
private class SongLengthBehaviour extends DataBehaviour
{
  override public function validateData():Void
  {
    var tl:EventTimeline = cast(_component, EventTimeline);
    tl.viewport.songLengthMs = _value;
    tl.toolbar.songLength = _value;
  }
}
#end
