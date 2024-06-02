package funkin.ui.debug.charting.toolboxes;

import haxe.ui.components.DropDown;
import haxe.ui.components.TextField;
import haxe.ui.events.UIEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.ui.debug.charting.components.ChartEditorNoteSprite;
import funkin.ui.debug.charting.components.ChartEditorHoldNoteSprite;
import funkin.play.notes.notestyle.NoteStyle;
import funkin.play.notes.notekind.NoteKindManager;

/**
 * The toolbox which allows modifying information like Note Kind.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/note-data.xml"))
class ChartEditorNoteDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxNotesNoteKind:DropDown;
  var toolboxNotesCustomKind:TextField;

  var _initializing:Bool = true;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    initialize();

    this.onDialogClosed = onClose;

    this._initializing = false;
  }

  function onClose(event:UIEvent)
  {
    chartEditorState.menubarItemToggleToolboxNoteData.selected = false;
  }

  function initialize():Void
  {
    toolboxNotesNoteKind.onChange = function(event:UIEvent) {
      var noteKind:Null<String> = event?.data?.id ?? null;
      if (noteKind == '') noteKind = null;

      trace('ChartEditorToolboxHandler.buildToolboxNoteDataLayout() - Note kind changed: $noteKind');

      // Edit the note data to place.
      if (noteKind == '~CUSTOM~')
      {
        showCustom();
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
      }
      else
      {
        hideCustom();
        chartEditorState.noteKindToPlace = noteKind;
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
      }

      if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
      {
        // Edit the note data of any selected notes.
        var noteSprites:Array<ChartEditorNoteSprite> = chartEditorState.renderedNotes.members.copy();
        var holdNoteSprites:Array<ChartEditorHoldNoteSprite> = chartEditorState.renderedHoldNotes.members.copy();
        for (note in chartEditorState.currentNoteSelection)
        {
          // update note sprites
          for (noteSprite in noteSprites)
          {
            if (noteSprite.noteData == note)
            {
              noteSprite.noteStyle = NoteKindManager.getNoteStyleId(chartEditorState.noteKindToPlace) ?? chartEditorState.currentSongNoteStyle;
              noteSprites.remove(noteSprite);
              break;
            }
          }

          // update hold note sprites
          for (holdNoteSprite in holdNoteSprites)
          {
            if (holdNoteSprite.noteData == note)
            {
              holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(chartEditorState.noteKindToPlace) ?? chartEditorState.currentSongNoteStyle;
              holdNoteSprites.remove(holdNoteSprite);
              break;
            }
          }

          note.kind = chartEditorState.noteKindToPlace;
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
      }
    };
    var startingValueNoteKind = ChartEditorDropdowns.populateDropdownWithNoteKinds(toolboxNotesNoteKind, '');
    toolboxNotesNoteKind.value = startingValueNoteKind;

    toolboxNotesCustomKind.onChange = function(event:UIEvent) {
      var customKind:Null<String> = event?.target?.text;
      chartEditorState.noteKindToPlace = customKind;

      if (chartEditorState.currentEventSelection.length > 0)
      {
        // Edit the note data of any selected notes.
        for (note in chartEditorState.currentNoteSelection)
        {
          note.kind = chartEditorState.noteKindToPlace;
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
      }
    };
    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
  }

  public override function refresh():Void
  {
    super.refresh();

    toolboxNotesNoteKind.value = ChartEditorDropdowns.lookupNoteKind(chartEditorState.noteKindToPlace);
    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
  }

  function showCustom():Void
  {
    toolboxNotesCustomKindLabel.hidden = false;
    toolboxNotesCustomKind.hidden = false;
  }

  function hideCustom():Void
  {
    toolboxNotesCustomKindLabel.hidden = true;
    toolboxNotesCustomKind.hidden = true;
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorNoteDataToolbox
  {
    return new ChartEditorNoteDataToolbox(chartEditorState);
  }
}
