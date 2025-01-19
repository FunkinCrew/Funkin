package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using Lambda;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;

class RegistryMacro
{
  public static macro function buildRegistry():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var baseMeta = cls.meta.get().find(function(m) return m.name == ':funkinBase');
    if (baseMeta != null || alreadyProcessed(cls))
    {
      return fields;
    }

    var typeParams = getTypeParams(cls);
    var entryCls = typeParams.entryCls;
    var jsonCls = typeParams.jsonCls;

    buildEntryImpl(entryCls, cls);
    buildRegistryImpl(cls, entryCls, jsonCls);

    fields = fields.concat(buildRegistryVariables(cls));
    fields = fields.concat(buildRegistryMethods(cls));

    cls.meta.add(":funkinProcessed", [], cls.pos);

    return fields;
  }

  public static macro function buildEntry():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var baseMeta = cls.meta.get().find(function(m) return m.name == ':funkinBase');
    if (baseMeta != null || alreadyProcessed(cls))
    {
      return fields;
    }

    var entryData = getEntryData(cls);

    fields = fields.concat(buildEntryVariables(cls, entryData));
    fields = fields.concat(buildEntryMethods(cls));

    cls.meta.add(":funkinProcessed", [], cls.pos);

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

  static function alreadyProcessed(cls:ClassType):Bool
  {
    var processedMeta = cls.meta.get().find(function(m) return m.name == ':funkinProcessed');

    if (processedMeta != null)
    {
      return true;
    }

    if (cls.superClass != null)
    {
      return alreadyProcessed(cls.superClass.t.get());
    }

    return false;
  }

  static function getTypeParams(cls:ClassType):RegistryTypeParamsNew
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

  static function getEntryData(cls:ClassType):Dynamic // DefType or ClassType
  {
    try
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
    catch (e)
    {
      throw '
        ${cls.name}:
        Make sure IRegistryEntry is the last implement
        class ExampleEntry implements ... implements IRegistryEntry
      ';
    }
  }

  static function buildRegistryVariables(cls:ClassType):Array<Field>
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    var newInstance:String = 'new ${cls.module}.${cls.name}()';

    return (macro class TempClass
      {
        static var _instance:Null<$clsType>;
        public static var instance(get, never):$clsType;

        static function get_instance():$clsType
        {
          if (_instance == null)
          {
            _instance = ${Context.parse(newInstance, Context.currentPos())};
          }
          return _instance;
        }
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }

  static function buildRegistryMethods(cls:ClassType):Array<Field>
  {
    var impl:String = 'funkin.macro.impl._${cls.name}_Impl';

    return (macro class TempClass
      {
        function getScriptedClassNames()
        {
          return ${Context.parse(impl, Context.currentPos())}.getScriptedClassNames(this);
        }

        function createScriptedEntry(clsName:String)
        {
          return ${Context.parse(impl, Context.currentPos())}.createScriptedEntry(this, clsName);
        }

        public function parseEntryData(id:String)
        {
          return ${Context.parse(impl, Context.currentPos())}.parseEntryData(this, id);
        }

        public function parseEntryDataRaw(contents:String, ?fileName:String)
        {
          return ${Context.parse(impl, Context.currentPos())}.parseEntryDataRaw(this, contents, fileName);
        }
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }

  static function buildEntryVariables(cls:ClassType, entryData:Dynamic):Array<Field>
  {
    var entryDataType:ComplexType = Context.getType('${entryData.module}.${entryData.name}').toComplexType();

    return (macro class TempClass
      {
        public final id:String;

        public final _data:Null<$entryDataType>;
      }).fields.filter((field) -> return !fieldAlreadyExists(field.name));
  }

  static function buildEntryMethods(cls:ClassType):Array<Field>
  {
    var impl:String = 'funkin.macro.impl._${cls.name}_Impl';

    return (macro class TempClass
      {
        public function _fetchData(id:String)
        {
          return ${Context.parse(impl, Context.currentPos())}._fetchData(this, id);
        }

        public function toString()
        {
          return ${Context.parse(impl, Context.currentPos())}.toString(this);
        }

        public function destroy()
        {
          ${Context.parse(impl, Context.currentPos())}.destroy(this);
        }
      }).fields.filter((field) -> !fieldAlreadyExists(field.name));
  }

  static function buildRegistryImpl(cls:ClassType, entryCls:ClassType, jsonCls:Dynamic):Void
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    var scriptedEntryClsName:String = entryCls.pack.join('.') + '.Scripted' + entryCls.name;

    var getScriptedClassName:String = '${scriptedEntryClsName}';

    var createScriptedEntry:String = '${scriptedEntryClsName}.init(clsName, "unknown")';

    var newJsonParser:String = 'new json2object.JsonParser<${jsonCls.module}.${jsonCls.name}>()';

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['funkin', 'macro', 'impl'],
        name: '_${cls.name}_Impl',
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: (macro class TempClass
          {
            public static inline function getScriptedClassNames(me:$clsType)
            {
              return ${Context.parse(getScriptedClassName, Context.currentPos())}.listScriptClasses();
            }

            public static inline function createScriptedEntry(me:$clsType, clsName:String)
            {
              return ${Context.parse(createScriptedEntry, Context.currentPos())};
            }

            public static inline function parseEntryData(me:$clsType, id:String)
            {
              var parser = ${Context.parse(newJsonParser, Context.currentPos())};
              parser.ignoreUnknownVariables = false;

              @:privateAccess
              switch (me.loadEntryFile(id))
              {
                case {fileName: fileName, contents: contents}:
                  parser.fromJson(contents, fileName);
                default:
                  return null;
              }

              if (parser.errors.length > 0)
              {
                @:privateAccess
                me.printErrors(parser.errors, id);
                return null;
              }
              return parser.value;
            }

            public static inline function parseEntryDataRaw(me:$clsType, contents:String, ?fileName:String)
            {
              var parser = ${Context.parse(newJsonParser, Context.currentPos())};
              parser.ignoreUnknownVariables = false;
              parser.fromJson(contents, fileName);

              if (parser.errors.length > 0)
              {
                @:privateAccess
                me.printErrors(parser.errors, fileName);
                return null;
              }
              return parser.value;
            }
          }).fields
      });
  }

  static function buildEntryImpl(cls:ClassType, registryCls:ClassType):Void
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    var registry:String = '${registryCls.module}.${registryCls.name}';

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: ['funkin', 'macro', 'impl'],
        name: '_${cls.name}_Impl',
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: (macro class TempClass
          {
            public static inline function _fetchData(me:$clsType, id:String)
            {
              return $
              {
                Context.parse(registry, Context.currentPos())
              }.instance.parseEntryDataWithMigration(id, ${Context.parse(registry, Context.currentPos())}.instance.fetchEntryVersion(id));
            }

            public static inline function toString(me:$clsType)
            {
              return $v{cls.name} + '(' + me.id + ')';
            }

            public static inline function destroy(me:$clsType) {}
          }).fields
      });
  }
  #end
}

#if macro
typedef RegistryTypeParamsNew =
{
  var entryCls:ClassType;
  var jsonCls:Dynamic; // DefType or ClassType
}
#end
