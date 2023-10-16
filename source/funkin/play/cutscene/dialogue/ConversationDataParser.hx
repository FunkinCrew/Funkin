package funkin.play.cutscene.dialogue;

import openfl.Assets;
import funkin.util.assets.DataAssets;
import funkin.play.cutscene.dialogue.ScriptedConversation;

/**
 * Contains utilities for loading and parsing conversation data.
 * TODO: Refactor to use the json2object + BaseRegistry system that actually validates things for you.
 */
class ConversationDataParser
{
  public static final CONVERSATION_DATA_VERSION:String = '1.0.0';
  public static final CONVERSATION_DATA_VERSION_RULE:String = '1.0.x';

  static final conversationCache:Map<String, Conversation> = new Map<String, Conversation>();
  static final conversationScriptedClass:Map<String, String> = new Map<String, String>();

  static final DEFAULT_CONVERSATION_ID:String = 'UNKNOWN';

  /**
   * Parses and preloads the game's conversation data and scripts when the game starts.
   *
   * If you want to force conversations to be reloaded, you can just call this function again.
   */
  public static function loadConversationCache():Void
  {
    clearConversationCache();
    trace('Loading dialogue conversation cache...');

    //
    // SCRIPTED CONVERSATIONS
    //
    var scriptedConversationClassNames:Array<String> = ScriptedConversation.listScriptClasses();
    trace('  Instantiating ${scriptedConversationClassNames.length} scripted conversations...');
    for (conversationCls in scriptedConversationClassNames)
    {
      var conversation:Conversation = ScriptedConversation.init(conversationCls, DEFAULT_CONVERSATION_ID);
      if (conversation != null)
      {
        trace('    Loaded scripted conversation: ${conversationCls}');
        // Disable the rendering logic for conversation until it's loaded.
        // Note that kill() =/= destroy()
        conversation.kill();

        // Then store it.
        conversationCache.set(conversation.conversationId, conversation);
      }
      else
      {
        trace('    Failed to instantiate scripted conversation class: ${conversationCls}');
      }
    }

    //
    // UNSCRIPTED CONVERSATIONS
    //
    // Scripts refers to code here, not the actual dialogue.
    var conversationIdList:Array<String> = DataAssets.listDataFilesInPath('dialogue/conversations/');
    // Filter out conversations that are scripted.
    var unscriptedConversationIds:Array<String> = conversationIdList.filter(function(conversationId:String):Bool {
      return !conversationCache.exists(conversationId);
    });
    trace('  Fetching data for ${unscriptedConversationIds.length} conversations...');
    for (conversationId in unscriptedConversationIds)
    {
      try
      {
        var conversation:Conversation = new Conversation(conversationId);
        // Say something offensive to kill the conversation.
        // We will revive it later.
        conversation.kill();
        if (conversation != null)
        {
          trace('    Loaded conversation data: ${conversation.conversationId}');
          conversationCache.set(conversation.conversationId, conversation);
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
   * Fetches data for a conversation and returns a Conversation instance,
   * ready to be displayed.
   * @param conversationId The ID of the conversation to fetch.
   * @return The conversation instance, or null if the conversation was not found.
   */
  public static function fetchConversation(conversationId:String):Null<Conversation>
  {
    if (conversationId != null && conversationId != '' && conversationCache.exists(conversationId))
    {
      trace('Successfully fetched conversation: ${conversationId}');
      var conversation:Conversation = conversationCache.get(conversationId);
      // ...ANYway...
      conversation.revive();
      return conversation;
    }
    else
    {
      trace('Failed to fetch conversation, not found in cache: ${conversationId}');
      return null;
    }
  }

  static function clearConversationCache():Void
  {
    if (conversationCache != null)
    {
      for (conversation in conversationCache)
      {
        conversation.destroy();
      }
      conversationCache.clear();
    }
  }

  public static function listConversationIds():Array<String>
  {
    return conversationCache.keys().array();
  }

  /**
   * Load a conversation's JSON file, parse its data, and return it.
   *
   * @param conversationId The conversation to load.
   * @return The conversation data, or null if validation failed.
   */
  public static function parseConversationData(conversationId:String):Null<ConversationData>
  {
    trace('Parsing conversation data: ${conversationId}');
    var rawJson:String = loadConversationFile(conversationId);

    try
    {
      var conversationData:ConversationData = ConversationData.fromString(rawJson);
      return conversationData;
    }
    catch (e)
    {
      trace('Failed to parse conversation ($conversationId).');
      trace(e);
      return null;
    }
  }

  static function loadConversationFile(conversationPath:String):String
  {
    var conversationFilePath:String = Paths.json('dialogue/conversations/${conversationPath}');
    var rawJson:String = Assets.getText(conversationFilePath).trim();

    while (!rawJson.endsWith('}') && rawJson.length > 0)
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }
}
