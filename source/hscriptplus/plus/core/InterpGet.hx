package hscriptplus.plus.core;

class InterpGet {
    public static function get(interp:InterpPlus, o:Dynamic, f:String):Dynamic {
		var value:Dynamic = null;
		
		if (DynamicFun.isDynamicObject(o))
			value = DynamicFun.getFirstInHierachy(o, f);
		else value = interp.superGet(o, f);

		return value;
	}
}