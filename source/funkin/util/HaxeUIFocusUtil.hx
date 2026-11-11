package funkin.util;

/**
 * Whether a HaxeUI component has focus.
 */
class HaxeUIFocusUtil
{
  static var checkedTicks:Float = -1;
  static var focused:Bool = false;

  /**
   * @return Whether a HaxeUI component currently has focus.
   */
  public static function isFocused():Bool
  {
    #if FEATURE_HAXEUI
    var ticks:Float = FlxG.game != null ? FlxG.game.ticks : -2;
    if (ticks != checkedTicks || ticks < 0)
    {
      checkedTicks = ticks;
      focused = haxe.ui.focus.FocusManager.instance?.focus != null;
    }
    return focused;
    #else
    return false;
    #end
  }
}
