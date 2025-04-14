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
    var dataFilePath:String = switch (Context.getLocalType())
    {
      case TInst(_, [_, _, TInst(_.get() => {kind: KExpr(macro $v{(s : String)})}, _)]): s;
      default: throw 'Should not happen';
    }

    var params:Array<Type> = switch (Context.getLocalType())
    {
      case TInst(_, [p1, p2, _]): [p1, p2];
      default: throw 'Should not happen';
    }

    var complexParams:Array<ComplexType> = [for (p in params) p.toComplexType()];

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

    var fields:Array<Field> = Context.getBuildFields().filter((f) -> return !f.access.contains(AAbstract) && f.name != 'dataFilePath');

    fields = fields.concat(buildRegistryVariables(dataFilePath));

    fields = fields.concat(buildRegistryMethods(entryType, dataType, dataFilePath));

    fields = deparameterizeFields(fields, complexParams);

    var cls:ClassType = Context.getLocalClass().get();
    var registry:ComplexType = buildRegistryImpl(cls, fields, params);

    // Build an internal class with static functions that allow the Entry class to call functions on the Registry class.
    var localModule:String = Context.getLocalModule();
    buildEntryImpl(entryType, '${localModule}');

    return registry;
  }

  /**
   * Builds the registry entry class.
   *
   * @return The modified list of fields for the target class.
   */
  public static macro function buildEntry():Array<Field>
  {
    var cls:ClassType = Context.getLocalClass().get();
    var fields:Array<Field> = Context.getBuildFields();

    // Classes with the `@:funkinProcessed` meta should be ignored.
    if (alreadyProcessed(cls)) return fields;

    // Get the type of the JSON data for an entry.
    var entryData:Any = getEntryData(cls);

    // Build variables and methods for the entry.
    fields = fields.concat(buildEntryVariables(cls, entryData));
    fields = fields.concat(buildEntryMethods(cls));

    // Indicate that the class has been processed so we don't process twice.
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
  static function buildRegistryImpl(cls:ClassType, fields:Array<Field>, params:Array<Type>):ComplexType
  {
    var module:String = cls.module;
    var pack:Array<String> = cls.pack;
    var name:String = cls.name;
    for (p in params)
      name += '_${genericTypePath(p)}';

    var imports = [
      generateImport('funkin.util.assets.DataAssets'),
      generateImport('funkin.util.VersionUtil'),
      generateImport('flixel.FlxG')
    ];

    var usings = [
      generateUsing('StringTools'),
      generateUsing('funkin.util.tools.IteratorTools'),
      generateUsing('funkin.util.tools.MapTools')
    ];

    Context.defineModule(module, [
      {
        pos: Context.currentPos(),
        pack: pack,
        name: name,
        kind: TypeDefKind.TDClass(null, [], false, false, false),
        fields: fields
      }
    ], imports, usings);

    return TPath(
      {
        pack: pack,
        name: module.split('.')[pack.length],
        sub: name
      });
  }

  /**
   * Returns the fields for the registry class.
   * @param dataFilePath The path to the files for the registry.
   * @return The variables for the registry class.
   */
  static function buildRegistryVariables(dataFilePath:String):Array<Field>
  {
    return (macro class TempClass
      {
        final dataFilePath:String = $v{dataFilePath};
      }).fields;
  }

  /**
   * Builds new static and instance methods for a registry class.
   *
   * @param entryType The class type of entries in the registry.
   * @param dataType The type of the data for entries in the registry.
   * @param dataFilePath The path to the files for the registry.
   * @return The modified list of fields for the target class.
   */
  static function buildRegistryMethods(entryType:ClassType, dataType:Dynamic, dataFilePath:String):Array<Field>
  {
    var scriptedEntryClsName:String = '${entryType.pack.join('.')}.Scripted${entryType.name}';

    var getScriptedClassName:String = '${scriptedEntryClsName}';

    var createEntry:String = 'new ${entryType.module}.${entryType.name}(id)';

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

        function getScriptedClassNames()
        {
          return ${Context.parse(getScriptedClassName, Context.currentPos())}.listScriptClasses();
        }

        function createEntry(id:String)
        {
          return ${Context.parse(createEntry, Context.currentPos())};
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
              parser.fromJson(contents, fileName);
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
      }).fields;
  }

  /**
   * Apply the generic parameters to the fields of the registry class.
   * @param fields The fields to apply the generic parameters to.
   * @param complexParams The generic parameters to apply.
   * @return The modified list of fields for the target class.
   */
  static function deparameterizeFields(fields:Array<Field>, complexParams:Array<ComplexType>):Array<Field>
  {
    function deparameterizeType(t:ComplexType):ComplexType
    {
      switch (t)
      {
        case TPath(tp):
          if (tp.name == 'T') return complexParams[0];
          else if (tp.name == 'J') return complexParams[1];

          for (i in 0...tp.params.length)
          {
            switch (tp.params[i])
            {
              case TPType(t):
                tp.params[i] = TPType(deparameterizeType(t));
              default:
                throw 'Should not happen';
            }
          }
        default:
          throw 'Not yet handled';
      }

      return t;
    }

    function deparameterizeExpr(e:Expr):Expr
    {
      final regexT = ~/(\bT\b)(?=[^a-zA-Z0-9_]|$)/g;
      final regexJ = ~/(\bJ\b)(?=[^a-zA-Z0-9_]|$)/g;

      var exprString = e.toString();
      exprString = regexT.replace(exprString, complexParams[0].toString());
      exprString = regexJ.replace(exprString, complexParams[1].toString());

      return Context.parse(exprString, Context.currentPos());
    }

    for (f in fields)
    {
      switch (f.kind)
      {
        case FVar(t, e):
          t = deparameterizeType(t);
          if (e != null) e = deparameterizeExpr(e);
        case FFun(f):
          for (i in 0...f.args.length)
            if (f.args[i].type != null) f.args[i].type = deparameterizeType(f.args[i].type);
          if (f.ret != null) f.ret = deparameterizeType(f.ret);
          if (f.expr != null) f.expr = deparameterizeExpr(f.expr);
        case FProp(_, _, t, e):
          t = deparameterizeType(t);
          if (e != null) e = deparameterizeExpr(e);
      }
    }

    return fields;
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
          throw '${cls.name}: Type parameter for Entry must be a Class or typedef';
      }
    }
    catch (e)
    {
      throw '${cls.name}: IRegistryEntry must be the last implemented interface';
    }
  }

  /**
   * Add fields to the entry class.
   * @param cls The entry class to add fields to.
   * @param entryData The type of the data for the entry.
   * @return The modified list of fields for the target class.
   */
  static function buildEntryVariables(cls:ClassType, entryData:Dynamic):Array<Field>
  {
    var entryDataType:ComplexType = Context.getType('${entryData.module}.${entryData.name}').toComplexType();

    return (macro class TempClass
      {
        public final id:String;

        public final _data:Null<$entryDataType>;
      }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name));
  }

  /**
   * Add methods to the entry class.
   * @param cls The entry class to add methods to.
   * @return The modified list of fields for the target class.
   */
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
          }).fields
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

  /**
   * Generate an `ImportExpr` from a path.
   * @param path The path to the class
   * @return The `ImportExpr` of the class.
   */
  static function generateImport(path:String):ImportExpr
  {
    var parts = [];
    for (part in path.split('.'))
      parts.push(
        {
          pos: Context.currentPos(),
          name: part
        });

    return {
      path: parts,
      mode: INormal
    }
  }

  /**
   * Generate a `TypePath` from a path.
   * @param path The path to the class
   * @return The `TypePath` of the class.
   */
  static function generateUsing(path:String):TypePath
  {
    var parts = path.split('.');
    var pack = parts.slice(0, parts.length - 1);
    var name = parts[parts.length - 1];

    return {
      pack: pack,
      name: name
    };
  }
  #end
}
