package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using StringTools;

class RegistryMacro
{
  public static macro function build():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();
    var clsName = cls.pack.join('.') + '.' + cls.name;

    var typeParams = getTypeParams(cls);

    var entryCls = typeParams[0];
    var entryClsName = entryCls.pack.join('.') + '.' + entryCls.name;

    var jsonCls = typeParams[1];
    var jsonClsName = jsonCls.pack.join('.') + '.' + jsonCls.name;

    trace('ENTRY', entryClsName);
    trace('JSON', jsonClsName);

    return fields;
  }

  #if macro
  static function getTypeParams(cls:ClassType):Array<ClassType>
  {
    switch (cls.superClass.t.get().kind)
    {
      case KGenericInstance(t, params):
        var typeParams = [];
        for (param in params)
        {
          switch (param)
          {
            case TInst(t, _params):
              typeParams.push(t.get());
            default:
              throw 'Not a class';
          }
        }
        return typeParams;
      default:
        throw 'Not in the correct format';
    }
    return [];
  }
  #end
}
