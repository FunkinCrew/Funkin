package options;

import haxe.Http;
import haxe.Json;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.ui.FlxVirtualPad;
import flixel.util.FlxSave;
import flixel.math.FlxPoint;

class ModsState extends MusicBeatSubstate
{
    var grpMenuShit:FlxTypedGroup<Alphabet>;

	var menuItems:Array<String> = ['default fps', 'ninety fps'];
	var curSelected:Int = 0;
    
    var _pad:FlxVirtualPad;

    static inline final url:String = "http://localhost:80/api/mods/";
	public var http = new haxe.Http(url);

    var output:Json;


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

		cameras = [FlxG.cameras.list[FlxG.cameras.list.length - 1]];
        
		_pad = new FlxVirtualPad(UP_DOWN, A_B);
    	_pad.alpha = 0.75;
    	this.add(_pad);

        init();
	}

    function setsec(data) {
        /*
        for (i in 0...data.length)
        {
            var songText:Alphabet = new Alphabet(0, (70 * i) + 30, data[i].name, true, false);
            songText.isMenuItem = true;
            songText.targetY = i;
            grpMenuShit.add(songText);
        }
        */
            
        changeSelection();
    }

    function init() {
        http.onData = function (data:String) {
			output = haxe.Json.parse(data);
            trace(output);
            //setsec(output);
		}
		http.onError = function (error) {
			trace(error);
            FlxG.switchState(new options.OptionsMenu());
		}
		http.request(); 
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
        
        if (ACCEPT || FlxG.android.justReleased.BACK == true)
        {
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
