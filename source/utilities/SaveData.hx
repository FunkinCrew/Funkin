package utilities;

import shaders.NoteColors;
import modding.ModList;
import game.Conductor;
import flixel.FlxG;
import game.Highscore;

class SaveData
{
    public static function init()
    {
        FlxG.save.bind('leathersfunkinengine', 'leather128');

        if(.enemyGlow == null)
            .enemyGlow = true;

        if(.fpsCounter == null)
            .fpsCounter = true;

        if(.memoryCounter == null)
            .memoryCounter = true;

        if(.killBind == null)
            .killBind = "R";

        if(.uiSkin == null)
            .uiSkin = "default";

        if(.msText == null)
            .msText = true;

        if(.downscroll == null)
			.downscroll = false;

        if(.nightMusic == null)
			.nightMusic = false;

        if(.songOffset == null)
            .songOffset = 0;

        if(.discordRPC == null)
            .discordRPC = true;

        if(.quickRestart == null)
            .quickRestart = false;

        if(.fpsCap == null)
            .fpsCap = 120;

        if(.fpsCap > 1000)
            .fpsCap = 1000;

        if(.fpsCap < 10)
            .fpsCap = 10;

        if(.cutscenePlays == null)
            .cutscenePlays = "story";

        if(.binds == null)
            .binds = NoteVariables.Default_Binds;

        if(.antialiasing == null)
            .antialiasing = true;

        if(.healthIcons == null)
            .healthIcons = true;

        if(.chrsAndBGs == null)
            .chrsAndBGs = true;

        if(.menuBGs == null)
            .menuBGs = true;

        if(.nohit == null)
            .nohit = false;

        if(.versionDisplay == null)
            .versionDisplay = true;

        if(.displayFont == null)
            .displayFont = "_sans";

        if(.ghostTapping == null)
            .ghostTapping = true;

        if(.fullscreenBind == null)
            .fullscreenBind = "F11";

        if(.inputMode == null)
            .inputMode = "standard";

        if(.judgementTimings == null || .judgementTimings.length < 4)
            .judgementTimings = [25, 50, 70, 100];

        if(.antiMash == null)
            .antiMash = true;

        if(.marvelousRatings == null)
            .marvelousRatings = true;

        if(.ratingMode == null)
            .ratingMode = "complex";

        if(.showRatingsOnSide == null)
            .showRatingsOnSide = true;

        if(.noteBGAlpha == null)
            .noteBGAlpha = 0;

        if(.noDeath == null)
            .noDeath = false;

        if(.missOnHeldNotes == null)
            .missOnHeldNotes = true;

        if(.extraKeyReminders == null)
            .extraKeyReminders = true;

        if(.playAs == null)
            .playAs = "bf";

        if(.useCustomScrollSpeed == null)
            .useCustomScrollSpeed = false;

        if(.scrollSpeed == null)
            .scrollSpeed = 1;

        if(.hitsound == null)
            .hitsound = "none";

        if(.cameraTracksDirections == null)
            .cameraTracksDirections = false;

        if(.cameraZooms == null)
            .cameraZooms = true;

        if(.missOnShit == null)
            .missOnShit = true;

        if(.playerNoteSplashes == null && .opponentNoteSplashes == null)
        {
            if(.noteSplashes == true)
            {
                if(.playerNoteSplashes == null)
                    .playerNoteSplashes = true;
        
                if(.opponentNoteSplashes == null)
                    .opponentNoteSplashes = true;
            }
            else if(.noteSplashes == false)
            {
                if(.playerNoteSplashes == null)
                    .playerNoteSplashes = false;
        
                if(.opponentNoteSplashes == null)
                    .opponentNoteSplashes = false;
            }
            else
            {
                if(.playerNoteSplashes == null)
                    .playerNoteSplashes = true;
        
                if(.opponentNoteSplashes == null)
                    .opponentNoteSplashes = false;
            }

            .noteSplashes = null;
        }

        if(.biggerScoreInfo == null)
            .biggerScoreInfo = false;

        if(.biggerInfoText == null)
            .biggerInfoText = false;
        
        FlxG.save.flush();

        Options.init();

        Conductor.offset = .songOffset;

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();
        ModList.load();
        NoteColors.load();
    }

    public static function fixBinds()
    {
        if(.binds == null)
            .binds = NoteVariables.Default_Binds;
        
        if(.binds.length < NoteVariables.Default_Binds.length)
        {
            for(i in Std.int(.binds.length - 1)...NoteVariables.Default_Binds.length)
            {
                .binds[i] = NoteVariables.Default_Binds[i];
            }
        }
    }
}