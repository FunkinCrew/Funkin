package funkin;

import funkin.play.stage.StageData.StageDataParser;
import funkin.play.character.CharacterData.CharacterDataParser;
import flixel.FlxState;
import flixel.FlxSubState;
import flixel.util.FlxColor;
import flixel.text.FlxText;
import funkin.modding.events.ScriptEvent;
import funkin.modding.module.ModuleHandler;
import funkin.modding.events.ScriptEvent.UpdateScriptEvent;
import funkin.Conductor.BPMChangeEvent;
import flixel.addons.ui.FlxUIState;

/**
 * MusicBeatState actually represents the core utility FlxState of the game.
 * It includes functionality for event handling, as well as maintaining BPM-based update events.
 */
class MusicBeatState extends FlxUIState
{
	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;
	private var lastBeatHitTime:Float = 0;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	public var leftWatermarkText:FlxText = null;
	public var rightWatermarkText:FlxText = null;

	public function new()
	{
		super();

		initCallbacks();
	}

	function initCallbacks()
	{
		subStateOpened.add(onOpenSubstateComplete);
		subStateClosed.add(onCloseSubstateComplete);
	}

	override function create()
	{
		super.create();

		createWatermarkText();
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		// This can now be used in EVERY STATE YAY!
		if (FlxG.keys.justPressed.F5)
			debug_refreshModules();

		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep >= 0)
			stepHit();

		dispatchEvent(new UpdateScriptEvent(elapsed));
	}

	function createWatermarkText()
	{
		// Both have an xPos of 0, but a width equal to the full screen.
		// The rightWatermarkText is right aligned, which puts the text in the correct spot.
		leftWatermarkText = new FlxText(0, FlxG.height - 18, FlxG.width, '', 12);
		rightWatermarkText = new FlxText(0, FlxG.height - 18, FlxG.width, '', 12);

		// 100,000 should be good enough.
		leftWatermarkText.zIndex = 100000;
		rightWatermarkText.zIndex = 100000;
		leftWatermarkText.scrollFactor.set(0, 0);
		rightWatermarkText.scrollFactor.set(0, 0);
		leftWatermarkText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		rightWatermarkText.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

		add(leftWatermarkText);
		add(rightWatermarkText);
	}

	function dispatchEvent(event:ScriptEvent)
	{
		ModuleHandler.callEvent(event);
	}

	function debug_refreshModules()
	{
		ModuleHandler.clearModuleCache();

		// Forcibly reload scripts so that scripted stages can be edited.
		polymod.hscript.PolymodScriptClass.clearScriptClasses();
		polymod.hscript.PolymodScriptClass.registerAllScriptClasses();

		// Reload the stages in cache. This might cause a lag spike but who cares this is a debug utility.
		StageDataParser.loadStageCache();
		CharacterDataParser.loadCharacterCache();
		ModuleHandler.loadModuleCache();

		// Create a new instance of the current state class.
		FlxG.resetState();
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		lastBeatHitTime = Conductor.songPosition;
		// do literally nothing dumbass
	}

	override function switchTo(nextState:FlxState):Bool
	{
		var event = new StateChangeScriptEvent(ScriptEvent.STATE_CHANGE_BEGIN, nextState, true);

		dispatchEvent(event);

		if (event.eventCanceled)
		{
			return false;
		}

		return super.switchTo(nextState);
	}

	public override function openSubState(targetSubstate:FlxSubState):Void
	{
		var event = new SubStateScriptEvent(ScriptEvent.SUBSTATE_OPEN_BEGIN, targetSubstate, true);

		dispatchEvent(event);

		if (event.eventCanceled)
		{
			return;
		}

		super.openSubState(targetSubstate);
	}

	function onOpenSubstateComplete(targetState:FlxSubState):Void
	{
		dispatchEvent(new SubStateScriptEvent(ScriptEvent.SUBSTATE_OPEN_END, targetState, true));
	}

	public override function closeSubState():Void
	{
		var event = new SubStateScriptEvent(ScriptEvent.SUBSTATE_CLOSE_BEGIN, this.subState, true);

		dispatchEvent(event);

		if (event.eventCanceled)
		{
			return;
		}

		super.closeSubState();
	}

	function onCloseSubstateComplete(targetState:FlxSubState):Void
	{
		dispatchEvent(new SubStateScriptEvent(ScriptEvent.SUBSTATE_CLOSE_END, targetState, true));
	}
}
