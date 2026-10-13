package hscriptplus.plus.core;

import hscriptplus.Expr;

class ClassImporter {
	public static inline var PATH_PLACEHOLDER = "$PATH";
	public static inline var ERROR_MESSAGE = 'hscriptplus.plus.core.ClassImporter: $PATH_PLACEHOLDER not found';

	var globals:Map<String, Dynamic>;
    var resolveDynamicClass:String->Dynamic = name -> null;

	var path:String;
	var classType:Dynamic;

    public function new(interp:InterpPlus) {
		globals = interp.variables;
    }

	public function setResolveImportFunction(func:String->Dynamic) {
		resolveDynamicClass = func;
	}

    public function importFromExpr(expr:Expr) {
    	extractClassPathFromExpr(expr);
        if (classPathExtractedSuccessfully())
            importClass();
    }

    function extractClassPathFromExpr(expr:Expr) {
        switch (ExprHelper.getExprDef(expr)) {
            case EImport(path):
                this.path = path;
            default:
				this.path = "";
        }
    }

    inline function classPathExtractedSuccessfully() {
        return path != "";
    }

    function importClass() {
		tryResolveClassType();
		throwErrorIfCannotResolve();
		addClassToGlobalsIfSuccessful();
	}

	function tryResolveClassType() {
		if (DynamicFun.isHaxeClassName(path))
			classType = resolveHaxeClass(path)
		else classType = resolveDynamicClass(path);
	}

	function resolveHaxeClass(classNameOrPath:String) {
		return Type.resolveClass(classNameOrPath);
	}

	function throwErrorIfCannotResolve() {
		if (cannotResolveClassType())
			throw formatErrorMessage(path);
	}

	function cannotResolveClassType() {
		return classType == null;
	}

	function formatErrorMessage(invalidPath:String) {
		return StringTools.replace(ERROR_MESSAGE, PATH_PLACEHOLDER, invalidPath);
	}

	function addClassToGlobalsIfSuccessful() {
		var className = getClassNameFromPath();
		globals.set(className, classType);
	}

	function getClassNameFromPath() {
		return path.split(".").pop();
	}
}