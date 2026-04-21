package funkin.ui.haxeui.components;

import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.util.Variant;

@:composite(IconButtonBuilder)
class IconButton extends Button
{
  /** Icon shown when `toggle = true` and the button is selected; falls back to `icon` if null. **/
  @:clonable @:behaviour(ApplyIconBehaviour)
  public var selectedIcon:Variant;

  public function new()
  {
    super();
    allowFocus = false;
    customStyle.padding = 0;
    behaviours.register("icon", ApplyIconBehaviour);
  }
}

@:dox(hide) @:noCompletion
private class ApplyIconBehaviour extends DataBehaviour
{
  override function validateData():Void
  {
    IconButtonBuilder.applyIcon(cast _component);
  }
}

@:dox(hide) @:noCompletion
private class IconButtonBuilder extends CompositeBuilder
{
  var _btn:IconButton;

  public function new(btn:IconButton)
  {
    super(btn);
    _btn = btn;
  }

  override public function create():Void
  {
    _btn.registerEvent(MouseEvent.MOUSE_DOWN, (_:MouseEvent) -> {
      var icon:Image = cast _btn.findComponent("button-icon");
      if (icon != null)
      {
        icon.customStyle.marginTop = 1;
        _btn.invalidateComponentLayout();
      }
    });
    _btn.registerEvent(MouseEvent.MOUSE_UP, (_:MouseEvent) -> {
      var icon:Image = cast _btn.findComponent("button-icon");
      if (icon != null)
      {
        icon.customStyle.marginTop = 0;
        _btn.invalidateComponentLayout();
      }
    });
    _btn.registerEvent(MouseEvent.MOUSE_OUT, (_:MouseEvent) -> {
      var icon:Image = cast _btn.findComponent("button-icon");
      if (icon != null)
      {
        icon.customStyle.marginTop = 0;
        _btn.invalidateComponentLayout();
      }
    });

    _btn.registerEvent(UIEvent.CHANGE, (_:UIEvent) -> IconButtonBuilder.applyIcon(_btn));
  }

  public static function applyIcon(btn:IconButton):Void
  {
    var useSelected:Bool = btn.toggle && btn.selected && btn.selectedIcon != null && !btn.selectedIcon.isNull;
    var target:Variant = useSelected ? btn.selectedIcon : btn.icon;
    var hasTarget:Bool = target != null && !target.isNull && target.toString() != "";

    var iconCmp:Image = cast btn.findComponent("button-icon", false);

    if (!hasTarget)
    {
      if (iconCmp != null)
      {
        btn.customStyle.icon = null;
        btn.removeClass("has-icon", false);
        btn.removeComponent(iconCmp);
      }
      return;
    }

    if (iconCmp == null)
    {
      iconCmp = new Image();
      iconCmp.addClass("icon");
      if (btn.hasClass(":hover")) iconCmp.addClass(":hover");
      if (btn.hasClass(":down")) iconCmp.addClass(":down");
      iconCmp.id = "button-icon";
      btn.addClass("has-icon", false);
      btn.addComponentAt(iconCmp, 0);
      btn.invalidateComponentStyle(true);
    }

    iconCmp.resource = target;
  }
}
