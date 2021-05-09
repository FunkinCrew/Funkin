package;
#if cpp
import Sys.sleep;
import discord_rpc.DiscordRpc;
#end
using StringTools;

class DiscordClient
{
	public function new()
	{
        #if cpp
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "840632338949210114",
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
        #end
	}

	public static function shutdown()
	{
        #if cpp
		DiscordRpc.shutdown();
        #end
	}

	static function onReady()
	{
        #if cpp
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'icon',
			largeImageText: "Friday Night Funkin' Modding Plus"
		});
        #end
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
        #if cpp
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});
        #end
		trace("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float,
			?smallImageString:String)
	{
        #if cpp
		var startTimestamp:Float = if (hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}
		if (smallImageKey == null) {
			smallImageKey = "icon";
		}
		if (smallImageString == null) {
			smallImageString = "Friday Night Funkin' Modding Plus";
		}
		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: smallImageKey,
			largeImageText: smallImageString,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp: Std.int(startTimestamp / 1000),
			endTimestamp: Std.int(endTimestamp / 1000)
		});
        #end
		// trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
