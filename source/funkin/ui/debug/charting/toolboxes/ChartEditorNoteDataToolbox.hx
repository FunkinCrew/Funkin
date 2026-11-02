package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
import funkin.data.note.SongNoteSchema;
import funkin.play.notes.notekind.NoteKindManager;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.core.Component;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import haxe.ui.data.ArrayDataSource;

/**
 * The toolbox which allows modifying information like Note Kind.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build('assets/exclude/ui/editors/chart-editor/toolboxes/note-data.xml'))
class ChartEditorNoteDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxNotesNoteKind:DropDown;
  var toolboxNotesCustomKind:TextField;
  var toolboxNoteParamsFrame:Frame;
  var toolboxNoteParamsBox:VBox;

  var _initializing:Bool = true;

  /**
   * If `true`, changing the value of the Note Kind dropdown will trigger the `onNoteKindChanged` callback,
   * modifying the note kind of all selected notes.
   * Set to `false` to safety modify the dropdown directly, without modifying placed notes.
   */
  var shouldTriggerOnNoteKindChanged(default, set):Bool = true;

  function set_shouldTriggerOnNoteKindChanged(value:Bool):Bool
  {
    shouldTriggerOnNoteKindChanged = value;

    if (!shouldTriggerOnNoteKindChanged)
    {
      toolboxNotesNoteKind.pauseEvent(UIEvent.CHANGE, true);
    }
    else
    {
      toolboxNotesNoteKind.resumeEvent(UIEvent.CHANGE, true, true);
    }

    return shouldTriggerOnNoteKindChanged;
  }

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
    toolboxNotesNoteKind.onChange = onNoteKindChanged;
    shouldTriggerOnNoteKindChanged = false;

    var startingNoteKindValue = ChartEditorDropdowns.populateDropdownWithNoteKinds(toolboxNotesNoteKind, chartEditorState.noteKindToPlace);
    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Building Note toolbox with kind "${startingNoteKindValue}"');
    toolboxNotesNoteKind.value = startingNoteKindValue;

    shouldTriggerOnNoteKindChanged = true;

    toolboxNotesCustomKind.onChange = onCustomNoteKindChanged;
    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;
  }

  function onNoteKindChanged(event:UIEvent):Void
  {
    if (event.data == null)
    {
      trace(' WARNING '.bg_yellow().bold() + ' CHART EDITOR '.bold().bg_bright_yellow() + 'Note toolbox received an invalid UI event.');
      return;
    }

    var noteKind:String = event.data.id;
    var sameNote:Bool = (noteKind == chartEditorState.noteKindToPlace);

    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note toolbox changed kind to "$noteKind"');

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

    if (!sameNote) chartEditorState.noteParamsToPlace = {};

    var schema:SongNoteSchema = NoteKindManager.getNoteSchema(noteKind);
    toolboxNoteParamsFrame.hidden = schema == null;
    buildNoteParamsFormFromSchema(toolboxNoteParamsBox, schema, chartEditorState.noteKindToPlace);

    if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
    {
      // Edit the note params of any selected notes.
      trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note toolbox MODIFYING notes to kind "${chartEditorState.noteKindToPlace}"');
      for (note in chartEditorState.currentNoteSelection)
      {
        // Update note kind and params
        note.kind = chartEditorState.noteKindToPlace;
        note.params = Reflect.copy(chartEditorState.noteParamsToPlace);

        // Update note visuals
        for (noteSprite in chartEditorState.renderedNotes.members)
        {
          if (noteSprite.noteData == note)
          {
            noteSprite.noteStyle = NoteKindManager.getNoteStyleId(note.kind) ?? chartEditorState.currentSongNoteStyle;
            break;
          }
        }

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
  }

  function onCustomNoteKindChanged(event:UIEvent):Void
  {
    var customKind:Null<String> = event?.target?.text;
    chartEditorState.noteKindToPlace = customKind;

    if (toolboxNotesNoteKind.value == null || toolboxNotesNoteKind.value.id != '~CUSTOM~') return;

    if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
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

    toolboxNotesCustomKind.pauseEvent(UIEvent.CHANGE, true);

    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;

    toolboxNotesCustomKind.resumeEvent(UIEvent.CHANGE, true, true);
  }

  override public function refresh():Void
  {
    super.refresh();

    shouldTriggerOnNoteKindChanged = false;

    toolboxNotesNoteKind.value = ChartEditorDropdowns.lookupNoteKind(chartEditorState.noteKindToPlace);
    toolboxNotesCustomKind.value = chartEditorState.noteKindToPlace;

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.noteKindToPlace, toolboxNotesNoteKind);

    if (toolboxNotesNoteKind.value != newDropdownElement || lastNoteKind != toolboxNotesNoteKind.value.id)
    {
      toolboxNotesNoteKind.value = newDropdownElement;

      if (toolboxNotesNoteKind.value.id == '~CUSTOM~' && chartEditorState.noteKindToPlace != null) showCustom();
      else hideCustom();

      var schema:SongNoteSchema = NoteKindManager.getNoteSchema(chartEditorState.noteKindToPlace);
      toolboxNoteParamsFrame.hidden = schema == null;

      trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note Toolbox: Kind changed to "${chartEditorState.noteKindToPlace}", rebuilding form...');
      buildNoteParamsFormFromSchema(toolboxNoteParamsBox, schema, chartEditorState.noteKindToPlace);
    }
    else
    {
      trace('ChartEditorNoteDataToolbox - Note kind not changed: ${toolboxNotesNoteKind.value} == ${newDropdownElement} == ${lastNoteKind}');
    }

    for (pair in chartEditorState.noteParamsToPlace.keyValueIterator())
    {
      var fieldId:String = pair.key;
      var value:Null<Dynamic> = pair.value;

      var field:Component = toolboxNoteParamsBox.findComponent(fieldId);
      field.pauseEvent(UIEvent.CHANGE, true);

      if (field == null)
      {
        throw 'ChartEditorNoteDataToolbox - Field "${fieldId}" does not exist in the note params form for kind ${lastNoteKind}.';
      }
      else
      {
        switch (Type.getClass(field))
        {
          case NumberStepper:
            var numberStepper:NumberStepper = cast field;
            numberStepper.value = value;
          case CheckBox:
            var checkBox:CheckBox = cast field;
            checkBox.selected = value;
          case DropDown:
            var dropDown:DropDown = cast field;
            dropDown.value = value;
          case TextField:
            var textField:TextField = cast field;
            textField.text = value;
          default:
            throw 'ChartEditorNoteDataToolbox - Field "${fieldId}" is of unknown type "${Type.getClassName(Type.getClass(field))}".';
        }
      }
      field.resumeEvent(UIEvent.CHANGE, true, true);
    }

    shouldTriggerOnNoteKindChanged = true;
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

  var lastNoteKind:String = '';

  function buildNoteParamsFormFromSchema(target:Box, schema:SongNoteSchema, noteKind:String):Void
  {
    // trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note Toolbox: Building form from schema ("${noteKind}")...');

    _initializing = true;

    lastNoteKind = noteKind ?? '';

    // Clear the frame.
    target.removeAllComponents();

    if (schema == null)
    {
      _initializing = false;
      return;
    }

    recursiveChildAdd(target, schema);

    _initializing = false;
  }

  function recursiveChildAdd(parent:Component, schema:SongNoteSchema)
  {
    for (field in schema)
    {
      if (field == null) continue;

      var hbox:HBox = new HBox();
      hbox.percentWidth = 100;
      parent.addComponent(hbox);

      // Add a label for the data field.
      var label:Label = new Label();
      label.text = field.title;
      label.verticalAlign = "center";
      label.percentWidth = 50;
      hbox.addComponent(label);

      // Add an input field for the data field.
      var input:Component;
      switch (field.type)
      {
        case INTEGER:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 1.0;
          if (field.min != null) numberStepper.min = field.min;
          if (field.max != null) numberStepper.max = field.max;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case FLOAT:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 0.1;
          if (field.min != null) numberStepper.min = field.min;
          if (field.max != null) numberStepper.max = field.max;
          if (field.defaultValue != null) numberStepper.value = field.defaultValue;
          input = numberStepper;
        case BOOL:
          var checkBox:CheckBox = new CheckBox();
          checkBox.id = field.name;
          if (field.defaultValue != null) checkBox.selected = field.defaultValue;
          input = checkBox;
        case ENUM:
          var dropDown:DropDown = new DropDown();
          dropDown.id = field.name;
          dropDown.percentWidth = 100.0;
          dropDown.dropdownSize = 10;
          dropDown.searchable = true;
          dropDown.dataSource = new ArrayDataSource();

          if (field.keys == null) throw 'Field "${field.name}" is of Enum type but has no keys.';

          // Add entries to the dropdown.
          for (optionName in field.keys.keys())
          {
            var optionValue:Null<Dynamic> = field.keys.get(optionName);
            dropDown.dataSource.add({value: optionValue, text: optionName});
          }

          dropDown.value = field.defaultValue;

          // TODO: Add an option to customize sort.
          dropDown.dataSource.sort('text', ASCENDING);

          input = dropDown;
        case STRING:
          input = new TextField();
          input.id = field.name;
          if (field.defaultValue != null) input.text = field.defaultValue;
        case FRAME:
          hbox.removeComponent(label, true);

          input = new Frame();
          input.id = field.name;
          input.text = field.title;
          input.percentWidth = 100;
          if (field.collapsible != null)
          {
            var targetFrame:Frame = cast parent;
            targetFrame.collapsible = field.collapsible;
          }

          var frameVBox:VBox = new VBox();
          frameVBox.percentWidth = 100;
          input.addComponent(frameVBox);

          if (field.children != null) recursiveChildAdd(frameVBox, new SongNoteSchema(field.children));

        default:
          // Unknown type. Display a label that proclaims the type so we can debug it.
          input = new Label();
          input.id = field.name;
          input.text = field.type;
      }

      // Putting in a box so we can add a unit label easily if there is one.
      var inputBox:HBox = new HBox();
      inputBox.percentWidth = 50;
      if (field.type != FRAME) inputBox.addComponent(input);

      hbox.addComponent(field.type == FRAME ? input : inputBox);

      // Ensure chartEditorState.noteParamsToPlace reflects default UI values so preview is correct on first open
      if (field.defaultValue != null)
      {
        // Only set if not already present (don't overwrite existing selection data)
        if (chartEditorState.noteParamsToPlace.get(field.name) == null)
        {
          chartEditorState.noteParamsToPlace.set(field.name, field.defaultValue);
        }
      }

      // Update the value of the note params without modifying
      input.pauseEvent(UIEvent.CHANGE, true);
      input.onChange = function(event:UIEvent) {
        if (field.type == FRAME) return;

        var value = event.target.value;
        if (field.type == ENUM)
        {
          var drp:DropDown = cast event.target;
          value = drp.selectedItem?.value ?? field.defaultValue;
        }
        else if (field.type == BOOL)
        {
          var chk:CheckBox = cast event.target;
          value = cast(chk.selected, Null<Bool>); // Need to cast to nullable bool or the compiler will get mad.
        }

        trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note Toolbox Form: ${event.target.id} = ${value}');

        // Edit the note params to place.
        if (value == null)
        {
          chartEditorState.noteParamsToPlace.remove(event.target.id);
        }
        else
        {
          chartEditorState.noteParamsToPlace.set(event.target.id, value);
        }

        // Edit the note params of any existing notes.
        if (!_initializing && chartEditorState.currentNoteSelection.length > 0)
        {
          trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Note Toolbox MODIFYING all selected notes...');
          for (note in chartEditorState.currentNoteSelection)
          {
            note.kind = chartEditorState.noteKindToPlace;
            note.params = Reflect.copy(chartEditorState.noteParamsToPlace);
          }
          chartEditorState.saveDataDirty = true;
          chartEditorState.noteDisplayDirty = true;
          chartEditorState.notePreviewDirty = true;
          chartEditorState.noteTooltipsDirty = true;
        }
      }

      input.resumeEvent(UIEvent.CHANGE, true, true);
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorNoteDataToolbox
  {
    return new ChartEditorNoteDataToolbox(chartEditorState);
  }
}
#end
