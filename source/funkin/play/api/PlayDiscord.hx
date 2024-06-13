package funkin.play.api;

#if discord_rpc
import funkin.api.discord.Discord.DiscordClient;
#end

enum APIStatus
{
  DEFAULT;
  TIMED;
  CUTSCENE;
  DIALOGUE;
  GAMEOVER;
  RESULTS;
}

class PlayDiscord
{
  #if discord_rpc
  public static var lastStatus:APIStatus = DEFAULT;
  public static var lastWasPaused:Bool = false;

  public static function changePresence(?type:APIStatus = DEFAULT, ?paused:Bool = false)
  {
    var storyMode:Bool = PlayStatePlaylist.isStoryMode;

    var iconRPC:String = getIcon();
    var details:String = storyMode ? 'Story Mode: ${PlayStatePlaylist.campaignId}' : 'Freeplay';
    var state:String = getState();

    var hasTime:Bool = (type == TIMED);
    var time:Float = (hasTime ? getSongTime() : 0);

    if (type == RESULTS)
    {
      details = (storyMode ? 'Story Mode' : 'Freeplay');
      if (storyMode) state = PlayStatePlaylist.campaignTitle;
    }

    lastStatus = type;
    lastWasPaused = paused;

    DiscordClient.changePresence(getStatus() + details, state, iconRPC, hasTime, time);
  }

  static function getStatus():String
  {
    var status:String = '';
    if (lastStatus == GAMEOVER) status = 'Game Over';
    else if (lastStatus == RESULTS) status = 'RESULTS';
    else if (lastStatus == CUTSCENE) status = 'In Cutscene';
    else if (lastStatus == DIALOGUE) status = 'In Dialogue';

    if (lastWasPaused)
    {
      if (status.length > 0) status += ' (Paused)';
      else
        status = 'Paused';
    }

    if (status.length > 0) status += ' - ';

    return status;
  }

  static function getIcon():String
  {
    var rpc:String = '';

    if (PlayState.instance != null)
    {
      rpc = PlayState.instance.currentChart?.characters?.opponent;

      // To avoid having duplicate images in Discord assets
      switch (rpc)
      {
        case 'senpai-angry':
          rpc = 'senpai';
        case 'monster-christmas':
          rpc = 'monster';
        case 'mom-car':
          rpc = 'mom';
      }
    }

    return rpc;
  }

  static function getState():String
  {
    var state:String = '';

    if (PlayState.instance != null)
    {
      state = PlayState.instance.currentChart?.songName;
      if (PlayState.instance.currentDifficulty != null) state += ' (' + PlayState.instance.currentDifficulty.toUpperCase() + ')';
    }

    return state;
  }

  static function getSongTime():Float
  {
    var time:Float = 0;
    if (PlayState.instance != null) time += PlayState.instance.currentSongLengthMs;
    if (Conductor.instance != null) time -= Conductor.instance.songPosition;

    return time;
  }
  #end
}
