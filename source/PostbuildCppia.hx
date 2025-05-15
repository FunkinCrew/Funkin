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
}
