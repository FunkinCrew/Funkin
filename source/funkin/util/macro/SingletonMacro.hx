package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;

class SingletonMacro
{
  public static macro function build():Array<Field>
  {
    var cls = Context.getLocalClass().get();

    var fields = Context.getBuildFields();

    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();
    var newExpr:String = 'new ${cls.module}.${cls.name}()';

    fields = fields.concat((macro class TempClass
      {
        static var _instance:Null<$clsType>;
        public static var instance(get, never):$clsType;

        static function get_instance():$clsType
        {
          if (_instance == null)
          {
            _instance = ${Context.parse(newExpr, Context.currentPos())};
          }
          return _instance;
        }
      }).fields);

    return fields;
  }
}
