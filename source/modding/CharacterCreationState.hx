package modding;

import states.OptionsMenu;
import utilities.MusicUtilities;
import flixel.FlxG;
import game.Conductor;
import states.MusicBeatState;

#if discord_rpc
import utilities.Discord.DiscordClient;
#end

using StringTools;

class CharacterCreationState extends MusicBeatState
{
    override public function new(?char:String = "bf")
    {
        super();
    }

    override public function create()
    {
        #if discord_rpc
        DiscordClient.changePresence("Creating characters.", null, null, true);
        #end

        super.create();

        if(FlxG.sound.music == null)
            FlxG.sound.playMusic(MusicUtilities.GetOptionsMenuMusic(), 0.7, true);
    }

    override function update(elapsed:Float)
    {
        super.update(elapsed);

        if(FlxG.sound.music != null)
            Conductor.songPosition = FlxG.sound.music.time;

        if(controls.BACK)
            FlxG.switchState(new OptionsMenu());
    }
}