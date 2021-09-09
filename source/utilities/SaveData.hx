package utilities;

import modding.ModList;
import game.Conductor;
import flixel.FlxG;
import game.Highscore;

class SaveData {
    public static function init() {
        FlxG.save.bind('leathersfunkinengine', 'leather128');

        if (FlxG.save.data.enemyGlow == null)
            FlxG.save.data.enemyGlow = true;

        if (FlxG.save.data.fpsCounter == null)
            FlxG.save.data.fpsCounter = true;

        if (FlxG.save.data.memoryCounter == null)
            FlxG.save.data.memoryCounter = true;

        if (FlxG.save.data.leftBind == null)
            FlxG.save.data.leftBind = "A";

        if (FlxG.save.data.downBind == null)
            FlxG.save.data.downBind = "S";

        if (FlxG.save.data.upBind == null)
            FlxG.save.data.upBind = "W";

        if (FlxG.save.data.rightBind == null)
            FlxG.save.data.rightBind = "D";

        if (FlxG.save.data.killBind == null)
            FlxG.save.data.killBind = "R";

        if (FlxG.save.data.uiSkin == null)
            FlxG.save.data.uiSkin = "default";

        if (FlxG.save.data.msText == null)
            FlxG.save.data.msText = true;

        if(FlxG.save.data.nightMusic == null)
			FlxG.save.data.nightMusic = false;

        if(FlxG.save.data.songOffset == null)
            FlxG.save.data.songOffset = 0;
        
        Conductor.offset = FlxG.save.data.songOffset;

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();
        ModList.load();

        FlxG.save.flush();
    }
}