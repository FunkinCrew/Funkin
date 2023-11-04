package funkin.ui.debug.charting.commands;

import funkin.data.song.SongData.SongEventData;
import funkin.data.song.SongData.SongNoteData;
import funkin.data.song.SongDataUtils;
import funkin.data.song.SongDataUtils.SongClipboardItems;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

/**
 * A command which inserts the contents of the clipboard into the chart editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class PasteItemsCommand implements ChartEditorCommand
{
  var targetTimestamp:Float;
  // Notes we added with this command, for undo.
  var addedNotes:Array<SongNoteData> = [];
  var addedEvents:Array<SongEventData> = [];

  public function new(targetTimestamp:Float)
  {
    this.targetTimestamp = targetTimestamp;
  }

  public function execute(state:ChartEditorState):Void
  {
    var currentClipboard:SongClipboardItems = SongDataUtils.readItemsFromClipboard();

    if (currentClipboard.valid != true)
    {
      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: 'Failed to Paste',
          body: 'Could not parse clipboard contents.',
          type: NotificationType.Error,
          expiryMs: Constants.NOTIFICATION_DISMISS_TIME
        });
      #end
      return;
    }

    trace(currentClipboard.notes);

    addedNotes = SongDataUtils.offsetSongNoteData(currentClipboard.notes, Std.int(targetTimestamp));
    addedEvents = SongDataUtils.offsetSongEventData(currentClipboard.events, Std.int(targetTimestamp));

    state.currentSongChartNoteData = state.currentSongChartNoteData.concat(addedNotes);
    state.currentSongChartEventData = state.currentSongChartEventData.concat(addedEvents);
    state.currentNoteSelection = addedNotes.copy();
    state.currentEventSelection = addedEvents.copy();

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();

    #if !mac
    NotificationManager.instance.addNotification(
      {
        title: 'Paste Successful',
        body: 'Successfully pasted clipboard contents.',
        type: NotificationType.Success,
        expiryMs: Constants.NOTIFICATION_DISMISS_TIME
      });
    #end
  }

  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('chartingSounds/undo'));

    state.currentSongChartNoteData = SongDataUtils.subtractNotes(state.currentSongChartNoteData, addedNotes);
    state.currentSongChartEventData = SongDataUtils.subtractEvents(state.currentSongChartEventData, addedEvents);
    state.currentNoteSelection = [];
    state.currentEventSelection = [];

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;

    state.sortChartData();
  }

  public function toString():String
  {
    var currentClipboard:SongClipboardItems = SongDataUtils.readItemsFromClipboard();

    var len:Int = currentClipboard.notes.length + currentClipboard.events.length;

    if (currentClipboard.notes.length == 0) return 'Paste $len Events';
    else if (currentClipboard.events.length == 0) return 'Paste $len Notes';
    else
      return 'Paste $len Items';
  }
}
