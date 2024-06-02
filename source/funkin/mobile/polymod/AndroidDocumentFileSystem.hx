package funkin.mobile.polymod;

#if android
import android.DocumentFileUtil;
import haxe.io.Bytes;
import polymod.fs.PolymodFileSystem;
import polymod.fs.SysFileSystem;
import polymod.Polymod;

/**
 * Represents a custom file system implementation tailored for the Polymod framework on Android.
 *
 * This allows interacting with files and directories managed by the Android storage access framework.
 */
class AndroidDocumentFileSystem extends SysFileSystem
{
  /**
   * Constructor for AndroidDocumentFileSystem.
   *
   * @param params The parameters required for initializing the file system.
   */
  public function new(params:PolymodFileSystemParams):Void
  {
    super(params);
  }

  /**
   * Checks if a file or directory exists at the specified path.
   *
   * @param path The path to the file or directory.
   * @return true if the file or directory exists, false otherwise.
   */
  public override function exists(path:String):Bool
  {
    return DocumentFileUtil.exists(path);
  }

  /**
   * Checks if the specified path is a directory.
   *
   * @param path The path to check.
   * @return true if the path is a directory, false otherwise.
   */
  public override function isDirectory(path:String):Bool
  {
    return DocumentFileUtil.isDirectory(path);
  }

  /**
   * Reads the contents of a directory at the specified path.
   *
   * @param path The path to the directory.
   * @return An array of strings representing the names of the files and directories in the specified directory.
   */
  public override function readDirectory(path:String):Array<String>
  {
    try
    {
      return DocumentFileUtil.readDirectory(path);
    }
    catch (e:Dynamic)
    {
      Polymod.warning(DIRECTORY_MISSING, 'Could not find directory "${path}"');
      return [];
    }
  }

  /**
   * Gets the content of a file at the specified path as a string.
   *
   * @param path The path to the file.
   * @return The content of the file as a string.
   */
  public override function getFileContent(path:String):String
  {
    return DocumentFileUtil.getContent(path);
  }

  /**
   * Gets the content of a file at the specified path as bytes.
   *
   * @param path The path to the file.
   * @return The content of the file as a byte array.
   */
  public override function getFileBytes(path:String):Bytes
  {
    if (!exists(path)) return null;

    return DocumentFileUtil.getBytes(path);
  }
}
#end
