package funkin.util.macro;

import haxe.io.Path;

class HaxelibVersions
{
  public static macro function getLibraryVersions():haxe.macro.Expr.ExprOf<Array<String>>
  {
    #if !display
    return macro $v{formatHmmData(readHmmData())};
    #else
    // `#if display` is used for code completion. In this case returning an
    // empty string is good enough; We don't want to call functions on every hint.
    var commitHash:String = "";
    return macro $v{commitHashSplice};
    #end
  }

  #if (debug && macro)
  static function readHmmData():hmm.HmmConfig
  {
    return hmm.HmmConfig.HmmConfigs.readHmmJsonOrThrow();
  }

  static function formatHmmData(hmmData:hmm.HmmConfig):Array<String>
  {
    var result:Array<String> = [];

    for (library in hmmData.dependencies)
    {
      switch (library)
      {
        case Haxelib(name, version):
          result.push('${name} haxelib(${o(version)})');
        case Git(name, url, ref, dir):
          result.push('${name} git(${url}/${o(dir, '')}:${o(ref)})');
        case Mercurial(name, url, ref, dir):
          result.push('${name} mercurial(${url}/${o(dir, '')}:${o(ref)})');
        case Dev(name, path):
          result.push('${name} dev(${path})');
      }
    }

    return result;
  }

  static function o(option:haxe.ds.Option<String>, defaultValue:String = 'None'):String
  {
    switch (option)
    {
      case Some(value):
        return value;
      case None:
        return defaultValue;
    }
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
