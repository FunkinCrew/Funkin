package animate;

import animate.FlxSymbol.Parsed;
import animate.FlxSymbol.Timeline;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import haxe.Json;
import lime.utils.Assets;

class AnimateTimeline extends FlxTypedGroup<FlxSprite>
{
	var coolParsed:Parsed;
	var playhead:FlxSprite;

	public var curFrame(default, set):Int;

	function set_curFrame(frm:Int):Int
	{
		if (playhead != null)
			playhead.x = 5 + (frm * 12) + (12 * 5);
		return frm;
	}

	var hudCamShit:FlxCamera;

	public function new(parsed:String)
	{
		super();

		hudCamShit = new FlxCamera();
		hudCamShit.bgColor = null;
		FlxG.cameras.add(hudCamShit, false);

		playhead = new FlxSprite(0, -12).makeGraphic(2, 10, FlxColor.MAGENTA);
		add(playhead);

		hudCamShit.follow(playhead);
		hudCamShit.setScrollBounds(0, null, -14, null);

		curFrame = 0;

		coolParsed = cast Json.parse(Assets.getText(parsed));

		var layerNum:Int = 0;
		for (layer in coolParsed.AN.TL.L)
		{
			var frameNum:Int = 0;

			for (frame in layer.FR)
			{
				var coolFrame:TimelineFrame = new TimelineFrame((frame.I * 12) + 12 * 5, layerNum * 12, frame.DU, frame);
				add(coolFrame);
				frameNum++;
			}

			var layerName:FlxText = new FlxText(0, layerNum * 12, 0, layer.LN, 10);
			layerName.color = FlxColor.PURPLE;
			layerName.scrollFactor.x = 0;

			var layerBG:FlxSprite = new FlxSprite(0, layerNum * 12).makeGraphic(12 * 4, 12);
			layerBG.scrollFactor.x = 0;

			add(layerBG);
			add(layerName);

			layerNum++;
		}

		this.cameras = [hudCamShit];
	}
}
