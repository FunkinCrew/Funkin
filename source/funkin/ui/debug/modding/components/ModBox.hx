package funkin.ui.debug.modding.components;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.Events;

/**
 * HaxeUI component for the mod menu
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/components/modbox.xml"))
@:composite(ModBoxEvents)
class ModBox extends VBox
{
  var modLabel:Label;

  public var modId(default, null):String;
  public var modName(default, null):String;
  public var modDescription(default, null):String;

  public function new(modId:String, modName:String, modDescription:String)
  {
    super();

    this.modLabel.value = modName;
    this.modLabel.tooltip = modDescription;

    this.modId = modId;
    this.modName = modName;
    this.modDescription = modDescription;
  }
}

/**
 * Composite class for handling mouse events
 */
class ModBoxEvents extends Events
{
  var _modBox:ModBox;

  public function new(modbox:ModBox)
  {
    super(modbox);
    _modBox = modbox;
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
    if (!hasEvent(MouseEvent.CLICK, onClick))
    {
      registerEvent(MouseEvent.CLICK, onClick);
    }
  }

  public override function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_OVER, onMouseOver);
    unregisterEvent(MouseEvent.MOUSE_OUT, onMouseOut);
    unregisterEvent(MouseEvent.CLICK, onClick);
  }

  function onMouseOver(event:MouseEvent):Void
  {
    _modBox.addClass(":hover", true, true);
  }

  function onMouseOut(event:MouseEvent):Void
  {
    _modBox.removeClass(":hover", true, true);
  }

  function onClick(event:MouseEvent):Void
  {
    _modBox.removeClass(":hover", true, true);
  }
}
