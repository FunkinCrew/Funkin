package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.data.ArrayDataSource;
import haxe.ui.events.UIEvent;
import haxe.ui.core.Component;

/**
 * Generic schema-driven inspector for camera editor song events.
 */
class GenericSongEventContainer extends VBox
{
  public var cameraEditorState:CameraEditorState;

  var schema:Null<SongEventSchema>;
  var _initializing:Bool = true;

  public function new(state:CameraEditorState)
  {
    super();
    id = 'propertiesContainer';
    percentWidth = 100;
    cameraEditorState = state;
    schema = cameraEditorState.selectedSongEvent != null ? cameraEditorState.selectedSongEvent.getSchema() : null;
    build();
    _initializing = false;
  }

  function build():Void
  {
    if (cameraEditorState.selectedSongEvent == null || schema == null)
    {
      var empty = new Label();
      empty.text = 'No event schema available.';
      addComponent(empty);
      return;
    }

    var eventValue = cameraEditorState.selectedSongEvent.value;
    if (eventValue == null)
    {
      eventValue = new Map<String, Dynamic>();
      cameraEditorState.selectedSongEvent.value = eventValue;
    }

    cleanUpExtraFields(eventValue);

    for (field in schema)
    {
      if (field == null) continue;

      final fieldName:String = field.name;
      final fieldTitle:String = field.title;
      final fieldType:SongEventFieldType = field.type;
      final fieldUnits:Null<String> = field.units;
      final fieldDefaultValue:Dynamic = field.defaultValue;

      var row = new HBox();
      row.percentWidth = 100;
      row.id = 'container_${fieldName}';

      var label = new Label();
      label.text = fieldTitle;
      label.verticalAlign = 'center';
      label.percentWidth = 50;
      row.addComponent(label);

      var inputBox = new HBox();
      inputBox.percentWidth = 50;

      var currentValue = eventValue.get(fieldName);
      if (currentValue == null) currentValue = fieldDefaultValue;

      var input = createInput(field, currentValue);
      if (input != null)
      {
        final inputRef:Component = input;
        inputRef.id = fieldName;
        inputRef.pauseEvent(UIEvent.CHANGE, true);
        inputRef.onChange = function(_):Void
        {
          if (_initializing) return;

          var newValue = getValueFromInput(inputRef, fieldType);
          eventValue.set(fieldName, newValue);

          updateCameraPreview();
          updateBlockVisuals();
        };
        inputRef.resumeEvent(UIEvent.CHANGE, true, true);
        inputBox.addComponent(inputRef);
      }

      if (fieldUnits != null && fieldUnits != '')
      {
        var units = new Label();
        units.text = fieldUnits;
        units.verticalAlign = 'center';
        inputBox.addComponent(units);
      }

      row.addComponent(inputBox);
      addComponent(row);

      if (fieldDefaultValue != null && !eventValue.exists(fieldName))
      {
        eventValue.set(fieldName, fieldDefaultValue);
      }
    }
  }

  /**
   * Clear all existing values.
   */
  function cleanUpExtraFields(eventValue:Map<String, Dynamic>):Void
  {
    if (schema == null) return;

    var schemaFieldNames:Array<String> = [];
    for (field in schema)
    {
      if (field != null) schemaFieldNames.push(field.name);
    }

    var keysToRemove:Array<String> = [];
    for (key in eventValue.keys())
    {
      if (!schemaFieldNames.contains(key)) keysToRemove.push(key);
    }
    for (key in keysToRemove)
    {
      eventValue.remove(key);
    }
  }

  function createInput(field:Dynamic, currentValue:Dynamic):Component
  {
    return switch (field.type)
    {
      case STRING:
        var textField = new TextField();
        textField.text = currentValue != null ? Std.string(currentValue) : '';
        textField;
      case INTEGER:
        var stepper = new NumberStepper();
        stepper.step = field.step != null ? field.step : 1.0;
        if (field.min != null) stepper.min = field.min;
        if (field.max != null) stepper.max = field.max;
        if (currentValue != null) stepper.value = currentValue;
        stepper;
      case FLOAT:
        var stepper = new NumberStepper();
        stepper.step = field.step != null ? field.step : 0.1;
        if (field.min != null) stepper.min = field.min;
        if (field.max != null) stepper.max = field.max;
        if (currentValue != null) stepper.value = currentValue;
        stepper;
      case BOOL:
        var checkBox = new CheckBox();
        checkBox.selected = currentValue == true;
        checkBox;
      case ENUM:
        var dropDown = new DropDown();
        dropDown.width = 160;
        dropDown.dropdownSize = 10;
        dropDown.searchable = true;
        var data = new ArrayDataSource();
        if (field.keys != null)
        {
          var keyMap:Map<String, Dynamic> = cast field.keys;
          for (optionName in keyMap.keys())
          {
            data.add({text: optionName, value: keyMap.get(optionName)});
          }
        }
        dropDown.dataSource = data;
        if (currentValue != null) dropDown.value = currentValue;
        dropDown;
      default:
        var fallback = new TextField();
        fallback.text = currentValue != null ? Std.string(currentValue) : '';
        fallback;
    }
  }

  function getValueFromInput(input:Component, fieldType:SongEventFieldType):Dynamic
  {
    return switch (fieldType)
    {
      case STRING:
        var tf:TextField = cast input;
        tf.text;
      case INTEGER:
        var ns:NumberStepper = cast input;
        Std.int(ns.value);
      case FLOAT:
        var ns:NumberStepper = cast input;
        ns.value;
      case BOOL:
        var cb:CheckBox = cast input;
        cb.selected;
      case ENUM:
        var dd:DropDown = cast input;
        dd.selectedItem != null ? dd.selectedItem.value : dd.value;
      default:
        var tf:TextField = cast input;
        tf.text;
    }
  }

  function updateCameraPreview():Void
  {
    cameraEditorState.replayCameraTimeline(cameraEditorState.conductorInUse.songPosition);
  }

  function updateBlockVisuals():Void
  {
    cameraEditorState.timeline.viewport.refreshBlockVisuals(true);
  }
}
#end
