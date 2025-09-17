package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
#end

using StringTools;

/**
 * A macro class that loads environment variables from a .env file for compile-time injection.
 */
class EnvironmentMacro
{
  /**
   * Initializes static Null<String> fields annotated with @:envField from the .env file.
   *
   * @return Array<Field> The modified array of fields with injected environment values.
   */
  public static macro function build():Array<Field>
  {
    final envFile:Map<String, String> = parseEnvFile(#if ios '../../../../../.env' #else '.env' #end);

    final buildFields:Array<Field> = Context.getBuildFields();

    for (i in 0...buildFields.length)
    {
      final field:Field = buildFields[i];

      if (field.access.contains(AStatic))
      {
        switch (field.kind)
        {
          case FVar(t, e):
            for (meta in field.meta)
            {
              if (meta.name == ':envField')
              {
                var isNullString:Bool = false;

                switch (t)
                {
                  case TPath(tp):
                    if (tp.name == 'Null' && tp.params != null && tp.params.length == 1)
                    {
                      switch (tp.params[0])
                      {
                        case TPType(TPath(tptp)):
                          if (tptp.name == 'String')
                          {
                            isNullString = true;
                          }
                        default:
                      }
                    }
                  default:
                }

                if (!isNullString)
                {
                  Context.fatalError('Field ${field.name} must be of type Null<String> to use :envField', field.pos);
                }
                else
                {
                  var e:Expr = macro $v{null};

                  if (envFile.exists(field.name))
                  {
                    e = macro $v{envFile.get(field.name)};
                  }
                  else
                  {
                    Context.warning('Value for ${field.name} is not present in the ".env" file.', field.pos);
                  }

                  buildFields[i].kind = FVar(t, e);
                }
              }
            }
          default:
        }
      }
    }

    return buildFields;
  }

  #if macro
  static function parseEnvFile(envPath:String):Map<String, String>
  {
    final env:Map<String, String> = [];

    if (FileSystem.exists(envPath))
    {
      final envContent:Null<String> = File.getContent(envPath);

      if (envContent != null && envContent.length > 0)
      {
        for (line in envContent.split('\n'))
        {
          line = line.trim();

          if (line.length <= 0 || line.startsWith('#') || shouldExcludeKey(line))
          {
            continue;
          }

          final index:Int = line.indexOf('=');

          if (index == -1)
          {
            continue;
          }

          final value:String = line.substr(index + 1);

          if (value.length == 0)
          {
            continue;
          }

          env.set(stripTargetPrefix(line.substr(0, index)), value);
        }
      }
    }

    return env;
  }

  static function shouldExcludeKey(key:String):Bool
  {
    final isAndroid:Bool = key.startsWith('ANDROID_');
    final isIos:Bool = key.startsWith('IOS_');
    final isMobile:Bool = key.startsWith('MOBILE_') || isIos || isAndroid;
    final isWeb:Bool = key.startsWith('WEB_');
    final isDesktop:Bool = key.startsWith('DESKTOP_');

    #if web
    return isMobile || isDesktop;
    #elseif desktop
    return isMobile || isWeb;
    #elseif android
    return isIos || isWeb || isDesktop;
    #elseif ios
    return isAndroid || isWeb || isDesktop;
    #end

    return false;
  }

  static function stripTargetPrefix(key:String):String
  {
    final index:Int = key.indexOf('_');

    if (index == -1)
    {
      return key;
    }

    final prefix:String = key.substr(0, index);
    final rest:String = key.substr(index + 1);

    return switch (prefix)
    {
      #if android
      case 'ANDROID', 'MOBILE':
        rest;
      #elseif ios
      case 'IOS', 'MOBILE':
        rest;
      #elseif web
      case 'WEB':
        rest;
      #elseif desktop
      case 'DESKTOP':
        rest;
      #end
      default:
        key;
    }
  }
  #end
}
