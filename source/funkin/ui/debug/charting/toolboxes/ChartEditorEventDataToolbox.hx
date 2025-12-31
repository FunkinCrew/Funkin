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
import haxe.ui.containers.VBox;
import haxe.ui.containers.Frame;
import haxe.ui.events.UIEvent;
import haxe.ui.data.ArrayDataSource;

// TODO: Fix null safety when used with HaxeUI build macros.

/**
 * The toolbox which allows modifying information like Song Title, Scroll Speed, Characters/Stages, and starting BPM.
 */
@:access(funkin.ui.debug.charting.ChartEditorState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/chart-editor/toolboxes/event-data.xml"))
class ChartEditorEventDataToolbox extends ChartEditorBaseToolbox
{
  var toolboxEventsEventKind:DropDown;
  var toolboxEventsDataFrame:Frame;
  var toolboxEventsDataBox:VBox;

  var _initializing:Bool = true;

  /**
   * If `true`, changing the value of the Event Kind dropdown will trigger the `onEventKindChanged` callback,
   * modifying the event kind of all selected events.
   * Set to `false` to safety modify the dropdown directly, without modifying placed events.
   */
  var shouldTriggerOnEventKindChanged(default, set):Bool = true;

  function set_shouldTriggerOnEventKindChanged(value:Bool):Bool
  {
    shouldTriggerOnEventKindChanged = value;

    if (!shouldTriggerOnEventKindChanged)
    {
      toolboxEventsEventKind.pauseEvent(UIEvent.CHANGE, true);
    }
    else
    {
      toolboxEventsEventKind.resumeEvent(UIEvent.CHANGE, true, true);
    }

    return shouldTriggerOnEventKindChanged;
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
    chartEditorState.menubarItemToggleToolboxEventData.selected = false;
  }

  function initialize():Void
  {
    toolboxEventsEventKind.onChange = onEventKindChanged;
    shouldTriggerOnEventKindChanged = false;

    var startingEventValue = ChartEditorDropdowns.populateDropdownWithSongEvents(toolboxEventsEventKind, chartEditorState.eventKindToPlace);
    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Building Event toolbox with kind "${startingEventValue}"');
    toolboxEventsEventKind.value = startingEventValue;

    shouldTriggerOnEventKindChanged = true;
  }

  function onEventKindChanged(event:UIEvent):Void
  {
    if (event.data == null)
    {
      trace(' WARNING '.bg_yellow().bold() + ' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox received an invalid UI event.');
      return;
    }

    var eventKind:String = event.data.id;
    var sameEvent:Bool = (eventKind == chartEditorState.eventKindToPlace);

    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox changed kind to "$eventKind"');

    // Edit the event data to place.
    chartEditorState.eventKindToPlace = eventKind;

    var schema:SongEventSchema = SongEventRegistry.getEventSchema(eventKind);

    if (schema == null)
    {
      trace(' WARNING '.bold().bg_yellow() + ' Event toolbox attempted to use unknown event kind "$eventKind"');
      return;
    }

    if (!sameEvent) chartEditorState.eventDataToPlace = {};
    buildEventDataFormFromSchema(toolboxEventsDataBox, schema, chartEditorState.eventKindToPlace);

    if (!_initializing && chartEditorState.currentEventSelection.length > 0)
    {
      // Edit the event data of any selected events.
      trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event toolbox MODIFYING events to kind "${chartEditorState.eventKindToPlace}"');
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

  public override function refresh():Void
  {
    super.refresh();

    shouldTriggerOnEventKindChanged = false;

    var newDropdownElement = ChartEditorDropdowns.findDropdownElement(chartEditorState.eventKindToPlace, toolboxEventsEventKind);

    if (newDropdownElement == null)
    {
      throw 'CHART EDITOR - In Event Toolbox, event kind "${chartEditorState.eventKindToPlace}" not in dropdown!';
    }
    else if (toolboxEventsEventKind.value != newDropdownElement || lastEventKind != toolboxEventsEventKind.value.id)
    {
      toolboxEventsEventKind.value = newDropdownElement;

      var schema:SongEventSchema = SongEventRegistry.getEventSchema(chartEditorState.eventKindToPlace);
      if (schema == null)
      {
        trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event kind "${chartEditorState.eventKindToPlace}" has no schema for Event toolbox!');
      }
      else
      {
        trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox: Kind changed to "${chartEditorState.eventKindToPlace}", rebuilding form...');
        buildEventDataFormFromSchema(toolboxEventsDataBox, schema, chartEditorState.eventKindToPlace);
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

      var field:Component = toolboxEventsDataBox.findComponent(fieldId);
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

    shouldTriggerOnEventKindChanged = true;
  }

  var lastEventKind:String = 'unknown';

  function buildEventDataFormFromSchema(target:Box, schema:SongEventSchema, eventKind:String):Void
  {
    trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox: Building form from schema ("${eventKind}")...');

    _initializing = true;

    lastEventKind = eventKind ?? 'unknown';

    // Clear the frame.
    target.removeAllComponents();

    recursiveChildAdd(target, schema);

    _initializing = false;
  }

  function recursiveChildAdd(parent:Component, schema:SongEventSchema)
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

          if (field.children != null) recursiveChildAdd(frameVBox, new SongEventSchema(field.children));

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

      // Add a unit label if applicable.
      if (field.units != null && field.units != "")
      {
        var units:Label = new Label();
        units.text = field.units;
        units.verticalAlign = "center";
        inputBox.addComponent(units);
      }

      hbox.addComponent(field.type == FRAME ? input : inputBox);

      // Update the value of the event data without modifying
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

        trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox Form: ${event.target.id} = ${value}');

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
          trace(' CHART EDITOR '.bold().bg_bright_yellow() + 'Event Toolbox MODIFYING all selected events...');
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
      input.resumeEvent(UIEvent.CHANGE, true, true);
    }
  }

  /**
   * Constructs a new Event toolbox for the given Chart Editor.
   * @param chartEditorState The Chart Editor state to build the toolbox for.
   * @return The newly constructed toolbox.
   */
  public static function build(chartEditorState:ChartEditorState):ChartEditorEventDataToolbox
  {
    return new ChartEditorEventDataToolbox(chartEditorState);
  }
}
#end
