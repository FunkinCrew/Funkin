package funkin.api.discord;

import Sys.sleep;
import discord_rpc.DiscordRpc;

class DiscordClient
{
  public function new()
  {
    trace("Discord Client starting...");
    DiscordRpc.start(
      {
        clientID: "1244363525527310367",
        onReady: onReady,
        onError: onError,
        onDisconnected: onDisconnected
      });
    trace("Discord Client started.");

    while (true)
    {
      DiscordRpc.process();
      sleep(2);
      // trace("Discord Client Update");
    }

    DiscordRpc.shutdown();
  }

  public static function shutdown()
  {
    DiscordRpc.shutdown();
  }

  static function onReady()
  {
    DiscordRpc.presence(
      {
        details: "In the Menus",
        state: null,
        largeImageKey: 'chorus',
        largeImageText: "Project Chorus"
      });
  }

  static function onError(_code:Int, _message:String)
  {
    trace('Error! $_code : $_message');
  }

  static function onDisconnected(_code:Int, _message:String)
  {
    trace('Disconnected! $_code : $_message');
  }

  public static function initialize()
  {
    var DiscordDaemon = sys.thread.Thread.create(() -> {
      new DiscordClient();
    });
    trace("Discord Client initialized");
  }

  public static function changePresence(details:String, ?state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
      ?largeImageKey:String = 'chorus')
  {
    var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

    if (endTimestamp > 0)
    {
      endTimestamp = startTimestamp + endTimestamp;
    }

    DiscordRpc.presence(
      {
        details: details,
        state: state,
        largeImageKey: largeImageKey,
        largeImageText: "Project Chorus",
        smallImageKey: smallImageKey,
        // Obtained times are in milliseconds so they are divided so Discord can use it
        startTimestamp: Std.int(startTimestamp / 1000),
        endTimestamp: Std.int(endTimestamp / 1000)
      });

    // trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
  }
}
