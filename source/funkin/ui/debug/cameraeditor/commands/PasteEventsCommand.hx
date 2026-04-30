package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.audio.FunkinSound;
import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongDataUtils;
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

    for (event in addedEvents)
    {
      state.currentSongChartData.events.push(event);
      state.timeline.viewport.addEventBlock(event);
    }

    state.currentSongChartData.events.sort(sortEvents);
    state.timeline.viewport.refreshLayout();
    state.selectedSongEvents = addedEvents.copy();
    state.saved = false;

    FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/note-place'));

    var title = isRedo ? 'Redone Paste Successfully' : 'Paste Successful';
    var msg = isRedo ? 'Successfully placed pasted event(s) back.' : 'Successfully pasted clipboard contents.';
    CameraEditorNotificationHandler.success(state, title, msg);

    isRedo = false;
  }

  public function undo(state:CameraEditorState):Void
  {
    state.currentSongChartData.events = SongDataUtils.subtractEvents(state.currentSongChartData.events, addedEvents);
    state.selectedSongEvents = selectionBefore.copy();

    for (event in addedEvents)
    {
      state.timeline.viewport.removeEventBlock(event);
    }

    state.timeline.viewport.refreshLayout();
    state.saved = false;

    FunkinSound.playOnce(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));

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

  static function sortEvents(a:SongEventData, b:SongEventData):Int
  {
    if (a.time < b.time) return -1;
    if (a.time > b.time) return 1;
    return 0;
  }
}
#end
