package options;

import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import ui.FlxVirtualPad;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;
import Config;

class SetFpsSubState extends MusicBeatSubstate
{
    var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['default fps', 'ninety fps'];
	var curSelected:Int = 0;
    
    var _pad:FlxVirtualPad;

    var _gamesave:FlxSave;

	public function new()
	{
		super();

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.BLACK);
		bg.alpha = 0.6;
		bg.scrollFactor.set();
		add(bg);

        FlxTween.tween(bg, {alpha: 0.6}, 0.4, {ease: FlxEase.quartInOut});

        grpMenuShit = new FlxTypedGroup<Alphabet>();
		add(grpMenuShit);

		for (i in 0...menuItems.length)
		{
			var songText:Alphabet = new Alphabet(0, (70 * i) + 30, menuItems[i], true, false);
			songText.isMenuItem = true;
			songText.targetY = i;
			grpMenuShit.add(songText);
		}

        var notice = new FlxText(0, 0, 0,"the fps will be changed after you restart the game", 24);
		add(notice);
        notice.x = (FlxG.width / 2) - (notice.width / 2);
        notice.y = FlxG.height - 56;
        notice.alpha = 0.3;

        changeSelection();

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];

        _gamesave = new FlxSave();
    	_gamesave.bind("gamesetup");
        
		_pad = new FlxVirtualPad(UP_DOWN, A_B);
    	_pad.alpha = 0.75;
    	this.add(_pad);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
		/*
		var upP = controls.UP_P;
		var downP = controls.DOWN_P;
		var accepted = controls.ACCEPT;
		*/
		var UP_P = _pad.buttonUp.justReleased;
		var DOWN_P = _pad.buttonDown.justReleased;
		var BACK = _pad.buttonB.justReleased;
		var ACCEPT = _pad.buttonA.justReleased;

        #if android
			var BACK = _pad.buttonB.justPressed || FlxG.android.justReleased.BACK;
		#else
			var BACK = _pad.buttonB.justPressed;
		#end

        if (UP_P)
        {
            changeSelection(-1);
        }
        if (DOWN_P)
        {
            changeSelection(1);
        }

        if (BACK)
        {
            close();
        } 
        
        if (ACCEPT)
        {
            switch (curSelected){
                case 1:
                    new Config().setFrameRate(90);
                default:
                    new Config().setFrameRate();
            }
            close();
        }
        

	}

	override function destroy()
	{
		super.destroy();
	}
    
    function changeSelection(change:Int = 0):Void
    {
        curSelected += change;
    
        if (curSelected < 0)
            curSelected = menuItems.length - 1;
        if (curSelected >= menuItems.length)
            curSelected = 0;
    
        var bullShit:Int = 0;
    
        for (item in grpMenuShit.members)
        {
            item.targetY = bullShit - curSelected;
            bullShit++;
    
            item.alpha = 0.6;
            // item.setGraphicSize(Std.int(item.width * 0.8));
    
            if (item.targetY == 0)
            {
                item.alpha = 1;
                // item.setGraphicSize(Std.int(item.width));
            }
        }
    }
}
