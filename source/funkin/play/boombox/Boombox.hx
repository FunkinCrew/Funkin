package funkin.play.boombox;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxSort;
import funkin.modding.IScriptedClass.IPlayStateScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.BaseCharacter;
import funkin.util.SortUtil;

/**
 * A Boombox represents the speakers that the gf characters sit on.
 * It's an `FlxSpriteGroup` in case your boomboxes contain multiple elements (such as for Nene's A-Bot).
 * It doesn't do anything on its own though.
 */
@:nullSafety
class Boombox extends FlxSpriteGroup implements IPlayStateScriptedClass
{
  public var parentCharacter:Null<BaseCharacter> = null;

  public function refresh():Void
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  public function onAdd(event:ScriptEvent):Void {}

  public function onScriptEvent(event:ScriptEvent) {}

  public function onCreate(event:ScriptEvent) {}

  public function onDestroy(event:ScriptEvent) {}

  public function onUpdate(event:UpdateScriptEvent) {}

  public function onStepHit(event:SongTimeScriptEvent) {}

  public function onBeatHit(event:SongTimeScriptEvent):Void {}

  public function onPause(event:PauseScriptEvent) {}

  public function onResume(event:ScriptEvent) {}

  public function onSongStart(event:ScriptEvent) {}

  public function onSongEnd(event:ScriptEvent) {}

  public function onGameOver(event:ScriptEvent) {}

  public function onNoteIncoming(event:NoteScriptEvent) {}

  public function onNoteHit(event:HitNoteScriptEvent) {}

  public function onNoteHoldDrop(event:HoldNoteScriptEvent) {}

  public function onNoteMiss(event:NoteScriptEvent) {}

  public function onSongEvent(event:SongEventScriptEvent) {}

  public function onNoteGhostMiss(event:GhostMissNoteScriptEvent) {}

  public function onCountdownStart(event:CountdownScriptEvent) {}

  public function onCountdownStep(event:CountdownScriptEvent) {}

  public function onCountdownEnd(event:CountdownScriptEvent) {}

  public function onSongLoaded(event:SongLoadScriptEvent) {}

  public function onSongRetry(event:SongRetryEvent) {}
}
