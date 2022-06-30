package ui;

import openfl.Lib;
import openfl.display.FPS;
import flixel.FlxG;
import lime.app.Application;
import openfl.events.Event;
import openfl.system.System;
import openfl.text.TextField;
import openfl.text.TextFormat;

/**
 * FPS class extension to display memory usage.
 * @author Kirill Poletaev
 */

class SimpleInfoDisplay extends TextField
{
    //                                      fps    mem    version
    public var infoDisplayed:Array<Bool> = [false, false, false];

	public var memPeak:Float = 0;

    public var currentFPS:Int = 0;

    public var currentTime:Float = 0.0;
	public var times:Array<Float> = [];

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000, ?font:String) 
	{
		super();

		x = inX;
		y = inY;
		selectable = false;
		defaultTextFormat = new TextFormat(font != null ? font : openfl.utils.Assets.getFont(Paths.font("vcr.ttf")).fontName, (font == "_sans" ? 12 : 14), inCol);

		addEventListener(Event.ENTER_FRAME, onEnter);

		width = FlxG.width;
		height = FlxG.height;
	}

	private function onEnter(event:Event)
	{
        text = "";

        if(visible)
        {
            for(i in 0...infoDisplayed.length)
            {
                if(infoDisplayed[i])
                {
                    switch(i)
                    {
                        case 0:
                            currentTime = Lib.getTimer();
                            times.push(currentTime);
                    
                            while(currentTime > times[0] + 1000)
                            {
                                times.remove(times.shift());
                            }
                    
                            currentFPS = times.length;

                            // FPS
                            fps_Function();
                        case 1:
                            // Memory
                            memory_Function();
                        case 2:
                            // Version
                            version_Function();
                    }

                    text += "\n";
                }
            }
        }
	}

    function fps_Function()
    {
        text += "FPS: " + currentFPS;
    }

    function memory_Function()
    {
		var mem:Float = Math.fround(System.totalMemory / 1024.0 / 1024.0 * 100.0) / 100.0;

		if(mem != Math.abs(mem))
			mem = 2048.0 + (2048.0 - Math.abs(mem));
		
		if(mem > memPeak) memPeak = mem;

		text += "MEM: " + mem + " MB\n" + "MEM peak: " + memPeak + " MB";
    }

    function version_Function()
    {
        text += "Version: " + Application.current.meta.get('version');
    }
}
