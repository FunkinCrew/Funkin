package funkin.ui.debug.charting.toolboxes;

#if FEATURE_CHART_EDITOR
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
  var toolboxEventsModifyAllEvents:CheckBox;
  var toolboxEventsDataFrame:Frame;
  var selectedEventDropdownItemRenderer:haxe.ui.core.ItemRenderer;
  var toolboxEventsDataGrid:Grid;
  var toolboxEventsCustomKindLabel:Label;
  var toolboxEventsCustomKind:TextField;

  var _initializing:Bool = true;
  var populateSelectedEventsDropDown:Bool = true;

  public function new(chartEditorState2:ChartEditorState)
  {
    super(chartEditorState2);

    selectedEventDropdownItemRenderer = toolboxEventsSelectedEvents.findComponent(haxe.ui.core.ItemRenderer);

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

      if (!sameEvent) trace('ChartEditorEventDataToolbox - Event type changed: $eventType');

      // Edit the event data to place.
      chartEditorState.eventKindToPlace = eventType;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(eventType);

      if (!sameEvent) chartEditorState.eventDataToPlace = {};
      if (schema == null)
      {
        trace('ChartEditorEventDataToolbox - Building useless schema for unknown event');
        toolboxEventsCustomKindLabel.hidden = false;
        toolboxEventsCustomKind.hidden = false;
        buildEventDataFormFromSchema(toolboxEventsDataGrid, buildSchemaFromEventData(), chartEditorState.eventKindToPlace);
      }
      else
      {
        toolboxEventsCustomKindLabel.hidden = true;
        toolboxEventsCustomKind.hidden = true;
        buildEventDataFormFromSchema(toolboxEventsDataGrid, schema, chartEditorState.eventKindToPlace);
      }

      if (!_initializing && toolboxEventsModifyAllEvents.selected && chartEditorState.currentEventSelection.length > 0)
      {
        // Edit the event data of all selected events.
        for (event in chartEditorState.currentEventSelection)
        {
          event.eventKind = chartEditorState.eventKindToPlace;
          event.value = chartEditorState.eventDataToPlace;
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
        chartEditorState.noteTooltipsDirty = true;
      }
    }
    toolboxEventsCustomKind.onChange = function(event:UIEvent) {
      var customKind:Null<String> = event?.target?.text;

      if (customKind == null) return;

      var prevEventKindToPlace = chartEditorState.eventKindToPlace;
      chartEditorState.eventKindToPlace = customKind;

      if (!_initializing && chartEditorState.currentEventSelection.length > 0)
      {
        if (toolboxEventsModifyAllEvents.selected)
        {
          // Edit the event data of any existing events of the same type.
          for (event in chartEditorState.currentEventSelection)
          {
            if (event.eventKind == prevEventKindToPlace)
            event.eventKind = chartEditorState.eventKindToPlace;
          }
        }
        else
        {
          // Find the currently selected event and update it's values.
          var event = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex];
          if (event != null)
          {
            event.eventKind = chartEditorState.eventKindToPlace;
          }
        }
        chartEditorState.saveDataDirty = true;
        chartEditorState.noteDisplayDirty = true;
        chartEditorState.notePreviewDirty = true;
        chartEditorState.noteTooltipsDirty = true;
      }
    }

    toolboxEventsSelectedEvents.onChange = function(event:UIEvent) {
      if (event.target.value == null) return;
      // Forced to pass event.target.value.id rather than the selectedIndex due to it not getting set at all in refreshSelectedEvents for no reason.
      var selectedEvent = chartEditorState.currentEventSelection[Std.parseInt(event.target.value.id)];
      if (selectedEvent != null)
      {
        chartEditorState.eventKindToPlace = selectedEvent.eventKind;
        chartEditorState.eventDataToPlace = selectedEvent.value;

        // This bool prevents the selected event from having it's data overridden (and unnecessary code execution). Look, it works, don't question it.
        populateSelectedEventsDropDown = false;

        refresh();

        populateSelectedEventsDropDown = true;
      }
    }

    toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);

    refreshSelectedEvents();

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    trace('ChartEditorEventDataToolbox - Starting event kind: ${startingEventValue}');
    toolboxEventsEventKind.value = startingEventValue;

    toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
  }

  function refreshSelectedEvents(startingChartEvent:Int = 0):Void
  {
    var startingSelectedEvent = ChartEditorDropdowns.populateDropdownWithChartEvents(toolboxEventsSelectedEvents, chartEditorState, startingChartEvent);
    // Why does this particular selectedIndex refuse to be set more than once??????
    toolboxEventsSelectedEvents.selectedIndex = Std.parseInt(startingSelectedEvent.id);
    toolboxEventsSelectedEvents.value = startingSelectedEvent;
    selectedEventDropdownItemRenderer.data = startingSelectedEvent;
  }

  public override function refresh():Void
  {
    super.refresh();

    toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);

    if (populateSelectedEventsDropDown) refreshSelectedEvents();

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      trace('ChartEditorEventDataToolbox - Event kind not in dropdown: ${chartEditorState.eventKindToPlace}');
      newDropdownElement = ChartEditorDropdowns.findDropdownElement('unknown', toolboxEventsEventKind);
      toolboxEventsCustomKindLabel.hidden = false;
      toolboxEventsCustomKind.hidden = false;
      toolboxEventsCustomKind.value = chartEditorState.eventKindToPlace;
    }
    else
    {
      toolboxEventsCustomKindLabel.hidden = true;
      toolboxEventsCustomKind.hidden = true;
    }

    if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
      if (schema == null)
      {
        // Build the event schema using the selected unknown event's value instead.
        trace('ChartEditorEventDataToolbox - Unknown event kind: ${chartEditorState.eventKindToPlace}');
        buildEventDataFormFromSchema(toolboxEventsDataGrid, buildSchemaFromEventData(), chartEditorState.eventKindToPlace);
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
      field.pauseEvent(UIEvent.CHANGE, true);

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
      field.resumeEvent(UIEvent.CHANGE, true, true);
    }

    toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
  }

  function buildSchemaFromEventData():SongEventSchema
  {
    var schema:SongEventSchema = new SongEventSchema([]);

    for (pair in chartEditorState.eventDataToPlace.keyValueIterator())
    {
      var fieldId:String = pair.key;
      var value:Null<Dynamic> = pair.value;

      switch (value)
      {
        case Std.isOfType(_, Int) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              defaultValue: value,
              step: 1,
              type: SongEventFieldType.INTEGER,
            });
        case Std.isOfType(_, Float) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              defaultValue: value,
              step: 0.1,
              type: SongEventFieldType.FLOAT,
            });
        case Std.isOfType(_, Bool) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              type: SongEventFieldType.BOOL,
              defaultValue: value,
            });
        case Std.isOfType(_, String) => true:
          schema.push(
            {
              name: '$fieldId',
              title: '$fieldId',
              type: SongEventFieldType.STRING,
              defaultValue: '$value',
            });
        default:
          throw 'ChartEditorEventDataToolbox - Field "${fieldId}" is of unknown type "${Type.getClassName(Type.getClass(value))}".';
      }
    }

    if (schema.getFirstField() == null)
    {
      // Fine, here's some useless values for the psychic in you.
      schema = new SongEventSchema([
        {
          name: 'value1',
          title: 'value1',
          type: SongEventFieldType.STRING,
          defaultValue: '',
        },
        {
          name: 'value2',
          title: 'value2',
          type: SongEventFieldType.STRING,
          defaultValue: '',
        },
      ]);
    }

    return schema;
  }

  var lastEventKind:String = 'unknown';

  function buildEventDataFormFromSchema(target:Box, schema:SongEventSchema, eventKind:String):Void
  {
    trace('Building event data form from schema for event kind: ${eventKind}');
    // trace(schema);

    lastEventKind = eventKind ?? 'unknown';

    // Clear the frame.
    target.removeAllComponents();

    if (schema == null) return;

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
          dropDown.width = 157.0;
          dropDown.dropdownSize = 10;
          dropDown.dropdownWidth = 157;
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

        if (!_initializing && chartEditorState.currentEventSelection.length > 0)
        {
          if (toolboxEventsModifyAllEvents.selected)
          {
            // Edit the event data of any existing events of the same type.
            for (event in chartEditorState.currentEventSelection)
            {
              if (event.eventKind == chartEditorState.eventKindToPlace) event.value = chartEditorState.eventDataToPlace;
            }
          }
          else
          {
            // Find the currently selected event and update it's values.
            var event = chartEditorState.currentEventSelection[toolboxEventsSelectedEvents.selectedIndex];
            if (event != null)
            {
              event.eventKind = chartEditorState.eventKindToPlace;
              event.value = Reflect.copy(chartEditorState.eventDataToPlace);
            }
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
#end
