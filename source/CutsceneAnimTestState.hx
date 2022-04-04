package;

import animate.FlxAnimate;
import flixel.util.FlxColor;
import flixel.FlxState;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.text.FlxText;

class CutsceneAnimTestState extends FlxState
{
	var curSelected:Int = 0;
	var debugTxt:FlxText;

	override public function new()
	{
		super();
		var grid:FlxSprite = FlxGridOverlay.create(10, 10);
		grid.scrollFactor.set(0.5, 0.5);
		add(grid);
		debugTxt = new FlxText(900, 20, 0, "", 20);
		debugTxt.color = FlxColor.BLUE;
		add(debugTxt);
		var tankman:FlxAnimate = new FlxAnimate(600, 200);
		add(tankman);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}
}