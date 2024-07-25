package funkin.ui.modmenu.components;

import haxe.ui.containers.VBox;
import haxe.ui.components.Label;
import haxe.ui.extensions.Draggable;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.Events;
import haxe.ui.events.DragEvent;

/**
 * HaxeUI component for the mod menu
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/components/mod.xml"))
@:composite(ModBoxEvents)
class ModBox extends VBox implements Draggable
{
  var isDragging:Bool;

  var modLabel:Label;
  var modDescription:String;

  public function new(name:String, desc:String)
  {
    super();

    // this.draggable = true;
    // TODO: Implement dragging, since that would be nicer
    // but for now im just gonna do it in a simple way
    // when we implement dragging we should probably remove the click event
    this.draggable = false;

    this.modLabel.value = name;
    this.modDescription = desc;

    this.isDragging = false;
  }
}

/**
 * Composite class for handling mouse events
 */
@:access(funkin.ui.modmenu.components.ModBox)
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
    if (!hasEvent(DragEvent.DRAG_START, onDragStart))
    {
      registerEvent(DragEvent.DRAG_START, onDragStart);
    }
    if (!hasEvent(DragEvent.DRAG_END, onDragEnd))
    {
      registerEvent(DragEvent.DRAG_END, onDragEnd);
    }
  }

  public override function unregister():Void
  {
    unregisterEvent(MouseEvent.MOUSE_OVER, onMouseOver);
    unregisterEvent(MouseEvent.MOUSE_OUT, onMouseOut);
    unregisterEvent(MouseEvent.CLICK, onClick);
    unregisterEvent(DragEvent.DRAG_START, onDragStart);
    unregisterEvent(DragEvent.DRAG_END, onDragEnd);
  }

  function onMouseOver(event:MouseEvent):Void
  {
    if (_modBox.isDragging)
    {
      return;
    }

    _modBox.addClass(":hover", true, true);
  }

  function onMouseOut(event:MouseEvent):Void
  {
    _modBox.removeClass(":hover", true, true);
    _modBox.removeClass(":down", true, true);
  }

  function onClick(event:MouseEvent):Void
  {
    _modBox.removeClass(":hover", true, true);
    _modBox.removeClass(":down", true, true);
  }

  function onDragStart(event:DragEvent):Void
  {
    _modBox.removeClass(":hover", true, true);
    _modBox.addClass(":down", true, true);
    _modBox.isDragging = true;
  }

  function onDragEnd(event:DragEvent):Void
  {
    _modBox.removeClass(":down", true, true);
    _modBox.addClass(":hover", true, true);
    _modBox.isDragging = false;
  }
}
