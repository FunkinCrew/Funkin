package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;

/**
	*DEBUG MODE
 */
class Charting extends FlxState
{
	var bf:Boyfriend;
	var textAnim:FlxText;
	var dumbTexts:FlxTypedGroup<FlxText>;
	var animList:Array<String> = [];
	var curAnim:Int = 0;

	override function create()
	{
		FlxG.sound.music.stop();

		var gridBG:FlxSprite = FlxGridOverlay.create(4, 4);

		add(gridBG);

		bf = new Boyfriend(0, 0);
		bf.screenCenter();
		bf.debugMode = true;
		add(bf);

		dumbTexts = new FlxTypedGroup<FlxText>();
		add(dumbTexts);

		textAnim = new FlxText();
		textAnim.size = 26;
		add(textAnim);

		genBoyOffsets();

		super.create();
	}

	function genBoyOffsets(pushList:Bool = true):Void
	{
		var daLoop:Int = 0;
		for (anim => offsets in bf.animOffsets)
		{
			var text:FlxText = new FlxText(10, 20 + (18 * daLoop), 0, anim + ": " + offsets, 15);
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
		textAnim.setPosition(bf.x, bf.y - 60);
		textAnim.text = bf.animation.curAnim.name;

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
			bf.animation.play(animList[curAnim]);
		}

		var upP = FlxG.keys.anyJustPressed([UP]);
		var rightP = FlxG.keys.anyJustPressed([RIGHT]);
		var downP = FlxG.keys.anyJustPressed([DOWN]);
		var leftP = FlxG.keys.anyJustPressed([LEFT]);

		if (upP || rightP || downP || leftP)
		{
			updateTexts();
			if (upP)
				bf.animOffsets.get(animList[curAnim])[1] += 1;
			if (downP)
				bf.animOffsets.get(animList[curAnim])[1] -= 1;
			if (leftP)
				bf.animOffsets.get(animList[curAnim])[0] += 1;
			if (rightP)
				bf.animOffsets.get(animList[curAnim])[0] -= 1;

			updateTexts();
			genBoyOffsets(false);
		}

		super.update(elapsed);
	}
}
