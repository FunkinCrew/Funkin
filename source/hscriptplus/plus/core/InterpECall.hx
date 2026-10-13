package hscriptplus.plus.core;

import hscriptplus.Expr;

@:access(hscriptplus.plus.InterpPlus)
class InterpECall {
    static var interp:InterpPlus;
    static var thisHistory:Array<Dynamic> = [];

    public static function expr(interp:InterpPlus, e:Expr) {
        InterpECall.interp = interp;

        switch (interp.edef(e)) {
            case ECall(e, params):
                var args = new Array();
                for(p in params)
                    args.push(interp.expr(p));

                switch(interp.edef(e)) {
                    case EField(e, f):
                        var obj = interp.expr(e);
                        if(obj == null) interp.error(EInvalidAccess(f));
                        return call(obj, f, args);
                    default:
                        return interp.call(null, interp.expr(e), args);
                }
            default: return null;
        }
    }

    public static function call(object:Dynamic, field:String, args:Array<Dynamic>):Dynamic {
         var objectIsDynamic = DynamicFun.isDynamicObject(object);
        if (objectIsDynamic)
            setThis(object);
        var value = interp.fcall(object, field, args);
        if (objectIsDynamic)
            popThis();
        return value;
    }

    static function setThis(object:Dynamic) {
        var oldObject = interp.globals.get("this");
        if (oldObject != null)
            thisHistory.push(oldObject); 
        interp.globals.set("this", object);
    }

    static function popThis() {
        var oldObject = thisHistory.pop();
        interp.globals.set("this", oldObject);
    }
}