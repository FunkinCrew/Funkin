package funkin.play.cutscene.dialogue;

import openfl.Assets;
import funkin.util.assets.DataAssets;
import funkin.play.cutscene.dialogue.Speaker;
import funkin.play.cutscene.dialogue.ScriptedSpeaker;

/**
 * Contains utilities for loading and parsing speaker data.
 */
class SpeakerDataParser
{
  public static final SPEAKER_DATA_VERSION:String = '1.0.0';
  public static final SPEAKER_DATA_VERSION_RULE:String = '1.0.x';

  static final speakerCache:Map<String, Speaker> = new Map<String, Speaker>();

  static final speakerScriptedClass:Map<String, String> = new Map<String, String>();

  static final DEFAULT_SPEAKER_ID:String = 'UNKNOWN';

  /**
   * Parses and preloads the game's speaker data and scripts when the game starts.
   * 
   * If you want to force speakers to be reloaded, you can just call this function again.
   */
  public static function loadSpeakerCache():Void
  {
    clearSpeakerCache();
    trace('Loading dialogue speaker cache...');

    //
    // SCRIPTED CONVERSATIONS
    //
    var scriptedSpeakerClassNames:Array<String> = ScriptedSpeaker.listScriptClasses();
    trace('  Instantiating ${scriptedSpeakerClassNames.length} scripted speakers...');
    for (speakerCls in scriptedSpeakerClassNames)
    {
      var speaker:Speaker = ScriptedSpeaker.init(speakerCls, DEFAULT_SPEAKER_ID);
      if (speaker != null)
      {
        trace('    Loaded scripted speaker: ${speaker.speakerName}');
        // Disable the rendering logic for speaker until it's loaded.
        // Note that kill() =/= destroy()
        speaker.kill();

        // Then store it.
        speakerCache.set(speaker.speakerId, speaker);
      }
      else
      {
        trace('    Failed to instantiate scripted speaker class: ${speakerCls}');
      }
    }

    //
    // UNSCRIPTED CONVERSATIONS
    //
    // Scripts refers to code here, not the actual dialogue.
    var speakerIdList:Array<String> = DataAssets.listDataFilesInPath('dialogue/speakers/');
    // Filter out speakers that are scripted.
    var unscriptedSpeakerIds:Array<String> = speakerIdList.filter(function(speakerId:String):Bool {
      return !speakerCache.exists(speakerId);
    });
    trace('  Fetching data for ${unscriptedSpeakerIds.length} speakers...');
    for (speakerId in unscriptedSpeakerIds)
    {
      try
      {
        var speaker:Speaker = new Speaker(speakerId);
        if (speaker != null)
        {
          trace('    Loaded speaker data: ${speaker.speakerName}');
          speakerCache.set(speaker.speakerId, speaker);
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
   * Fetches data for a speaker and returns a Speaker instance,
   * ready to be displayed.
   * @param speakerId The ID of the speaker to fetch.
   * @return The speaker instance, or null if the speaker was not found.
   */
  public static function fetchSpeaker(speakerId:String):Null<Speaker>
  {
    if (speakerId != null && speakerId != '' && speakerCache.exists(speakerId))
    {
      trace('Successfully fetched speaker: ${speakerId}');
      var speaker:Speaker = speakerCache.get(speakerId);
      speaker.revive();
      return speaker;
    }
    else
    {
      trace('Failed to fetch speaker, not found in cache: ${speakerId}');
      return null;
    }
  }

  static function clearSpeakerCache():Void
  {
    if (speakerCache != null)
    {
      for (speaker in speakerCache)
      {
        speaker.destroy();
      }
      speakerCache.clear();
    }
  }

  public static function listSpeakerIds():Array<String>
  {
    return speakerCache.keys().array();
  }

  /**
   * Load a speaker's JSON file, parse its data, and return it.
   * 
   * @param speakerId The speaker to load.
   * @return The speaker data, or null if validation failed.
   */
  public static function parseSpeakerData(speakerId:String):Null<SpeakerData>
  {
    var rawJson:String = loadSpeakerFile(speakerId);

    try
    {
      var speakerData:SpeakerData = SpeakerData.fromString(rawJson);
      return speakerData;
    }
    catch (e)
    {
      trace('Failed to parse speaker ($speakerId).');
      trace(e);
      return null;
    }
  }

  static function loadSpeakerFile(speakerPath:String):String
  {
    var speakerFilePath:String = Paths.json('dialogue/speakers/${speakerPath}');
    var rawJson:String = Assets.getText(speakerFilePath).trim();

    while (!rawJson.endsWith('}') && rawJson.length > 0)
    {
      rawJson = rawJson.substr(0, rawJson.length - 1);
    }

    return rawJson;
  }
}
