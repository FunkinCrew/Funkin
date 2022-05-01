package funkin.ui.stageBuildShit;

import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
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

			var GF_FEET_SNIIIIIIIIIIIIIFFFF = PlayState.instance.currentStage.getGirlfriend().feetPosition;
			stageLol.characters.gf.position[0] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.x);
			stageLol.characters.gf.position[1] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.y);

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

	var char:BaseCharacter = null;

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
				for (thing in PlayState.instance.currentStage)
				{
					if (FlxG.mouse.overlaps(thing) && Std.isOfType(thing, BaseCharacter))
						char = cast thing;
				}

				sprOld.x = char.x;
				sprOld.y = char.y;

				mosPosOld.x = FlxG.mouse.x;
				mosPosOld.y = FlxG.mouse.y;
			}

			if (char != null)
			{
				char.x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
				char.y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
			}
		}

		if (FlxG.keys.justPressed.Y)
		{
			PlayState.instance.resetCamera();
			FlxG.mouse.visible = false;
			close();
		}
	}
}
