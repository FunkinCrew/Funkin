package;

import animate.FlxAnimate;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;

// import animateAtlasPlayer.assets.AssetManager;
// import animateAtlasPlayer.core.Animation;
class CutsceneAnimTestState extends FlxState
{
	var cutsceneGroup:CutsceneCharacter;

	var curSelected:Int = 0;
	var debugTxt:FlxText;

	public function new()
	{
		super();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

		debugTxt = new FlxText(900, 20, 0, "", 20);
		debugTxt.color = FlxColor.BLUE;
		add(debugTxt);

		var animated:FlxAnimate = new FlxAnimate(600, 200);
		add(animated);

		// createCutscene(0);
		// createCutscene(1);
		// createCutscene(2);
		// createCutscene(3);
		// createCutscene(4);
	}

	override function update(elapsed:Float)
	{
		/* if (FlxG.keys.pressed.SHIFT)
			{
				if (FlxG.keys.justPressed.UP)
					curSelected -= 1;
				if (FlxG.keys.justPressed.DOWN)
					curSelected += 1;

				if (curSelected < 0)
					curSelected = cutsceneGroup.members.length - 1;
				if (curSelected >= cutsceneGroup.members.length)
					curSelected = 0;
			}
			else
			{
				var valueMulti:Float = 1;

				if (FlxG.keys.pressed.SPACE)
					valueMulti = 10;

				if (FlxG.keys.justPressed.UP)
					cutsceneGroup.members[curSelected].y -= valueMulti;
				if (FlxG.keys.justPressed.DOWN)
					cutsceneGroup.members[curSelected].y += valueMulti;
				if (FlxG.keys.justPressed.LEFT)
					cutsceneGroup.members[curSelected].x -= valueMulti;
				if (FlxG.keys.justPressed.RIGHT)
					cutsceneGroup.members[curSelected].x += valueMulti;
			}

			debugTxt.text = curSelected + " : " + cutsceneGroup.members[curSelected].getPosition();
		 */

		super.update(elapsed);
	}
}
