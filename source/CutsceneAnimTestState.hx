package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.Assets;
import openfl.display.BitmapData;
import openfl.display.MovieClip;

class CutsceneAnimTestState extends FlxState
{
	var cutsceneGroup:CutsceneCharacter;

	var curSelected:Int = 0;
	var debugTxt:FlxText;

	var funnySprite:FlxSprite = new FlxSprite();
	var clip:MovieClip;

	public function new()
	{
		super();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

		debugTxt = new FlxText(900, 20, 0, "", 20);
		debugTxt.color = FlxColor.BLUE;
		add(debugTxt);

		clip = Assets.getMovieClip("tanky:");
		clip.x = FlxG.width/2;
		clip.y = FlxG.height/2;
		FlxG.stage.addChild(clip);

		funnySprite.x = FlxG.width/2;
		add(funnySprite);

	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		var funnyBmp:BitmapData = new BitmapData(FlxG.width, FlxG.height, true, 0x00000000);
		funnyBmp.draw(clip, clip.transform.matrix, true);
		funnySprite.loadGraphic(funnyBmp);
	}
}
