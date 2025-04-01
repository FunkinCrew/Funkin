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
import funkin.play.notes.notekind.NoteKind.NoteKindParam;
import funkin.play.notes.notekind.NoteKind.NoteKindParamType;
import funkin.data.song.SongData.NoteParamData;

/**
 * The toolbox which allows modifying information like Note Kind.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/note-data.xml"))
class ChartEditorNoteDataToolbox extends ChartEditorBaseToolbox
{
  // 100 is the height used in note-data.xml
  static final DIALOG_HEIGHT:Int = 100;

  // toolboxNotesGrid.height + 45
  // this is what i found out by printing this.height and grid.height
  // and then seeing that this.height is 100 and grid.height is 55
  static final HEIGHT_OFFSET:Int = 45;

  // minimizing creates a gray bar the bottom, which would obscure the components,
  // which is why we use an extra offset of 20
  static final MINIMIZE_FIX:Int = 20;

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
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
      }
      else
      {
        hideCustom();
        chartEditorState.noteKindToPlace = noteKind;
        toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
      }

      createNoteKindParams(noteKind);

      if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
      {
        for (note in chartEditorState.currentNoteSelection)
        {
          // Edit the note data of any selected notes.
          note.kind = chartEditorState.noteKindToPlace;
          note.params = ChartEditorState.cloneNoteParams(chartEditorState.noteParamsToPlace);

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

  function createNoteKindParams(noteKind:Null<String>):Void
  {
    clearNoteKindParams();

    var setParamsToPlace:Bool = false;
    if (!_initializing)
    {
      for (note in chartEditorState.currentNoteSelection)
      {
        if (note.kind == chartEditorState.noteKindToPlace)
        {
          chartEditorState.noteParamsToPlace = ChartEditorState.cloneNoteParams(note.params);
          setParamsToPlace = true;
          break;
        }
      }
    }

    var noteKindParams:Array<NoteKindParam> = NoteKindManager.getParams(noteKind);

    for (i in 0...noteKindParams.length)
    {
      var param:NoteKindParam = noteKindParams[i];

      var paramLabel:Label = new Label();
      paramLabel.value = param.description;
      paramLabel.verticalAlign = "center";
      paramLabel.horizontalAlign = "right";

      var paramComponent:Component = null;

      switch (param.type)
      {
        case NoteKindParamType.INT | NoteKindParamType.FLOAT:
          var paramStepper:NumberStepper = new NumberStepper();
          paramStepper.value = (setParamsToPlace ? chartEditorState.noteParamsToPlace[i].value : param.data?.defaultValue) ?? 0.0;
          paramStepper.percentWidth = 100;
          paramStepper.step = param.data?.step ?? 1.0;

          // this check should be unnecessary but for some reason
          // even when these are null it will set it to 0
          if (param.data?.min != null)
          {
            paramStepper.min = param.data.min;
          }
          if (param.data?.max != null)
          {
            paramStepper.max = param.data.max;
          }
          if (param.data?.precision != null)
          {
            paramStepper.precision = param.data.precision;
          }
          paramComponent = paramStepper;

        case NoteKindParamType.STRING:
          var paramTextField:TextField = new TextField();
          paramTextField.value = (setParamsToPlace ? chartEditorState.noteParamsToPlace[i].value : param.data?.defaultValue) ?? '';
          paramTextField.percentWidth = 100;
          paramComponent = paramTextField;
      }

      if (paramComponent == null)
      {
        continue;
      }

      paramComponent.onChange = function(event:UIEvent) {
        chartEditorState.noteParamsToPlace[i].value = paramComponent.value;

        for (note in chartEditorState.currentNoteSelection)
        {
          if (note.params.length != noteKindParams.length)
          {
            break;
          }

          if (note.params[i].name == param.name)
          {
            note.params[i].value = paramComponent.value;
          }
        }
      }

      addNoteKindParam(paramLabel, paramComponent);
    }

    if (!setParamsToPlace)
    {
      var noteParamData:Array<NoteParamData> = [];
      for (i in 0...noteKindParams.length)
      {
        noteParamData.push(new NoteParamData(noteKindParams[i].name, toolboxNotesParams[i].component.value));
      }
      chartEditorState.noteParamsToPlace = noteParamData;
    }
  }

  function addNoteKindParam(label:Label, component:Component):Void
  {
    toolboxNotesParams.push({label: label, component: component});
    toolboxNotesGrid.addComponent(label);
    toolboxNotesGrid.addComponent(component);

    this.height = Math.max(DIALOG_HEIGHT, DIALOG_HEIGHT - 30 + toolboxNotesParams.length * 30);
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

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // current dialog is minimized, dont change the height
    if (this.minimized)
    {
      return;
    }

    var heightToSet:Int = Std.int(Math.max(DIALOG_HEIGHT, (toolboxNotesGrid?.height ?? 50.0) + HEIGHT_OFFSET)) + MINIMIZE_FIX;
    if (this.height != heightToSet)
    {
      this.height = heightToSet;
    }
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
