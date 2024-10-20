package funkin.util.macro;

import haxe.io.Path;

class HaxelibVersions
{
  public static macro function getLibraryVersions():haxe.macro.Expr.ExprOf<Array<String>>
  {
    #if !display
    return macro $v{formatHxPkgData()};
    #else
    // `#if display` is used for code completion. In this case returning an
    // empty string is good enough; We don't want to call functions on every hint.
    var commitHash:Array<String> = [];
    return macro $v{commitHash};
    #end
  }

  #if (macro)
  @SuppressWarnings('checkstyle:Dynamic')
  static function formatHxPkgData():Array<String>
  {
    var result:Array<String> = [];

    var hxPkgData:Array<Dynamic> = cast haxe.Json.parse(sys.io.File.getContent('.hxpkg'));
    for (profile in hxPkgData)
    {
      if (profile.profile != 'default')
      {
        continue;
      }

      var pkgs:Array<Dynamic> = cast profile.pkgs;
      for (pkg in pkgs)
      {
        var type:String = pkg.link != null ? 'git' : 'haxelib';
        var innerText:String = switch (type)
        {
          case 'git':
            '${pkg.link}:${pkg.branch ?? 'None'}';
          case 'haxelib':
            '${pkg.version ?? 'None'}';
          default:
            'THIS CANT HAPPEN';
        }

        result.push('${pkg.name} ${type}(${innerText})');
      }
    }

    return result;
  }

  static function readLibraryCurrentVersion(libraryName:String):String
  {
    var path = Path.join([Path.addTrailingSlash(Sys.getCwd()), '.haxelib', libraryName, '.current']);
    // This is compile time so we should always have Sys available.
    var result = sys.io.File.getContent(path);

    return result;
  }
  #end
}
