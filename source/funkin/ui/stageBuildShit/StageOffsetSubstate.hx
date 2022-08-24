package funkin.ui.stageBuildShit;

import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEventManager;
import flixel.math.FlxPoint;
import flixel.ui.FlxButton;
import funkin.play.PlayState;
import funkin.play.character.BaseCharacter;
import funkin.play.stage.StageData;
import haxe.Json;
import haxe.ui.ComponentBuilder;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.Toolkit;
import haxe.ui.components.Button;
import haxe.ui.containers.HBox;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import openfl.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class StageOffsetSubstate extends MusicBeatSubstate
{
	override function create()
	{
		super.create();

		FlxG.mouse.visible = true;
		PlayState.instance.pauseMusic();
		FlxG.camera.target = null;

		var str = Paths.xml('ui/stage-editor-view');
		var uiStuff:Component = RuntimeComponentBuilder.fromAsset(str);

		uiStuff.findComponent("lol").onClick = saveCharacterCompile;
		uiStuff.findComponent('saveAs').onClick = saveStageFileRef;

		add(uiStuff);

		PlayState.instance.persistentUpdate = true;
		uiStuff.cameras = [PlayState.instance.camHUD];
		// btn.cameras = [PlayState.instance.camHUD];

		for (thing in PlayState.instance.currentStage)
		{
			FlxMouseEventManager.add(thing, spr ->
			{
				char = cast thing;
				trace("JUST PRESSED!");
				sprOld.x = thing.x;
				sprOld.y = thing.y;

				mosPosOld.x = FlxG.mouse.x;
				mosPosOld.y = FlxG.mouse.y;
			}, null, spr ->
			{
				// ID tag is to see if currently overlapping hold basically!, a bit more reliable than checking transparency!
				// used for bug where you can click, and if you click on NO sprite, it snaps the thing to position! unintended!
				spr.ID = 1;
				spr.alpha = 0.5;
			}, spr ->
			{
				spr.ID = 0;
				spr.alpha = 1;
			});
		}
	}

	var mosPosOld:FlxPoint = new FlxPoint();
	var sprOld:FlxPoint = new FlxPoint();

	var char:FlxSprite = null;
	var overlappingChar:Bool = false;

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (char != null && char.ID == 1 && FlxG.mouse.pressed)
		{
			char.x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
			char.y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
		}

		CoolUtil.mouseCamDrag();

		if (FlxG.keys.pressed.CONTROL)
			CoolUtil.mouseWheelZoom();

		if (FlxG.keys.justPressed.Y)
		{
			for (thing in PlayState.instance.currentStage)
			{
				FlxMouseEventManager.remove(thing);
				thing.alpha = 1;
			}

			PlayState.instance.resetCamera();
			FlxG.mouse.visible = false;
			close();
		}
	}

	var _file:FileReference;

	private function saveStageFileRef(_):Void
	{
		var jsonStr = prepStageStuff();

		_file = new FileReference();
		_file.addEventListener(Event.COMPLETE, onSaveComplete);
		_file.addEventListener(Event.CANCEL, onSaveCancel);
		_file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file.save(jsonStr, PlayState.instance.currentStageId + ".json");
	}

	function onSaveComplete(_)
	{
		fileRemoveListens();
		FlxG.log.notice("Successfully saved!");
	}

	function onSaveCancel(_)
	{
		fileRemoveListens();
	}

	function onSaveError(_)
	{
		fileRemoveListens();
		FlxG.log.error("Problem saving Stage file!");
	}

	function fileRemoveListens()
	{
		_file.removeEventListener(Event.COMPLETE, onSaveComplete);
		_file.removeEventListener(Event.CANCEL, onSaveCancel);
		_file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
		_file = null;
	}

	private function saveCharacterCompile(_):Void
	{
		var outputJson:String = prepStageStuff();

		#if sys
		// save "local" to the current export.
		sys.io.File.saveContent('./assets/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);

		// save to the dev version
		sys.io.File.saveContent('../../../../assets/preload/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);
		#end
	}

	private function prepStageStuff():String
	{
		var stageLol:StageData = StageDataParser.parseStageData(PlayState.instance.currentStageId);

		for (prop in stageLol.props)
		{
			@:privateAccess
			var posStuff = PlayState.instance.currentStage.namedProps.get(prop.name);

			prop.position[0] = posStuff.x;
			prop.position[1] = posStuff.y;
		}

		var bfPos = PlayState.instance.currentStage.getBoyfriend().feetPosition;
		stageLol.characters.bf.position[0] = Std.int(bfPos.x);
		stageLol.characters.bf.position[1] = Std.int(bfPos.y);

		var dadPos = PlayState.instance.currentStage.getDad().feetPosition;

		stageLol.characters.dad.position[0] = Std.int(dadPos.x);
		stageLol.characters.dad.position[1] = Std.int(dadPos.y);

		var GF_FEET_SNIIIIIIIIIIIIIFFFF = PlayState.instance.currentStage.getGirlfriend().feetPosition;
		stageLol.characters.gf.position[0] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.x);
		stageLol.characters.gf.position[1] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.y);

		return CoolUtil.jsonStringify(stageLol);
	}
}
