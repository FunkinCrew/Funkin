package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;

class RegistryMacro
{
  public static macro function buildRegistry():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    if (!cls.name.endsWith('Registry'))
    {
      throw '${cls.module}.${cls.name} needs to end with "Registry"';
    }

    var typeParams = getTypeParams(cls);
    var entryCls = typeParams.entryCls;
    var jsonCls = typeParams.jsonCls;
    var scriptedEntryCls = getScriptedEntryClass(entryCls);

    fields = fields.concat(buildRegistryVariables(cls));
    fields = fields.concat(buildRegistryMethods(cls));

    buildEntryImpl(entryCls, cls);
    buildRegistryImpl(cls, entryCls, scriptedEntryCls, jsonCls);

    return fields;
  }

  public static macro function buildEntry():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    var entryData = getEntryData(cls);

    // since the registries also use a build macro
    // the fields aren't callable unless we first get
    // the class type of the registry
    makeFieldsCallable(cls);

    fields = fields.concat(buildEntryVariables(cls, entryData));
    fields = fields.concat(buildEntryMethods(cls));

    return fields;
  }

  #if macro
  static function makeFieldsCallable(cls:ClassType)
  {
    // TODO: lets not have this if statement
    // like what the hell is wrong with this
    if (cls.name == 'Song')
    {
      MacroUtil.getClassTypeFromExpr(macro funkin.data.song.SongRegistry);
      return;
    }

    var registries:Array<String> = [];
    for (localImport in Context.getLocalImports())
    {
      var names = [];
      for (path in localImport.path)
      {
        names.push(path.name);
      }
      var fullName = names.join('.');

      if (fullName.endsWith('Registry'))
      {
        registries.push(fullName);
      }
    }

    for (registry in registries)
    {
      MacroUtil.getClassTypeFromExpr(Context.parse(registry, Context.currentPos()));
    }
  }

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

  static function buildRegistryImpl(cls:ClassType, entryCls:ClassType, scriptedEntryCls:ClassType, jsonCls:Dynamic):Void
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    var getScriptedClassName:String = '${scriptedEntryCls.module}.${scriptedEntryCls.name}';

    var createScriptedEntry:String = '${scriptedEntryCls.module}.${scriptedEntryCls.name}.init(clsName, "unknown")';

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
