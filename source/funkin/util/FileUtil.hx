package funkin.util;

import haxe.zip.Entry;
import lime.utils.Bytes;
import lime.ui.FileDialog;
import openfl.net.FileFilter;
import haxe.io.Path;

/**
 * Utilities for reading and writing files on various platforms.
 */
class FileUtil
{
  /**
   * Browses for a single file, then calls `onSelect(path)` when a path chosen.
   * Note that on HTML5 this will immediately fail, you should call `openFile(onOpen:Resource->Void)` instead.
   * 
   * @param typeFilter Filters what kinds of files can be selected.
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForFile(?typeFilter:Array<FileFilter>, ?onSelect:String->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = convertTypeFilter(typeFilter);

    var fileDialog = new FileDialog();
    if (onSelect != null) fileDialog.onSelect.add(onSelect);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.browse(OPEN, filter, defaultPath, dialogTitle);
    return true;
    #elseif html5
    onCancel();
    return false;
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Browses for a directory, then calls `onSelect(path)` when a path chosen.
   * Note that on HTML5 this will immediately fail.
   * 
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForDirectory(?typeFilter:Array<FileFilter>, ?onSelect:String->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = convertTypeFilter(typeFilter);

    var fileDialog = new FileDialog();
    if (onSelect != null) fileDialog.onSelect.add(onSelect);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.browse(OPEN_DIRECTORY, filter, defaultPath, dialogTitle);
    return true;
    #elseif html5
    onCancel();
    return false;
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Browses for multiple file, then calls `onSelect(paths)` when a path chosen.
   * Note that on HTML5 this will immediately fail.
   * 
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForMultipleFiles(?typeFilter:Array<FileFilter>, ?onSelect:Array<String>->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = convertTypeFilter(typeFilter);

    var fileDialog = new FileDialog();
    if (onSelect != null) fileDialog.onSelectMultiple.add(onSelect);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.browse(OPEN_MULTIPLE, filter, defaultPath, dialogTitle);
    return true;
    #elseif html5
    onCancel();
    return false;
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Browses for a file location to save to, then calls `onSelect(path)` when a path chosen.
   * Note that on HTML5 you can't do much with this, you should call `saveFile(resource:haxe.io.Bytes)` instead.
   * 
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForSaveFile(?typeFilter:Array<FileFilter>, ?onSelect:String->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = convertTypeFilter(typeFilter);

    var fileDialog = new FileDialog();
    if (onSelect != null) fileDialog.onSelect.add(onSelect);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.browse(SAVE, filter, defaultPath, dialogTitle);
    return true;
    #elseif html5
    onCancel();
    return false;
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Browses for a single file location, then reads it and passes it to `onOpen(resource:haxe.io.Bytes)`.
   * Works great on desktop and HTML5.
   * 
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function openFile(?typeFilter:Array<FileFilter>, ?onOpen:Bytes->Void, ?onCancel:Void->Void, ?defaultPath:String, ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = convertTypeFilter(typeFilter);

    var fileDialog = new FileDialog();
    if (onOpen != null) fileDialog.onOpen.add(onOpen);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.open(filter, defaultPath, dialogTitle);
    return true;
    #elseif html5
    var filter = convertTypeFilter(typeFilter);

    var onFileLoaded = function(event) {
      var loadedFileRef:FileReference = event.target;
      trace('Loaded file: ' + loadedFileRef.name);
      onOpen(loadedFileRef.data);
    }

    var onFileSelected = function(event) {
      var selectedFileRef:FileReference = event.target;
      trace('Selected file: ' + selectedFileRef.name);
      selectedFileRef.addEventListener(Event.COMPLETE, onFileLoaded);
      selectedFileRef.load();
    }

    var fileRef = new FileReference();
    file.addEventListener(Event.SELECT, onFileSelected);
    file.open(filter, defaultPath, dialogTitle);
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Browses for a single file location, then writes the provided `haxe.io.Bytes` data and calls `onSave(path)` when done.
   * Works great on desktop and HTML5.
   * 
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function saveFile(data:Bytes, ?onSave:String->Void, ?onCancel:Void->Void, ?defaultFileName:String, ?dialogTitle:String):Bool
  {
    #if desktop
    var filter = defaultFileName != null ? Path.extension(defaultFileName) : null;

    var fileDialog = new FileDialog();
    if (onSave != null) fileDialog.onSelect.add(onSave);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.save(data, filter, defaultFileName, dialogTitle);
    return true;
    #elseif html5
    var filter = defaultFileName != null ? Path.extension(defaultFileName) : null;

    var fileDialog = new FileDialog();
    if (onSave != null) fileDialog.onSave.add(onSave);
    if (onCancel != null) fileDialog.onCancel.add(onCancel);

    fileDialog.save(data, filter, defaultFileName, dialogTitle);
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Prompts the user to save multiple files.
   * On desktop, this will prompt the user for a directory, then write all of the files to there.
   * On HTML5, this will zip the files up and prompt the user to save that.
   * 
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function saveMultipleFiles(resources:Array<Entry>, ?onSaveAll:Array<String>->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?force:Bool = false):Bool
  {
    #if desktop
    // Prompt the user for a directory, then write all of the files to there.
    var onSelectDir = function(targetPath:String) {
      var paths:Array<String> = [];
      for (resource in resources)
      {
        var filePath = haxe.io.Path.join([targetPath, resource.fileName]);
        try
        {
          if (resource.data == null)
          {
            trace('WARNING: File $filePath has no data or content. Skipping.');
            continue;
          }
          else
          {
            writeBytesToPath(filePath, resource.data, force ? Force : Skip);
          }
        }
        catch (e:Dynamic)
        {
          trace('Failed to write file (probably already exists): $filePath' + filePath);
          continue;
        }
        paths.push(filePath);
      }
      onSaveAll(paths);
    }

    browseForDirectory(null, onSelectDir, onCancel, defaultPath, "Choose directory to save all files to...");

    return true;
    #elseif html5
    saveFilesAsZIP(resources, onSaveAll, onCancel, defaultPath, force);

    return true;
    #else
    onCancel();
    return false;
    #end
  }

  /**
   * Takes an array of file entries and prompts the user to save them as a ZIP file.
   */
  public static function saveFilesAsZIP(resources:Array<Entry>, ?onSave:Array<String>->Void, ?onCancel:Void->Void, ?defaultPath:String,
      ?force:Bool = false):Bool
  {
    // Create a ZIP file.
    var zipBytes = createZIPFromEntries(resources);

    var onSave = function(path:String) {
      onSave([path]);
    };

    // Prompt the user to save the ZIP file.
    saveFile(zipBytes, onSave, onCancel, defaultPath, "Save files as ZIP...");

    return true;
  }

