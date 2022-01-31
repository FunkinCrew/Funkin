package animate;

import flixel.FlxG;
import lime.utils.Assets;
import haxe.Json;

using StringTools;

class FlxAnimate extends FlxSymbol
{
	var playingAnim:Bool = false;
	var frameTickTypeShit:Float = 0;

	/* override public function new(X:Float, Y:Float)
	{
		coolParse = Json.parse(Assets.getText(Paths.getPath('images/tightBars/Animation.json', TEXT, null)));
		coolParse.AN.TL.L.reverse();
		super(X, Y, coolParse);
		frames = fromAnimate(Paths.image('tightBars/spritemap1'), Paths.xml('tightBars/spritemap1'));
	}

	public static function fromAnimate(img:String, xml:String)
	{

	}

	override function draw()
	{
		super.draw();

		renderFrame(coolParse.AN.TL, coolParse, true);
		
		if (FlxG.keys.justPressed.E)
		{
			for (i in FlxSymbol.nestedShit.keys())
			{
				for (j in FlxSymbol.nestedShit.get(i))
				{
					j.draw();
				}
			}
			FlxSymbol.nestedShit.clear();
		}
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (FlxG.keys.justPressed.SPACE)
		{
			playingAnim = !playingAnim;
		}

		if (playingAnim)
		{
			frameTickTypeShit += elapsed;
			
			if (frameTickTypeShit >= 1 / 24)
			{
				changeFrame(1);
				frameTickTypeShit = 0;
			}
		}

		if (FlxG.keys.justPressed.RIGHT)
		{
			changeFrame(1);
		}
		if (FlxG.keys.justPressed.LEFT)
		{
			changeFrame(-1);
		}
	} */
}