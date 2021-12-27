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

    var fpsCounter:FPS;

	public function new(inX:Float = 10.0, inY:Float = 10.0, inCol:Int = 0x000000, ?font:String) 
	{
		super();

		x = inX;
		y = inY;
		selectable = false;
		defaultTextFormat = new TextFormat(font != null ? font : openfl.utils.Assets.getFont(Paths.font("vcr.ttf")).fontName, (font == "_sans" ? 12 : 14), inCol);

        fpsCounter = new FPS(10000, 10000, inCol);
        fpsCounter.visible = false;
        Lib.current.addChild(fpsCounter);

		addEventListener(Event.ENTER_FRAME, onEnter);
		width = FlxG.width;
		height = FlxG.height;
	}

	private function onEnter(event:Event)
	{
        currentFPS = fpsCounter.currentFPS;

        if(visible)
        {
            text = "";

            for(i in 0...infoDisplayed.length)
            {
                if(infoDisplayed[i])
                {
                    switch(i)
                    {
                        case 0:
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
        else
            text = "";
	}

    function fps_Function()
    {
        text += "FPS: " + currentFPS;
    }

    function memory_Function()
    {
		var mem:Float = Math.abs(Math.round(System.totalMemory / 1024 / 1024 * 100)/100);
		
		if(mem > memPeak) memPeak = mem;

		text += "MEM: " + mem + " MB\n" + "MEM peak: " + memPeak + " MB";
    }

    function version_Function()
    {
        text += "Version: " + Application.current.meta.get('version');
    }
}