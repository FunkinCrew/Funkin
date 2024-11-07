package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;

class RegistryMacro
{
  public static macro function build():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var typeParams = getTypeParams(cls);
    var entryCls = typeParams.entryCls;
    var jsonCls = typeParams.jsonCls;
    var scriptedEntryCls = getScriptedEntryClass(entryCls);

    fields = fields.concat(buildVariables(cls));
    fields = fields.concat(buildMethods(cls, entryCls, scriptedEntryCls, jsonCls));

    return fields;
  }

  #if macro
  static function fieldAlreadyExists(name:String):Bool
  {
    for (field in Context.getBuildFields())
    {
      if (field.name == name && !((field.access ?? []).contains(Access.AAbstract)))
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
        if (field.name == name && !field.isAbstract)
        {
          return true;
        }
      }

      // recursively check superclasses
      return fieldAlreadyExistsSuper(name, superClass.superClass?.t.get());
    }

    return fieldAlreadyExistsSuper(name, Context.getLocalClass().get().superClass?.t.get());
  }

  static function getTypeParams(cls:ClassType):RegistryTypeParams
  {
    switch (cls.superClass.t.get().kind)
    {
      case KGenericInstance(_, params):
        var typeParams:Array<Dynamic> = [];
        for (param in params)
        {
          switch (param)
          {
            case TInst(t, _):
              typeParams.push(t.get());
            case TType(t, _):
              typeParams.push(t.get());
            default:
              throw 'Not a class';
          }
        }
        return {entryCls: typeParams[0], jsonCls: typeParams[1]};
      default:
        throw 'Not in the correct format';
    }
  }

  static function getScriptedEntryClass(entryCls:ClassType):ClassType
  {
    var scriptedEntryClsName = entryCls.pack.join('.') + '.Scripted' + entryCls.name;
    switch (Context.getType(scriptedEntryClsName))
    {
      case Type.TInst(t, _):
        return t.get();
      default:
        throw 'Not A Class (${scriptedEntryClsName})';
    };
  }

  static function buildVariables(cls:ClassType):Array<Field>
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    var newInstanceExpr:String = 'new ${cls.module}.${cls.name}()';

    return (macro class TempClass
      {
        static var _instance:Null<$clsType>;
        public static var instance(get, never):$clsType;

        static function get_instance():$clsType
        {
          if (_instance == null)
          {
            _instance = ${Context.parse(newInstanceExpr, Context.currentPos())};
          }
          return _instance;
        }
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }

  static function buildMethods(cls:ClassType, entryCls:ClassType, scriptedEntryCls:ClassType, jsonCls:Dynamic):Array<Field>
  {
    var getScriptedClassNameExpr:String = '${scriptedEntryCls.module}.${scriptedEntryCls.name}';

    var createScriptedEntryExpr = '${scriptedEntryCls.module}.${scriptedEntryCls.name}.init(clsName, \'unknown\')';

    var jsonParserNewExpr = 'new json2object.JsonParser<${jsonCls.module}.${jsonCls.name}>()';

    return (macro class TempClass
      {
        function getScriptedClassNames()
        {
          return ${Context.parse(getScriptedClassNameExpr, Context.currentPos())}.listScriptClasses();
        }

        function createScriptedEntry(clsName:String)
        {
          return ${Context.parse(createScriptedEntryExpr, Context.currentPos())};
        }

        public function parseEntryData(id:String)
        {
          var parser = ${Context.parse(jsonParserNewExpr, Context.currentPos())};
          parser.ignoreUnknownVariables = false;

          switch (loadEntryFile(id))
          {
            case {fileName: fileName, contents: contents}:
              parser.fromJson(contents, fileName);
            default:
              return null;
          }

          if (parser.errors.length > 0)
          {
            printErrors(parser.errors, id);
            return null;
          }
          return parser.value;
        }

        public function parseEntryDataRaw(contents:String, ?fileName:String)
        {
          var parser = ${Context.parse(jsonParserNewExpr, Context.currentPos())};
          parser.ignoreUnknownVariables = false;
          parser.fromJson(contents, fileName);

          if (parser.errors.length > 0)
          {
            printErrors(parser.errors, fileName);
            return null;
          }
          return parser.value;
        }
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }
  #end
}

#if macro
typedef RegistryTypeParams =
{
  var entryCls:ClassType;
  var jsonCls:Dynamic; // DefType or ClassType
}
#end
