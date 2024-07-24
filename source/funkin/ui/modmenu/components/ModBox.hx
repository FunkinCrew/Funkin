package funkin.ui.modmenu.components;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.extensions.Draggable;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.Events;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/components/mod.xml"))
@:composite(ModBoxEvents)
class ModBox extends VBox implements Draggable
{
  var modLabel:Label;
  var modDescription:String;

  public function new(name:String, desc:String)
  {
    super();

    this.draggable = true;

    this.modLabel.value = name;
    this.modDescription = desc;
  }
}

class ModBoxEvents extends Events
{
  var _vbox:VBox;

  public function new(vbox:VBox)
  {
    super(vbox);
    _vbox = vbox;
  }

  public override function register():Void
  {
    if (!hasEvent(MouseEvent.MOUSE_OVER, onMouseOver))
    {
      registerEvent(MouseEvent.MOUSE_OVER, onMouseOver);
    }
    if (!hasEvent(MouseEvent.MOUSE_OUT, onMouseOut))
    {
      registerEvent(MouseEvent.MOUSE_OUT, onMouseOut);
    }
  }

  public override function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_OVER, onMouseOver);
    unregisterEvent(MouseEvent.MOUSE_OUT, onMouseOut);
  }

  function onMouseOver(event:MouseEvent):Void
  {
    _vbox.addClass(":hover", true, true);
  }

  function onMouseOut(event:MouseEvent):Void
  {
    _vbox.removeClass(":hover", true, true);
  }
}
