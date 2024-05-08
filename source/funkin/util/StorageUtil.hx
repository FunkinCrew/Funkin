package funkin.util;

import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.Exception;
import lime.utils.Assets;

using StringTools;

class StorageUtil
{
  public static function copyNecessaryFiles(what:Map<String, String>):Void
  {
    for (key => value in what)
    {
      for (file in Assets.list().filter(folder -> folder.startsWith(value)))
      {
        if (Path.extension(file) == key)
        {
          final shit:String = file.replace(file.substring(0, file.indexOf('/', 0) + 1), '');
          final library:String = shit.replace(shit.substring(shit.indexOf('/', 0), shit.length), '');

          @:privateAccess
          copyFile(Assets.libraryPaths.exists(library) ? '$library:$file' : file, file);
        }
      }
    }
  }

  public static function mkDirs(directory:String):Void
  {
    var total:String = '';

    if (directory.substr(0, 1) == '/') total = '/';

    final parts:Array<String> = directory.split('/');

    if (parts.length > 0 && parts[0].indexOf(':') > -1) parts.shift();

    for (part in parts)
    {
      if (part != '.' && part.length > 0)
      {
        if (total != '/' && total.length > 0) total += '/';

        total += part;

        FileUtil.createDirIfNotExists(total);
      }
    }
  }

  public static function copyFile(copyPath:String, savePath:String):Void
  {
    try
    {
      if (!FileUtil.doesFileExist.exists(savePath) && Assets.exists(copyPath))
      {
        if (!FileUtil.doesFileExist(Path.directory(savePath))) Storage.mkDirs(Path.directory(savePath));

        FileUtil.writeBytesToPath(savePath, Assets.getBytes(copyPath), Force);
      }
    }
    catch (e:Exception)
      trace(e.message);
  }
}
