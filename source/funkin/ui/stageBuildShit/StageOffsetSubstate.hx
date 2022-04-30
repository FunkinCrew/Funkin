package funkin.ui.stageBuildShit;

import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import funkin.play.PlayState;
import funkin.play.stage.StageData;
import haxe.Json;
import openfl.Assets;

class StageOffsetSubstate extends MusicBeatSubstate
{
	public function new()
	{
		super();
		FlxG.mouse.visible = true;
		PlayState.instance.pauseMusic();
		FlxG.camera.target = null;

		var btn:FlxButton = new FlxButton(10, 10, "SAVE COMPILE", function()
		{
			var stageLol:StageData = StageDataParser.parseStageData(PlayState.instance.currentStageId);

			var bfPos = PlayState.instance.currentStage.getBoyfriend().feetPosition;
			stageLol.characters.bf.position[0] = Std.int(bfPos.x);
			stageLol.characters.bf.position[1] = Std.int(bfPos.y);

			var dadPos = PlayState.instance.currentStage.getDad().feetPosition;

			stageLol.characters.dad.position[0] = Std.int(dadPos.x);
			stageLol.characters.dad.position[1] = Std.int(dadPos.y);

			var outputJson = CoolUtil.jsonStringify(stageLol);

			#if sys
			// save "local" to the current export.
			sys.io.File.saveContent('./assets/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);

			// save to the dev version
			sys.io.File.saveContent('../../../../assets/preload/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);
			#end
			// trace(dipshitJson);

			// put character position data to a file of some sort
		});
		btn.scrollFactor.set();
		add(btn);
	}

	var mosPosOld:FlxPoint = new FlxPoint();
	var sprOld:FlxPoint = new FlxPoint();

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		CoolUtil.mouseCamDrag();

		if (FlxG.keys.pressed.CONTROL)
			CoolUtil.mouseWheelZoom();

		if (FlxG.mouse.pressed)
		{
			if (FlxG.mouse.justPressed)
			{
				sprOld.x = PlayState.instance.currentStage.getBoyfriend().x;
				sprOld.y = PlayState.instance.currentStage.getBoyfriend().y;

				mosPosOld.x = FlxG.mouse.x;
				mosPosOld.y = FlxG.mouse.y;
			}

			PlayState.instance.currentStage.getBoyfriend().x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
			PlayState.instance.currentStage.getBoyfriend().y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
		}

		if (FlxG.mouse.pressedRight)
		{
			if (FlxG.mouse.justPressedRight)
			{
				sprOld.x = PlayState.instance.currentStage.getDad().x;
				sprOld.y = PlayState.instance.currentStage.getDad().y;

				mosPosOld.x = FlxG.mouse.x;
				mosPosOld.y = FlxG.mouse.y;
			}

			PlayState.instance.currentStage.getDad().x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
			PlayState.instance.currentStage.getDad().y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
		}

		if (FlxG.keys.justPressed.Y)
		{
			PlayState.instance.resetCamera();
			FlxG.mouse.visible = false;
			close();
		}
	}
}
