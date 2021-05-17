package;

import Sys.sleep;
import discord_rpc.DiscordRpc;

using StringTools;

class DiscordClient
{
	public function new()
	{
		if (STOptionsRewrite._variables.discordRPC == true) {
			trace("Discord Client starting...");
			DiscordRpc.start({
				clientID: "827349708565118996",
				onReady: onReady,
				onError: onError,
				onDisconnected: onDisconnected
			});
			trace("Discord Client started.");

			while (true)
			{
				DiscordRpc.process();
				sleep(2);
				//trace("Discord Client Update");
			}

			DiscordRpc.shutdown();
		}
	}

	public static function shutdown()
	{
		if (STOptionsRewrite._variables.discordRPC == true)
			DiscordRpc.shutdown();
	}
	
	static function onReady()
	{
		if (STOptionsRewrite._variables.discordRPC == true) {
			DiscordRpc.presence({
				details: "In the Menus",
				state: null,
				largeImageKey: 'icon',
				largeImageText: "Friday Night Funkin': Small Things"
			});
		}
	}

	static function onError(_code:Int, _message:String)
	{
		if (STOptionsRewrite._variables.discordRPC == true)
			trace('Error! $_code : $_message');
	}

	static function onDisconnected(_code:Int, _message:String)
	{
		if (STOptionsRewrite._variables.discordRPC == true)
			trace('Disconnected! $_code : $_message');
	}

	public static function initialize()
	{
		if (STOptionsRewrite._variables.discordRPC == true) {
			var DiscordDaemon = sys.thread.Thread.create(() ->
			{
				new DiscordClient();
			});
			trace("Discord Client initialized");
		}
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		if (STOptionsRewrite._variables.discordRPC == true) {
			var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

			if (endTimestamp > 0)
			{
				endTimestamp = startTimestamp + endTimestamp;
			}

			DiscordRpc.presence({
				details: details,
				state: state,
				largeImageKey: 'icon',
				largeImageText: "Friday Night Funkin': Small Things",
				smallImageKey : smallImageKey,
				// Obtained times are in milliseconds so they are divided so Discord can use it
				startTimestamp : Std.int(startTimestamp / 1000),
				endTimestamp : Std.int(endTimestamp / 1000)
			});

			//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
		}
	}
}
