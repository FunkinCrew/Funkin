package funkin.ui.debug.stageeditor.handlers;

import funkin.util.SortUtil;
import funkin.util.FileUtil;
import funkin.data.stage.StageData;
import funkin.data.stage.StageRegistry;
import funkin.play.stage.Stage;
import funkin.ui.debug.stageeditor.components.StageEditorObject;

/**
 * Contains functions for importing, loading, saving, and exporting stages.
 */
@:nullSafety
@:access(funkin.ui.debug.stageeditor.StageEditorState)
class StageEditorImportExportHandler
{
  public static final BACKUPS_PATH:String = './stagebackups/';

  public static function loadStageAsTemplate(state:StageEditorState, stageId:String):Void
  {
    trace('===============START===============');

    var stage:Null<Stage> = StageRegistry.instance.fetchEntry(stageId);

    if (stage == null) return;

    var stageData:Null<StageData> = stage?._data;

    if (stageData == null) return;

    loadStage(state, stageData);

    state.isHaxeUIDialogOpen = false;
    state.currentWorkingFilePath = null; // New file, so no path.

    state.refreshToolbox(StageEditorState.STAGE_EDITOR_TOOLBOX_METADATA_LAYOUT);

    state.success('Success', 'Loaded stage (${stageData.name})');

    trace('===============END===============');
  }

  /**
   * Loads the stage from given stage data into the editor.
   * @param newStageData The stage data to load.
   */
  public static function loadStage(state:StageEditorState, newStageData:StageData):Void
  {
    state.stageData = newStageData;

    Paths.setCurrentLevel(state.currentStageDirectory);

    loadCharacters(state, state.stageData.characters);

    // add characters

    for (prop in state.spriteArray)
    {
      state.spriteArray.remove(prop);

      state.remove(prop, true);
      state.selectedProp?.destroy();
      state.selectedProp = null;
    }
    state.spriteArray.clear();

    if (state.stageData.props != null)
    {
      for (propData in state.stageData.props)
      {
        var prop = new StageEditorObject();
        if (!propData.assetPath.startsWith('#')) StageEditorAssetDataHandler.bitmaps.set(propData.assetPath, Assets.getBitmapData(Paths.image(propData.assetPath)));

        var usePacker:Bool = propData.animType == "packer";
        var animPath:String = Paths.file("images/" + propData.assetPath + (usePacker ? ".txt" : ".xml"));
        var animText:String = Assets.exists(animPath) ? Assets.getText(animPath) : "";

        prop.fromData({
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

    // Clear the undo and redo history
    state.undoHistory = [];
    state.redoHistory = [];
    state.commandHistoryDirty = true;
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
      character.cameraFocusPoint.x += (characterData.cameraOffsets != null ? characterData.cameraOffsets[0] : 0.0);
      character.cameraFocusPoint.y += (characterData.cameraOffsets != null ? characterData.cameraOffsets[1] : 0.0);

      character.alpha = characterData.alpha ?? 1.0;
      character.angle = characterData.angle ?? 0.0;
      character.scrollFactor.set(characterData.scroll != null ? characterData.scroll[0] : 1.0, characterData.scroll != null ? characterData.scroll[1] : 1.0);

      //  = characterData.cameraOffsets.copy();
    }
  }

  public static function getLatestBackupPath():Null<String>
  {
    #if sys
    FileUtil.createDirIfNotExists(BACKUPS_PATH);

    var entries:Array<String> = sys.FileSystem.readDirectory(BACKUPS_PATH);
    entries.sort(SortUtil.alphabetically);

    var latestBackupPath:Null<String> = entries[(entries.length - 1)];

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
}
