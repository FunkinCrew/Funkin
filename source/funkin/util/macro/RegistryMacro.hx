package funkin.util.macro;

import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Expr.ComplexType;
import haxe.macro.Expr.Field;
import haxe.macro.Expr.TypeDefKind;
import haxe.macro.Expr.MetadataEntry;
import haxe.macro.Type;
import haxe.macro.Type.ClassType;

using Lambda;
using haxe.macro.ExprTools;
using haxe.macro.TypeTools;
using StringTools;

/**
 * The type parameters for a class extending `BaseRegistry`.
 */
typedef RegistryTypeParams =
{
  /**
   * The class type of the entry. Must implement `IRegistryEntry`.
   */
  var entryType:ClassType;

  /**
   * The type for the data of an entry. This is usually a typedef of a struct.
   */
  var dataType:Any; // DefType or ClassType

}

/**
 * A set of build macros to be applied to `Registry` classes in the `funkin.data` package.
 *
 * @see `funkin.data.BaseRegistry`
 */
class RegistryMacro
{
  #if ios
  static final DATA_FILE_BASE_PATH:String = "../../../../../assets/preload/data";
  #else
  static final DATA_FILE_BASE_PATH:String = "assets/preload/data";
  #end

  /**
   * Builds the registry class.
   *
   * @return The modified list of fields for the target class.
   */
  public static macro function buildRegistry():Array<Field>
  {
    var cls:ClassType = Context.getLocalClass().get();
    var fields:Array<Field> = Context.getBuildFields();

    // Classes with the `@:funkinBase` meta or `@:funkinProcessed` meta should be ignored.
    var baseMeta:Null<MetadataEntry> = cls.meta.get().find(function(m) return m.name == ':funkinBase');
    if (baseMeta != null || alreadyProcessed(cls)) return fields;

    var typeParams:RegistryTypeParams = getTypeParams(cls);

    // Build an internal class with static functions that allow the Entry class to call functions on the Registry class.
    buildEntryImpl(typeParams.entryType, cls);

    fields = fields.concat(buildRegistryMethods(cls, fields, typeParams.entryType, typeParams.dataType));

    // Indicate that the class has been processed so we don't process twice.
    cls.meta.add(":funkinProcessed", [], cls.pos);

    return fields;
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
   * Retrieve the type parameters for a class extending `BaseRegistry<T, J>`.
   * @param cls The class to retrieve the type parameters for.
   * @return The type parameters for the class.
   */
  static function getTypeParams(cls:ClassType):RegistryTypeParams
  {
    switch (cls.superClass.t.get().kind)
    {
      case KGenericInstance(_, params):
        var typeParams:Array<Any> = [];
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
        return {entryType: typeParams[0], dataType: typeParams[1]};
      default:
        throw '${cls.name}: Could not interpret type parameters of Registry class.';
    }
  }

  /**
   * Builds new static and instance methods for a registry class.
   *
   * @param cls The registry class to build the methods for.
   * @param fields The fields of the registry class.
   * @param entryType The class type of entries in the registry.
   * @param dataType The type of the data for entries in the registry.
   * @return The modified list of fields for the target class.
   */
  static function buildRegistryMethods(cls:ClassType, fields:Array<Field>, entryType:ClassType, dataType:Dynamic):Array<Field>
  {
    var scriptedEntryClsName:String = entryType.pack.join('.') + '.Scripted' + entryType.name;

    var getScriptedClassName:String = '${scriptedEntryClsName}';

    var createScriptedEntry:String = '${scriptedEntryClsName}.init(clsName, "unknown")';

    var newJsonParser:String = 'new json2object.JsonParser<${dataType.module}.${dataType.name}>()';

    var dataFilePath:String = getRegistryDataFilePath(cls, fields);
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
      }).fields.filter((field) -> return !MacroUtil.fieldAlreadyExists(field.name));
  }

  /**
   * Build an internal class that calls functions for an associated registry class.
   * @param cls The entry class to build the internal class for.
   * @param registryCls The registry class that the entry class is associated with.
   */
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

  static function getRegistryDataFilePath(cls:ClassType, fields:Array<Field>):String
  {
    for (field in fields)
    {
      if (field.name == 'new')
      {
        // We found a field called `new`, it's probably the constructor.
        switch (field.kind)
        {
          case FFun(f):
            // Inside the function.
            switch (f.expr.expr)
            {
              // Inside the block.
              case EBlock(exprs):
                var superCall:Expr = exprs[0];
                switch (superCall.expr)
                {
                  // Inside the super() call.
                  case ECall(_, args):
                    // var registryId:String = args[0].toString();
                    var dataPath:String = args[1].toString().replace('"', '').replace("'", '');
                    // var versionRule = args[2].toString();

                    return dataPath;
                  default:
                    Context.error('${cls.name}.new: RegistryMacro expected super call', field.pos);
                }
              default:
                Context.error('${cls.name}.new: RegistryMacro expected super call', field.pos);
            }
          default:
            // Continue looking for the actual constructor.
        }
      }
    }

    return '';
  }

  static function listBaseGameEntryIds(dataFilePath:String):Array<Expr>
  {
    var result:Array<Expr> = [];
    var files:Array<String> = sys.FileSystem.readDirectory(dataFilePath);

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
  #end
}
