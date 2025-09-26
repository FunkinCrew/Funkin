package funkin.util;

import haxe.zip.Entry;
import lime.utils.Bytes;
import lime.ui.FileDialog;
import openfl.net.FileFilter;
import haxe.io.Path;
import openfl.net.FileReference;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.dialogs.Dialogs.SelectedFileInfo;
import haxe.ui.containers.dialogs.Dialogs.FileDialogExtensionInfo;

using StringTools;

/**
 * Utilities for reading and writing files on various platforms.
 */
@:nullSafety
class FileUtil
{
  public static final FILE_FILTER_FNFC:FileFilter = new FileFilter("Friday Night Funkin' Chart (.fnfc)", "*.fnfc");
  public static final FILE_FILTER_JSON:FileFilter = new FileFilter("JSON Data File (.json)", "*.json");
  public static final FILE_FILTER_ZIP:FileFilter = new FileFilter("ZIP Archive (.zip)", "*.zip");
  public static final FILE_FILTER_PNG:FileFilter = new FileFilter("PNG Image (.png)", "*.png");
  public static final FILE_FILTER_FNFS:FileFilter = new FileFilter("Friday Night Funkin' Stage (.fnfs)", "*.fnfs");

  public static final FILE_EXTENSION_INFO_FNFC:FileDialogExtensionInfo =
    {
      extension: 'fnfc',
      label: 'Friday Night Funkin\' Chart',
    };
  public static final FILE_EXTENSION_INFO_ZIP:FileDialogExtensionInfo =
    {
      extension: 'zip',
      label: 'ZIP Archive',
    };
  public static final FILE_EXTENSION_INFO_PNG:FileDialogExtensionInfo =
    {
      extension: 'png',
      label: 'PNG Image',
    };

  public static final FILE_EXTENSION_INFO_FNFS:FileDialogExtensionInfo =
    {
      extension: 'fnfs',
      label: 'Friday Night Funkin\' Stage',
    };

  /**
   * Paths which should not be deleted or modified by scripts.
   */
  public static var PROTECTED_PATHS(get, never):Array<String>;

  public static function get_PROTECTED_PATHS():Array<String>
  {
    final protected:Array<String> = [
      '',
      '.',
      'assets',
      'assets/*',
      'backups',
      'backups/*',
      'manifest',
      'manifest/*',
      'plugins',
      'plugins/*',
      'Funkin.exe',
      'Funkin',
      'icon.ico',
      'libvlc.dll',
      'libvlccore.dll',
      'lime.ndll',
      'scores.json'
    ];

    #if sys
    for (i in 0...protected.length)
    {
      protected[i] = sys.FileSystem.fullPath(Path.join([gameDirectory, protected[i]]));
    }
    #end

    return protected;
  }

