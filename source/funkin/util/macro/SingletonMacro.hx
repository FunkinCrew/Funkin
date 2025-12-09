package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Type.ClassType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.ComplexType;

using haxe.macro.Tools;

/**
 * A macro which automatically creates a Singleton `instance` property for a class.
 * Add `implements funkin.util.tools.ISingleton` to your class to use.
 */
class SingletonMacro
{
  /**
   * Applies an `instance` static field to the target class.
   * @return The modified list of fields for the target class.
   */
  public static macro function build():Array<Field>
  {
    var cls:ClassType = Context.getLocalClass().get();

    var fields:Array<Field> = Context.getBuildFields();

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
