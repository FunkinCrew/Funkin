package funkin.util.macro;

class MacroUtil
{
	public static macro function getDefine(key:String, defaultValue:String = null):haxe.macro.Expr
	{
		var value = haxe.macro.Context.definedValue(key);
		if (value == null)
			value = defaultValue;
		return macro $v{value};
	}
}
