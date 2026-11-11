package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.play.event.CustomSongEvent;
import funkin.play.event.CustomSongEvent.CustomEventParam;
import funkin.ui.haxeui.components.CustomEventParamsList;
import funkin.ui.haxeui.components.LabeledRow;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.events.UIEvent;

/**
 * The contents of the Properties panel, while a Custom Event is selected.
 */
class CustomEventContainer extends BaseEventContainer
{
  var nameField:TextField;
  var offsetStepper:NumberStepper;
  var durationStepper:NumberStepper;
  var easeDropdown:DropDown;
  var easeDirDropdown:DropDown;
  var paramsList:CustomEventParamsList;

  static final EASES:Array<String> = [
    'linear', 'sine', 'quad', 'cube', 'quart', 'quint', 'expo', 'smoothStep', 'smootherStep', 'elastic', 'back', 'bounce', 'circ'
  ];
  static final EASE_DIRS:Array<String> = ['In', 'Out', 'InOut'];

  public function new(state:CameraEditorState)
  {
    super(state);
    this.id = 'propertiesContainer';
    this.percentWidth = 100;

    var row:LabeledRow = new LabeledRow();
    row.text = 'Name';
    nameField = new TextField();
    nameField.width = 160;
    row.addComponent(nameField);
    addComponent(row);

    offsetStepper = new NumberStepper();
    offsetStepper.width = 160;
    offsetStepper.step = 1;
    offsetStepper.precision = 3;
    offsetStepper.tooltip = 'Moves when the event starts, negative is earlier.';
    addRow('Offset (ms)', offsetStepper);

    durationStepper = new NumberStepper();
    durationStepper.width = 160;
    durationStepper.min = 0;
    durationStepper.step = 0.5;
    durationStepper.precision = 2;
    addRow('Duration (steps)', durationStepper);

    easeDropdown = buildChoices(EASES);
    addRow('Easing Type', easeDropdown);
    easeDirDropdown = buildChoices(EASE_DIRS);
    addRow('Easing Direction', easeDirDropdown);

    paramsList = new CustomEventParamsList();
    paramsList.onParamsChanged = onParamsChanged;
    addComponent(paramsList);

    bindStringField(nameField, 'name');
    bindFloatField(offsetStepper, 'offset');
    bindFloatField(durationStepper, 'duration');
    bindChoice(easeDropdown, 'ease');
    bindChoice(easeDirDropdown, 'easeDir');
  }

  function addRow(label:String, control:haxe.ui.core.Component):Void
  {
    var row:LabeledRow = new LabeledRow();
    row.text = label;
    row.addComponent(control);
    addComponent(row);
  }

  static function buildChoices(values:Array<String>):DropDown
  {
    var dropdown:DropDown = new DropDown();
    dropdown.width = 160;
    for (value in values) dropdown.dataSource.add({id: value, text: value});
    return dropdown;
  }

  function bindChoice(dropdown:DropDown, fieldName:String):Void
  {
    dropdown.registerEvent(UIEvent.CHANGE, function(_):Void
    {
      if (primaryEvent == null || dropdown.selectedItem == null) return;
      var value:String = dropdown.selectedItem.id;
      if (!isUserChoiceChange(dropdown, value)) return;
      setOnAll(fieldName, value);
      updateCameraPreview();
    });
  }

  function loadChoice(dropdown:DropDown, fieldName:String, defaultValue:String):Void
  {
    var primary = primaryEvent;
    if (primary == null) return;
    markShared(dropdown, allMatch(fieldName, defaultValue));
    var value:String = primary.getString(fieldName) ?? defaultValue;
    quietly(dropdown, () -> dropdown.selectItemBy(item -> item != null && item.id == value));
    rememberChoice(dropdown, value);
  }

  public function loadCurrentEventData():Void
  {
    var primary = primaryEvent;
    if (primary == null) return;
    loadStringField(nameField, 'name', '');
    loadFloatField(offsetStepper, 'offset', 0);
    loadFloatField(durationStepper, 'duration', 0);
    loadChoice(easeDropdown, 'ease', 'linear');
    loadChoice(easeDirDropdown, 'easeDir', 'InOut');
    paramsList.setParams(CustomSongEvent.paramsOf(primary));
  }

  function onParamsChanged(params:Array<CustomEventParam>):Void
  {
    if (primaryEvent == null) return;
    for (event in editedEvents) event.set(CustomSongEvent.PARAMS_FIELD, CustomSongEvent.copyParams(params));
    updateCameraPreview();
  }
}
#end
