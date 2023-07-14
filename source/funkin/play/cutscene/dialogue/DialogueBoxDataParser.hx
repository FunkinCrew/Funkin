package funkin.play.cutscene.dialogue;

import openfl.Assets;
import funkin.util.assets.DataAssets;
import funkin.play.cutscene.dialogue.DialogueBox;
import funkin.play.cutscene.dialogue.ScriptedDialogueBox;

/**
 * Contains utilities for loading and parsing dialogueBox data.
 */
class DialogueBoxDataParser
{
  public static final DIALOGUE_BOX_DATA_VERSION:String = '1.0.0';
  public static final DIALOGUE_BOX_DATA_VERSION_RULE:String = '1.0.x';

  static final dialogueBoxCache:Map<String, DialogueBox> = new Map<String, DialogueBox>();

  static final dialogueBoxScriptedClass:Map<String, String> = new Map<String, String>();

  static final DEFAULT_DIALOGUE_BOX_ID:String = 'UNKNOWN';

  /**
   * Parses and preloads the game's dialogueBox data and scripts when the game starts.
   *
   * If you want to force dialogue boxes to be reloaded, you can just call this function again.
   */
  public static function loadDialogueBoxCache():Void
  {
    clearDialogueBoxCache();
    trace('Loading dialogue box cache...');

    //
    // SCRIPTED CONVERSATIONS
    //
    var scriptedDialogueBoxClassNames:Array<String> = ScriptedDialogueBox.listScriptClasses();
    trace('  Instantiating ${scriptedDialogueBoxClassNames.length} scripted dialogue boxes...');
    for (dialogueBoxCls in scriptedDialogueBoxClassNames)
    {
      var dialogueBox:DialogueBox = ScriptedDialogueBox.init(dialogueBoxCls, DEFAULT_DIALOGUE_BOX_ID);
      if (dialogueBox != null)
      {
        trace('    Loaded scripted dialogue box: ${dialogueBox.dialogueBoxName}');
        // Disable the rendering logic for dialogueBox until it's loaded.
        // Note that kill() =/= destroy()
        dialogueBox.kill();

        // Then store it.
        dialogueBoxCache.set(dialogueBox.dialogueBoxId, dialogueBox);
      }
      else
      {
        trace('    Failed to instantiate scripted dialogueBox class: ${dialogueBoxCls}');
      }
    }

    //
    // UNSCRIPTED CONVERSATIONS
    //
    // Scripts refers to code here, not the actual dialogue.
    var dialogueBoxIdList:Array<String> = DataAssets.listDataFilesInPath('dialogue/boxes/');
    // Filter out dialogue boxes that are scripted.
    var unscriptedDialogueBoxIds:Array<String> = dialogueBoxIdList.filter(function(dialogueBoxId:String):Bool {
      return !dialogueBoxCache.exists(dialogueBoxId);
    });
    trace('  Fetching data for ${unscriptedDialogueBoxIds.length} dialogue boxes...');
    for (dialogueBoxId in unscriptedDialogueBoxIds)
    {
      try
      {
        var dialogueBox:DialogueBox = new DialogueBox(dialogueBoxId);
        if (dialogueBox != null)
        {
          trace('    Loaded dialogueBox data: ${dialogueBox.dialogueBoxName}');
          dialogueBoxCache.set(dialogueBox.dialogueBoxId, dialogueBox);
        }
      }
      catch (e)
      {
        trace(e);
        continue;
      }
    }
  }

  /**
   * Fetches data for a dialogueBox and returns a DialogueBox instance,
   * ready to be displayed.
   * @param dialogueBoxId The ID of the dialogueBox to fetch.
   * @return The dialogueBox instance, or null if the dialogueBox was not found.
   */
  public static function fetchDialogueBox(dialogueBoxId:String):Null<DialogueBox>
  {
    if (dialogueBoxId != null && dialogueBoxId != '' && dialogueBoxCache.exists(dialogueBoxId))
    {
      trace('Successfully fetched dialogueBox: ${dialogueBoxId}');
      var dialogueBox:DialogueBox = dialogueBoxCache.get(dialogueBoxId);
      dialogueBox.revive();
      return dialogueBox;
    }
    else
    {
      trace('Failed to fetch dialogueBox, not found in cache: ${dialogueBoxId}');
      return null;
    }
  }

  static function clearDialogueBoxCache():Void
  {
    if (dialogueBoxCache != null)
    {
      for (dialogueBox in dialogueBoxCache)
      {
        dialogueBox.destroy();
      }
      dialogueBoxCache.clear();
    }
  }

  public static function listDialogueBoxIds():Array<String>
  {
    return dialogueBoxCache.keys().array();
  }

  /**
   * Load a dialogueBox's JSON file, parse its data, and return it.
   *
   * @param dialogueBoxId The dialogueBox to load.
   * @return The dialogueBox data, or null if validation failed.
   */
  public static function parseDialogueBoxData(dialogueBoxId:String):Null<DialogueBoxData>
  {
    var rawJson:String = loadDialogueBoxFile(dialogueBoxId);

    try
    {
      var dialogueBoxData:DialogueBoxData = DialogueBoxData.fromString(rawJson);
      return dialogueBoxData;
    }
    catch (e)
    {
      trace('Failed to parse dialogueBox ($dialogueBoxId).');
      trace(e);
      return null;
    }
  }

  static function loadDialogueBoxFile(dialogueBoxPath:String):String
  {
    var dialogueBoxFilePath:String = Paths.json('dialogue/boxes/${dialogueBoxPath}');
    var rawJson:String = Assets.getText(dialogueBoxFilePath).trim();

    while (!rawJson.endsWith('}') && rawJson.length > 0)
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }
}
