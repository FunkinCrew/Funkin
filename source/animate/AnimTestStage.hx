package animate;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;

class AnimTestStage extends FlxState
{
	override function create()
	{
		var bg:FlxSprite = FlxGridOverlay.create(32, 32);
		add(bg);
		bg.scrollFactor.set();

		var swag:FlxAnimate = new FlxAnimate(200, 200);
		add(swag);

		super.create();
	}

	override function update(elapsed:Float)
	{
		CoolUtil.mouseWheelZoom();
		CoolUtil.mouseCamDrag();

		super.update(elapsed);
	}
}
