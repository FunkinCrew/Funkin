package funkin.ui.debug.stageeditor.handlers;

import funkin.util.DateUtil;
import funkin.util.FileUtil;
import funkin.util.SortUtil;
import haxe.io.Bytes;
import haxe.io.Path;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;
import funkin.play.character.BaseCharacter;
import funkin.ui.debug.stageeditor.components.StageEditorObject;
import openfl.display.BitmapData;

/**
 * Contains functions for importing, loading, saving, and exporting stages.
 */
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './backups/stages/';

  public static function loadStageAsTemplate(state:StageEditorState, stageId:String):Void
  {
    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);
    if (stage == null) return;

    var rawStageData:Null<StageData> = stage?._data;
    if (rawStageData == null) return;

    // Clone to prevent modifying the original.
    var stageData:StageData = rawStageData.clone();

    loadStage(state, stageData);

    state.isHaxeUIDialogOpen = false;
    state.currentWorkingFilePath = null; // New file, so no path.

    state.success('Success', 'Loaded stage (${stageData.name})');
  }

  /**
   * Loads the stage from given stage data into the editor.
   * @param newStageData The stage data to load.
   */
  public static function loadStage(state:StageEditorState, newStageData:StageData):Void
  {
    state.stageData = newStageData;
    state.clearAssets();
    StageEditorAssetHandler.bitmaps.clear();

    Paths.setCurrentLevel(state.currentStageDirectory);

    // Load characters
    loadCharacters(state, state.stageData.characters);

    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT);
    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT);
    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT);

    // Load props
    if (state.stageData.props != null)
    {
      for (propData in state.stageData.props)
      {
        var prop = new StageEditorObject();
        if (!propData.assetPath.startsWith('#')) StageEditorAssetHandler.bitmaps.set(propData.assetPath, Assets.getBitmapData(Paths.image(propData.assetPath)));

        var usePacker:Bool = propData.animType == "packer";
        var animPath:String = Paths.file("images/" + propData.assetPath + (usePacker ? ".txt" : ".xml"));
        var animText:String = Assets.exists(animPath) ? Assets.getText(animPath) : "";

        prop.fromData(
          {
            name: propData.name ?? 'Unnamed',
            assetPath: propData.assetPath,
            animations: propData.animations?.copy(),
            scale: propData.scale,
            position: propData.position,
            alpha: propData.alpha,
            angle: propData.angle,
            zIndex: propData.zIndex,
            danceEvery: propData.danceEvery,
            isPixel: propData.isPixel,
            scroll: propData.scroll?.copy(),
            color: propData.color,
            blend: propData.blend,
            flipX: propData.flipX,
            flipY: propData.flipY,
            startingAnimation: propData.startingAnimation,
            animData: animText,
          });

        state.add(prop);
      }

      state.sortObjects();
    }

    // Set the camera to be in the middle of girlfriend
    var gf:Null<BaseCharacter> = state.characters.get('gf');
    var gfData:Null<StageDataCharacter> = state.stageData.characters.gf;
    if (state.stageData.cameraZoom == null || gf == null || gfData == null) return;
    FlxG.camera.zoom = state.stageData.cameraZoom ?? 1.0;
    state.cameraFollowPoint.x = gf.cameraFocusPoint.x + (gfData.cameraOffsets != null ? gfData.cameraOffsets[0] : 0.0);
    state.cameraFollowPoint.y = gf.cameraFocusPoint.y + (gfData.cameraOffsets != null ? gfData.cameraOffsets[1] : 0.0);
  }

  /**
   * Load stage data from an FNFS file path.
   * @param state
   * @param path
   * @return `null` on failure, `[]` on success, `[warnings]` on success with warnings.
   */
  public static function loadFromFNFSPath(state:StageEditorState, path:String):Null<Array<String>>
  {
    var bytes:Null<Bytes> = FileUtil.readBytesFromPath(path);
    if (bytes == null) return null;

    trace('Loaded ${bytes.length} bytes from $path');

    var result:Null<Array<String>> = loadFromFNFS(state, bytes);
    if (result != null)
    {
      state.currentWorkingFilePath = path;
      state.saveDataDirty = false; // Just loaded file!
    }

    return result;
  }

  public static function loadFromFNFS(state:StageEditorState, bytes:Bytes):Null<Array<String>>
  {
    state.clearAssets();
    StageEditorAssetHandler.bitmaps.clear();

    var output:Array<String> = [];

    var fileEntries:Array<haxe.zip.Entry> = FileUtil.readZIPFromBytes(bytes);
    var mappedFileEntries:Map<String, haxe.zip.Entry> = FileUtil.mapZIPEntriesByName(fileEntries);
    var xmls:Map<String, String> = [];

    for (entry in mappedFileEntries)
    {
      if (entry == null || entry.data == null || entry.fileName == null) continue;
      var extension:Null<String> = entry.fileName.split('.').pop();
      if (extension == null) continue;

      switch (extension)
      {
        case "png", "jpg", "jpeg", "gif", "bmp":
          var bitmapData:BitmapData = BitmapData.fromBytes(entry.data);
          StageEditorAssetHandler.bitmaps.set(Path.withoutExtension(entry.fileName), bitmapData);

        case "xml":
          xmls.set(Path.withoutExtension(entry.fileName), entry.data.toString());

        case "json":
          state.stageData = StageRegistry.instance.parseEntryDataRaw(entry.data.toString(), entry.fileName.replace(extension, '')) ?? new StageData();
      }
    }

    if (state.stageData == null)
    {
      state.failure('Failed to Load Stage', 'No valid stage data found in the provided file.');
      return null;
    }

    // Load characters
    loadCharacters(state, state.stageData.characters);

    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT);
    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_CHARACTER_LAYOUT);
    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_OBJECT_PROPERTIES_LAYOUT);

    // Load props
    if (state.stageData.props != null)
    {
      for (propData in state.stageData.props)
      {
        var prop = new StageEditorObject();

        prop.fromData(
          {
            name: propData.name ?? 'Unnamed',
            assetPath: propData.assetPath,
            animations: propData.animations?.copy(),
            scale: propData.scale,
            position: propData.position,
            alpha: propData.alpha,
            angle: propData.angle,
            zIndex: propData.zIndex,
            danceEvery: propData.danceEvery,
            isPixel: propData.isPixel,
            scroll: propData.scroll?.copy(),
            color: propData.color,
            blend: propData.blend,
            flipX: propData.flipX,
            flipY: propData.flipY,
            startingAnimation: propData.startingAnimation,
            animData: xmls[propData.assetPath] ?? ''
          });

        state.add(prop);
      }

      state.sortObjects();
    }
    else
    {
      output.push('No props found in stage data.');
    }

    return output;
  }

  public static function loadCharacters(state:StageEditorState, characterDatas:StageDataCharacters):Void
  {
    for (charType => character in state.characters)
    {
      if (character == null) continue;
      var characterData:StageDataCharacter = Reflect.field(characterDatas, charType.toString().toLowerCase());
      if (characterData == null) continue;

      character.resetCharacter(true);

      character.x = (characterData.position != null ? characterData.position[0] : 0.0) - character.characterOrigin.x + character.globalOffsets[0];
      character.y = (characterData.position != null ? characterData.position[1] : 0.0) - character.characterOrigin.y + character.globalOffsets[1];
      character.zIndex = characterData.zIndex ?? 0;
      character.setScale(character.getBaseScale() * (characterData.scale ?? 1.0));

      character.alpha = characterData.alpha ?? 1.0;
      character.angle = characterData.angle ?? 0.0;
      character.scrollFactor.set(characterData.scroll != null ? characterData.scroll[0] : 1.0, characterData.scroll != null ? characterData.scroll[1] : 1.0);

      state.updateVisuals();
    }
  }

  public static function getLatestBackupPath():Null<String>
  {
    #if sys
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    var files:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    var filestats:Array<sys.FileStat> = [];
    if (files.length > 0)
    {
      while (!files[files.length - 1].endsWith(Constants.EXT_CHART) || !files[files.length - 1].startsWith("stage-editor-"))
      {
        if (files.length == 0) break;
        files.pop();
      }
    }

    var latestBackupPath:Null<String> = files[0];
    for (file in files)
    {
      filestats.push(sys.FileSystem.stat(haxe.io.Path.join([BACKUPS_PATH + file])));
    }

    var latestFileIndex:Int = 0;
    for (index in 0...filestats.length)
    {
      if (filestats[latestFileIndex].mtime.getTime() < filestats[index].mtime.getTime())
      {
        latestFileIndex = index;
        latestBackupPath = files[index];
      }
    }

    if (latestBackupPath == null) return null;
    return haxe.io.Path.join([BACKUPS_PATH, latestBackupPath]);
    #else
    return null;
    #end
  }

  public static function getLatestBackupDate():Null<String>
  {
    #if sys
    var latestBackupPath:Null<String> = getLatestBackupPath();
    if (latestBackupPath == null) return null;

    var latestBackupName:String = haxe.io.Path.withoutDirectory(latestBackupPath);
    latestBackupName = haxe.io.Path.withoutExtension(latestBackupName);

    var stat = sys.FileSystem.stat(latestBackupPath);
    var sizeInMB = (stat.size / 1000000).round(3);

    return "Full Name: " + latestBackupName + "\nLast Modified: " + stat.mtime.toString() + "\nSize: " + sizeInMB + " MB";
    #else
    return null;
    #end
  }

  /**
   * @param force Whether to export without prompting. `false` will prompt the user for a location.
   * @param targetPath where to export if `force` is `true`. If `null`, will export to the `backups` folder.
   * @param onSaveCb Callback for when the file is saved.
   * @param onCancelCb Callback for when saving is cancelled.
   */
  public static function exportAllStageData(state:StageEditorState, force:Bool = false, targetPath:Null<String>, ?onSaveCb:String->Void,
      ?onCancelCb:Void->Void):Void
  {
    var zipEntries:Array<haxe.zip.Entry> = [];

    // Add Stage Data
    zipEntries.push(FileUtil.makeZIPEntry('${state.currentStageId}.json', state.stageData.serialize()));

    // Add images
    state.removeUnusedBitmaps();
    for (name => image in StageEditorAssetHandler.bitmaps)
    {
      var data:Null<Bytes> = image?.image?.encode(PNG);
      if (data == null) continue;
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('${name}.png', data));
    }

    // Add xmls
    var xmlMap:Map<String, String> = [];
    for (prop in state.spriteArray)
    {
      var data = prop.toData(false);
      if (!xmlMap.exists(data.assetPath) && data.animData != '') xmlMap.set(data.assetPath, data.animData);
    }
    for (path => xml in xmlMap)
    {
      var data:Null<Bytes> = Bytes.ofString(xml);
      if (data == null) continue;
      zipEntries.push(FileUtil.makeZIPEntryFromBytes('${path}.xml', data));
    }

    if (force)
    {
      var targetMode:FileWriteMode = Force;
      if (targetPath == null)
      {
        // Force writing to a generic path (autosave or crash recovery)
        targetMode = Skip;
        targetPath = Path.join([
          BACKUPS_PATH,
          'stage-editor-${state.currentStageId}-${DateUtil.generateTimestamp()}.${Constants.EXT_STAGE}'
        ]);
        // We have to force write because the program will die before the save dialog is closed.
        trace('Force exporting to $targetPath...');
        try
        {
          FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath, targetMode);
          // On success.
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e)
        {
          // On failure.
          if (onCancelCb != null) onCancelCb();
        }
      }
      else
      {
        // Force write since we know what file the user wants to overwrite.
        trace('Force exporting to $targetPath...');
        try
        {
          // On success.
          FileUtil.saveFilesAsZIPToPath(zipEntries, targetPath, targetMode);
          state.saveDataDirty = false;
          if (onSaveCb != null) onSaveCb(targetPath);
        }
        catch (e)
        {
          // On failure.
          if (onCancelCb != null) onCancelCb();
        }
      }
    }
    else
    {
      // Prompt and save.
      var onSave:Array<String>->Void = function(paths:Array<String>) {
        if (paths.length != 1)
        {
          trace('[WARN] Could not get save path.');
          state.applyWindowTitle();
        }
        else
        {
          trace('Saved to "${paths[0]}"');
          state.currentWorkingFilePath = paths[0];
          state.applyWindowTitle();
          if (onSaveCb != null) onSaveCb(paths[0]);
        }
      };

      var onCancel:Void->Void = function() {
        trace('Export cancelled.');
        if (onCancelCb != null) onCancelCb();
      };

      trace('Exporting to user-defined location...');
      try
      {
        FileUtil.saveStageAsFNFS(zipEntries, onSave, onCancel, '${state.currentStageId}.${Constants.EXT_STAGE}');
        state.saveDataDirty = false;
      }
      catch (e) {}
    }
  }
}
