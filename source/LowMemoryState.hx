package;

import flixel.effects.FlxFlicker;
import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.group.FlxSpriteGroup;
import ui.Mobilecontrols;
import sys.FileSystem;
import sys.io.File;
import lime.system.JNI;
import flixel.text.FlxText;
import sys.io.Process;
import openfl.system.System;

using StringTools;

class LowMemoryState extends MusicBeatState {
    var sizeStrings = ['keep original', '75%', '50%', '10%'];
	var curSelected:Int;
    var sizeItems:FlxSpriteGroup;
	var selectedSomethin:Bool;


    override function create() {
        var total = Std.int(getTotal() / (1024 * 1024));

        var text = new FlxText(0,0, 0,  '${total} Gb is not enough for fnf\nwanna choice texture size?', 64);
        text.screenCenter();
        text.y -= 200;
        add(text);

        sizeItems = new FlxSpriteGroup();

        for (i in 0...sizeStrings.length) {
            var sizeText = new FlxText(if (i != 0) 50 else 0, 50 * (i + 1), 0, sizeStrings[i], 24);
            sizeItems.add(sizeText);
        }
        sizeItems.screenCenter();
        add(sizeItems);

        if (PlayerSettings.player1 == null)
            PlayerSettings.init();

        if (Mobilecontrols.isEnabled)
        {
            add(Mobilecontrols.createVirtualPad(UP_DOWN, A));
        }

        changeItem();

        super.create();
    }

    override function update(elapsed:Float) {
        if (!selectedSomethin)
		{
			if (controls.UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.ACCEPT)
			{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					FlxFlicker.flicker(sizeItems.members[curSelected], 1.1, 0.15, false);

					switch (curSelected)
                    {
                        case 1: // 0.75
                            AssetManager.maxCustomTextureSize = 0.75;

                        case 2: // 0.5
                            AssetManager.maxCustomTextureSize = 0.5;

                        case 3: // 0.1
                            AssetManager.maxCustomTextureSize = 0.1;
                        default:

                    }

                    FlxG.switchState(new TitleState());
				
			}
		}
        super.update(elapsed);
    }

    function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= sizeItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = sizeItems.length - 1;

		var it:FlxText = cast sizeItems.members[curSelected];

        it.color = FlxColor.YELLOW;

        sizeItems.forEach(i -> if (i != it) i.color = FlxColor.WHITE);
	}

    public static function isNotEnoughRam() {
        var total = getTotal();
        if (total != null)
            return total < 3145728; // 3gb
        else 
            return false;
    }

    // kB
    public static function getTotal():Null<Int> {
        #if (android || linux)
        try{
            var f = File.read('/proc/meminfo');
            var result = f.readAll().toString();
            if (result == "" || result == null || result.charAt(0) != "M")
                return null;
            var memTotalLine = result.split('\n')[0];
            memTotalLine = memTotalLine.replace(' ', '');
            memTotalLine = memTotalLine.replace('kB', '');
            memTotalLine = memTotalLine.replace('MemTotal:', '');

            return Std.parseInt(memTotalLine);
        }
        #end

        return null;
    }
}