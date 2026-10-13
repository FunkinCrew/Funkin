package hscriptplus.plus.core;

class InterpCnew {
	static var interp:InterpPlus;

    public static function cnew(interp:InterpPlus, className:String, args:Array<Dynamic>):Dynamic {
		InterpCnew.interp = interp;
        return createNewClass(className, args);
	}

    static function createNewClass(className:String, args:Array<Dynamic>):Dynamic {
		if (DynamicFun.isHaxeClassName(className))
			return interp.superCnew(className, args);
		else return createDynamicClass(className, args);
	}

	static function createDynamicClass(className:String, args:Array<Dynamic>) {
		var dynamicClass = interp.superResolve(className);
		return DynamicFun.create(interp, "", dynamicClass, null, args);
	}
}