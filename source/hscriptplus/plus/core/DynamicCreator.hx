package hscriptplus.plus.core;

class DynamicCreator {
    static var interp:InterpPlus;
    static var object:Dynamic;

    public static function create(interp:InterpPlus, ?name:String = "", ?superObject:Dynamic, ?body:Dynamic, ?args:Array<Dynamic>):Dynamic {
        DynamicCreator.interp = interp;
        createNewObject(name, superObject);
        copyConstructorIfNotExists();
        copyBody(body);
        callConstructor(args);

        return object;
    }

    static function createNewObject(name:String, superObject:Dynamic) {
        object = { __sname__:name, super:superObject };
    }

    static function copyConstructorIfNotExists() {
        if (constructor(object) == null && object.super != null)
            Reflect.setField(object, "new", constructor(object.super));
    }

    static function constructor(object:Dynamic) {
        return Reflect.field(object, "new");
    }

    static function copyBody(body:Dynamic) {
        if (body == null) return;

        for (fieldName in Reflect.fields(body))
			Reflect.setField(object, fieldName, Reflect.field(body, fieldName));
    }

    static function callConstructor(args:Array<Dynamic>) {
        if (args == null)
            args = [];
        
        var constructor:Dynamic = Reflect.field(object, "new");
        if (constructor != null) {
            var oldThis = interp.globals.get("this");
            interp.globals.set("this", object);
            Reflect.callMethod(object, constructor, args);
            interp.globals.set("this", oldThis);
        }
    }
}