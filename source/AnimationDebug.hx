package;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;

/**
	*DEBUG MODE
 */
class AnimationDebug extends FlxState
{
	var bf:Boyfriend;
	var dad:Character;
	var char:Character;
	var textAnim:FlxText;
	var textCam:FlxText;
	var camOffsetText:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;
	var isDad:Bool = true;
	var daAnim:String = 'spooky';
	var daOtherAnim:String = 'bf';
	var camFollow:FlxObject;

	public function new(daAnim:String = 'spooky', daOtherAnim:String = 'bf')
	{
		super();
		this.daAnim = daAnim;
		this.daOtherAnim = daOtherAnim;
	}

	override function create()
	{
		FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(10, 10);
		gridBG.scrollFactor.set(0.5, 0.5);
		add(gridBG);

			dad = new Character(100, 100, daAnim);
			dad.debugMode = true;
			add(dad);

			char = dad;
			dad.flipX = false;

			bf = new Boyfriend(770, 450, daOtherAnim);
			bf.debugMode = true;
			add(bf);

			char = dad;
			bf.flipX = false;

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText(300, 16);
		textAnim.size = 26;
		textAnim.scrollFactor.set();
		add(textAnim);

		genBoyOffsets();

		camFollow = new FlxObject(0, 0, 2, 2);
		camFollow.screenCenter();
		add(camFollow);

		textCam = new FlxText(500, 16);
		textCam.size = 14;
		textCam.scrollFactor.set();
		add(textCam);

		camOffsetText = new FlxText(500, 46);
		camOffsetText.size = 14;
		camOffsetText.scrollFactor.set();
		add(camOffsetText);

		FlxG.camera.follow(camFollow);

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;

		for (anim => offsets in char.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
			text.scrollFactor.set();
			text.color = FlxColor.BLUE;
			dumbTexts.add(text);

			if (pushList)
				animList.push(anim);

			daLoop++;
		}
	}

	function updateTexts():Void
	{
		dumbTexts.forEach(function(text:FlxText)
		{
			text.kill();
			dumbTexts.remove(text, true);
		});
	}

	override function update(elapsed:Float)
	{
		/*
		TODO

		make cam offset editing better

		 */
		textAnim.text = char.animation.curAnim.name;

		textCam.text = camFollow.x + ", " + camFollow.y;

		camOffsetText.text = ((bf.followCamX - camFollow.x) + ", " + (bf.followCamY - camFollow.y));
		// you're gonna need some math to fix these camera offsets!

		if (FlxG.keys.justPressed.E)
			FlxG.camera.zoom += (0.25 * 0.25); // this could either make zooming better or break it entirely
		if (FlxG.keys.justPressed.Q)
			FlxG.camera.zoom -= (0.25 * 0.25);

		var holdShift = FlxG.keys.pressed.SHIFT;
		var holdCtrl = FlxG.keys.pressed.CONTROL;
		var multiplier = 1;
		if (holdShift)
			multiplier = 10;
		if (holdCtrl)
			multiplier = 100;

		if (FlxG.keys.pressed.I || FlxG.keys.pressed.J || FlxG.keys.pressed.K || FlxG.keys.pressed.L)
		{
			if (FlxG.keys.pressed.I)
				camFollow.velocity.y = -90 * multiplier;
			else if (FlxG.keys.pressed.K)
				camFollow.velocity.y = 90 * multiplier;
			else
				camFollow.velocity.y = 0;

			if (FlxG.keys.pressed.J)
				camFollow.velocity.x = -90 * multiplier;
			else if (FlxG.keys.pressed.L)
				camFollow.velocity.x = 90 * multiplier;
			else
				camFollow.velocity.x = 0;
		}
		else if (FlxG.keys.pressed.F)
		{
			if (holdShift)
				camFollow.setPosition(bf.getMidpoint().x + bf.followCamX, bf.getMidpoint().y + bf.followCamY);
			else
				camFollow.setPosition(bf.getMidpoint().x, bf.getMidpoint().y);
		}
		else
		{
			camFollow.velocity.set();
		}

		if (FlxG.keys.justPressed.W)
		{
			curAnim -= 1;
		}

		if (FlxG.keys.justPressed.S)
		{
			curAnim += 1;
		}

		if (curAnim < 0)
			curAnim = animList.length - 1;

		if (curAnim >= animList.length)
			curAnim = 0;

		if (FlxG.keys.justPressed.S || FlxG.keys.justPressed.W || FlxG.keys.justPressed.SPACE)
		{
			char.playAnim(animList[curAnim]);

			updateTexts();
			genBoyOffsets(false);
		}

		if (FlxG.keys.justPressed.G)
		{
			bf.flipX = !bf.flipX;
		}

		if (FlxG.keys.justPressed.Y) //camera origin
		{
			camFollow.x = 0;
			camFollow.y = 0;
		}

		//if (FlxG.keys.justPressed.T) // this is supposed to swap the character whose anims ur editing, i dont know why its not working
		//{
		//	updateTexts();
		//
		//	if (char == bf)
		//		char == dad;
		//	if (char == dad)
		//		char == bf;
		//
		//	updateTexts();
		//	genBoyOffsets(false);
		//	char.playAnim(animList[curAnim]);
		//}

		if (FlxG.keys.justPressed.ENTER)
		{
			FlxG.switchState(new FreeplayState());
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);



		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
				char.animOffsets.get(animList[curAnim])[1] += 1 * multiplier;
			if (downP)
				char.animOffsets.get(animList[curAnim])[1] -= 1 * multiplier;
			if (leftP)
				char.animOffsets.get(animList[curAnim])[0] += 1 * multiplier;
			if (rightP)
				char.animOffsets.get(animList[curAnim])[0] -= 1 * multiplier;

			updateTexts();
			genBoyOffsets(false);
			char.playAnim(animList[curAnim]);
		}

		super.update(elapsed);
	}
}
