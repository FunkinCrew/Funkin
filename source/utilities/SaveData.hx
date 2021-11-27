package utilities;

import modding.ModList;
import game.Conductor;
import flixel.FlxG;
import game.Highscore;

class SaveData {
    public static function init() {
        FlxG.save.bind('leathersfunkinengine', 'leather128');

        if(FlxG.save.data.enemyGlow == null)
            FlxG.save.data.enemyGlow = true;

        if(FlxG.save.data.fpsCounter == null)
            FlxG.save.data.fpsCounter = true;

        if(FlxG.save.data.memoryCounter == null)
            FlxG.save.data.memoryCounter = true;

        if(FlxG.save.data.killBind == null)
            FlxG.save.data.killBind = "R";

        if(FlxG.save.data.uiSkin == null)
            FlxG.save.data.uiSkin = "default";

        if(FlxG.save.data.msText == null)
            FlxG.save.data.msText = true;

        if(FlxG.save.data.nightMusic == null)
			FlxG.save.data.nightMusic = false;

        if(FlxG.save.data.songOffset == null)
            FlxG.save.data.songOffset = 0;

        if(FlxG.save.data.noteSplashes == null)
            FlxG.save.data.noteSplashes = true;

        if(FlxG.save.data.deaths == null)
            FlxG.save.data.deaths = 0;

        if(FlxG.save.data.discordRPC == null)
            FlxG.save.data.discordRPC = true;

        if(FlxG.save.data.quickRestart == null)
            FlxG.save.data.quickRestart = false;

        if(FlxG.save.data.fpsCap == null)
            FlxG.save.data.fpsCap = 120;

        if(FlxG.save.data.fpsCap > 800)
            FlxG.save.data.fpsCap = 800;

        if(FlxG.save.data.fpsCap < 10)
            FlxG.save.data.fpsCap = 10;

        if(FlxG.save.data.cutscenePlays == null)
            FlxG.save.data.cutscenePlays = "story";

        if(FlxG.save.data.binds == null)
            FlxG.save.data.binds = NoteVariables.Default_Binds;

        if(FlxG.save.data.antialiasing == null)
            FlxG.save.data.antialiasing = true;

        if(FlxG.save.data.healthIcons == null)
            FlxG.save.data.healthIcons = true;

        if(FlxG.save.data.chrsAndBGs == null)
            FlxG.save.data.chrsAndBGs = true;

        if(FlxG.save.data.menuBGs == null)
            FlxG.save.data.menuBGs = true;

        if(FlxG.save.data.nohit == null)
            FlxG.save.data.nohit = false;

        if(FlxG.save.data.versionDisplay == null)
            FlxG.save.data.versionDisplay = true;

        if(FlxG.save.data.displayFont == null)
            FlxG.save.data.displayFont = "_sans";

        if(FlxG.save.data.bigNoteSplashes == null)
            FlxG.save.data.bigNoteSplashes = false;

        if(FlxG.save.data.ghostTapping == null)
            FlxG.save.data.ghostTapping = true;

        if(FlxG.save.data.fullscreenBind == null)
            FlxG.save.data.fullscreenBind = "F11";

        if(FlxG.save.data.inputMode == null)
            FlxG.save.data.inputMode = "standard";

        if(FlxG.save.data.judgementTimings == null || FlxG.save.data.judgementTimings.length < 4)
            FlxG.save.data.judgementTimings = [25, 50, 70, 100];

        if(FlxG.save.data.antiMash == null)
            FlxG.save.data.antiMash = true;

        if(FlxG.save.data.marvelousRatings == null)
            FlxG.save.data.marvelousRatings = true;

        if(FlxG.save.data.ratingMode == null)
            FlxG.save.data.ratingMode = "complex";

        if(FlxG.save.data.showRatingsOnSide == null)
            FlxG.save.data.showRatingsOnSide = true;
        
        FlxG.save.flush();

        Conductor.offset = FlxG.save.data.songOffset;

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();
        ModList.load();
    }
}