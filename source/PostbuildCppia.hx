package source; // Yeah, I know...

import sys.FileSystem;
import sys.io.File;

using StringTools;

/**
 * A script which executes after the game is built.
 */
class PostbuildCppia
{
  static inline final EXPORT_CLASSES_FILE:String = 'export_classes.info';

  static inline final BIN_DIR:String = haxe.macro.Compiler.getDefine('BIN_DIR');

  static function main():Void
  {
    processExportClasses();
    processHaxeCompiler();
  }

  static function processExportClasses():Void
  {
    if (FileSystem.exists(EXPORT_CLASSES_FILE))
    {
      var content = File.getContent(EXPORT_CLASSES_FILE);
      var lines = content.split('\n');
      var filtered = lines.filter(function(line) return !line.ltrim().startsWith('file'));
      FileSystem.deleteFile(EXPORT_CLASSES_FILE);
      File.saveContent('${BIN_DIR}/${EXPORT_CLASSES_FILE}', filtered.join('\n'));

      trace('Saved exported classes to: ${BIN_DIR}/${EXPORT_CLASSES_FILE}');
    }
  }

  static function processHaxeCompiler():Void
  {
    var haxeCompilerSrc:String = 'haxe';
    var haxeCompilerDest:String = '${BIN_DIR}/haxe';

    if (!FileSystem.exists(haxeCompilerSrc)) throw 'Haxe compiler binaries do not exist';

    var scriptStdSrc:String = 'script_std';
    var scriptStdDest:String = '${BIN_DIR}/haxe/std';

    if (!FileSystem.exists(scriptStdSrc)) throw 'Script standard library does not exist';

    function copyDir(from:String, to:String):Void
    {
      if (!FileSystem.exists(to)) FileSystem.createDirectory(to);
      for (entry in FileSystem.readDirectory(from))
      {
        var fromPath:String = from + '/' + entry;
        var toPath:String = to + '/' + entry;
        if (FileSystem.isDirectory(fromPath)) copyDir(fromPath, toPath);
        else
          File.saveBytes(toPath, File.getBytes(fromPath));
      }
    }
    copyDir(haxeCompilerSrc, haxeCompilerDest);
    trace('Copied haxe compiler to: $haxeCompilerDest');

    copyDir(scriptStdSrc, scriptStdDest);
    trace('Copied script standard library to: $scriptStdDest');

    function deleteDirContents(dir:String):Void
    {
      for (entry in FileSystem.readDirectory(dir))
      {
        var path:String = dir + '/' + entry;
        if (FileSystem.isDirectory(path))
        {
          deleteDirContents(path);
          FileSystem.deleteDirectory(path);
        }
        else
        {
          FileSystem.deleteFile(path);
        }
      }
    }
    deleteDirContents(scriptStdSrc);
    FileSystem.deleteDirectory(scriptStdSrc);
  }
}
