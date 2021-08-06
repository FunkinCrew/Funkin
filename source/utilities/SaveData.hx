package utilities;

import flixel.FlxG;
import game.Highscore;

class SaveData {
    public static function init() {
        FlxG.save.bind('leathersfunkinengine', 'leather128');

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();

        if (FlxG.save.data.enemyGlow == null)
            FlxG.save.data.enemyGlow = true;

        if (FlxG.save.data.fpsCounter == null)
            FlxG.save.data.fpsCounter = true;

        if (FlxG.save.data.memoryCounter == null)
            FlxG.save.data.memoryCounter = true;

        FlxG.save.flush();
    }
}