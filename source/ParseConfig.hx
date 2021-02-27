package;

import lime.system.System;
import haxe.Json;
import haxe.format.JsonParser;
import lime.utils.Assets;
import StringTools;
import lime.system.System;

using StringTools;

class ParseConfig
{    
    
    public static function data()
    {
        //System.openFile();
        //trace(Json.parse(asdfasf));
        //trace(Json.parse(asdfasf).screen.width);
        
        var text = Assets.getText('assets/data/config.json').trim();
    
        return Json.parse(text);
    }
}