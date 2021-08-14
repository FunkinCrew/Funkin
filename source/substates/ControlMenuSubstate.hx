package substates;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;

class ControlMenuSubstate extends MusicBeatSubstate
{
    var key_Count:Int = 4;

    public function new()
    {
        super();
        
        var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
        bg.alpha = 0.5;
        bg.scrollFactor.set();
        add(bg);

        create_Arrows();
    }

    override function update(elapsed:Float) {
        super.update(elapsed);

        var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
        var back = controls.BACK;

        if(back)
        {
            FlxG.save.flush();
            FlxG.state.closeSubState();
        }
    }

    function create_Arrows(?new_Key_Count = 4)
    {
        if(new_Key_Count != null)
            key_Count = new_Key_Count;


    }
}