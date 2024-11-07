package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;

class EntryMacro
{
  public static macro function build(registry:ExprOf<Class<Dynamic>>, ...additionalReferencedRegistries:ExprOf<Class<Dynamic>>):Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var entryData = getEntryData(cls);

    makeFieldsCallable(additionalReferencedRegistries.append(registry));

    fields = fields.concat(buildVariables(cls, entryData));
    fields = fields.concat(buildMethods(cls, registry));

    return fields;
  }

  #if macro
  static function makeFieldsCallable(registries:Array<ExprOf<Class<Dynamic>>>)
  {
    for (registry in registries)
    {
      MacroUtil.getClassTypeFromExpr(registry);
    }
  }

  static function fieldAlreadyExists(name:String):Bool
  {
    for (field in Context.getBuildFields())
    {
      if (field.name == name)
      {
        return true;
      }
    }

    function fieldAlreadyExistsSuper(name:String, superClass:Null<ClassType>)
    {
      if (superClass == null)
      {
        return false;
      }

      for (field in superClass.fields.get())
      {
        if (field.name == name)
        {
          return true;
        }
      }

      // recursively check superclasses
      return fieldAlreadyExistsSuper(name, superClass.superClass?.t.get());
    }

    return fieldAlreadyExistsSuper(name, Context.getLocalClass().get().superClass?.t.get());
  }

  static function getEntryData(cls:ClassType):Dynamic // DefType or ClassType
  {
    switch (cls.interfaces[0].params[0])
    {
      case Type.TInst(t, _):
        return t.get();
      case Type.TType(t, _):
        return t.get();
      default:
        throw 'Entry Data is not a class or typedef';
    }
  }

  static function buildVariables(cls:ClassType, entryData:Dynamic):Array<Field>
  {
    var entryDataType:ComplexType = Context.getType('${entryData.module}.${entryData.name}').toComplexType();

    return (macro class TempClass
      {
        public final id:String;

        public final _data:Null<$entryDataType>;
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }

  static function buildMethods(cls:ClassType, registry:ExprOf<Class<Dynamic>>):Array<Field>
  {
    return (macro class TempClass
      {
        public function _fetchData(id:String)
        {
          return ${registry}.instance.parseEntryDataWithMigration(id, ${registry}.instance.fetchEntryVersion(id));
        }

        public function toString()
        {
          return $v{cls.name} + '(' + id + ')';
        }

        public function destroy() {}
      }).fields.filter((field) -> !fieldAlreadyExists(field.name));
  }
  #end
}
