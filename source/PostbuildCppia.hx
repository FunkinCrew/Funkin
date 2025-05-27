package source; // Yeah, I know...

import haxe.io.Path;
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
    trace('Postbuild script executed successfully.');
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
    trace('Initializing Haxe compiler...');

    var haxeCompilerSrc:String = Path.normalize(Sys.getEnv("HAXEPATH"));
    var haxeCompilerDest:String = '${BIN_DIR}/haxe';

    if (haxeCompilerSrc == null || !FileSystem.exists(haxeCompilerSrc)) throw 'Haxe compiler binaries do not exist or HAXEPATH is not set';

    recursiveCopy(haxeCompilerSrc, haxeCompilerDest, ['$haxeCompilerSrc/lib']);

    var libs:Array<String> = File.getContent('.copy_libs').split('\n');

    for (lib in libs)
    {
      if (!FileSystem.exists(lib)) throw 'Library does not exist: $lib';

      var dest:String = '${BIN_DIR}/haxe/std/${lib.split('/').pop()}';

      recursiveCopy(lib, dest, []);
    }

    FileSystem.deleteFile('.copy_libs');
  }

  static function recursiveCopy(from:String, to:String, skip:Array<String>):Void
  {
    if (!FileSystem.exists(to)) FileSystem.createDirectory(to);
    for (entry in FileSystem.readDirectory(from))
    {
      var fromPath:String = '$from/$entry';
      var toPath:String = '$to/$entry';
      if (skip.contains(fromPath)) continue;
      if (FileSystem.isDirectory(fromPath)) recursiveCopy(fromPath, toPath, skip);
      else
        File.saveBytes(toPath, File.getBytes(fromPath));
    }
  }
}
