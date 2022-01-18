package;

import animate.FlxAnimate;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;

using StringTools;

class CutsceneAnimTestState extends FlxState
{
	var curSelected:Int = 0;
	var debugTxt:FlxText;

	override public function new()
	{
		super();
		var a = FlxGridOverlay.create(10, 10);
		a.scrollFactor.set(.5, .5);
		add(a);
		debugTxt = new FlxText(900, 20, 0, "", 20);
		debugTxt.color = 0xFF0000FF;
		add(debugTxt);
		var b = new FlxAnimate(600, 200);
		add(b);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}