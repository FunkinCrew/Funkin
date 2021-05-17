package;

import sys.FileSystem;
import haxe.Json;
import sys.io.File;

// Hey, alot of this is based on Mic'd Up's implementation of options
// so credits to them i guess

// variables type
typedef Variables = {
    var customIntro:Bool;
    var disableFNFVersionCheck:Bool;
    var debug:Bool;
    var discordRPC:Bool;
    var extraDialogue:Bool;
    var extraSongs:Bool;
    var fixMonsterIconFreeplay:Bool;
    var fixScoreLayout:Bool;
    var fixWeek6CountSounds:Bool;
    var hideOptionsMenu:Bool;
    var inputMode:Int;
    var instMode:Bool;
    var logNG:Bool;
    var lyrics:Bool;
    var makeSpacesConsistent:Bool;
    var monsterIntro:Bool;
    var noticeEnabled:Bool;
    var outlinePauseInfo:Bool;
    var outlineScore:Bool;
    var songIndicator:Bool;
    var startWHP2Invis:Bool;
    var unknownIcons:Bool;
    var updatedInputSystem:Bool;
    var missCounter:Bool;
}

class STOptionsRewrite
{
    public static var _variables:Variables;

    // save to config.json
    public static function Save():Void
    {
        File.saveContent(('config.json'), Json.stringify(_variables));
    }

    // load from config.json
    public static function Load():Void
    {
        // if we dont have a config.json, set default values
        if (!FileSystem.exists('config.json'))
        {
            _variables = {
                customIntro: true,
                debug: false,
                disableFNFVersionCheck: true,
                discordRPC: true,
                extraDialogue: true,
                extraSongs: true,
                fixMonsterIconFreeplay: true,
                fixScoreLayout: true,
                fixWeek6CountSounds: true,
                hideOptionsMenu: true,
                inputMode: 0,
                instMode: false,
                logNG: true,
                lyrics: true,
                makeSpacesConsistent: true,
                monsterIntro: true,
                noticeEnabled: false,
                outlinePauseInfo: true,
                outlineScore: true,
                songIndicator: true,
                startWHP2Invis: true,
                unknownIcons: true,
                updatedInputSystem: true,
                missCounter: true
            };

            // save defaults to file
            Save();
        } else {
            // load current values
            var data:String = File.getContent('config.json');
            _variables = Json.parse(data);
        }
    }
}