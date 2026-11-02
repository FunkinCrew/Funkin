package funkin.ui.debug.cameraeditor.commands;

#if FEATURE_CAMERA_EDITOR
import funkin.data.song.SongData.SongEventData;

/**
 * Represents a reversible edit to the values of one or more events, made from the Properties panel.
 */
@:access(funkin.ui.debug.cameraeditor.CameraEditorState)
class EditEventPropertiesCommand implements CameraEditorCommand
{
  /**
   * Edits to the same fields of the same events this close together become one history entry.
   */
  static inline var MERGE_WINDOW_SEC:Float = 1.0;

  var events:Array<SongEventData>;
  var before:Array<Dynamic>;
  var after:Array<Dynamic>;
  var fieldsKey:String;
  var lastEditTime:Float;

  public function new(events:Array<SongEventData>, before:Array<Dynamic>, after:Array<Dynamic>, fieldsKey:String)
  {
    this.events = events.copy();
    this.before = before;
    this.after = after;
    this.fieldsKey = fieldsKey;
    this.lastEditTime = haxe.Timer.stamp();
  }

  /**
   * Adds an edit that was already applied to the history, merging it into the previous entry when it continues the same edit.
   *
   * @param state The CameraEditorState to add the edit to.
   * @param events The edited events.
   * @param before A copy of each event's value before the edit.
   * @param after A copy of each event's value after the edit.
   */
  public static function push(state:CameraEditorState, events:Array<SongEventData>, before:Array<Dynamic>, after:Array<Dynamic>):Void
  {
    var fields:Array<String> = changedFields(before, after);
    if (fields.length == 0) return;
    fields.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    var key:String = fields.join(',');

    var last:Null<CameraEditorCommand> = state.undoHistory[state.undoHistory.length - 1];
    if (Std.isOfType(last, EditEventPropertiesCommand))
    {
      var lastEdit:EditEventPropertiesCommand = cast last;
      if (lastEdit.canMerge(events, key))
      {
        lastEdit.after = after;
        lastEdit.lastEditTime = haxe.Timer.stamp();
        state.redoHistory = [];
        state.saved = false;
        return;
      }
    }

    state.undoHistory.push(new EditEventPropertiesCommand(events, before, after, key));
    state.redoHistory = [];
    state.commandHistoryDirty = true;
    state.saved = false;
  }

  function canMerge(otherEvents:Array<SongEventData>, key:String):Bool
  {
    if (key != fieldsKey) return false;
    if (haxe.Timer.stamp() - lastEditTime > MERGE_WINDOW_SEC) return false;
    if (otherEvents.length != events.length) return false;
    for (i in 0...events.length)
    {
      if (otherEvents[i] != events[i]) return false;
    }
    return true;
  }

  static function changedFields(before:Array<Dynamic>, after:Array<Dynamic>):Array<String>
  {
    var result:Array<String> = [];
    for (i in 0...before.length)
    {
      var a:Dynamic = before[i];
      var b:Dynamic = after[i];
      for (field in Reflect.fields(a).concat(Reflect.fields(b)))
      {
        if (result.contains(field)) continue;
        if (Reflect.field(a, field) != Reflect.field(b, field)) result.push(field);
      }
    }
    return result;
  }

  public function execute(state:CameraEditorState):Void
  {
    apply(state, after);
    state.playEditSound('ui/editors/chart-editor/charting-sounds/note-place');
  }

  public function undo(state:CameraEditorState):Void
  {
    apply(state, before);
    state.playEditSound('ui/editors/chart-editor/charting-sounds/undo');
  }

  function apply(state:CameraEditorState, values:Array<Dynamic>):Void
  {
    for (i in 0...events.length) events[i].value = Reflect.copy(values[i]);

    state.selectedSongEvents = events.copy();
    state.timeline.viewport.refreshBlockVisuals();
    state.timeline.viewport.refreshLayout();
    state.requestCameraReplay();
    state.saved = false;
  }

  public function shouldAddToHistory(state:CameraEditorState):Bool
  {
    return true;
  }

  public function toString():String
  {
    var plural:String = events.length != 1 ? 'Events' : 'Event';
    return 'Edit ${events.length} $plural (${fieldsKey})';
  }
}
#end
