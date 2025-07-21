package funkin.api.discord;

#if FEATURE_DISCORD_RPC
import hxdiscord_rpc.Discord;
import hxdiscord_rpc.Types.DiscordButton;
import hxdiscord_rpc.Types.DiscordEventHandlers;
import hxdiscord_rpc.Types.DiscordRichPresence;
import hxdiscord_rpc.Types.DiscordUser;
import sys.thread.Thread;

@:nullSafety
class DiscordClient
{
  static final CLIENT_ID:String = "816168432860790794";

  public static var instance(get, never):DiscordClient;
  static var _instance:Null<DiscordClient> = null;

  static function get_instance():DiscordClient
  {
    if (DiscordClient._instance == null) _instance = new DiscordClient();
    if (DiscordClient._instance == null) throw "Could not initialize singleton DiscordClient!";
    return DiscordClient._instance;
  }

  var handlers:DiscordEventHandlers;

  private function new()
  {
    trace('[DISCORD] Initializing event handlers...');

    handlers = DiscordEventHandlers.create();

    handlers.ready = cpp.Function.fromStaticFunction(onReady);
    handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
    handlers.errored = cpp.Function.fromStaticFunction(onError);
  }

  public function init():Void
  {
    trace('[DISCORD] Initializing connection...');

    // Discord.initialize(CLIENT_ID, handlers, true, null);
    Discord.Initialize(CLIENT_ID, cpp.RawPointer.addressOf(handlers), 1, "");

    createDaemon();
  }

  var daemon:Null<Thread> = null;

  function createDaemon():Void
  {
    daemon = Thread.create(doDaemonWork);
  }

  function doDaemonWork():Void
  {
    while (true)
    {
      #if DISCORD_DISABLE_IO_THREAD
      Discord.updateConnection();
      #end

      Discord.runCallbacks();
      Sys.sleep(2);
    }
  }

  public function shutdown():Void
  {
    trace('[DISCORD] Shutting down...');

    Discord.shutdown();
  }

  public function setPresence(params:DiscordClientPresenceParams):Void
  {
    Discord.updatePresence(buildPresence(params));
  }

  function buildPresence(params:DiscordClientPresenceParams):DiscordRichPresence
  {
    var presence = DiscordRichPresence.create();

    // Presence should always be playing the game.
    presence.type = DiscordActivityType_Playing;

    // Text when hovering over the large image. We just leave this as the game name.
    presence.largeImageText = "Friday Night Funkin'";

    // State should be generally what the person is doing, like "In the Menus" or "Pico (Pico Mix) [Freeplay Hard]"
    presence.state = cast(params.state, Null<String>) ?? "";
    // Details should be what the person is specifically doing, including stuff like timestamps (maybe something like "03:24 elapsed").
    presence.details = cast(params.details, Null<String>) ?? "";

    // The large image displaying what the user is doing.
    // This should probably be album art.
    // IMPORTANT NOTE: This can be an asset key uploaded to Discord's developer panel OR any URL you like.
    presence.largeImageKey = cast(params.largeImageKey, Null<String>) ?? "album-volume1";

    // TODO: Make this use the song's album art.
    // presence.largeImageKey = "icon";
    // presence.largeImageKey = "https://f4.bcbits.com/img/a0746694746_16.jpg";

    // The small inset image for what the user is doing.
    // This can be the opponent's health icon?
    // NOTE: Like largeImageKey, this can be a URL, or an asset key.
    presence.smallImageKey = cast(params.smallImageKey, Null<String>) ?? "";

    // NOTE: In previous versions, this showed as "Elapsed", but now shows as playtime and doesn't look good
    // presence.startTimestamp = time - 10;
    // presence.endTimestamp = time + 30;

    final button1:DiscordButton = DiscordButton.create();
    button1.label = "Play on Web";
    button1.url = Constants.URL_NEWGROUNDS;
    presence.buttons[0] = button1;

    final button2:DiscordButton = DiscordButton.create();
    button2.label = "Download";
    button2.url = Constants.URL_ITCH;
    presence.buttons[1] = button2;

    return presence;
  }

  // TODO: WHAT THE FUCK get this pointer bullfuckery out of here
  private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
  {
    trace('[DISCORD] Client has connected!');

    final username:String = request[0].username;
    final globalName:String = request[0].username;
    final discriminator:Null<Int> = Std.parseInt(request[0].discriminator);

    if (discriminator != null && discriminator != 0)
    {
      trace('[DISCORD] User: ${username}#${discriminator} (${globalName})');
    }
    else
    {
      trace('[DISCORD] User: @${username} (${globalName})');
    }
  }

  private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
  {
    trace('[DISCORD] Client has disconnected! ($errorCode) "${cast (message, String)}"');
  }

  private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
  {
    trace('[DISCORD] Client has received an error! ($errorCode) "${cast (message, String)}"');
  }

  // public var type(get, set):DiscordActivityType;
  // public var state(get, set):String;
  // public var details(get, set):String;
  // public var startTimestamp(get, set):Int;
  // public var endTimestamp(get, set):Int;
  // public var largeImageKey(get, set):String;
  // public var largeImageText(get, set):String;
  // public var smallImageKey(get, set):String;
  // public var smallImageText(get, set):String;
  //
  //
  // public var partyId(get, set)
  // public var partySize(get, set)
  // public var partyMax(get, set)
  // public var partyPrivacy(get, set)
  //
  // public var buttons(get, set)
  //
  // public var matchSecret(get, set)
  // public var joinSecret(get, set)
  // public var spectateSecret(get, set)
}

typedef DiscordClientPresenceParams =
{
  /**
   * The first row of text below the game title.
   */
  var state:String;

  /**
   * The second row of text below the game title.
   * Use `null` to display no text.
   */
  var details:Null<String>;

  /**
   * A large, 4-row high image to the left of the content.
   */
  var ?largeImageKey:String;

  /**
   * A small, inset image to the bottom right of `largeImageKey`.
   */
  var ?smallImageKey:String;
}

class DiscordClientSandboxed
{
  public static function setPresence(params:DiscordClientPresenceParams):Void
  {
    DiscordClient.instance.setPresence(params);
  }

  public static function shutdown():Void
  {
    DiscordClient.instance.shutdown();
  }
}
#else
class DiscordClientSandboxed
{
  public static function setPresence(params:Dynamic):Void
  {
    // Do nothing.
  }

  public static function shutdown():Void
  {
    // Do nothing.
  }
}
#end
