package funkin.ui.debug.stageeditor.toolboxes;

import flixel.util.FlxColor;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import funkin.data.stage.StageData.StageDataProp;
import haxe.ui.containers.VBox;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-properties.xml"))
class StageEditorObjectPropertiesToolbox extends StageEditorBaseToolbox
{
  var linkedObject:Null<StageEditorObject> = null;

  var inputObjectPositionX:NumberStepper;
  var inputObjectPositionY:NumberStepper;
  var inputObjectScaleX:NumberStepper;
  var inputObjectScaleY:NumberStepper;
  var inputObjectZIndex:NumberStepper;
  var inputObjectScrollX:NumberStepper;
  var inputObjectScrollY:NumberStepper;
  var inputObjectAlpha:NumberStepper;
  var inputObjectAngle:NumberStepper;
  var inputObjectDanceEvery:NumberStepper;
  var inputObjectBlend:DropDown;
  var inputObjectTint:DropDown;

  var inputObjectFlipX:CheckBox;
  var inputObjectFlipY:CheckBox;
  var inputObjectAntialiasing:CheckBox;

  var dataObject:Null<StageDataProp> = null;

  public function new(stageEditorState2:StageEditorState)
  {
    super(stageEditorState2);

    initialize();

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowObjectProps.selected = false;
  }

  function initialize():Void
  {
    DropDownBuilder.HANDLER_MAP.set('inputObjectTint', Type.getClassName(ObjectTintHandler));

    inputObjectAlpha.onChange = event -> {
      if (linkedObject == null) return;
    }
  }

  public override function refresh():Void
  {
    linkedObject = stageEditorState.selectedProp;

    inputObjectPositionX.step = inputObjectPositionY.step = stageEditorState.moveStep;
    inputObjectAngle.step = stageEditorState.angleStep;

    // If there is no selected object, reset displays.
    if (linkedObject == null)
    {
      inputObjectPositionX.pos = 0;
      inputObjectPositionY.pos = 0;
      inputObjectScaleX.pos = 1;
      inputObjectScaleY.pos = 1;
      inputObjectZIndex.pos = 0;
      inputObjectScrollX.pos = 1;
      inputObjectScrollY.pos = 1;
      inputObjectAlpha.pos = 1;
      inputObjectAngle.pos = 0;
      inputObjectDanceEvery.pos = 0;
      inputObjectBlend.selectedIndex = 0;
      inputObjectTint.selectedItem = Color.fromString("white");

      inputObjectFlipX.selected = false;
      inputObjectFlipY.selected = false;
      inputObjectAntialiasing.selected = true;

      return;
    }

    dataObject = stageEditorState.currentProps.find(prop -> prop.name == linkedObject.name);
  }

  public static function build(stageEditorState:StageEditorState):StageEditorObjectPropertiesToolbox
  {
    return new StageEditorObjectPropertiesToolbox(stageEditorState);
  }
}

@:access(haxe.ui.core.Component)
private class ObjectTintHandler extends DropDownHandler
{
  private var _view:ObjectTintView = null;

  private override function get_component()
  {
    if (_view == null)
    {
      _view = new ObjectTintView();
      _view.dropdown = _dropdown;
      _view.currentColor = _cachedSelectedColor;
      _view.onChange = onColorChange;
    }

    return _view;
  }

  public override function prepare(_)
  {
    super.prepare(_);
    if (_view != null) _view.currentColor = _cachedSelectedColor;
  }

  private var _cachedSelectedColor:Null<Color> = null;

  private override function get_selectedItem():Dynamic
  {
    if (_view != null) _cachedSelectedColor = _view.currentColor;
    return _cachedSelectedColor;
  }

  private override function set_selectedItem(value:Dynamic):Dynamic
  {
    if ((value is String)) _cachedSelectedColor = Color.fromString(value);
    else
      _cachedSelectedColor = value;

    if (_view != null) _view.currentColor = _cachedSelectedColor;

    _dropdown.text = _cachedSelectedColor.toHex();

    return value;
  }

  private function onColorChange(e:UIEvent)
  {
    if (_view != null)
    {
      _cachedSelectedColor = _view.currentColor;
    }

    _dropdown.text = _cachedSelectedColor.toHex();

    var event = new UIEvent(UIEvent.CHANGE);
    event.value = _cachedSelectedColor.toHex();
    _dropdown.dispatch(event);
  }
}

@:xml('
<vbox style="spacing:0;padding:5px;">
    <color-picker id="picker" />
    <box id="cancelApplyButtons" style="padding-top: 5px;" width="100%">
        <hbox horizontalAlign="right">
            <button id="cancelButton" text="Cancel" styleName="text-small" style="padding: 4px 8px;" />
            <button id="applyButton" text="Apply" styleName="text-small" style="padding: 4px 8px;" />
        </hbox>
    </box>
</vbox>
')
private class ObjectTintView extends VBox
{
  public var dropdown:DropDown = null;

  public var currentColor(get, set):Null<Color>;

  private function get_currentColor():Null<Color>
  {
    return picker.currentColor;
  }

  private function set_currentColor(value:Null<Color>):Null<Color>
  {
    picker.currentColor = value;
    return value;
  }

  @:bind(cancelButton, MouseEvent.CLICK)
  private function onCancel(_)
  {
    dropdown.hideDropDown();
  }

  @:bind(applyButton, MouseEvent.CLICK)
  private function onApply(_)
  {
    dropdown.text = currentColor.toHex();

    var event = new UIEvent(UIEvent.CHANGE);
    event.value = currentColor.toHex();
    dropdown.dispatch(event);
  }
}
