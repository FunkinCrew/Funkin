package;

import flixel.FlxSprite;
import flixel.math.FlxPoint;
import flixel.group.FlxGroup.FlxTypedGroup;
import haxe.ds.StringMap;

using StringTools;

class CutsceneCharacter extends FlxTypedGroup<Dynamic>
{
	var coolPos:FlxPoint;
	var animShit = new StringMap<FlxPoint>();
	var arrayLMFAOOOO = [];
	var imageShit:String;

	public var onFinish:Dynamic;

	override public function new(x:Float, y:Float, image:String)
	{
		super();

		coolPos = FlxPoint.get(x, y);
		imageShit = image;
		parseOffsets();
		createCutscene(0);
	}

	function parseOffsets()
	{
		var swag = CoolUtil.coolTextFile(Paths.getPath('images/cutsceneStuff/' + this.imageShit + 'CutscenOffsets.txt', TEXT, null));
		for (stuff in swag)
		{
			var point = FlxPoint.get();
			var coords = stuff.split('---')[1].trim().split(' ');
			
			trace('cool split: ' + stuff.split('---')[1]);
			trace(coords);
			
			point.set(Std.parseFloat(coords[0]), Std.parseFloat(coords[1]));
			
			var name = stuff.split('---')[0].trim();
			animShit.set(name, point);
			
			arrayLMFAOOOO.push(stuff.split('---')[0].trim());
		}

		trace(animShit == null ? 'null' : animShit);
	}

	function createCutscene(num:Int = 0)
	{
		var spr = new FlxSprite(coolPos.x + animShit.get(arrayLMFAOOOO[num]).x, coolPos.y + animShit.get(arrayLMFAOOOO[num]).y);
		var path = 'cutsceneStuff/' + imageShit + '-' + num;
		spr.frames = Paths.getSparrowAtlas(path);
		spr.animation.addByPrefix('weed', arrayLMFAOOOO[num], 24, false);
		spr.animation.play('weed');
		spr.antialiasing = true;
		spr.animation.finishCallback = function(name)
		{
			spr.kill();
			spr.destroy();
			spr = null;
			
			if (num + 1 < arrayLMFAOOOO.length)
			{
				createCutscene(num + 1);
			}
			else
			{
				ended();
			}
		};
	}

	function ended()
	{
		if (onFinish != null)
		{
			onFinish();
		}
	}
}