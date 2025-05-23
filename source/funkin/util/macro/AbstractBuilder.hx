// this will actually be put inside the shipped haxe compiler
package funkin.util.macro.AbstractBuilder;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
using StringTools;

#if macro
class AbstractBuilder 
{
    public static function build():Array<Field> 
    {
        var fields = Context.getBuildFields();

        var clazzRef = Context.getLocalClass();
        if (clazzRef == null) return fields;

        if (clazzRef.toString() != 'flixel.util._FlxColor.FlxColor_Impl_') return fields;

        var clazz = clazzRef.get();

        var abstractSplit = clazzRef.toString().split('.')
        abstractSplit.pop();
        abstractSplit[abstractSplit.length - 1].substr(1);
        var abstractPath = abstractSplit.join('.');
        var abstractType = switch (Context.getType(abstractPath)) 
        {
            case TAbstract(a, params):
                a.get();
            default:
                throw 'Should not happen';
        };

        var underlyingComplexType = abstractType.type.toComplexType();

        for (field in fields) 
        {
            if (!field.access.contains(AStatic)) continue;

            switch (field.kind) 
            {
                case FFun(fun):
                    fun.args.insert(0, {
                        name: 'this',
                        type: underlyingComplexType
                    });
                default:
            }
        }

        return fields;
    }
}
#else
class AbstractBuilder {}
#end
