package funkin.util;

import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.Exception;
import lime.utils.Assets;

using StringTools;

/**
 * Utility class for managing file operations and storage.
 */
class StorageUtil
{
  /**
   * Copies necessary files based on specified mappings of file extensions to folder paths.
   * 
   * @param extensionToFolder A map containing file extensions as keys and folder paths as values.
   */
  public static function copyNecessaryFiles(extensionToFolder:Map<String, String>):Void
  {
    for (key => value in extensionToFolderMap)
    {
      for (file in Assets.list().filter(folder -> folder.startsWith(value)))
      {
        if (Path.extension(file) == key)
        {
          // Extract the library name from the file path
          final fileName:String = file.replace(file.substring(0, file.indexOf('/', 0) + 1), '');
          final library:String = fileName.replace(fileName.substring(fileName.indexOf('/', 0), fileName.length), '');

          // Copy the file using library prefix if available, otherwise directly
          @:privateAccess
          copyFile(Assets.libraryPaths.exists(library) ? '$library:$file' : file, file);
        }
      }
    }
  }

  /**
   * Creates directories recursively for a given directory path.
   * 
   * @param directory The directory path to create.
   */
  public static function mkDirs(directory:String):Void
  {
    var total:String = '';

    // Check if the directory is absolute
    if (directory.substr(0, 1) == '/')
    {
      total = '/';
    }

    final parts:Array<String> = directory.split('/');

    // Remove protocol if present
    if (parts.length > 0 && parts[0].indexOf(':') > -1)
    {
      parts.shift();
    }

    for (part in parts)
    {
      if (part != '.' && part.length > 0)
      {
        if (total != '/' && total.length > 0)
        {
          total += '/';
        }

        total += part;

        // Create the directory if it doesn't exist
        FileUtil.createDirIfNotExists(total);
      }
    }
  }

  /**
   * Copies a file from assets to a specified location.
   * 
   * @param copyPath The path of the asset to copy.
   * @param savePath The destination path to save the copied file.
   */
  public static function copyFile(copyPath:String, savePath:String):Void
  {
    try
    {
      if (!FileUtil.doesFileExist.exists(savePath) && Assets.exists(copyPath))
      {
        if (!FileUtil.doesFileExist(Path.directory(savePath)))
        {
          StorageUtil.mkDirs(Path.directory(savePath));
        }

        // Write bytes to the savePath
        FileUtil.writeBytesToPath(savePath, Assets.getBytes(copyPath), true);
      }
    }
    catch (e:Exception)
    {
      // Catch and trace any exceptions that occur
      trace(e.message);
    }
  }
}
