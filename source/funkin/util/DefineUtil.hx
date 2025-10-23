package funkin.util;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

/**
 * A collection of utility functions for Haxe macros.
 */
@:nullSafety
class DefineUtil
{
  /**
   * Returns the defined values
   */
  public static var defines(get, never):Map<String, String>;

  // Manually, without macro for scripts.
  public static function isDefined(define:String):Bool
    return defines.exists(define);

  static inline function get_defines():Map<String, String>
  {
    return __getDefines();
  }

  static macro function __getDefines():Expr
  {
    #if display
    return macro $v{[]};
    #else
    return macro $v{haxe.macro.Context.getDefines()};
    #end
  }
}
