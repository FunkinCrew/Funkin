package funkin;

import flixel.FlxSubState;
import flixel.util.FlxColor;
import funkin.Conductor.BPMChangeEvent;
import funkin.modding.events.ScriptEvent;
import funkin.modding.module.ModuleHandler;

/**
 * MusicBeatSubState reincorporates the functionality of MusicBeatState into an FlxSubState.
 */
class MusicBeatSubState extends FlxSubState
{
  public function new(bgColor:FlxColor = FlxColor.TRANSPARENT)
  {
    super(bgColor);
  }

  var curStep:Int = 0;
  var curBeat:Int = 0;
  var controls(get, never):Controls;

  inline function get_controls():Controls
    return PlayerSettings.player1.controls;

  override function update(elapsed:Float)
  {
    // everyStep();
    var oldStep:Int = curStep;

    updateCurStep();
    curBeat = Math.floor(curStep / 4);

    if (oldStep != curStep && curStep >= 0) stepHit();

    super.update(elapsed);
  }

  function updateCurStep():Void
  {
    var lastChange:BPMChangeEvent =
      {
        stepTime: 0,
        songTime: 0,
        bpm: 0
      }
    for (i in 0...Conductor.bpmChangeMap.length)
    {
      if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime) lastChange = Conductor.bpmChangeMap[i];
    }

    curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - Conductor.audioOffset) - lastChange.songTime) / Conductor.stepCrochet);
  }

  public function stepHit():Bool
  {
    var event = new SongTimeScriptEvent(ScriptEvent.SONG_STEP_HIT, curBeat, curStep);

    dispatchEvent(event);

    if (event.eventCanceled) return false;

    if (curStep % 4 == 0) beatHit();

    return true;
  }

  function dispatchEvent(event:ScriptEvent)
  {
    ModuleHandler.callEvent(event);
  }

  /**
   * Close this substate and replace it with a different one.
   */
  public function switchSubState(substate:FlxSubState):Void
  {
    this.close();
    this._parentState.openSubState(substate);
  }

  public function beatHit():Bool
  {
    var event = new SongTimeScriptEvent(ScriptEvent.SONG_BEAT_HIT, curBeat, curStep);

    dispatchEvent(event);

    if (event.eventCanceled) return false;

    return true;
  }
}
