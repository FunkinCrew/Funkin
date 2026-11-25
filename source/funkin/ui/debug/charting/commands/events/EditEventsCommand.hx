package funkin.ui.debug.charting.commands.events;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.SongEventData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents an edit to one or more events, storing the state of the events before and after the edit.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class EditEventsCommand implements ChartEditorCommand
{
  static inline var MERGE_WINDOW_SEC:Float = 1.0;

  var events:Array<SongEventData>;
  var before:Array<EventSnapshot>;
  var after:Array<EventSnapshot>;
  var field:String;
  var lastEditTime:Float;

  public function new(events:Array<SongEventData>, before:Array<EventSnapshot>, after:Array<EventSnapshot>, field:String)
  {
    this.events = events.copy();
    this.before = before;
    this.after = after;
    this.field = field;
    this.lastEditTime = haxe.Timer.stamp();
  }

  /**
   * A copy of each event's kind and value.
   */
  public static function snapshot(events:Array<SongEventData>):Array<EventSnapshot>
  {
    return[for (event in events) {
      kind: event.eventKind,
      value: Reflect.copy(event.valueAsStruct())
    }];
  }

  /**
   * Add an edit that was already applied to the history, merging it with the last edit if possible.
   *
   * @param state The ChartEditorState to add the edit to.
   * @param events The edited events.
   * @param before A snapshot of the events from before the edit.
   * @param field The name of the edited field, used to tell when edits can be merged.
   */
  public static function push(state:ChartEditorState, events:Array<SongEventData>, before:Array<EventSnapshot>, field:String):Void
  {
    if (events.length == 0) return;
    var after:Array<EventSnapshot> = snapshot(events);

    var last:Null<ChartEditorCommand> = state.undoHistory[state.undoHistory.length - 1];
    if (Std.isOfType(last, EditEventsCommand))
    {
      var lastEdit:EditEventsCommand = cast last;
      if (lastEdit.canMerge(events, field))
      {
        lastEdit.after = after;
        lastEdit.lastEditTime = haxe.Timer.stamp();
        state.redoHistory = [];
        state.saveDataDirty = true;
        return;
      }
    }

    state.performCommand(new EditEventsCommand(events, before, after, field));
  }

  function canMerge(otherEvents:Array<SongEventData>,
    otherField:String):Bool
  {
    if (otherField != field) return false;
    if (haxe.Timer.stamp() - lastEditTime > MERGE_WINDOW_SEC) return false;
    if (otherEvents.length != events.length) return false;
    for (i in 0...events.length)
    {
      if (otherEvents[i] != events[i]) return false;
    }
    return true;
  }

  public function execute(state:ChartEditorState):Void
  {
    apply(state, after);
  }

  public function undo(state:ChartEditorState):Void
  {
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
    apply(state, before);
  }

  function apply(state:ChartEditorState, snapshots:Array<EventSnapshot>):Void
  {
    for (i in 0...events.length)
    {
      events[i].eventKind = snapshots[i].kind;
      events[i].value = Reflect.copy(snapshots[i].value);
    }

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return events.length > 0;
  }

  public function toString():String
  {
    return events.length == 1 ? 'Edit Event' : 'Edit ${events.length} Events';
  }
}

typedef EventSnapshot =
{
  var kind:String;
  var value:Null<Dynamic>;
}
#end
