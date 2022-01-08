package utilities;

#if discord_rpc
import Sys.sleep;
import discord_rpc.DiscordRpc;
import flixel.FlxG;

using StringTools;

class DiscordClient
{
	public static var started:Bool = false;

	public static var active:Bool = false;

	public function new()
	{
		startLmao();
	}

	public static function startLmao()
	{
		trace("Discord Client starting...");
		DiscordRpc.start({
			clientID: "864980501004812369",
			onReady: onReady,
			onError: onError,
			onDisconnected: onDisconnected
		});
		trace("Discord Client started.");

		active = true;

		while (active)
		{
			DiscordRpc.process();
			sleep(2);
		}

		if(active)
			DiscordRpc.shutdown();

		active = false;
	}

	public static function shutdown()
	{
		DiscordRpc.shutdown();

		active = false;
	}
	
	static function onReady()
	{
		DiscordRpc.presence({
			details: "In the Menus",
			state: null,
			largeImageKey: 'logo',
			largeImageText: "Leather Engine"
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
		var DiscordDaemon = sys.thread.Thread.create(() ->
		{
			new DiscordClient();
		});

		started = true;
		trace("Discord Client initialized");
	}

	public static function changePresence(details:String, state:Null<String>, ?smallImageKey : String, ?hasStartTimestamp : Bool, ?endTimestamp: Float)
	{
		var startTimestamp:Float = if(hasStartTimestamp) Date.now().getTime() else 0;

		if (endTimestamp > 0)
		{
			endTimestamp = startTimestamp + endTimestamp;
		}

		DiscordRpc.presence({
			details: details,
			state: state,
			largeImageKey: 'logo',
			largeImageText: "Leather Engine",
			smallImageKey : smallImageKey,
			// Obtained times are in milliseconds so they are divided so Discord can use it
			startTimestamp : Std.int(startTimestamp / 1000),
            endTimestamp : Std.int(endTimestamp / 1000)
		});

		//trace('Discord RPC Updated. Arguments: $details, $state, $smallImageKey, $hasStartTimestamp, $endTimestamp');
	}
}
#end