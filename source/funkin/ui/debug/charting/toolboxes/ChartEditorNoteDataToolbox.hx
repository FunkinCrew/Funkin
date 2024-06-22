package funkin.ui.debug.charting.toolboxes;

import haxe.ui.components.DropDown;
import haxe.ui.components.TextField;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.containers.Grid;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.play.notes.notekind.NoteKindManager;

/**
 * The toolbox which allows modifying information like Note Kind.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/note-data.xml"))
class ChartEditorNoteDataToolbox extends ChartEditorBaseToolbox
{
  static final DIALOG_HEIGHT:Int = 100;

  var toolboxNotesGrid:Grid;
  var toolboxNotesNoteKind:DropDown;
  var toolboxNotesCustomKind:TextField;
  var toolboxNotesParams:Array<ToolboxNoteKindParam> = [];

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
        clearNoteKindParams();
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
      }
      else
      {
        hideCustom();
        chartEditorState.noteKindToPlace = noteKind;
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;

        clearNoteKindParams();
        for (param in NoteKindManager.getParams(noteKind))
        {
          var paramLabel:Label = new Label();
          paramLabel.value = param.description;
          paramLabel.verticalAlign = "center";
          paramLabel.horizontalAlign = "right";

          var paramStepper:NumberStepper = new NumberStepper();
          paramStepper.min = param.data.min;
          paramStepper.max = param.data.max;
          paramStepper.value = param.data.value;
          paramStepper.precision = 1;
          paramStepper.step = 0.1;
          paramStepper.percentWidth = 100;

          addNoteKindParam(paramLabel, paramStepper);
        }
      }

      createNoteKindParams(noteKind);

      if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
      {
        for (note in chartEditorState.currentNoteSelection)
        {
          // Edit the note data of any selected notes.
          note.kind = chartEditorState.noteKindToPlace;

          // update note sprites
          for (noteSprite in chartEditorState.renderedNotes.members)
          {
            if (noteSprite.noteData == note)
            {
              noteSprite.noteStyle = NoteKindManager.getNoteStyleId(note.kind) ?? chartEditorState.currentSongNoteStyle;
              break;
            }
          }

          // update hold note sprites
          for (holdNoteSprite in chartEditorState.renderedHoldNotes.members)
          {
            if (holdNoteSprite.noteData == note)
            {
              holdNoteSprite.noteStyle = NoteKindManager.getNoteStyleId(note.kind) ?? chartEditorState.currentSongNoteStyle;
              break;
            }
          }
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

    // just to be safe
    clearNoteKindParams();
  }

  public override function refresh():Void
  {
    super.refresh();

    toolboxNotesNoteKind.value = ChartEditorDropdowns.lookupNoteKind(chartEditorState.noteKindToPlace);
    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;

    createNoteKindParams(chartEditorState.noteKindToPlace);
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

  function addNoteKindParam(label:Label, component:Component):Void
  {
    toolboxNotesParams.push({label: label, component: component});
    toolboxNotesGrid.addComponent(label);
    toolboxNotesGrid.addComponent(component);

    this.height = Math.max(DIALOG_HEIGHT, DIALOG_HEIGHT - 30 + toolboxNotesParams.length * 30);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // toolboxNotesGrid.height + 45
    // this is what i found out is the calculation by printing this.height and grid.height
    var heightToSet:Int = Std.int(Math.max(DIALOG_HEIGHT, toolboxNotesGrid.height + 45));
    if (this.height != heightToSet)
    {
      this.height = heightToSet;
    }
  }

  function clearNoteKindParams():Void
  {
    for (param in toolboxNotesParams)
    {
      toolboxNotesGrid.removeComponent(param.component);
      toolboxNotesGrid.removeComponent(param.label);
    }
    toolboxNotesParams = [];
    this.height = DIALOG_HEIGHT;
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorNoteDataToolbox
  {
    return new ChartEditorNoteDataToolbox(chartEditorState);
  }
}

typedef ToolboxNoteKindParam =
{
  var label:Label;
  var component:Component;
}
