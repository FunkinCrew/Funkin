package ui.stageBuildShit;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;

class StageBuilderState extends MusicBeatState
{
	private var hudGrp:FlxGroup;

	private var sprGrp:FlxGroup;

	override function create()
	{
		super.create();

		FlxG.mouse.visible = true;

		var bg:FlxSprite = FlxGridOverlay.create(10, 10);
		add(bg);

		sprGrp = new FlxGroup();
		add(sprGrp);

		hudGrp = new FlxGroup();
		add(hudGrp);

		var imgBtn:FlxButton = new FlxButton(20, 20, "Load Image", loadImage);
		hudGrp.add(imgBtn);
	}

	function loadImage():Void
	{
		var img:FlxSprite = new FlxSprite().loadGraphic(Paths.image('newgrounds_logo'));
		img.scrollFactor.set(0.5, 2);
		sprGrp.add(img);
	}

	var oldCamPos:FlxPoint = new FlxPoint();
	var oldMousePos:FlxPoint = new FlxPoint();

	override function update(elapsed:Float)
	{
		if (FlxG.mouse.justPressedMiddle)
		{
			oldCamPos.set(FlxG.camera.scroll.x, FlxG.camera.scroll.y);
			oldMousePos.set(FlxG.mouse.screenX, FlxG.mouse.screenY);
		}

		if (FlxG.mouse.pressedMiddle)
		{
			FlxG.camera.scroll.x = oldCamPos.x + (FlxG.mouse.screenX - oldMousePos.x);
			FlxG.camera.scroll.y = oldCamPos.y + (FlxG.mouse.screenY - oldMousePos.y);
		}

		super.update(elapsed);
	}
}
