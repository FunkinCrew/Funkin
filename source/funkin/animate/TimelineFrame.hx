package funkin.animate;

import funkin.animate.ParseAnimate.Frame;
import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.util.FlxColor;

class TimelineFrame extends FlxSprite
{
	public var data:Frame;

	public function new(x:Float, y:Float, length:Int = 0, data:Frame)
	{
		super(x, y);

		this.data = data;

		makeGraphic((10 * length) + (2 * (length - 1)), 10, FlxColor.RED);

		FlxMouseEvent.add(this, null, null, function(spr:TimelineFrame)
		{
			alpha = 0.5;
		}, function(spr:TimelineFrame)
		{
			alpha = 1;
		}, false, true, true);
	}

	override function update(elapsed:Float)
	{
		// if (FlxG.mouse.overlaps(this, cameras[1]))
		// alpha = 0.6;
		// else
		// alpha = 1;

		if (FlxG.mouse.overlaps(this, cameras[0]) && FlxG.mouse.justPressed)
		{
			trace("\nFRAME DATA - \n\tFRAME NUM: " + data.I + "\n\tFRAME DURATION: " + data.DU);

			for (e in data.E)
			{
				var elementOutput:String = "\n";

				if (Reflect.hasField(e, 'ASI'))
				{
					elementOutput += "ELEMENT IS ASI!";

					elementOutput += "\n\t";
					elementOutput += "FRAME NAME: " + e.ASI.N;
				}
				else
				{
					elementOutput += "ELEMENT IS SYMBOL INSTANCE!";
					elementOutput += "\n\tSYMBOL NAME: " + e.SI.SN;
				}

				trace(elementOutput);
			}
		}

		super.update(elapsed);
	}
}
