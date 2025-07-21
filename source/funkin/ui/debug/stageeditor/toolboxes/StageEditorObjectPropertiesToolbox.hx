package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.containers.VBox;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Color;
import flixel.util.FlxColor;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-properties.xml"))
class StageEditorObjectPropertiesToolbox extends StageEditorDefaultToolbox
{
  var linkedObj:StageEditorObject = null;

  var objPosX:NumberStepper;
  var objPosY:NumberStepper;
  var objZIdx:NumberStepper;
  var objAlpha:NumberStepper;
  var objAngle:NumberStepper;
  var objScaleX:NumberStepper;
  var objScaleY:NumberStepper;
  var objScrollX:NumberStepper;
  var objScrollY:NumberStepper;
  var objDance:NumberStepper;

  var objPixel:CheckBox;
  var objFlipX:CheckBox;
  var objFlipY:CheckBox;

  var objBlend:DropDown;
  var objTint:DropDown;

  override public function new(state:StageEditorState)
  {
    super(state);

    // Initialize the custom DropDown view.
    DropDownBuilder.HANDLER_MAP.set("objTint", Type.getClassName(ObjectTintHandler));

    // Numeric callbacks.
    objPosX.onChange = function(_) {
      if (linkedObj != null) linkedObj.x = objPosX.pos;
    }

    objPosY.onChange = function(_) {
      if (linkedObj != null) linkedObj.y = objPosY.pos;
    }

    objZIdx.max = StageEditorState.MAX_Z_INDEX;
    objZIdx.onChange = function(_) {
      if (linkedObj != null)
      {
        linkedObj.zIndex = Std.int(objZIdx.pos);
        state.updateArray();
      }
    }

    objAlpha.onChange = function(_) {
      if (linkedObj != null) linkedObj.alpha = objAlpha.pos;
    }

    objAngle.onChange = function(_) {
      if (linkedObj != null) linkedObj.angle = objAngle.pos;
    }

    objScaleX.onChange = function(_) {
      if (linkedObj != null)
      {
        linkedObj.scale.x = objScaleX.pos;
        linkedObj.updateHitbox();
      }
    }

    objScaleY.onChange = function(_) {
      if (linkedObj != null)
      {
        linkedObj.scale.y = objScaleY.pos;
        linkedObj.updateHitbox();
      }
    }

    objScrollX.onChange = function(_) {
      if (linkedObj != null) linkedObj.scrollFactor.x = objScrollX.pos;
    }

    objScrollY.onChange = function(_) {
      if (linkedObj != null) linkedObj.scrollFactor.y = objScrollY.pos;
    }

    objDance.onChange = function(_) {
      if (linkedObj != null) linkedObj.danceEvery = Std.int(objDance.pos);
    }

    // Boolean callbacks.
    objPixel.onChange = function(_) {
      if (linkedObj != null) linkedObj.antialiasing = objPixel.selected; // Kind of misleading, but objPixel has the 'Antialiasing' label attached to it!
    }

    objFlipX.onChange = function(_) {
      if (linkedObj != null) linkedObj.flipX = objFlipX.selected;
    }

    objFlipY.onChange = function(_) {
      if (linkedObj != null) linkedObj.flipY = objFlipY.selected;
    }

    objBlend.onChange = function(_) {
      if (linkedObj != null)
      {
        linkedObj.blend = (objBlend.selectedItem?.text ?? "NONE") == "NONE" ? null : AssetDataHandler.blendFromString(objBlend.selectedItem.text);
      }
    }

    objTint.onChange = function(_) {
      if (linkedObj != null)
      {
        linkedObj.color = FlxColor.fromString(_.value) ?? 0xFFFFFFFF;
      }
    }

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowObjectProps.selected = false;
  }

  override public function refresh()
  {
    linkedObj = stageEditorState.selectedSprite;

    objPosX.step = stageEditorState.moveStep;
    objPosY.step = stageEditorState.moveStep;
    objAngle.step = funkin.save.Save.instance.stageEditorAngleStep;

    if (linkedObj == null)
    {
      // If there is no selected object, reset displays.
      objPosX.pos = 0;
      objPosY.pos = 0;
      objZIdx.pos = 0;
      objAlpha.pos = 1;
      objAngle.pos = 0;
      objScaleX.pos = 1;
      objScaleY.pos = 1;
      objScrollX.pos = 1;
      objScrollY.pos = 1;
      objDance.pos = 0;

      objPixel.selected = true;
      objFlipX.selected = false;
      objFlipY.selected = false;

      objBlend.selectedIndex = 0;
      objTint.selectedItem = Color.fromString("white");

      return;
    }

    // Otherwise, only update components whose linked object values have been changed.
    if (objPosX.pos != linkedObj.x) objPosX.pos = linkedObj.x;
    if (objPosY.pos != linkedObj.y) objPosY.pos = linkedObj.y;
    if (objZIdx.pos != linkedObj.zIndex) objZIdx.pos = linkedObj.zIndex;
    if (objAlpha.pos != linkedObj.alpha) objAlpha.pos = linkedObj.alpha;
    if (objAngle.pos != linkedObj.angle) objAngle.pos = linkedObj.angle;
    if (objScaleX.pos != linkedObj.scale.x) objScaleX.pos = linkedObj.scale.x;
    if (objScaleY.pos != linkedObj.scale.y) objScaleY.pos = linkedObj.scale.y;
    if (objScrollX.pos != linkedObj.scrollFactor.x) objScrollX.pos = linkedObj.scrollFactor.x;
    if (objScrollY.pos != linkedObj.scrollFactor.y) objScrollY.pos = linkedObj.scrollFactor.y;
    if (objDance.pos != linkedObj.danceEvery) objDance.pos = linkedObj.danceEvery;

    if (objPixel.selected != linkedObj.antialiasing) objPixel.selected = linkedObj.antialiasing;
    if (objFlipX.selected != linkedObj.flipX) objFlipX.selected = linkedObj.flipX;
    if (objFlipY.selected != linkedObj.flipY) objFlipY.selected = linkedObj.flipY;

    var blendMode:String = Std.string(linkedObj.blend) ?? "NONE";
    if (objBlend.selectedItem != blendMode.toUpperCase()) objBlend.selectedItem = blendMode.toUpperCase();

    var objColor:Color = Color.fromComponents(linkedObj.color.red, linkedObj.color.green, linkedObj.color.blue, linkedObj.color.alpha);
    if (objTint.selectedItem != objColor) objTint.selectedItem = objColor;
  }
}

// The following two classes are mostly carbon copies of ColorPickerPopup's handlers, just with an actually functioning onChange callback.
// The code looks like a bit of a mess though.

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
