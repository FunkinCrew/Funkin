package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongEventDataRaw;
import funkin.data.song.SongDataUtils;
import funkin.util.SortUtil;
import flixel.util.FlxSort;
import funkin.data.song.SongDataUtils.SongClipboardItems;
import funkin.ui.debug.cameraeditor.handlers.CameraEditorNotificationHandler;

@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class PasteEventsCommand implements CameraEditorCommand
{
  var targetTimestamp:Float;
  var addedEvents:Array<SongEventData> = [];
  var selectionBefore:Array<SongEventData> = [];
  var isRedo:Bool = false;
  var currentClipboard:SongClipboardItems = {
    valid: false,
    notes: [],
    events: []
  };

  public function new(targetTimestamp:Float)
  {
    this.targetTimestamp = targetTimestamp;
    this.currentClipboard = SongDataUtils.readItemsFromClipboard();
  }

  public function execute(state:CameraEditorState):Void
  {
    if (currentClipboard.valid != true || currentClipboard.events.length == 0)
    {
      CameraEditorNotificationHandler.error(state, 'Failed to Paste', 'Could not parse clipboard contents.');
      state.hasClipboardEvent = false;
      return;
    }

    selectionBefore = state.selectedSongEvents.copy();

    var earliest:Float = Math.POSITIVE_INFINITY;
    for (event in currentClipboard.events)
    {
      if (event.time < earliest) earliest = event.time;
    }

    var offset:Float = targetTimestamp - earliest;
    addedEvents = SongDataUtils.offsetSongEventData(currentClipboard.events, offset);
    addedEvents = SongDataUtils.clampSongEventData(addedEvents, 0.0, state.timeline.viewport.songLengthMs);

    var viewport = state.timeline.viewport;
    var selectedIndex:Int = viewport.selectedLayerIndex;

    for (event in addedEvents)
    {
      var raw:SongEventDataRaw = event;
      var targetIndex:Int = viewport.getLayerIndex(raw.editorLayer ?? 'Default');
      if (targetIndex < 0) targetIndex = selectedIndex;
      if (targetIndex < 0) targetIndex = 0;
      if (targetIndex >= viewport.layers.length) targetIndex = viewport.layers.length - 1;
      var targetLayer = viewport.layers[targetIndex];
      raw.editorLayer = (targetLayer == null || targetLayer.name == 'Default') ? null : targetLayer.name;
      state.currentSongChartData.events.push(event);
      state.timeline.viewport.addEventBlock(event);
    }

    state.currentSongChartData.events.sort(SortUtil.eventDataByTime.bind(FlxSort.ASCENDING));
    state.timeline.viewport.refreshLayout();
    state.selectedSongEvents = addedEvents.copy();
    state.saved = false;

    state.replayCameraTimeline(state.conductorInUse.songPosition);

    state.playEditSound('ui/editors/chart-editor/charting-sounds/note-place');

    var plural = addedEvents.length != 1 ? 'events' : 'event';
    state.showToast(isRedo ? 'Redid paste' : 'Pasted ${addedEvents.length} $plural');

    isRedo = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    for (event in addedEvents)
    {
      state.currentSongChartData.events.remove(event);
      state.timeline.viewport.removeEventBlock(event);
    }

    state.selectedSongEvents = selectionBefore.copy();

    state.timeline.viewport.refreshLayout();
    state.saved = false;

    state.replayCameraTimeline(state.conductorInUse.songPosition);

    state.playEditSound('ui/editors/chart-editor/charting-sounds/undo');

    isRedo = true;
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return addedEvents.length > 0;
  }

  public function toString():String
  {
    return 'Paste ${currentClipboard.events.length} Events';
  }
}
#end
