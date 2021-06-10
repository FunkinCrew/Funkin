package;

class Macros
{
  public static macro function getFlag(flag:String) : haxe.macro.Expr {
		if (haxe.macro.Context.defined(flag)) {
			return macro $v{haxe.macro.Context.definedValue(flag)};
		} else {
			return macro $v{""};
		}
	}
}