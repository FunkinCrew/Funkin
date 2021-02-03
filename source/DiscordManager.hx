package ;

import flixel.util.FlxTimer;
import discord_rpc.DiscordRpc;

class DiscordManager
{
    public static function init() {
        DiscordRpc.start({
            clientID : "806658783132516383",
            onReady : _onReady,
            onError : _onError,
            onDisconnected : _onDisconnected
        });

        DiscordRpc.process();
        new FlxTimer().start(1, process, 0);

        trace("Discord RPC Initialized!");
    }

    static function process(timer:FlxTimer):Void {
        DiscordRpc.process();
    }

    static function _onReady() {
        DiscordRpc.presence({
            state : "Title Screen",
            largeImageKey : "icon",
            largeImageText : "Friday Night Funkin'"
        });

        trace("Discord RPC Ready!");
    }

    public static function updateState(_state : String) {
        DiscordRpc.presence({
            state : _state,
            largeImageKey : "icon",
            largeImageText : "Friday Night Funkin'"
        });

        trace("Discord RPC State Updated!");
    }

    static function _onError(_code : Int, _message : String) {
        trace('ERROR! $_code : $_message');
    }

    static function _onDisconnected(_code : Int, _message : String) {
        trace('DISCONNECTED! $_code : $_message');
    }

    public static function shutdown() {
        DiscordRpc.shutdown();
    }
}
