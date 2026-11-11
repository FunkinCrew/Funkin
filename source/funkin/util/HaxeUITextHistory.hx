package funkin.util;

#if FEATURE_HAXEUI
import haxe.ui.components.TextField;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.focus.FocusManager;

/**
 * Undo and redo for typing in HaxeUI text fields.
 */
class HaxeUITextHistory
{
  /**
   * Typing this soon after the last change is part of the same undo step.
   */
  static inline var GROUP_MS:Float = 750;

  static inline var MAX_STEPS:Int = 100;

  static var field:Null<TextField> = null;
  static var lastText:String = '';
  static var lastChangeTicks:Float = -1;
  static var undoStack:Array<String> = [];
  static var redoStack:Array<String> = [];

  /**
   * Set after an undo or redo, so the field tidying up what was put back is not an edit.
   */
  static var settling:Bool = false;

  /**
   * Call every frame, so changes to the focused field are remembered.
   */
  public static function update():Void
  {
    var focused:Null<TextField> = focusedField();
    if (focused != field)
    {
      field = focused;
      lastText = field?.text ?? '';
      undoStack = [];
      redoStack = [];
      lastChangeTicks = -1;
      settling = false;
      return;
    }
    if (field == null) return;

    var text:String = field.text ?? '';
    if (text == lastText) return;
    if (settling)
    {
      settling = false;
      lastText = text;
      return;
    }

    var now:Float = FlxG.game.ticks;
    if (lastChangeTicks < 0 || now - lastChangeTicks > GROUP_MS)
    {
      undoStack.push(lastText);
      if (undoStack.length > MAX_STEPS) undoStack.shift();
    }
    redoStack = [];
    lastChangeTicks = now;
    lastText = text;
  }

  /**
   * Undoes the last change to the focused text field.
   * @return Whether a text field has the focus, so the key belongs to it.
   */
  public static function undo():Bool
  {
    update();
    // Nothing typed here to take back, so the editor's own undo gets the key instead.
    if (field == null || undoStack.length == 0) return false;
    redoStack.push(lastText);
    restore(undoStack.pop());
    return true;
  }

  /**
   * Redoes the last undone change to the focused text field.
   * @return Whether a text field has the focus, so the key belongs to it.
   */
  public static function redo():Bool
  {
    update();
    if (field == null || redoStack.length == 0) return false;
    undoStack.push(lastText);
    restore(redoStack.pop());
    return true;
  }

  static function restore(text:String):Void
  {
    lastText = text;
    lastChangeTicks = -1;
    settling = true;
    field.text = text;
    field.syncComponentValidation();
    field.caretIndex = text.length;

    field.dispatch(new UIEvent(UIEvent.CHANGE));
  }

  /**
   * Get the focused text field, or the one inside the focused component.
   */
  static function focusedField():Null<TextField>
  {
    var focus:Null<Component> = cast FocusManager.instance.focus;
    if (focus == null) return null;
    var parent:Null<Component> = focus;
    while (parent != null)
    {
      if (parent is haxe.ui.components.NumberStepper) return null;
      parent = parent.parentComponent;
    }
    if (focus is TextField) return cast focus;
    return focus.findComponent(null, TextField);
  }
}
#end
