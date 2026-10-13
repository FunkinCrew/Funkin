package hscriptplus.plus.core;

import hscriptplus.Expr;

class InterpEClass {
	static var interp:InterpPlus;
	static var globals:Map<String, Dynamic>;

	static var name:String;
	static var eclass:Expr;
	static var superClassName:String;
	static var classObject:Dynamic;

    public static function expr(interp:InterpPlus, expr:Expr):Dynamic {
		InterpEClass.interp = interp;
		globals = interp.variables;

        return createClassIfIsEClass(expr);
    }

	static function createClassIfIsEClass(expr:Expr) {
		switch (ExprHelper.getExprDef(expr)) {
			case EClass(name, e, superClassName):
				referenceProperties(name, e, superClassName);
				return createClass();
			default:
				return null;
		}
	}

	static function referenceProperties(n:String, e:Expr, s:String) {
		name = n;
		eclass = e;
		superClassName = s;
	}

	static function createClass() {
		createClassObject();
		addFieldsToClassObjectFromParsingBlock();
		addClassObjectToGlobals();
		return classObject;
	}

	static function createClassObject() {
		var superClass = getSuperClassFromGlobals();
		classObject = DynamicFun.create(interp, name, superClass);
	}

	static function getSuperClassFromGlobals() {
		return superClassName == null ? null : globals.get(superClassName);
	}

	static function addFieldsToClassObjectFromParsingBlock() {
		switch (ExprHelper.getExprDef(eclass)) {
			case EBlock(exprList):
				for (e in exprList)
					addVarsAndFunctions(classObject, e);
			default:
		}
	}

	static function addClassObjectToGlobals() {
		globals.set(name, classObject);
	}

	static function addVarsAndFunctions(classType:Dynamic, e:Expr) {
		switch (ExprHelper.getExprDef(e)) {
			case EFunction(args, _, name, _, access):
				setClassField(classType, name, e, access);
			case EVar(name, _, e, access):
				setClassField(classType, name, e, access);
			default:
		}
	}

	static function setClassField(object:Dynamic, name:String, e:Expr, access:Array<Access>) {
		var field = interp.superExpr(e);
		Reflect.setField(object, name, field);
	}
}