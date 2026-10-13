package hscriptplus.plus.core;

class InterpResolve {
    public static function resolve(interp:InterpPlus, id:String):Dynamic {
		var value:Dynamic = null;
		
		try {
			value = interp.superResolve(id);
		}
		catch (e:Dynamic) {
			var thisObject = interp.globals.get("this");
			if (thisObject != null)
				value = DynamicFun.getFirstInHierachy(thisObject, id);
		}

		return value;
	}
}