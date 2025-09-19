package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.TypeDefKind;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Type;
import haxe.macro.Type.ClassType;
#if macro
import sys.FileSystem;
#end

using haxe.macro.Tools;
using Lambda;
using StringTools;

/**
 * A set of build macros to be applied to `Registry` classes in the `funkin.data` package.
 *
 * @see `funkin.data.BaseRegistry`
 */
class RegistryMacro
{
  static final DATA_FILE_BASE_PATH:String = 'assets/preload/data';

  /**
   * Builds the registry class.
   *
   * @return The modified list of fields for the target class.
   */
  public static macro function buildRegistry():ComplexType
  {
    var params:Array<Type> = switch (Context.getLocalType())
    {
      case TInst(_, [p1, p2, p3, p4]): [p1, p2, p3, p4];
      default: throw 'Should not happen';
    }

    var cls:ClassType = Context.getLocalClass().get();
    var pack:Array<String> = cls.pack;
    var name:String = cls.name;
    for (p in params.slice(0, 3))
    {
      name += '_${genericTypePath(p)}';
    }
    var fullPath:String = '${pack.join('.')}.${name}';

    var entryType:ClassType = switch (params[0])
    {
      case TInst(t, _):
        t.get();
      default:
        throw 'Not a class';
    }

    var dataType:Any = switch (params[1])
    {
      case TInst(t, _):
        t.get();
      case TType(t, _):
        t.get();
      default:
        throw 'Not a class';
    }

    var fetchType:Any = switch (params[2])
    {
      case TInst(t, _):
        t.get();
      case TType(t, _):
        t.get();
      default:
        throw 'Not a class';
    }

    var dataFilePath:String = switch (params[3])
    {
      case TInst(_.get() => {kind: KExpr(macro $v{(s : String)})}, _): s;
      default: throw 'Should not happen';
    }

    var registry:ComplexType = buildRegistryImpl(name, pack, params, entryType, dataType, fetchType, dataFilePath);

    // Build an internal class with static functions that allow the Entry class to call functions on the Registry class.
    var localModule:String = Context.getLocalModule();
    buildEntryImpl(entryType, '${localModule}');

    return registry;
  }

  public static macro function buildEntry():Array<Field>
  {
    var fields = Context.getBuildFields();

    var cls = Context.getLocalClass().get();

    if (alreadyProcessed(cls))
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
  /**
   * Defines the registry implementation class.
   * @param cls The `BaseRegistry` class
   * @param fields The fields that the registry class should have.
   * @param params The parameters of the registry class.
   * @return The `ComplexType` of the registry class.
   */
  static function buildRegistryImpl(name:String, pack:Array<String>, params:Array<Type>, entryType:ClassType, dataType:Dynamic, fetchType:Dynamic,
      dataFilePath:String):ComplexType
  {
    var registryParams:Array<TypeParam> = [];

    for (p in params)
    {
      switch (p)
      {
        case TInst(_.get() => {kind: KExpr(e)}, _):
          registryParams.push(TPExpr(e));
        case TInst(t, _):
          registryParams.push(TPType(p.toComplexType()));
        case TType(t, _):
          registryParams.push(TPType(p.toComplexType()));
        default:
          throw 'Should not happen';
      }
    }

    var fullPath:String = '${pack.join('.')}.${name}';

    var baseRegistryImpl:TypePath =
      {
        pack: ['funkin', 'data'],
        name: 'BaseRegistry',
        sub: 'BaseRegistryImpl',
        params: registryParams,
      };
    var registry:TypeDefinition = macro class $name extends $baseRegistryImpl {}
    registry.pos = Context.currentPos();
    registry.pack = pack;
    registry.fields = registry.fields.concat(buildRegistryMethods(entryType, dataType, fetchType, dataFilePath));

    Context.defineType(registry);
    var result:ComplexType = Context.getType(fullPath).toComplexType();
    return result;
  }

  /**
   * Builds new static and instance methods for a registry class.
   *
   * @param entryType The class type of entries in the registry.
   * @param dataType The type of the data for entries in the registry.
   * @param dataFilePath The path to the files for the registry.
   * @return The modified list of fields for the target class.
   */
  static function buildRegistryMethods(entryType:ClassType, dataType:Dynamic, fetchType:Dynamic, dataFilePath:String):Array<Field>
  {
    var scriptedEntryClsName:String = '${entryType.pack.join('.')}.Scripted${entryType.name}';

    var getScriptedClassName:String = '${scriptedEntryClsName}';

    var createScriptedEntry:String = '${scriptedEntryClsName}.init(clsName, "unknown")';

    var newJsonParser:String = 'new json2object.JsonParser<${dataType.module}.${dataType.name}>()';

    var baseGameEntryIds:Array<Expr> = listBaseGameEntryIds('${DATA_FILE_BASE_PATH}/${dataFilePath}/');

    return (macro class TempClass
      {
        public function listBaseGameEntryIds():Array<String>
        {
          return $a{baseGameEntryIds};
        }

        public function listModdedEntryIds():Array<String>
        {
          return listEntryIds().filter(function(id:String):Bool {
            return listBaseGameEntryIds().indexOf(id) == -1;
          });
        }

        function get_dataFilePath():String
        {
          return $v{dataFilePath};
        }

        function getScriptedClassNames()
        {
          return ${Context.parse(getScriptedClassName, Context.currentPos())}.listScriptClasses();
        }

        function createScriptedEntry(clsName:String)
        {
          return ${Context.parse(createScriptedEntry, Context.currentPos())};
        }

        public function parseEntryData(id:String)
        {
          var parser = ${Context.parse(newJsonParser, Context.currentPos())};
          parser.ignoreUnknownVariables = false;

          @:privateAccess
          switch (this.loadEntryFile(id))
          {
            case {fileName: fileName, contents: contents}:
              parser.fromJson(contents.substring(contents.indexOf("{"), contents.lastIndexOf("}") + 1), fileName);
            default:
              return null;
          }

          if (parser.errors.length > 0)
          {
            @:privateAccess
            this.printErrors(parser.errors, id);
            return null;
          }
          return parser.value;
        }

        public function parseEntryDataRaw(contents:String, ?fileName:String)
        {
          var parser = ${Context.parse(newJsonParser, Context.currentPos())};
          parser.ignoreUnknownVariables = false;
          parser.fromJson(contents, fileName);

          if (parser.errors.length > 0)
          {
            @:privateAccess
            this.printErrors(parser.errors, fileName);
            return null;
          }
          return parser.value;
        }
      }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name));
  }