  /**
   * Regex for invalid filesystem characters.
   */
  public static final INVALID_CHARS:EReg = ~/[:*?"<>|\n\r\t]/g;

  #if sys
  private static var _gameDirectory:Null<String> = null;
  public static var gameDirectory(get, never):String;

  public static function get_gameDirectory():String
  {
    if (_gameDirectory != null)
    {
      return _gameDirectory;
    }

    return _gameDirectory = sys.FileSystem.fullPath(Path.directory(Sys.programPath()));
  }
  #end

  /**
   * Browses for a single file, then calls `onSelect(fileInfo)` when a file is selected.
   * Powered by HaxeUI, so it works on all platforms.
   * File contents will be binary, not String.
   *
   * @param typeFilter
   * @param onSelect A callback that provides a `SelectedFileInfo` object when a file is selected.
   * @param onCancel A callback that is called when the user closes the dialog without selecting a file.
   */
  public static function browseForBinaryFile(dialogTitle:String, ?typeFilter:Array<FileDialogExtensionInfo>, onSelect:(SelectedFileInfo) -> Void,
      ?onCancel:() -> Void)
  {
    var onComplete = function(button, selectedFiles) {
      if (button == DialogButton.OK && selectedFiles.length > 0)
      {
        onSelect(selectedFiles[0]);
      }
      else if (onCancel != null)
      {
        onCancel();
      }
    };

    Dialogs.openFile(onComplete,
      {
        readContents: true,
        readAsBinary: true, // Binary
        multiple: false,
        extensions: typeFilter ?? new Array<FileDialogExtensionInfo>(),
        title: dialogTitle,
      });
  }

  /**
   * Browses for a single file, then calls `onSelect(fileInfo)` when a file is selected.
   * Powered by HaxeUI, so it works on all platforms.
   * File contents will be a String, not binary.
   *
   * @param typeFilter
   * @param onSelect A callback that provides a `SelectedFileInfo` object when a file is selected.
   * @param onCancel A callback that is called when the user closes the dialog without selecting a file.
   */
  public static function browseForTextFile(dialogTitle:String, ?typeFilter:Array<FileDialogExtensionInfo>, onSelect:(SelectedFileInfo) -> Void,
      ?onCancel:() -> Void):Void
  {
    var onComplete = function(button, selectedFiles) {
      if (button == DialogButton.OK && selectedFiles.length > 0)
      {
        onSelect(selectedFiles[0]);
      }
      else if (onCancel != null)
      {
        onCancel();
      }
    };

    Dialogs.openFile(onComplete,
      {
        readContents: true,
        readAsBinary: false, // Text
        multiple: false,
        extensions: typeFilter ?? new Array<FileDialogExtensionInfo>(),
        title: dialogTitle,
      });
  }

  /**
   * Browses for a directory, then calls `onSelect(path)` when a path chosen.
   * Note that on HTML5 this will immediately fail.
   *
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForDirectory(?typeFilter:Array<FileFilter>, onSelect:(String) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter:Null<String> = convertTypeFilter(typeFilter);
    var fileDialog:FileDialog = new FileDialog();
    fileDialog.onSelect.add(onSelect);
    if (onCancel != null)
    {
      fileDialog.onCancel.add(onCancel);
    }

    fileDialog.browse(OPEN_DIRECTORY, filter, defaultPath, dialogTitle);

    return true;
    #else
    trace('WARNING: browseForDirectory not implemented for this platform');

    if (onCancel != null)
    {
      onCancel();
    }

    return false;
    #end
  }

  /**
   * Browses for multiple file, then calls `onSelect(paths)` when a path chosen.
   * Note that on HTML5 this will immediately fail.
   *
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForMultipleFiles(?typeFilter:Array<FileFilter>, onSelect:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter:Null<String> = convertTypeFilter(typeFilter);
    var fileDialog:FileDialog = new FileDialog();
    fileDialog.onSelectMultiple.add(onSelect);
    if (onCancel != null)
    {
      fileDialog.onCancel.add(onCancel);
    }

    fileDialog.browse(OPEN_MULTIPLE, filter, defaultPath, dialogTitle);

    return true;
    #else
    trace('WARNING: browseForMultipleFiles not implemented for this platform');

    if (onCancel != null)
    {
      onCancel();
    }

    return false;
    #end
  }

  /**
   * Browses for a file location to save to, then calls `onSave(path)` when a path chosen.
   * Note that on HTML5 you can't do much with this, you should call `saveFile(resource:haxe.io.Bytes)` instead.
   *
   * @param typeFilter TODO What does this do?
   * @return Whether the file dialog was opened successfully.
   */
  public static function browseForSaveFile(?typeFilter:Array<FileFilter>, onSelect:(String) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter:Null<String> = convertTypeFilter(typeFilter);
    var fileDialog:FileDialog = new FileDialog();
    fileDialog.onSelect.add(onSelect);
    if (onCancel != null)
    {
      fileDialog.onCancel.add(onCancel);
    }

    fileDialog.browse(SAVE, filter, defaultPath, dialogTitle);

    return true;
    #else
    trace('WARNING: browseForSaveFile not implemented for this platform');

    if (onCancel != null)
    {
      onCancel();
    }

    return false;
    #end
  }

  /**
   * Browses for a single file location, then writes the provided `haxe.io.Bytes` data and calls `onSave(path)` when done.
   * Works great on desktop and HTML5.
   *
   * @return Whether the file dialog was opened successfully.
   */
  public static function saveFile(data:Bytes, ?typeFilter:Array<FileFilter>, ?onSave:(String) -> Void, ?onCancel:() -> Void, ?defaultFileName:String,
      ?dialogTitle:String):Bool
  {
    #if desktop
    var filter:Null<String> = convertTypeFilter(typeFilter);
    var fileDialog:FileDialog = new FileDialog();
    if (onSave != null)
    {
      fileDialog.onSave.add(onSave);
    }

    if (onCancel != null)
    {
      fileDialog.onCancel.add(onCancel);
    }

    fileDialog.save(data, filter, defaultFileName, dialogTitle);

    return true;
    #elseif html5
    var filter:Null<String> = defaultFileName != null ? Path.extension(defaultFileName) : null;
    var fileDialog:FileDialog = new FileDialog();
    if (onSave != null)
    {
      fileDialog.onSave.add(onSave);
    }

    if (onCancel != null)
    {
      fileDialog.onCancel.add(onCancel);
    }

    fileDialog.save(data, filter, defaultFileName, dialogTitle);

    return true;
    #else
    trace('WARNING: saveFile not implemented for this platform');

    if (onCancel != null)
    {
      onCancel();
    }

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
  public static function saveMultipleFiles(resources:Array<Entry>, ?onSaveAll:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    #if desktop
    // Prompt the user for a directory, then write all of the files to there.
    var onSelectDir:(String) -> Void = function(targetPath:String):Void {
      var paths:Array<String> = new Array<String>();
      for (resource in resources)
      {
        /*
          var filePath:String = Path.join([targetPath, resource.fileName]);
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
            throw 'Failed to write file (probably already exists): $filePath';
          }
         */
        if (resource.data == null)
        {
          trace('WARNING: File ${resource.fileName} has no data or content. Skipping.');
          continue;
        }

        var filePath:String = Path.join([targetPath, resource.fileName]);

        paths.push(filePath);
      }

      if (onSaveAll != null)
      {
        onSaveAll(paths);
      }
    }

    trace('Browsing for directory to save individual files to...');

    #if mac
    defaultPath = null;
    #end

    browseForDirectory(null, onSelectDir, onCancel, defaultPath, 'Choose directory to save all files to...');

    return true;
    #elseif html5
    saveFilesAsZIP(resources, onSaveAll, onCancel, defaultPath, force);

    return true;
    #else
    trace('WARNING: saveMultipleFiles not implemented for this platform');

    if (onCancel != null)
    {
      onCancel();
    }

    return false;
    #end
  }

  /**
   * Takes an array of file entries and prompts the user to save them as a ZIP file.
   */
  public static function saveFilesAsZIP(resources:Array<Entry>, ?onSave:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    // Create a ZIP file.
    var zipBytes:Bytes = createZIPFromEntries(resources);
    var onSave:(String) -> Void = function(path:String) {
      trace('Saved ${resources.length} files to ZIP at "$path"');

      if (onSave != null)
      {
        onSave([path]);
      }
    };

    // Prompt the user to save the ZIP file.
    saveFile(zipBytes, [FILE_FILTER_ZIP], onSave, onCancel, defaultPath, 'Save files as ZIP...');
    return true;
  }

  /**
   * Takes an array of file entries and prompts the user to save them as a FNFC file.
   */
  public static function saveChartAsFNFC(resources:Array<Entry>, ?onSave:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    // Create a ZIP file.
    var zipBytes:Bytes = createZIPFromEntries(resources);
    var onSave:(String) -> Void = function(path:String) {
      trace('Saved FNFC file to "$path"');

      if (onSave != null)
      {
        onSave([path]);
      }
    };
    // Prompt the user to save the ZIP file.
    saveFile(zipBytes, [FILE_FILTER_FNFC], onSave, onCancel, defaultPath, 'Save chart as FNFC...');
    return true;
  }

  /**
   * Takes an array of file entries and forcibly writes a ZIP to the given path.
   * Only works on native, because HTML5 doesn't allow you to write files to arbitrary paths.
   * Use `saveFilesAsZIP` instead.
   * @param force Whether to force overwrite an existing file.
   */
  public static function saveFilesAsZIPToPath(resources:Array<Entry>, path:String, mode:FileWriteMode = Skip):Bool
  {
    #if sys
    // Create a ZIP file.
    var zipBytes:Bytes = createZIPFromEntries(resources);
    // Write the ZIP.
    writeBytesToPath(path, zipBytes, mode);
    return true;
    #else
    return false;
    #end
  }

  /**
   * Read string file contents directly from a given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @return The file contents.
   */
  public static function readStringFromPath(path:String):String
  {
    #if sys
    return sys.io.File.getContent(path);
    #else
    throw 'Direct file reading by path is not supported on this platform.';
    #end
  }

  /**
   * Read bytes file contents directly from a given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @return The file contents.
   */
  public static function readBytesFromPath(path:String):Bytes
  {
    #if sys
    return sys.io.File.getBytes(path);
    #else
    throw 'Direct file reading by path is not supported on this platform.';
    #end
  }

  /**
   * Browse for a file to read and execute a callback once we have a file reference.
   * Works great on HTML5 or desktop.
   *
   * @param	callback The function to call when the file is loaded.
   */
  public static function browseFileReference(callback:(FileReference) -> Void):Void
  {
    var file = new FileReference();
    file.addEventListener(Event.SELECT, function(e) {
      var selectedFileRef:FileReference = e.target;
      trace('Selected file: ' + selectedFileRef.name);

      selectedFileRef.addEventListener(Event.COMPLETE, function(e) {
        var loadedFileRef:FileReference = e.target;
        trace('Loaded file: ' + loadedFileRef.name);

        callback(loadedFileRef);
      });

      selectedFileRef.load();
    });

    file.browse();
  }

  /**
   * Prompts the user to save a file to their computer.
   */
  public static function writeFileReference(path:String, data:String, callback:String->Void)
  {
    var file = new FileReference();

    file.addEventListener(Event.COMPLETE, function(e:Event) {
      trace('Successfully wrote file: "$path"');
      callback("success");
    });

    file.addEventListener(Event.CANCEL, function(e:Event) {
      trace('Cancelled writing file: "$path"');
      callback("info");
    });

    file.addEventListener(IOErrorEvent.IO_ERROR, function(e:IOErrorEvent) {
      trace('IO error writing file: "$path"');
      callback("error");
    });

    file.save(data, path);
  }

  /**
   * Read JSON file contents directly from a given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @return The JSON data.
   */
  public static function readJSONFromPath(path:String):Dynamic
  {
    #if sys
    return SerializerUtil.fromJSON(sys.io.File.getContent(path));
    #else
    throw 'Direct file reading by path is not supported on this platform.';
    #end
  }

  /**
   * Write string file contents directly to a given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @param data The string to write.
   * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
   */
  public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip):Void
  {
    #if sys
    if (directoryExists(path))
    {
      throw 'Target path is a directory, not a file: "$path"';
    }

    createDirIfNotExists(Path.directory(path));

    switch (mode)
    {
      case Force:
        sys.io.File.saveContent(path, data);
      case Skip:
        if (!pathExists(path))
        {
          sys.io.File.saveContent(path, data);
        }
      case Ask:
        if (pathExists(path))
        {
          // TODO: We don't have the technology to use native popups yet.
          throw 'Entry at path already exists: $path';
        }
        else
        {
          sys.io.File.saveContent(path, data);
        }
    }
    #else
    throw 'Direct file writing by path is not supported on this platform.';
    #end
  }

  /**
   * Write byte file contents directly to a given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @param data The bytes to write.
   * @param mode Whether to Force, Skip, or Ask to overwrite an existing file.
   */
  public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void
  {
    #if sys
    if (directoryExists(path))
    {
      throw 'Target path is a directory, not a file: "$path"';
    }

    var shouldWrite:Bool = true;
    switch (mode)
    {
      case Force:
        shouldWrite = true;
      case Skip:
        if (!pathExists(path))
        {
          shouldWrite = true;
        }
      case Ask:
        if (pathExists(path))
        {
          // TODO: We don't have the technology to use native popups yet.
          throw 'Entry at path already exists: "$path"';
        }
        else
        {
          shouldWrite = true;
        }
    }

    if (shouldWrite)
    {
      createDirIfNotExists(Path.directory(path));
      sys.io.File.saveBytes(path, data);
    }
    #else
    throw 'Direct file writing by path is not supported on this platform.';
    #end
  }

  /**
   * Write string file contents directly to the end of a file at the given path.
   * Only works on native.
   *
   * @param path The path to the file.
   * @param data The string to append.
   */
  public static function appendStringToPath(path:String, data:String):Void
  {
    #if sys
    if (!pathExists(path))
    {
      writeStringToPath(path, data, Force);
      return;
    }
    else if (directoryExists(path))
    {
      throw 'Target path is a directory, not a file: "$path"';
    }

    var output:Null<sys.io.FileOutput> = null;
    try
    {
      output = sys.io.File.append(path, false);
      output.writeString(data);
      output.close();
    }
    catch (e:Dynamic)
    {
      if (output != null)
      {
        output.close();
      }

      throw 'Failed to append to file: "$path"';
    }
    #else
    throw 'Direct file writing by path is not supported on this platform.';
    #end
  }

  /**
   * Moves a file from one location to another.
   * Only works on native.
   *
   * @param path The path to the file.
   * @param destination The path to move the file to.
   */
  public static function moveFile(path:String, destination:String):Void
  {
    #if sys
    if (Path.extension(destination) != '')
    {
      destination = Path.directory(destination);
    }

    sys.FileSystem.rename(path, Path.join([destination, Path.withoutDirectory(path)]));
    #else
    throw 'File moving is not supported on this platform.';
    #end
  }

  /**
   * Delete a file at the given path.
   * Only works on native.
   *
   * @param path The path to the file.
   */
  public static function deleteFile(path:String):Void
  {
    #if sys
    sys.FileSystem.deleteFile(path);
    #else
    throw 'File deletion is not supported on this platform.';
    #end
  }

  /**
   * Get a file's size in bytes. Max representable size is ~2.147 GB.
   * Only works on native.
   *
   * @param path The path to the file.
   * @return The size of the file in bytes.
   */
  public static function getFileSize(path:String):Int
  {
    #if sys
    return sys.FileSystem.stat(path).size;
    #else
    throw 'File size calculation is not supported on this platform.';
    #end
  }

  /**
   * Check if a path exists on the filesystem.
   * Only works on native.
   *
   * @param path The path to the potential file or directory.
   * @return Whether the path exists.
   */
  public static function pathExists(path:String):Bool
  {
    #if sys
    return sys.FileSystem.exists(path);
    #else
    return false;
    #end
  }

  /**
   * Check if a path is a file on the filesystem.
   * Only works on native.
   *
   * @param path The path to the potential file.
   * @return Whether the path exists and is a file.
   */
  public static function fileExists(path:String):Bool
  {
    #if sys
    return pathExists(path) && !directoryExists(path);
    #else
    throw 'Filesystem check is not supported on this platform.';
    #end
  }

  /**
   * Check if a path is a directory on the filesystem.
   * Only works on native.
   *
   * @param path The path to the potential directory.
   * @return Whether the path exists and is a directory.
   */
  public static function directoryExists(path:String):Bool
  {
    #if sys
    try
    {
      return sys.FileSystem.isDirectory(path);
    }
    catch (e:Dynamic)
    {
      return false;
    }
    #else
    throw 'Filesystem check is not supported on this platform.';
    #end
  }

  /**
   * Create a directory if it doesn't already exist.
   * Only works on native.
   *
   * @param dir The path to the directory.
   */
  public static function createDirIfNotExists(dir:String):Void
  {
    if (!directoryExists(dir))
    {
      #if sys
      sys.FileSystem.createDirectory(dir);
      #else
      throw 'Directory creation is not supported on this platform.';
      #end
    }
  }

  /**
   * List all entries in a directory.
   * Only works on native.
   *
   * @param path The path to the directory.
   * @return An array of entries in the directory.
   */
  public static function readDir(path:String):Array<String>
  {
    #if sys
    return sys.FileSystem.readDirectory(path);
    #else
    throw 'Directory reading is not supported on this platform.';
    #end
  }

  /**
   * Move a directory from one location to another, optionally ignoring some paths.
   * Only works on native.
   *
   * @param path The path to the directory.
   * @param destination The path to move the directory to.
   * @param ignore A list of paths to ignore.
   * @param strict Fails if the destination directory is not empty.
   */
  public static function moveDir(path:String, destination:String, ?ignore:Array<String>, strict:Bool = true):Void
  {
    #if sys
    if (!directoryExists(path))
    {
      throw 'Path is not a directory: "$path"';
    }

    createDirIfNotExists(destination);
    if (strict)
    {
      // Ensure the destination is empty if strict mode is enabled.
      var entries:Array<String> = readDir(destination);
      if (entries.length > 0)
      {
        throw 'Destination directory "$destination" is not empty.';
      }
    }

    var stack:Array<String> = [path];
    while (stack.length > 0)
    {
      var currentPath:Null<String> = stack.pop();
      if (currentPath == null) continue;

      var entries:Array<String> = readDir(currentPath);
      for (entry in entries)
      {
        var entryPath:String = Path.join([currentPath, entry]);
        if (ignore != null && ignore.contains(entryPath)) continue;
        if (directoryExists(entryPath))
        {
          stack.push(entryPath);
        }
        else
        {
          moveFile(entryPath, Path.join([destination, entry]));
        }
      }
    }

    if (readDir(path)?.length == 0)
    {
      deleteDir(path);
    }
    #else
    throw 'Directory moving is not supported on this platform.';
    #end
  }

  /**
   * Delete a directory, optionally including its contents, and optionally ignoring some paths.
   * Only works on native.
   *
   * @param path The path to the directory.
   * @param recursive Whether to delete all contents of the directory.
   * @param ignore A list of paths to ignore.
   */
  public static function deleteDir(path:String, recursive:Bool = false, ?ignore:Array<String>):Void
  {
    #if sys
    if (!directoryExists(path))
    {
      throw 'Path is not a valid directory: "$path"';
    }

    if (recursive)
    {
      var stack:Array<String> = [path];
      while (stack.length > 0)
      {
        var currentPath:Null<String> = stack.pop();
        if (currentPath == null) continue;

        var entries:Array<String> = readDir(currentPath);
        for (entry in entries)
        {
          var entryPath:String = Path.join([currentPath, entry]);
          if (ignore != null && ignore.contains(entryPath)) continue;
          if (directoryExists(entryPath))
          {
            stack.push(entryPath);
          }
          else
          {
            deleteFile(entryPath);
          }
        }
      }
    }
    else
    {
      sys.FileSystem.deleteDirectory(path);
    }
    #else
    throw 'Directory deletion is not supported on this platform.';
    #end
  }

  /**
   * Get a directory's total size in bytes. Max representable size is ~2.147 GB.
   * Only works on native.
   *
   * @param path The path to the directory.
   * @return The total size of the directory in bytes.
   */
  public static function getDirSize(path:String):Int
  {
    #if sys
    if (!directoryExists(path))
    {
      throw 'Path is not a valid directory path: $path';
    }

    var stack:Array<String> = [path];
    var total:Int = 0;
    while (stack.length > 0)
    {
      var currentPath:Null<String> = stack.pop();
      if (currentPath == null) continue;

      for (entry in readDir(currentPath))
      {
        var entryPath:String = Path.join([currentPath, entry]);
        if (directoryExists(entryPath))
        {
          stack.push(entryPath);
        }
        else
        {
          total += getFileSize(entryPath);
        }
      }
    }

    return total;
    #else
    throw 'Directory size calculation not supported on this platform.';
    #end
  }

  static var tempDir:Null<String> = null;
  static final TEMP_ENV_VARS:Array<String> = ['TEMP', 'TMPDIR', 'TEMPDIR', 'TMP'];

  /**
   * Get the path to a temporary directory we can use for writing files.
   * Only works on native.
   *
   * @return The path to the temporary directory.
   */
  public static function getTempDir():Null<String>
  {
    if (tempDir != null) return tempDir;
    #if sys
    #if windows
    var path:Null<String> = null;
    for (envName in TEMP_ENV_VARS)
    {
      path = Sys.getEnv(envName);
      if (path == '') path = null;
      if (path != null) break;
    }
    tempDir = Path.join([path ?? '', 'funkin/']);
    return tempDir;
    #elseif android
    tempDir = Path.addTrailingSlash(extension.androidtools.content.Context.getCacheDir());
    return tempDir;
    #else
    tempDir = '/tmp/funkin/';
    return tempDir;
    #end
    #else
    return null;
    #end
  }

  /**
   * Rename a file or directory.
   * Only works on native.
   *
   * @param path The path to the file or directory.
   * @param newName The new name of the file or directory.
   * @param keepExtension Whether to keep the extension the same, if applicable.
   */
  public static function rename(path:String, newName:String, keepExtension:Bool = true):Void
  {
    #if sys
    if (!pathExists(path))
    {
      throw 'Path does not exist: "$path"';
    }

    final isDirectory:Bool = directoryExists(path);
    newName = Path.withoutDirectory(newName);
    if (isDirectory)
    {
      newName = Path.withoutExtension(newName);
    }
    else if (keepExtension)
    {
      newName = Path.withExtension(newName, Path.extension(path));
    }

    newName = Path.join([Path.directory(path), newName]);
    if (newName == path)
    {
      return;
    }

    if (pathExists(newName))
    {
      // Prevent overwriting something.
      throw 'Destination path already exists: "$newName"';
    }

    sys.FileSystem.rename(path, newName);
    #else
    throw 'File renaming by path is not supported on this platform.';
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
    var o:haxe.io.BytesOutput = new haxe.io.BytesOutput();
    var zipWriter:haxe.zip.Writer = new haxe.zip.Writer(o);
    zipWriter.write(entries.list());
    return o.getBytes();
  }

  public static function readZIPFromBytes(input:Bytes):Array<Entry>
  {
    var bytesInput = new haxe.io.BytesInput(input);
    var zippedEntries = haxe.zip.Reader.readZip(bytesInput);
    var results:Array<Entry> = new Array<Entry>();
    for (entry in zippedEntries)
    {
      if (entry.compressed)
      {
        entry.data = haxe.zip.Reader.unzip(entry);
      }

      results.push(entry);
    }

    return results;
  }

  public static function mapZIPEntriesByName(input:Array<Entry>):Map<String, Entry>
  {
    var results:Map<String, Entry> = new Map<String, Entry>();
    for (entry in input)
    {
      results.set(entry.fileName, entry);
    }

    return results;
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
    var data:Bytes = haxe.io.Bytes.ofString(content, UTF8);
    return makeZIPEntryFromBytes(name, data);
  }

  /**
   * Create a ZIP file entry from a file name and its string contents.
   *
   * @param name The name of the file. You can use slashes to create subdirectories.
   * @param data The byte data of the file.
   * @return The resulting entry.
   */
  public static function makeZIPEntryFromBytes(name:String, data:haxe.io.Bytes):Entry
  {
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

  /**
   * Runs platform-specific code to open a path in the file explorer.
   *
   * @param pathFolder The path of the folder to open.
   * @param createIfNotExists If `true`, creates the folder if missing; otherwise, throws an error.
   */
  public static function openFolder(pathFolder:String, createIfNotExists:Bool = true):Void
  {
    #if sys
    pathFolder = pathFolder.trim();
    if (createIfNotExists)
    {
      createDirIfNotExists(pathFolder);
    }
    else if (!directoryExists(pathFolder))
    {
      throw 'Path is not a directory: "$pathFolder"';
    }

    #if windows
    Sys.command('explorer', [pathFolder.replace('/', '\\')]);
    #elseif mac
    // mac could be fuckie with where the log folder is relative to the game file...
    // if this comment is still here... it means it has NOT been verified on mac yet!
    //
    // FileUtil.hx note: this was originally used to open the logs specifically!
    // thats why the above comment is there!
    Sys.command('open', [pathFolder]);
    #elseif linux
    // TODO: implement linux
    // some shit with xdg-open :thinking: emoji...
    #end
    #else
    throw 'External folder open is not supported on this platform.';
    #end
  }

  /**
   * Runs platform-specific code to open a file explorer and select a specific file.
   *
   * @param path The path of the file to select.
   */
  public static function openSelectFile(path:String):Void
  {
    #if sys
    path = path.trim();
    if (!pathExists(path))
    {
      throw 'Path does not exist: "$path"';
    }

    #if windows
    Sys.command('explorer', ['/select,', path.replace('/', '\\')]);
    #elseif mac
    Sys.command('open', ['-R', path]);
    #elseif linux
    // TODO: unsure of the linux equivalent to opening a folder and then "selecting" a file.
    Sys.command('open', [path]);
    #end
    #else
    throw 'External file selection is not supported on this platform.';
    #end
  }

  private static function convertTypeFilter(?typeFilter:Array<FileFilter>):Null<String>
  {
    var filter:Null<String> = null;
    if (typeFilter != null)
    {
      var filters:Array<String> = new Array<String>();
      for (type in typeFilter)
      {
        filters.push(type.extension.replace('*.', '').replace(';', ','));
      }

      filter = filters.join(';');
    }

    return filter;
  }
}

/**
 * Utilities for reading and writing files on various platforms.
 * Wrapper for `FileUtil` that sanitizes paths for script safety.
 */
@:nullSafety
class FileUtilSandboxed
{
  /**
   * Prevent paths from exiting the root.
   *
   * @param path The path to sanitize.
   * @return The sanitized path.
   */
  public static function sanitizePath(path:String):String
  {
    path = (path ?? '').trim();
    if (path == '')
    {
      #if sys
      return FileUtil.gameDirectory;
      #else
      return '';
      #end
    }

    if (path.contains(':'))
    {
      path = path.substring(path.lastIndexOf(':') + 1);
    }

    path = path.replace('\\', '/');
    while (path.contains('//'))
    {
      path = path.replace('//', '/');
    }

    final parts:Array<String> = FileUtil.INVALID_CHARS.replace(path, '').split('/');
    final sanitized:Array<String> = new Array<String>();
    for (part in parts)
    {
      switch (part)
      {
        case '.' | '':
          continue;
        case '..':
          sanitized.pop();
        default:
          sanitized.push(part.trim());
      }
    }

    if (sanitized.length == 0)
    {
      #if sys
      return FileUtil.gameDirectory;
      #else
      return '';
      #end
    }

    #if sys
    // TODO: figure out how to get "real" path of symlinked paths
    final realPath:String = sys.FileSystem.fullPath(Path.join([FileUtil.gameDirectory, sanitized.join('/')]));
    if (!realPath.startsWith(FileUtil.gameDirectory))
    {
      return FileUtil.gameDirectory;
    }

    return realPath;
    #else
    return sanitized.join('/');
    #end
  }

  /**
   * Check against protected paths.
   * @param path The path to check.
   * @return Whether the path is protected.
   */
  public static function isProtected(path:String, sanitizeFirst:Bool = true):Bool
  {
    if (sanitizeFirst) path = sanitizePath(path);
    @:privateAccess for (protected in FileUtil.PROTECTED_PATHS)
    {
      if (path == protected || (protected.contains('*') && path.startsWith(protected.substring(0, protected.indexOf('*')))))
      {
        return true;
      }
    }

    return false;
  }

  public static final FILE_FILTER_FNFC:FileFilter = FileUtil.FILE_FILTER_FNFC;
  public static final FILE_FILTER_JSON:FileFilter = FileUtil.FILE_FILTER_JSON;
  public static final FILE_FILTER_ZIP:FileFilter = FileUtil.FILE_FILTER_ZIP;
  public static final FILE_FILTER_PNG:FileFilter = FileUtil.FILE_FILTER_PNG;

  public static final FILE_EXTENSION_INFO_FNFC:FileDialogExtensionInfo = FileUtil.FILE_EXTENSION_INFO_FNFC;
  public static final FILE_EXTENSION_INFO_ZIP:FileDialogExtensionInfo = FileUtil.FILE_EXTENSION_INFO_ZIP;
  public static final FILE_EXTENSION_INFO_PNG:FileDialogExtensionInfo = FileUtil.FILE_EXTENSION_INFO_PNG;

  public static function browseForBinaryFile(dialogTitle:String, ?typeFilter:Array<FileDialogExtensionInfo>, onSelect:(SelectedFileInfo) -> Void,
      ?onCancel:() -> Void)
  {
    FileUtil.browseForBinaryFile(dialogTitle, typeFilter, onSelect, onCancel);
  }

  public static function browseForTextFile(dialogTitle:String, ?typeFilter:Array<FileDialogExtensionInfo>, onSelect:(SelectedFileInfo) -> Void,
      ?onCancel:() -> Void):Void
  {
    FileUtil.browseForTextFile(dialogTitle, typeFilter, onSelect, onCancel);
  }

  public static function browseForDirectory(?typeFilter:Array<FileFilter>, onSelect:(String) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    return FileUtil.browseForDirectory(typeFilter, onSelect, onCancel, defaultPath, dialogTitle);
  }

  public static function browseForMultipleFiles(?typeFilter:Array<FileFilter>, onSelect:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    return FileUtil.browseForMultipleFiles(typeFilter, onSelect, onCancel, defaultPath, dialogTitle);
  }

  public static function browseForSaveFile(?typeFilter:Array<FileFilter>, onSelect:(String) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      ?dialogTitle:String):Bool
  {
    return FileUtil.browseForSaveFile(typeFilter, onSelect, onCancel, defaultPath, dialogTitle);
  }

  public static function saveFile(data:Bytes, ?typeFilter:Array<FileFilter>, ?onSave:(String) -> Void, ?onCancel:() -> Void, ?defaultFileName:String,
      ?dialogTitle:String):Bool
  {
    return FileUtil.saveFile(data, typeFilter, onSave, onCancel, defaultFileName, dialogTitle);
  }

  public static function saveMultipleFiles(resources:Array<Entry>, ?onSaveAll:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    return FileUtil.saveMultipleFiles(resources, onSaveAll, onCancel, defaultPath, force);
  }

  public static function saveFilesAsZIP(resources:Array<Entry>, ?onSave:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    return FileUtil.saveFilesAsZIP(resources, onSave, onCancel, defaultPath, force);
  }

  public static function saveChartAsFNFC(resources:Array<Entry>, ?onSave:(Array<String>) -> Void, ?onCancel:() -> Void, ?defaultPath:String,
      force:Bool = false):Bool
  {
    return FileUtil.saveChartAsFNFC(resources, onSave, onCancel, defaultPath, force);
  }

  public static function saveFilesAsZIPToPath(resources:Array<Entry>, path:String, mode:FileWriteMode = Skip):Bool
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
    return FileUtil.saveFilesAsZIPToPath(resources, path, mode);
  }

  public static function readStringFromPath(path:String):String
  {
    return FileUtil.readStringFromPath(sanitizePath(path));
  }

  public static function readBytesFromPath(path:String):Bytes
  {
    return FileUtil.readBytesFromPath(sanitizePath(path));
  }

  public static function browseFileReference(callback:(FileReference) -> Void):Void
  {
    FileUtil.browseFileReference(callback);
  }

  public static function writeFileReference(path:String, data:String, callback:String->Void):Void
  {
    FileUtil.writeFileReference(path, data, callback);
  }

  public static function readJSONFromPath(path:String):Dynamic
  {
    return FileUtil.readJSONFromPath(sanitizePath(path));
  }

  public static function writeStringToPath(path:String, data:String, mode:FileWriteMode = Skip):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
    FileUtil.writeStringToPath(path, data, mode);
  }

