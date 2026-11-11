package funkin.ui.debug.charting.commands.notes;

#if FEATURE_CHART_EDITOR
import funkin.data.song.SongData.NoteParamData;
import funkin.data.song.SongData.SongNoteData;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.debug.charting.commands.ChartEditorCommand;

/**
 * Represents a reversible action to change the kind and params of notes.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class SetNoteKindCommand implements ChartEditorCommand
{
  var notes:Array<SongNoteData>;
  var kinds:Array<Null<String>>;
  var params:Array<Array<NoteParamData>>;
  var previousKinds:Array<Null<String>> = [];
  var previousParams:Array<Array<NoteParamData>> = [];
  var label:String;

  /**
   * @param notes The notes to change.
   * @param kinds The kind each note gets, in the same order.
   * @param params The params each note gets, in the same order.
   * @param label What the undo history calls this.
   */
  public function new(notes:Array<SongNoteData>, kinds:Array<Null<String>>, params:Array<Array<NoteParamData>>, label:String = 'Set Note Kind')
  {
    this.notes = notes;
    this.kinds = kinds;
    this.params = params;
    this.label = label;
  }

  /**
   * Perform the action, changing the notes.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function execute(state:ChartEditorState):Void
  {
    previousKinds = [for (note in notes) note.kind];
    previousParams = [for (note in notes) ChartEditorNoteUtil.cloneNoteParams(note.params)];
    apply(state, kinds, params);
  }

  /**
   * Reverse the action, putting the old kinds and params back.
   *
   * @param state The ChartEditorState to perform the command on.
   */
  public function undo(state:ChartEditorState):Void
  {
    apply(state, previousKinds, previousParams);
    state.playSound(Paths.sound('ui/editors/chart-editor/charting-sounds/undo'));
  }

  function apply(state:ChartEditorState, newKinds:Array<Null<String>>, newParams:Array<Array<NoteParamData>>):Void
  {
    for (i in 0...notes.length)
    {
      notes[i].kind = newKinds[i];
      notes[i].params = ChartEditorNoteUtil.cloneNoteParams(newParams[i]);
    }
    refreshNoteStyles(state, notes);

    state.saveDataDirty = true;
    state.noteDisplayDirty = true;
    state.notePreviewDirty = true;
    state.noteTooltipsDirty = true;
  }

  /**
   * Point the drawn notes and holds at the note style their kind uses.
   */
  @:nullSafety(Off)
  public static function refreshNoteStyles(state:ChartEditorState, notes:Array<SongNoteData>):Void
  {
    for (noteSprite in state.renderedNotes.members)
    {
      if (noteSprite != null && noteSprite.noteData != null && notes.contains(noteSprite.noteData))
      {
        noteSprite.noteStyle = NoteKindManager.getNoteStyleId(noteSprite.noteData.kind) ?? state.currentSongNoteStyle;
      }
    }
    for (holdNoteSprite in state.renderedHoldNotes.members)
    {
      if (holdNoteSprite != null && holdNoteSprite.noteData != null && notes.contains(holdNoteSprite.noteData))
      {
        holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(holdNoteSprite.noteData.kind) ?? state.currentSongNoteStyle;
      }
    }
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
    for (i in 0...notes.length)
    {
      if (previousKinds[i] != kinds[i] || !sameParams(previousParams[i], params[i])) return true;
    }
    return false;
  }

  static function sameParams(a:Array<NoteParamData>, b:Array<NoteParamData>):Bool
  {
    if (a.length != b.length) return false;
    for (i in 0...a.length)
    {
      if (a[i].name != b[i].name || a[i].value != b[i].value) return false;
    }
    return true;
  }

  /**
   * Convert the action to a string. Used to display the action in the undo/redo history.
   * @return This command, as a readable string.
   */
  public function toString():String
  {
    return label;
  }
}
#end
