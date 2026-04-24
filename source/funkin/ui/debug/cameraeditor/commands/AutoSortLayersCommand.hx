package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.ui.haxeui.components.editors.timeline.TimelineLayerData;
import funkin.ui.haxeui.components.editors.timeline.TimelineUtil;

typedef AutoSortPlanLayer =
{
  var name:String;
  var events:Array<SongEventData>;
};

typedef AutoSortPlan =
{
  var layers:Array<AutoSortPlanLayer>;
};

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class AutoSortLayersCommand implements CameraEditorCommand
{
  var previousLayers:Array<TimelineLayerData>;
  var previousEventLayers:Array<{event:SongEventData, layer:Null<String>}>;
  var newLayers:Array<TimelineLayerData>;

  public function new()
  {
    this.previousLayers = [];
    this.previousEventLayers = [];
    this.newLayers = [];
  }

  /**
   * Decide what the per-type layer split should look like.
   * Within each event kind, runs greedy interval scheduling: events that don't
   * overlap each other share a track. If a kind needs only one track, the layer
   * is named just `$kind`. If it needs N>=2 tracks, layers are named `$kind (1)`
   * through `$kind (N)`.
   */
  public static function planSort(events:Array<SongEventData>, stepLengthMs:Float):AutoSortPlan
  {
    var orderedKinds:Array<String> = [];
    var byKind:Map<String, Array<SongEventData>> = new Map<String, Array<SongEventData>>();
    for (event in events)
    {
      if (event.eventKind != "FocusCamera" && event.eventKind != "ZoomCamera") continue;
      if (!byKind.exists(event.eventKind))
      {
        orderedKinds.push(event.eventKind);
        byKind.set(event.eventKind, []);
      }
      byKind.get(event.eventKind).push(event);
    }

    var plan:AutoSortPlan = {layers: []};
    for (kind in orderedKinds)
    {
      var tracks:Array<Array<SongEventData>> = scheduleTracks(byKind.get(kind), stepLengthMs);
      if (tracks.length == 1)
      {
        plan.layers.push({name: kind, events: tracks[0]});
      }
      else
      {
        for (i => track in tracks)
          plan.layers.push({name: '$kind (${i + 1})', events: track});
      }
    }
    return plan;
  }

  static function scheduleTracks(events:Array<SongEventData>, stepLengthMs:Float):Array<Array<SongEventData>>
  {
    var sorted:Array<SongEventData> = events.copy();
    sorted.sort(function(a:SongEventData, b:SongEventData):Int
    {
      if (a.time < b.time) return -1;
      if (a.time > b.time) return 1;
      return 0;
    });

    var tracks:Array<Array<SongEventData>> = [];
    var trackEnds:Array<Float> = [];
    for (event in sorted)
    {
      var endMs:Float = event.time + TimelineUtil.getEventDurationSteps(event) * stepLengthMs;
      var assigned:Bool = false;
      for (i in 0...trackEnds.length)
      {
        if (trackEnds[i] <= event.time)
        {
          tracks[i].push(event);
          trackEnds[i] = endMs;
          assigned = true;
          break;
        }
      }
      if (!assigned)
      {
        tracks.push([event]);
        trackEnds.push(endMs);
      }
    }
    return tracks;
  }

  public function execute(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;
    var allEvents:Array<SongEventData> = state.currentSongChartData.events;
    var stepMs:Float = state.conductorInUse.stepLengthMs;

    previousLayers = viewport.layers.copy();
    previousEventLayers = [];
    for (event in allEvents)
    {
      var raw:SongEventDataRaw = event;
      previousEventLayers.push({event: event, layer: raw.editorLayer});
    }

    var defaultLayer:TimelineLayerData = findDefaultLayer(previousLayers);

    var plan:AutoSortPlan = planSort(allEvents, stepMs);

    newLayers = [defaultLayer];
    for (i => planLayer in plan.layers)
    {
      var color:Int = TimelineLayerData.DEFAULT_LAYER_COLORS[(i + 1) % TimelineLayerData.DEFAULT_LAYER_COLORS.length];
      newLayers.push(new TimelineLayerData(planLayer.name, color));
    }

    for (planLayer in plan.layers)
    {
      for (event in planLayer.events)
      {
        var raw:SongEventDataRaw = event;
        raw.editorLayer = planLayer.name;
      }
    }

    viewport.layers = newLayers;
    viewport.selectedLayerIndex = 0;
    state.timeline.layerPanel.rebuildLayers(viewport.layers);
    viewport.rebuildBlocks(allEvents);

    state.saved = false;
  }

  static function findDefaultLayer(layers:Array<TimelineLayerData>):TimelineLayerData
  {
    for (layer in layers)
      if (layer.name == "Default") return layer;
    return new TimelineLayerData("Default", TimelineLayerData.DEFAULT_LAYER_COLORS[0]);
  }

  public function undo(state:CameraEditorState):Void
  {
    var viewport = state.timeline.viewport;

    for (entry in previousEventLayers)
    {
      var raw:SongEventDataRaw = entry.event;
      raw.editorLayer = entry.layer;
    }

    viewport.layers = previousLayers.copy();
    viewport.selectedLayerIndex = 0;
    state.timeline.layerPanel.rebuildLayers(viewport.layers);
    viewport.rebuildBlocks(state.currentSongChartData.events);

    state.saved = false;
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    return 'Auto-Sort Events by Type (${newLayers.length - 1} layers)';
  }
}
#end
