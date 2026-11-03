package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.event.SongEventSchema;
import funkin.data.event.SongEventSchema.SongEventFieldType;
import funkin.data.event.SongEventSchema.SongEventSchemaField;
import funkin.data.song.SongData.SongEventData;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;

/**
 * The Properties panel for a selection of different kinds of events.
 */
class SharedPropertiesContainer extends BaseEventContainer
{
  /**
   * Which fields the current controls were built for, so the same set is not built twice.
   */
  var builtKey:String = '';

  var fields:Array<SongEventSchemaField> = [];
  var controls:Array<Component> = [];
  var emptyLabel:Null<Label> = null;

  public function new(state:CameraEditorState)
  {
    super(state);
    this.id = 'propertiesContainer';
    this.percentWidth = 100;
  }

  public function loadCurrentEventData():Void
  {
    if (primaryEvent == null) return;

    var shared:Array<SongEventSchemaField> = findSharedFields();
    var key:String = [for (field in shared) '${field.name}:${field.type}:${enumKeys(field).join('|')}'].join(',');
    if (key != builtKey)
    {
      build(shared);
      builtKey = key;
    }

    for (i in 0...fields.length) loadControl(fields[i], controls[i]);
  }

  /**
   * The fields that every selected event has, with the same type.
   */
  function findSharedFields():Array<SongEventSchemaField>
  {
    var result:Array<SongEventSchemaField> = [];
    var first:Null<SongEventSchema> = primaryEvent.getSchema();
    if (first == null) return result;

    @:privateAccess
    var candidates:Array<SongEventSchemaField> = first.listAllFields(cast first);
    for (candidate in candidates)
    {
      if (candidate.type == SongEventFieldType.FRAME) continue;

      var keys:Null<Map<String, Dynamic>> = candidate.keys != null ? candidate.keys.copy() : null;
      var sharedByAll:Bool = true;
      for (event in editedEvents)
      {
        var other:Null<SongEventSchemaField> = event.getSchema()?.getByName(candidate.name);
        if (other == null || other.type != candidate.type)
        {
          sharedByAll = false;
          break;
        }
        if (keys != null)
        {
          for (title => value in keys.copy())
          {
            if (other.keys == null || !other.keys.exists(title) || other.keys.get(title) != value) keys.remove(title);
          }
        }
      }
      if (!sharedByAll) continue;
      if (keys != null && !keys.keys().hasNext()) continue;

      result.push(
        {
          name: candidate.name,
          title: candidate.title,
          type: candidate.type,
          keys: keys,
          min: candidate.min,
          max: candidate.max,
          step: candidate.step,
          units: candidate.units,
          defaultValue: candidate.defaultValue
        });
    }
    return result;
  }

  static function enumKeys(field:SongEventSchemaField):Array<String>
  {
    if (field.keys == null) return [];
    var keys:Array<String> = [for (key in field.keys.keys()) key];
    keys.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
    return keys;
  }

  function build(shared:Array<SongEventSchemaField>):Void
  {
    removeAllComponents();
    fields = shared;
    controls = [];
    loadedNumbers.clear();
    loadedTexts.clear();
    loadedBools.clear();
    checkboxLabels.clear();

    if (fields.length == 0)
    {
      emptyLabel = new Label();
      emptyLabel.text = 'The selected events have no properties in common.';
      addComponent(emptyLabel);
      return;
    }

    for (field in fields)
    {
      var row:HBox = new HBox();
      row.percentWidth = 100;

      var label:Label = new Label();
      label.text = field.units != null ? '${field.title} (${field.units})' : field.title;
      label.percentWidth = 40;
      label.verticalAlign = 'center';
      row.addComponent(label);

      var control:Component = createControl(field);
      control.percentWidth = 60;
      row.addComponent(control);

      addComponent(row);
      controls.push(control);
    }
  }

  function createControl(field:SongEventSchemaField):Component
  {
    switch (field.type)
    {
      case INTEGER | FLOAT:
        var stepper:NumberStepper = new NumberStepper();
        if (field.min != null) stepper.min = field.min;
        if (field.max != null) stepper.max = field.max;
        var step:Float = field.step ?? (field.type == INTEGER ? 1 : 0.1);
        stepper.step = step;
        stepper.precision = field.type == INTEGER ? 0 : decimalsOf(step);
        stepper.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
        {
          if (primaryEvent == null) return;
          if (!isUserNumberChange(stepper, stepper.value)) return;
          var value:Float = stepper.value;
          setOnAll(field.name, field.type == INTEGER ? Std.int(value) : value);
          afterEdit(field.name);
        });
        return stepper;

      case BOOL:
        var checkbox:CheckBox = new CheckBox();
        checkbox.text = '';
        checkbox.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
        {
          if (primaryEvent == null) return;
          if (!isUserBoolChange(checkbox, checkbox.selected)) return;
          restoreMixedLabel(checkbox);
          setOnAll(field.name, checkbox.selected);
          afterEdit(field.name);
        });
        return checkbox;

      case ENUM:
        var dropdown:DropDown = new DropDown();
        for (title in enumKeys(field))
        {
          dropdown.dataSource.add({id: field.keys.get(title), text: title});
        }
        dropdown.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
        {
          if (primaryEvent == null || dropdown.selectedItem == null) return;
          if (!isUserChoiceChange(dropdown, dropdown.selectedItem.id)) return;
          setOnAll(field.name, dropdown.selectedItem.id);
          afterEdit(field.name);
        });
        return dropdown;

      default:
        var text:TextField = new TextField();
        text.registerEvent(UIEvent.CHANGE, function(_:UIEvent):Void
        {
          if (primaryEvent == null) return;
          if (loadedTexts.get(text) == text.text) return;
          loadedTexts.set(text, text.text);
          setOnAll(field.name, text.text);
          afterEdit(field.name);
        });
        return text;
    }
  }

  function afterEdit(fieldName:String):Void
  {
    updateCameraPreview();
    if (fieldName == 'duration' || fieldName == 'ease') updateBlockVisuals();
  }

  /**
   * An event's value for the field, falling back to the field's default if not set.
   */
  function valueOf(event:SongEventData, field:SongEventSchemaField):Dynamic
  {
    var value:Dynamic = event.getDynamic(field.name);
    if (value != null) return value;
    return event.getSchema()?.getByName(field.name)?.defaultValue;
  }

  function sharedValue(field:SongEventSchemaField):Bool
  {
    var first:Dynamic = valueOf(primaryEvent, field);
    for (event in editedEvents)
    {
      if (valueOf(event, field) != first) return false;
    }
    return true;
  }

  function loadControl(field:SongEventSchemaField, control:Component):Void
  {
    markShared(control, sharedValue(field));
    var value:Dynamic = valueOf(primaryEvent, field);

    switch (field.type)
    {
      case INTEGER | FLOAT:
        loadNumber(control, value != null ? (value : Float) : 0);

      case BOOL:
        var checkbox:CheckBox = cast control;
        quietly(checkbox, () -> checkbox.selected = value == true);
        loadedBools.set(checkbox, value == true);

      case ENUM:
        var dropdown:DropDown = cast control;
        quietly(dropdown, () -> dropdown.selectItemBy(item -> item != null && item.id == value));
        rememberChoice(dropdown, value);

      default:
        var text:TextField = cast control;
        var str:String = value != null ? Std.string(value) : '';
        quietly(text, () -> text.text = str);
        loadedTexts.set(text, str);
    }
  }

  static function decimalsOf(step:Float):Int
  {
    var text:String = Std.string(step);
    var dot:Int = text.indexOf('.');
    return dot < 0 ? 0 : text.length - dot - 1;
  }
}
#end
