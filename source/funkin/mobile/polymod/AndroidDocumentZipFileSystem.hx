package funkin.mobile.polymod;

#if android
import funkin.mobile.polymod.AndroidDocumentFileSystem;
import haxe.io.Bytes;
import haxe.io.Path;
import polymod.fs.ZipFileSystem.ZipFileSystemParams;
import polymod.Polymod.ModMetadata;
import polymod.util.zip.ZipParser;
import polymod.util.Util;
import thx.semver.VersionRule;

using StringTools;

/**
 * Represents a file system implementation tailored for the Polymod framework on Android, capable of accessing files and directories managed by the Android storage access framework, as well as mod files from both directories and ZIP archives within the mod root.
 *
 * This class extends AndroidDocumentFileSystem and provides support for reading and extracting files from ZIP archives, in addition to standard file system operations.
 *
 * Supports compressed and uncompressed ZIP files.
 */
class AndroidDocumentZipFileSystem extends AndroidDocumentFileSystem
{
  /**
   * Specifies the name of the ZIP that contains each file.
   */
  var filesLocations:Map<String, String>;

  /**
   * Specifies the names of available directories within the ZIP files.
   */
  var fileDirectories:Array<String>;

  /**
   * The wrappers for each ZIP file that is loaded.
   */
  var zipParsers:Map<String, ZipParser>;

  public function new(params:ZipFileSystemParams):Void
  {
    super(params);

    filesLocations = new Map<String, String>();
    zipParsers = new Map<String, ZipParser>();
    fileDirectories = [];

    if (params.autoScan == null) params.autoScan = true;

    if (params.autoScan) addAllZips();
  }

  /**
   * Retrieve file bytes by pulling them from the ZIP file.
   */
  public override function getFileBytes(path:String):Null<Bytes>
  {
    path = Util.filterASCII(path);

    if (!filesLocations.exists(path))
    {
      // Fallback to the inner SysFileSystem.
      return super.getFileBytes(path);
    }
    else
    {
      // Rather than going to the `files` map for the contents (which are empty),
      // we go directly to the zip file and extract the individual file.

      // Determine which zip the target file is in.
      var zipPath = filesLocations.get(path);
      var zipParser = zipParsers.get(zipPath);
      var modId = Path.withoutExtension(Path.withoutDirectory(zipPath));

      var innerPath = path;

      // Remove mod root from path
      if (innerPath.startsWith(modRoot))
      {
        innerPath = innerPath.substring(modRoot.endsWith("/") ? modRoot.length : modRoot.length + 1);
      }

      // Remove mod ID from path
      if (innerPath.startsWith(modId))
      {
        innerPath = innerPath.substring(modId.length + 1);
      }

      var fileHeader = zipParser.getLocalFileHeaderOf(innerPath);
      if (fileHeader == null)
      {
        // Couldn't access file
        trace('WARNING: Could not access file $innerPath from ZIP ${zipParser.fileName}.');
        return null;
      }
      var fileBytes = fileHeader.readData();
      return fileBytes;
    }
  }

  public override function exists(path:String)
  {
    trace('Checking existance of file ${path}...');

    if (filesLocations.exists(path)) return true;
    if (fileDirectories.contains(path)) return true;

    return super.exists(path);
  }

  public override function isDirectory(path:String)
  {
    if (fileDirectories.contains(path)) return true;

    if (filesLocations.exists(path)) return false;

    return super.isDirectory(path);
  }

  public override function readDirectory(path:String):Array<String>
  {
    // Remove trailing slash
    if (path.endsWith("/")) path = path.substring(0, path.length - 1);

    var result = super.readDirectory(path);
    result = (result == null) ? [] : result;

    if (fileDirectories.contains(path))
    {
      // We check if directory ==, because
      // we don't want to read the directory recursively.

      for (file in filesLocations.keys())
      {
        if (Path.directory(file) == path)
        {
          result.push(Path.withoutDirectory(file));
        }
      }

      for (dir in fileDirectories)
      {
        if (Path.directory(dir) == path)
        {
          result.push(Path.withoutDirectory(dir));
        }
      }
    }

    return result;
  }

  /**
   * Scan the mod root for ZIP files and add each one to the SysZipFileSystem.
   */
  public function addAllZips():Void
  {
    Polymod.notice(MOD_LOAD_PREPARE, 'Searching for ZIP files in ' + modRoot);
    // Use SUPER because we don't want to add in files within the ZIPs.
    var modRootContents = super.readDirectory(modRoot);
    Polymod.notice(MOD_LOAD_PREPARE, 'Found ${modRootContents.length} files in modRoot.');

    for (modRootFile in modRootContents)
    {
      var filePath = Util.pathJoin(modRoot, modRootFile);

      // Skip directories.
      if (isDirectory(filePath)) continue;

      // Only process ZIP files.
      if (StringTools.endsWith(filePath, ".zip"))
      {
        Polymod.notice(MOD_LOAD_PREPARE, '- Adding zip file: $filePath');
        addZipFile(filePath);
      }
    }
  }

  public function addZipFile(zipPath:String):Void
  {
    // Strip the path and extension to get the mod ID.
    var modId = Path.withoutExtension(Path.withoutDirectory(zipPath));

    var zipParser = new ZipParser(zipPath);

    // SysZipFileSystem doesn't actually use the internal `files` map.
    // We populate it here simply so we know the files are there.
    for (fileName => fileHeader in zipParser.centralDirectoryRecords)
    {
      // File is empty. Skip.
      if (fileHeader.compressedSize == 0 || fileHeader.uncompressedSize == 0) continue;

      // File is a directory. Skip.
      if (StringTools.endsWith(fileName, '/')) continue;

      // Add to the list of files.
      // The file should appear in the mod list as though it was in a directory rather than a ZIP.
      var fullFilePath = Path.join([modRoot, modId, fileHeader.fileName]);
      filesLocations.set(fullFilePath, zipPath);

      // Generate the list of directories.
      var fileDirectory = Path.directory(fullFilePath);
      // Resolving recursively ensures parent directories are registered.
      // If the directory is already registered, its parents are already registered as well.
      while (fileDirectory != "" && !fileDirectories.contains(fileDirectory))
      {
        fileDirectories.push(fileDirectory);
        fileDirectory = Path.directory(fileDirectory);
      }
    }

    // Store the ZIP parser for later use.
    zipParsers.set(zipPath, zipParser);
  }
}
#end
