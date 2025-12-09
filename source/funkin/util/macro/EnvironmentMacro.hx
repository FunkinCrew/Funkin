package funkin.util.macro;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
import sys.io.File;
import funkin.util.macro.MacroUtil;
#end

using StringTools;
using funkin.util.AnsiUtil;

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
    final envFile:Map<String, String> = parseEnvFile('.env');

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
                // Retrieve the parameters of the metadata, if any.
                var mandatoryIfDefined:Null<String> = null;

                if (meta.params != null && meta.params.length >= 1)
                {
                  var params:Expr = meta.params[0];

                  var mandatoryIfDefinedExpr:Null<Expr> = MacroUtil.extractObjectField(params, 'mandatoryIfDefined');

                  if (mandatoryIfDefinedExpr != null)
                  {
                    mandatoryIfDefined = MacroUtil.extractStringConstant(mandatoryIfDefinedExpr);
                  }
                }

                // Validate that the field is of type Null<String> to ensure the macro works.
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
                  else if (mandatoryIfDefined != null)
                  {
                    var inverseDefine = (mandatoryIfDefined.startsWith('NO_')) ? mandatoryIfDefined.substr(4) : 'NO_$mandatoryIfDefined';

                    var errorMessage:String = 'Value for ${field.name} not found in the environment file.';

                    errorMessage += '\nThis field is flagged as MANDATORY; populate the `.env` file in the project root,';
                    errorMessage += ' or compile with -D${inverseDefine} to skip this check.';

                    Context.fatalError(errorMessage, field.pos);
                  }
                  else
                  {
                    warning('Value for '.bright_red() + field.name.bold().bright_red() + ' not found in the environment file.'.bright_red(), field.pos);
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

    #if ios
    if (!FileSystem.exists(envPath)) envPath = "../../../../../" + envPath;
    #end

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

  // MIGHT be able to repurpose this for custom context warnings hehe - Zack
  static function warning(msg:String, pos:Position)
  {
    var infos:Dynamic = Context.getPosInfos(pos);

    // file & position
    var fileContent = File.getContent(infos.file);
    var before = fileContent.substr(0, infos.min);
    var line = before.split("\n").length;
    var lastNewline = before.lastIndexOf("\n");
    var col0 = (lastNewline == -1) ? infos.min : infos.min - (lastNewline + 1);
    infos.line = line;
    infos.column = col0 + 1; // 1-based

    // line texts
    var lines = (fileContent == "") ? [] : fileContent.split("\n");
    var lineText = if (infos.line > 0 && infos.line <= lines.length) lines[Std.int(infos.line - 1)] else "";

    // highlight code line
    lineText = lineText.bold();

    // underline from min to max (at least one ^)
    var underlineLen = Std.int(Math.max(1, infos.max - infos.min));
    var underline = StringTools.lpad("", " ", Std.int(infos.column - 1)) + StringTools.rpad("", "^", underlineLen).bold().bright_red();

    // header like Haxe diagnostics
    var header_title = " ENVIRONMENT ".bold().bg_red();
    var header = '${header_title} ${infos.file}:${infos.line}: characters ${infos.column}-${infos.column + underlineLen}\n';

    // body with code + pointer + message
    var body = ' ${infos.line} |   ${lineText}\n' + '    |   ${underline}\n' + '    |  ${msg}\n';

    Sys.println(header + "\n" + body);
  }
  #end
}
