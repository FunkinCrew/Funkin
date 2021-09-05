package;

import flixel.addons.api.FlxGameJolt;

class GJApi {
    public var ready = false;

    public function new(apiKey:String, gameID:Int) {
        FlxGameJolt.init(gameID, apiKey, false);
        trace('initialized GJ Api');

        if (FlxGameJolt.initialized) {
            ready = true;
        }
    }

    public function auth(username:String, gameToken:String) {
        if (ready) {
            FlxGameJolt.authUser(username, gameToken);
            trace('authenticated: ${FlxGameJolt.username}');
        }
    }

    public function unlockAchievement(id:Int) {
        if (ready && FlxGameJolt.username != 'No user') {
            FlxGameJolt.addTrophy(id);
        }
    }
}