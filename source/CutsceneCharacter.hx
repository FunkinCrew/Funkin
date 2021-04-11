package;

import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;

using StringTools;

class CutsceneCharacter extends FlxTypedGroup<FlxSprite>
{
	public var coolPos:FlxPoint = FlxPoint.get();
	public var animShit:Map<String, FlxPoint> = new Map();

	private var imageShit:String;

	public function new(x:Float, y:Float, imageShit:String)
	{
		super();

		coolPos.set(x, y);

		this.imageShit = imageShit;
		parseOffsets();
		createCutscene(0);
	}

	// shitshow, oh well
	var arrayLMFAOOOO:Array<String> = [];

	function parseOffsets()
	{
		var splitShit:Array<String> = CoolUtil.coolTextFile(Paths.file('images/cutsceneStuff/' + imageShit + "CutsceneOffsets.txt"));

		for (i in splitShit)
		{
			var xAndY:FlxPoint = FlxPoint.get();
			var dumbSplit:Array<String> = i.split('---')[1].trim().split(' ');
			trace('cool split: ' + i.split('---')[1]);
			trace(dumbSplit);
			xAndY.set(Std.parseFloat(dumbSplit[0]), Std.parseFloat(dumbSplit[1]));

			animShit.set(i.split('---')[0].trim(), xAndY);
			arrayLMFAOOOO.push(i.split('---')[0].trim());
		}

		trace(animShit);
	}

	public function createCutscene(daNum:Int = 0)
	{
		var cutScene:FlxSprite = new FlxSprite(coolPos.x + animShit.get(arrayLMFAOOOO[daNum]).x, coolPos.y + animShit.get(arrayLMFAOOOO[daNum]).y);
		cutScene.frames = Paths.getSparrowAtlas('cutsceneStuff/' + imageShit + "-" + daNum);
		cutScene.animation.addByPrefix('weed', arrayLMFAOOOO[daNum], 24, false);
		cutScene.animation.play('weed');
		cutScene.antialiasing = true;

		cutScene.animation.finishCallback = function(anim:String)
		{
			cutScene.kill();
			cutScene.destroy();
			cutScene = null;

			if (daNum + 1 < arrayLMFAOOOO.length)
				createCutscene(daNum + 1);
			else
				ended();
		};

		add(cutScene);
	}

	public var onFinish:Void->Void;

	public function ended():Void
	{
		if (onFinish != null)
			onFinish();
	}
}
