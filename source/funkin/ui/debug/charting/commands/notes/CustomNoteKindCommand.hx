package funkin.ui.debug.charting.commands.notes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.NoteParamData;
import funkin.data.song.SongData.SongNoteData;
import funkin.ui.debug.charting.commands.ChartEditorCommand;
import funkin.ui.debug.charting.toolboxes.ChartEditorNoteDataToolbox;

/**
 * Represents a reversible action to add or delete a custom note kind.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class CustomNoteKindCommand implements ChartEditorCommand
{
  var kind:String;
  var adding:Bool;
  var notes:Array<SongNoteData>;
  var noteChange:Null<SetNoteKindCommand> = null;
  var wasListed:Bool = false;
  var previousPlaceKind:Null<String> = null;
  var previousPlaceParams:Array<NoteParamData> = [];

  /**
   * @param kind The custom kind id.
   * @param adding Add it when true, delete it when false.
   * @param notes The notes that change kind.
   */
  public function new(kind:String, adding:Bool, notes:Array<SongNoteData>)
  {
    this.kind = kind;
    this.adding = adding;
    this.notes = notes;
  }

  /**
   * Perform the action, adding or deleting the kind.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    var toolbox:Null<ChartEditorNoteDataToolbox> = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
    wasListed = toolbox != null && toolbox.hasCustomKind(kind);
    previousPlaceKind = state.noteKindToPlace;
    previousPlaceParams = state.noteParamsToPlace;

    if (adding)
    {
      toolbox?.addCustomKind(kind);
      state.noteKindToPlace = kind;
      state.noteParamsToPlace = [];
    }
    else
    {
      toolbox?.removeCustomKind(kind);
      if (state.noteKindToPlace == kind)
      {
        state.noteKindToPlace = null;
        state.noteParamsToPlace = [];
      }
    }

    if (notes.length > 0)
    {
      var newKind:Null<String> = adding ? kind : null;
      var change:SetNoteKindCommand = new SetNoteKindCommand(notes, [for (note in notes) newKind], [for (note in notes) []]);
      change.execute(state);
      noteChange = change;
    }
    if (!adding) state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/note-erase'));
    toolbox?.refresh();
  }

  /**
   * Reverse the action, putting the kind list, the notes and the kind new notes get back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    var toolbox:Null<ChartEditorNoteDataToolbox> = cast state.getToolbox(ChartEditorState.CHART_EDITOR_TOOLBOX_NOTE_DATA_LAYOUT);
    noteChange?.undo(state);
    if (wasListed) toolbox?.addCustomKind(kind);
    else
      toolbox?.removeCustomKind(kind);
    state.noteKindToPlace = previousPlaceKind;
    state.noteParamsToPlace = previousPlaceParams;
    // SetNoteKindCommand plays the undo sound itself when notes changed.
    if (noteChange == null) state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
    toolbox?.refresh();
  }

  /**
   * Whether the command should display in the undo/redo menu.
   * This should be `false` if no real actions were actually performed.
   *
   * @param state The ChartEditorState to perform the command on.
   * @return Whether the command should be added to the history.
   */
  public function shouldAddToHistory(state:ChartEditorState):Bool
  {
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return adding ? 'Add Custom Note Kind' : 'Delete Custom Note Kind';
  }
}
#end
