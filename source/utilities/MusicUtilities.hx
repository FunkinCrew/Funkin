package utilities;

import flixel.FlxG;

class MusicUtilities
{

    /**
    * This function returns the string path of the current music that should be played (as a replacement for the title screen music)
    */
    public static function GetTitleMusicPath():String
    {
        if (utilities.Options.getData("oldTitle"))
            return Paths.music('title');
        else
            if (Date.now().getDay() == 5 && Date.now().getHours() >= 18 || utilities.Options.getData("nightMusic"))
                return Paths.music('freakyNightMenu');
            else
                return Paths.music('freakyMenu');

        return Paths.music('freakyMenu');
    }

    /**
    * This function returns the string path of the current options menu music.
    */
    public static function GetOptionsMenuMusic():String
    {
        return Paths.music('optionsMenu');
    }
}