  /**
   * Retrieve the type of the JSON data for an entry.
   * @param cls The entry class to retrieve the type of the JSON data for.
   * @return Will be either a `DefType` or a `ClassType`.
   */
  static function getEntryData(cls:ClassType):Any // DefType or ClassType
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

  static function buildEntryVariables(cls:ClassType, entryData:Dynamic):Array<Field>
  {
    var entryDataType:ComplexType = Context.getType('${entryData.module}.${entryData.name}').toComplexType();

    return (macro class TempClass
      {
        public final id:String;

        public final _data:Null<$entryDataType>;
      }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name));
  }

  static function buildEntryMethods(cls:ClassType):Array<Field>
  {
    // The internal class built by `buildEntryImpl`.
    var impl:String = '${cls.pack.join('.')}.${cls.name}_DefaultImpl_';
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
      }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name));
  }

  /**
   * Build an internal class that calls functions for an associated registry class.
   * @param cls The entry class to build the internal class for.
   * @param registryPath The registry class that the entry class is associated with.
   */
  static function buildEntryImpl(cls:ClassType, registryPath:String):Void
  {
    var clsType:ComplexType = Context.getType('${cls.module}.${cls.name}').toComplexType();

    Context.defineType(
      {
        pos: Context.currentPos(),
        pack: cls.pack,
        name: '${cls.name}_DefaultImpl_',
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: (macro class TempClass
          {
            public static inline function _fetchData(me:$clsType, id:String)
            {
              return $
              {
                Context.parse(registryPath, Context.currentPos())
              }.instance.parseEntryDataWithMigration(id, ${Context.parse(registryPath, Context.currentPos())}.instance.fetchEntryVersion(id));
            }

            public static inline function toString(me:$clsType)
            {
              return $v{cls.name} + '(' + me.id + ')';
            }

            public static inline function destroy(me:$clsType) {}
          }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name))
      });
  }

  static function listBaseGameEntryIds(dataFilePath:String):Array<Expr>
  {
    var result:Array<Expr> = [];
    var files:Array<String> = FileSystem.readDirectory(dataFilePath);

    for (file in files)
    {
      result.push(macro $v{file.replace('.json', '')});
    }

    return result;
  }

  /**
   * Check whether this class has already been processed by the RegistryMacro,
   * as indicated by the `@:funkinProcessed` meta.
   * @param cls The class to check.
   * @return `true` if the class has already been processed, `false` otherwise.
   */
  static function alreadyProcessed(cls:ClassType):Bool
  {
    // Check for the `@:funkinProcessed` meta.
    var processedMeta:MetadataEntry = cls.meta.get().find(function(m) return m.name == ':funkinProcessed');
    if (processedMeta != null) return true;

    // If it's not found, check the superclass.
    if (cls.superClass != null) return alreadyProcessed(cls.superClass.t.get());
    return false;
  }

  /**
   * Generate a path for a generic type.
   * @param t The type to generate the path for.
   * @return The path of the type.
   */
  static function genericTypePath(t:Type):String
  {
    return switch (t)
    {
      case TInst(t, _): t.toString().replace('.', '_');
      case TType(t, _): t.toString().replace('.', '_');
      default: throw 'Type should be Class or Typedef';
    }
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