  /**
   * Takes an array of file entries and forcibly writes a ZIP to the given path.
   * Only works on desktop, because HTML5 doesn't allow you to write files to arbitrary paths.
   * Use `saveFilesAsZIP` instead.
   * @param force Whether to force overwrite an existing file.
   */
  public static function saveFilesAsZIPToPath(resources:Array<Entry>, path:String, ?force:Bool = false):Bool
  {
    #if desktop
    // Create a ZIP file.
    var zipBytes = createZIPFromEntries(resources);

    // Write the ZIP.
    writeBytesToPath(path, zipBytes, force ? Force : Skip);

    return true;
    #else
    return false;
    #end
  }

  /**
   * Write string file contents directly to a given path.
   * Only works on desktop.
   * 
   * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
   */
  public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip)
  {
    #if sys
    createDirIfNotExists(Path.directory(path));

    switch (mode)
    {
      case Force:
        sys.io.File.saveContent(path, data);
      case Skip:
        if (!sys.FileSystem.exists(path))
        {
          sys.io.File.saveContent(path, data);
        }
        else
        {
          throw 'File already exists: $path';
        }
      case Ask:
        if (sys.FileSystem.exists(path))
        {
          // TODO: We don't have the technology to use native popups yet.
        }
        else
        {
          sys.io.File.saveContent(path, data);
        }
    }
    #else
    throw 'Direct file writing by path not supported on this platform.';
    #end
  }

  /**
   * Write byte file contents directly to a given path.
   * Only works on desktop.
   * 
   * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
   */
  public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip)
  {
    #if sys
    createDirIfNotExists(Path.directory(path));

    switch (mode)
    {
      case Force:
        sys.io.File.saveBytes(path, data);
      case Skip:
        if (!sys.FileSystem.exists(path))
        {
          sys.io.File.saveBytes(path, data);
        }
        else
        {
          throw 'File already exists: $path';
        }
      case Ask:
        if (sys.FileSystem.exists(path))
        {
          // TODO: We don't have the technology to use native popups yet.
        }
        else
        {
          sys.io.File.saveBytes(path, data);
        }
    }
    #else
    throw 'Direct file writing by path not supported on this platform.';
    #end
  }

  /**
   * Write string file contents directly to the end of a file at the given path.
   * Only works on desktop.
   */
  public static function appendStringToPath(path:String, data:String)
  {
    sys.io.File.append(path, false).writeString(data);
  }

  /**
   * Create a directory if it doesn't already exist.
   * Only works on desktop.
   */
  public static function createDirIfNotExists(dir:String)
  {
    #if sys
    if (!sys.FileSystem.exists(dir))
    {
      sys.FileSystem.createDirectory(dir);
    }
    #end
  }

  static var tempDir:String = null;
  static final TEMP_ENV_VARS:Array<String> = ['TEMP', 'TMPDIR', 'TEMPDIR', 'TMP'];

  /**
   * Get the path to a temporary directory we can use for writing files.
   * Only works on desktop.
   */
  public static function getTempDir():String
  {
    if (tempDir != null) return tempDir;

    #if sys
    #if windows
    var path:String = null;

    for (envName in TEMP_ENV_VARS)
    {
      path = Sys.getEnv(envName);

      if (path == "") path = null;
      if (path != null) break;
    }

    return tempDir = Path.join([path, 'funkin/']);
    #else
    return tempDir = '/tmp/funkin/';
    #end
    #else
    return null;
    #end
  }

  /**
   * Create a Bytes object containing a ZIP file, containing the provided entries.
   * 
   * @param entries The entries to add to the ZIP file.
   * @return The ZIP file as a Bytes object.
   */
  public static function createZIPFromEntries(entries:Array<Entry>):Bytes
  {
    var o = new haxe.io.BytesOutput();

    var zipWriter = new haxe.zip.Writer(o);
    zipWriter.write(entries.list());

    return o.getBytes();
  }

  /**
   * Create a ZIP file entry from a file name and its string contents.
   * 
   * @param name The name of the file. You can use slashes to create subdirectories.
   * @param content The string contents of the file.
   * @return The resulting entry.
   */
  public static function makeZIPEntry(name:String, content:String):Entry
  {
    var data = haxe.io.Bytes.ofString(content, UTF8);

    return {
      fileName: name,
      fileSize: data.length,

      data: data,
      dataSize: data.length,

      compressed: false,

      fileTime: Date.now(),
      crc32: null,
      extraFields: null,
    };
  }

  static function convertTypeFilter(typeFilter:Array<FileFilter>):String
  {
    var filter = null;
    if (typeFilter != null)
    {
      var filters = [];
      for (type in typeFilter)
      {
        filters.push(StringTools.replace(StringTools.replace(type.extension, "*.", ""), ";", ","));
      }
      filter = filters.join(";");
    }

    return filter;
  }
}

enum FileWriteMode
{
  /**
   * Forcibly overwrite the file if it already exists.
   */
  Force;

  /**
   * Ask the user if they want to overwrite the file if it already exists.
   */
  Ask;

  /**
   * Skip the file if it already exists.
   */
  Skip;
}
