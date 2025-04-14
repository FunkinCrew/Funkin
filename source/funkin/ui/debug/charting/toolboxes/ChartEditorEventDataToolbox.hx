package funkin.ui.debug.charting.toolboxes;

import funkin.data.event.SongEventSchema;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.core.Component;
import funkin.data.event.SongEventRegistry;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.containers.Grid;

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/event-data.xml"))
class ChartEditorEventDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxEventsEventKind:DropDown;
  var toolboxEventsDataFrame:Frame;
  var toolboxEventsDataGrid:Grid;

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
    chartEditorState.menubarItemToggleToolboxEventData.selected = false;
  }

  function initialize():Void
  {
    toolboxEventsEventKind.onChange = function(event:UIEvent) {
      if (event.data == null)
      {
        trace('ChartEditorEventDataToolbox: Event data is null');
      }

      var eventType:String = event.data.id;
      var sameEvent:Bool = (eventType == chartEditorState.eventKindToPlace);

      trace('ChartEditorEventDataToolbox - Event type changed: $eventType');

      // Edit the event data to place.
      chartEditorState.eventKindToPlace = eventType;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(eventType);

      if (schema == null)
      {
        trace('ChartEditorEventDataToolbox - Unknown event kind: $eventType');
        return;
      }

      if (!sameEvent) chartEditorState.eventDataToPlace = {};
      buildEventDataFormFromSchema(toolboxEventsDataGrid, schema, chartEditorState.eventKindToPlace);

      if (!_initializing && chartEditorState.currentEventSelection.length > 0)
      {
        // Edit the event data of any selected events.
        for (event in chartEditorState.currentEventSelection)
        {
          event.eventKind = chartEditorState.eventKindToPlace;
          event.value = chartEditorState.eventDataToPlace;
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
      }
    }
    toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    trace('ChartEditorEventDataToolbox - Starting event kind: ${startingEventValue}');
    toolboxEventsEventKind.value = startingEventValue;

    toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
  }

  public override function refresh():Void
  {
    super.refresh();

    toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      throw 'ChartEditorEventDataToolbox - Event kind not in dropdown: ${chartEditorState.eventKindToPlace}';
    }
    else if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
      if (schema == null)
      {
        trace('ChartEditorEventDataToolbox - Unknown event kind: ${chartEditorState.eventKindToPlace}');
      }
      else
      {
        trace('ChartEditorEventDataToolbox - Event kind changed: ${toolboxEventsEventKind.value.id} != ${newDropdownElement.id} != ${lastEventKind}, rebuilding form');
        buildEventDataFormFromSchema(toolboxEventsDataGrid, schema, chartEditorState.eventKindToPlace);
      }
    }
    else
    {
      trace('ChartEditorEventDataToolbox - Event kind not changed: ${toolboxEventsEventKind.value} == ${newDropdownElement} == ${lastEventKind}');
    }

    for (pair in chartEditorState.eventDataToPlace.keyValueIterator())
    {
      var fieldId:String = pair.key;
      var value:Null<Dynamic> = pair.value;

      var field:Component = toolboxEventsDataGrid.findComponent(fieldId);

      if (field == null)
      {
        throw 'ChartEditorEventDataToolbox - Field "${fieldId}" does not exist in the event data form for kind ${lastEventKind}.';
      }
      else
      {
        switch (field)
        {
          case Std.isOfType(_, NumberStepper) => true:
            var numberStepper:NumberStepper = cast field;
            numberStepper.value = value;
          case Std.isOfType(_, CheckBox) => true:
            var checkBox:CheckBox = cast field;
            checkBox.selected = value;
          case Std.isOfType(_, DropDown) => true:
            var dropDown:DropDown = cast field;
            dropDown.value = value;
          case Std.isOfType(_, TextField) => true:
            var textField:TextField = cast field;
            textField.text = value;
          default:
            throw 'ChartEditorEventDataToolbox - Field "${fieldId}" is of unknown type "${Type.getClassName(Type.getClass(field))}".';
        }
      }
    }

    toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
  }

  var lastEventKind:String = 'unknown';

  function buildEventDataFormFromSchema(target:Box, schema:SongEventSchema, eventKind:String):Void
  {
    trace('Building event data form from schema for event kind: ${eventKind}');
    // trace(schema);

    lastEventKind = eventKind ?? 'unknown';

    // Clear the frame.
    target.removeAllComponents();

    for (field in schema)
    {
      if (field == null) continue;

      // Add a label for the data field.
      var label:Label = new Label();
      label.text = field.title;
      label.verticalAlign = "center";
      target.addComponent(label);

      // Add an input field for the data field.
      var input:Component;
      switch (field.type)
      {
        case INTEGER:
          var numberStepper:NumberStepper = new NumberStepper();
          numberStepper.id = field.name;
          numberStepper.step = field.step ?? 1.0;
          if (field.min != null) numberStepper.min = field.min;
          if (field.min != null) numberStepper.max = field.max;
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
          dropDown.width = 200.0;
          dropDown.dropdownSize = 10;
          dropDown.dropdownWidth = 300;
          dropDown.searchable = true;
          dropDown.dataSource = new ArrayDataSource();

          if (field.keys == null) throw 'Field "${field.name}" is of Enum type but has no keys.';

          // Add entries to the dropdown.

          for (optionName in field.keys.keys())
          {
            var optionValue:Null<Dynamic> = field.keys.get(optionName);
            // trace('$optionName : $optionValue');
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
        default:
          // Unknown type. Display a label that proclaims the type so we can debug it.
          input = new Label();
          input.id = field.name;
          input.text = field.type;
      }

      // Putting in a box so we can add a unit label easily if there is one.
      var inputBox:HBox = new HBox();
      inputBox.addComponent(input);

      // Add a unit label if applicable.
      if (field.units != null && field.units != "")
      {
        var units:Label = new Label();
        units.text = field.units;
        units.verticalAlign = "center";
        inputBox.addComponent(units);
      }

      target.addComponent(inputBox);

      // Update the value of the event data.
      input.onChange = function(event:UIEvent) {
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

        trace('ChartEditorToolboxHandler.buildEventDataFormFromSchema() - ${event.target.id} = ${value}');

        // Edit the event data to place.
        if (value == null)
        {
          chartEditorState.eventDataToPlace.remove(event.target.id);
        }
        else
        {
          chartEditorState.eventDataToPlace.set(event.target.id, value);
        }

        // Edit the event data of any existing events.
        if (!_initializing && chartEditorState.currentEventSelection.length > 0)
        {
          for (songEvent in chartEditorState.currentEventSelection)
          {
            songEvent.eventKind = chartEditorState.eventKindToPlace;
            songEvent.value = Reflect.copy(chartEditorState.eventDataToPlace);
          }
          chartEditorState.saveDataDirty = true;
          chartEditorState.noteDisplayDirty = true;
          chartEditorState.notePreviewDirty = true;
          chartEditorState.noteTooltipsDirty = true;
        }
      }
    }
  }

  public static function build(chartEditorState:ChartEditorState):ChartEditorEventDataToolbox
  {
    return new ChartEditorEventDataToolbox(chartEditorState);
  }
}
