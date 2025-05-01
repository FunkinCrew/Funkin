package funkin.util.macro;

#if sys
import sys.io.File;
import sys.FileSystem;
#end
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end
import haxe.ds.Map;

using StringTools;

/**
 * A macro that reads an environment file during the build process for you to access in runtime without exposing the value.
 */
#if !macro
#if ios
@:build(funkin.util.macro.EnvironmentConfigMacro.setupEnvConfig("../../../../../.env"))
#else
@:build(funkin.util.macro.EnvironmentConfigMacro.setupEnvConfig(".env"))
#end
#end
class EnvironmentConfigMacro
{
  /**
   * A map-like object that contains the environment variables.
   */
  public static final environmentConfig:Null<EnvironmentConfig> = null;

  #if macro
  /**
   * Parse a environment file and set it's fields at `environmentConfig`.
   * TODO: Make add the fields directly to `environmentConfig` instead of overriding it
   * @param file An environment file containing the fields to parse.
   */
  private static function setupEnvConfig(file:String)
  {
    var fields = Context.getBuildFields();
    var pos = Context.currentPos();

    if (!sys.FileSystem.exists(file))
    {
      trace('Failed to parse environment file: ${file}');
      return fields;
    }

    var envFile:String = File.getContent(file);

    if (envFile == null)
    {
      trace('Failed to parse environment file: ${file}');
      return fields;
    }

    var envFields:Array<String> = [];
    var envValues:Array<Dynamic> = [];

    for (line in envFile.split('\n'))
    {
      if (line == "" || line.startsWith("#")) continue;

      var parts = line.split('=');
      if (parts.length != 2) continue;

      envFields.push(parts[0]);
      envValues.push(parts[1]);
    }

    var newFields = fields.copy();
    for (i => field in fields)
    {
      if (field.name == 'environmentConfig')
      {
        var typePath:TypePath =
          {
            name: 'EnvironmentConfigMacro',
            pack: ['funkin', 'util', 'macro'],
            sub: 'EnvironmentConfig'
          };

        var args:Array<Expr> = [Context.makeExpr(envFields, pos), Context.makeExpr(envValues, pos)];

        var expr:Expr =
          {
            expr: ENew(typePath, args),
            pos: pos
          };

        newFields[i] =
          {
            name: 'environmentConfig',
            access: [APublic, AStatic, AFinal],
            kind: FVar(macro :funkin.util.macro.EnvironmentConfigMacro.EnvironmentConfig, expr),
            pos: pos,
          };
      }
    }

    return newFields;
  }
  #end
}

private class EnvironmentConfig
{
  private var map:Map<String, Dynamic>;

  public function new(fields:Array<String>, values:Array<Dynamic>)
  {
    map = new Map<String, Dynamic>();

    for (i => field in fields)
    {
      map.set(field, values[i]);
    }
  }

  public function get(key:String):Dynamic
  {
    return map.get(key);
  }

  public function exists(key:String):Bool
  {
    return map.exists(key);
  }
}