  public static function writeBytesToPath(path:String, data:Bytes, mode:FileWriteMode = Skip):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
    FileUtil.writeBytesToPath(path, data, mode);
  }

  public static function appendStringToPath(path:String, data:String):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot write to protected path: $path';
    FileUtil.appendStringToPath(path, data);
  }

  public static function moveFile(path:String, destination:String):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot move protected path: $path';
    if (isProtected(destination = sanitizePath(destination), false)) throw 'Cannot move to protected path: $destination';
    FileUtil.moveFile(path, destination);
  }

  public static function deleteFile(path:String):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot delete protected path: $path';
    FileUtil.deleteFile(path);
  }

  public static function getFileSize(path:String):Int
  {
    return FileUtil.getFileSize(sanitizePath(path));
  }

  public static function pathExists(path:String):Bool
  {
    return FileUtil.pathExists(sanitizePath(path));
  }

  public static function fileExists(path:String):Bool
  {
    return FileUtil.fileExists(sanitizePath(path));
  }

  public static function directoryExists(path:String):Bool
  {
    return FileUtil.directoryExists(sanitizePath(path));
  }

  public static function createDirIfNotExists(dir:String):Void
  {
    FileUtil.createDirIfNotExists(sanitizePath(dir));
  }

  public static function readDir(path:String):Array<String>
  {
    return FileUtil.readDir(sanitizePath(path));
  }

  public static function moveDir(path:String, destination:String, ?ignore:Array<String>, strict:Bool = true):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot move protected path: "$path"';
    if (isProtected(destination = sanitizePath(destination), false)) throw 'Cannot move to protected path: "$destination"';
    FileUtil.moveDir(path, destination, ignore, strict);
  }

  public static function deleteDir(path:String, recursive:Bool = false, ?ignore:Array<String>):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot delete protected path: "$path"';
    FileUtil.deleteDir(path, recursive, ignore);
  }

  public static function getDirSize(path:String):Int
  {
    return FileUtil.getDirSize(sanitizePath(path));
  }

  public static function getTempDir():Null<String>
  {
    return FileUtil.getTempDir();
  }

  public static function rename(path:String, newName:String, keepExtension:Bool = true):Void
  {
    if (isProtected(path = sanitizePath(path), false)) throw 'Cannot rename protected path: "$path"';
    FileUtil.rename(path, sanitizePath(newName), keepExtension);
  }

  public static function createZIPFromEntries(entries:Array<Entry>):Bytes
  {
    return FileUtil.createZIPFromEntries(entries);
  }

  public static function readZIPFromBytes(input:Bytes):Array<Entry>
  {
    return FileUtil.readZIPFromBytes(input);
  }

  public static function mapZIPEntriesByName(input:Array<Entry>):Map<String, Entry>
  {
    return FileUtil.mapZIPEntriesByName(input);
  }

  public static function makeZIPEntry(name:String, content:String):Entry
  {
    return FileUtil.makeZIPEntry(name, content);
  }

  public static function makeZIPEntryFromBytes(name:String, data:haxe.io.Bytes):Entry
  {
    return FileUtil.makeZIPEntryFromBytes(name, data);
  }

  public static function openFolder(pathFolder:String, createIfNotExists:Bool = true):Void
  {
    FileUtil.openFolder(sanitizePath(pathFolder), createIfNotExists);
  }

  public static function openSelectFile(path:String):Void
  {
    FileUtil.openSelectFile(sanitizePath(path));
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
