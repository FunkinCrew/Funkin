package funkin.ui.haxeui.components;

import haxe.ui.components.Button;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.events.MouseEvent;
import haxe.ui.util.Variant;

@:composite(IconButtonBuilder)
class IconButton extends Button
{
  public function new()
  {
    super();
    allowFocus = false;
    customStyle.padding = 0;
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
      var icon = _btn.findComponent("button-icon");
      if (icon != null) {
        icon.customStyle.marginTop = 1;
        _btn.invalidateComponentLayout();
      }
    });
    _btn.registerEvent(MouseEvent.MOUSE_UP, (_:MouseEvent) -> {
      var icon = _btn.findComponent("button-icon");
      if (icon != null) {
        icon.customStyle.marginTop = 0;
        _btn.invalidateComponentLayout();
      }
    });
    _btn.registerEvent(MouseEvent.MOUSE_OUT, (_:MouseEvent) -> {
      var icon = _btn.findComponent("button-icon");
      if (icon != null) {
        icon.customStyle.marginTop = 0;
        _btn.invalidateComponentLayout();
      }
    });
  }
}
