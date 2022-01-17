package utilities;

import shaders.NoteColors;
import modding.ModList;
import game.Highscore;

class SaveData
{
    public static function init()
    {
        Options.init();

        PlayerSettings.init();
        PlayerSettings.player1.controls.loadKeyBinds();
        
        Highscore.load();
        ModList.load();
        NoteColors.load();
    }

    public static function fixBinds()
    {
        /*
        if(.binds == null)
            .binds = NoteVariables.Default_Binds;
        
        if(.binds.length < NoteVariables.Default_Binds.length)
        {
            for(i in Std.int(.binds.length - 1)...NoteVariables.Default_Binds.length)
            {
                .binds[i] = NoteVariables.Default_Binds[i];
            }
        }*/
    }
}