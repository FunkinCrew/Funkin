package utilities;

import shaders.NoteColors;
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

        if(FlxG.save.data.noteBGAlpha == null)
            FlxG.save.data.noteBGAlpha = 0;

        if(FlxG.save.data.noDeath == null)
            FlxG.save.data.noDeath = false;

        if(FlxG.save.data.missOnHeldNotes == null)
            FlxG.save.data.missOnHeldNotes = true;

        if(FlxG.save.data.extraKeyReminders == null)
            FlxG.save.data.extraKeyReminders = true;

        if(FlxG.save.data.playAs == null)
            FlxG.save.data.playAs = "bf";

        if(FlxG.save.data.useCustomScrollSpeed == null)
            FlxG.save.data.useCustomScrollSpeed = false;

        if(FlxG.save.data.scrollSpeed == null)
            FlxG.save.data.scrollSpeed = 1;

        if(FlxG.save.data.hitsound == null)
            FlxG.save.data.hitsound = "none";

        if(FlxG.save.data.cameraTracksDirections == null)
            FlxG.save.data.cameraTracksDirections = false;

        if(FlxG.save.data.cameraZooms == null)
            FlxG.save.data.cameraZooms = true;

        if(FlxG.save.data.missOnShit == null)
            FlxG.save.data.missOnShit = true;

        if(FlxG.save.data.playerNoteSplashes == null && FlxG.save.data.opponentNoteSplashes == null)
        {
            if(FlxG.save.data.noteSplashes == true)
            {
                if(FlxG.save.data.playerNoteSplashes == null)
                    FlxG.save.data.playerNoteSplashes = true;
        
                if(FlxG.save.data.opponentNoteSplashes == null)
                    FlxG.save.data.opponentNoteSplashes = true;
            }
            else if(FlxG.save.data.noteSplashes == false)
            {
                if(FlxG.save.data.playerNoteSplashes == null)
                    FlxG.save.data.playerNoteSplashes = false;
        
                if(FlxG.save.data.opponentNoteSplashes == null)
                    FlxG.save.data.opponentNoteSplashes = false;
            }
            else
            {
                if(FlxG.save.data.playerNoteSplashes == null)
                    FlxG.save.data.playerNoteSplashes = true;
        
                if(FlxG.save.data.opponentNoteSplashes == null)
                    FlxG.save.data.opponentNoteSplashes = false;
            }

            FlxG.save.data.noteSplashes = null;
        }

        if(FlxG.save.data.biggerScoreInfo == null)
            FlxG.save.data.biggerScoreInfo = false;

        if(FlxG.save.data.biggerInfoText == null)
            FlxG.save.data.biggerInfoText = false;
        
        FlxG.save.flush();

        Conductor.offset = FlxG.save.data.songOffset;

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();
        ModList.load();
        NoteColors.load();
    }

    public static function fixBinds()
    {
        if(FlxG.save.data.binds == null)
            FlxG.save.data.binds = NoteVariables.Default_Binds;
        
        if(FlxG.save.data.binds.length < NoteVariables.Default_Binds.length)
        {
            for(i in Std.int(FlxG.save.data.binds.length - 1)...NoteVariables.Default_Binds.length)
            {
                FlxG.save.data.binds[i] = NoteVariables.Default_Binds[i];
            }
        }
    }
}