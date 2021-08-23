package;

import flixel.FlxState;
import flixel.FlxG;
import flixel.FlxObject;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.FlxCamera;
import flixel.FlxSprite;

class StagePositioningDebug extends FlxState
{
	public var daStage:String;
	public var daBf:String;
	public var daGf:String;
	public var opponent:String;

	var gf:Character;
	var boyfriend:Boyfriend;
	var dad:Character;
	var Stage:Stage;
	var camFollow:FlxObject;
	var posText:FlxText;
	var curChar:FlxSprite;
	var curCharIndex:Int = 0;
	var curCharString:String;
	var curChars:Array<FlxSprite>;
	var dragging:Bool = false;
	var oldMousePosX:Int;
	var oldMousePosY:Int;
	var camHUD:FlxCamera;
	var camGame:FlxCamera;

	public function new(daStage:String = 'stage', daGf:String = 'gf', daBf:String = 'bf', opponent:String = 'dad')
	{
		super();
		this.daStage = daStage;
		this.daGf = daGf;
		this.daBf = daBf;
		this.opponent = opponent;
		curCharString = daGf;
	}

	override function create()
	{
		FlxG.sound.music.stop();
		FlxG.mouse.visible = true;

		Stage = PlayState.Stage;

		gf = PlayState.gf;
		boyfriend = PlayState.boyfriend;
		dad = PlayState.dad;
		curChars = [gf, boyfriend, dad];
		curChar = curChars[curCharIndex];

		for (i in Stage.toAdd)
		{
			add(i);
		}

		for (index => array in Stage.layInFront)
		{
			switch (index)
			{
				case 0:
					add(gf);
					for (bg in array)
						add(bg);
				case 1:
					add(dad);
					for (bg in array)
						add(bg);
				case 2:
					add(boyfriend);
					for (bg in array)
						add(bg);
			}
		}

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		camHUD = new FlxCamera();
		camHUD.bgColor.alpha = 0;
		camGame = new FlxCamera();
		camGame.zoom = 0.7;
		FlxG.cameras.add(camGame);
		FlxG.cameras.add(camHUD);
		FlxCamera.defaultCameras = [camGame];
		camGame.follow(camFollow);

		posText = new FlxText(0, 0);
		posText.size = 26;
		posText.scrollFactor.set();
		posText.cameras = [camHUD];
		add(posText);
	}

	override public function update(elapsed:Float)
	{
		if (FlxG.keys.justPressed.E)
			camGame.zoom += 0.1;
		if (FlxG.keys.justPressed.Q)
		{
			if (camGame.zoom > 0.11) // me when floating point error
				camGame.zoom -= 0.1;
		}
        FlxG.watch.addQuick('Camera Zoom', camGame.zoom);

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90;
			else
				camFollow.velocity.x = 0;
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.SPACE)
		{
			++curCharIndex;
			if (curCharIndex >= curChars.length)
			{
				curChar = curChars[0];
				curCharIndex = 0;
			}
			else
				curChar = curChars[curCharIndex];
			switch (curCharIndex)
			{
				case 0:
					curCharString = daGf;
				case 1:
					curCharString = daBf;
				case 2:
					curCharString = opponent;
			}
		}

		if (FlxG.mouse.pressed && curChar.pixelsOverlapPoint(FlxG.mouse.getPosition()) && !dragging)
		{
			dragging = true;
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justMoved)
		{
			curChar.setPosition(-(oldMousePosX - FlxG.mouse.x) + curChar.x, -(oldMousePosY - FlxG.mouse.y) + curChar.y);
			updateMousePos();
		}

		if (dragging && FlxG.mouse.justReleased || FlxG.keys.justPressed.TAB)
			dragging = false;

		posText.text = (curCharString + " X: " + curChar.x + " Y: " + curChar.y);

		if (FlxG.keys.justPressed.ESCAPE)
			FlxG.switchState(new MainMenuState());

		super.update(elapsed);
	}

	public function updateMousePos()
	{
		oldMousePosX = FlxG.mouse.x;
		oldMousePosY = FlxG.mouse.y;
	}
}