package hscriptplus.plus.core;

class DynamicFun {
	public static var create(default, null) = DynamicCreator.create;

	public static function getFirstInHierachy(object:Dynamic, fieldName:String) {
		var value = Reflect.field(object, fieldName);
		var objectSuper = object.super;

		var fieldNotFound = value == null;
		var objectHasSuper = objectSuper != null;

		if (fieldNotFound && objectHasSuper)
			return getFirstInHierachy(objectSuper, fieldName);
		return value;
	}

	public static inline function isHaxeClassName(className:String) {
		return Type.resolveClass(className) != null;
	}

	public static inline function isDynamicObject(object:Dynamic) {
		return object != null && Reflect.hasField(object, "super");
	}
}