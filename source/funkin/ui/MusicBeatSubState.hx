package funkin.ui;

import flixel.FlxSubState;
import flixel.text.FlxText;
import funkin.ui.mainmenu.MainMenuState;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IEventHandler;
import funkin.modding.module.ModuleHandler;
import funkin.modding.PolymodHandler;
import funkin.util.SortUtil;
import flixel.util.FlxSort;
import funkin.input.Controls;
#if mobile
import funkin.graphics.FunkinCamera;
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.input.PreciseInputHandler;
import funkin.mobile.ui.FunkinBackButton;
import funkin.play.notes.NoteDirection;
#end

/**
 * MusicBeatSubState reincorporates the functionality of MusicBeatState into an FlxSubState.
 */
@:nullSafety
class MusicBeatSubState extends FlxSubState implements IEventHandler
{
  public var leftWatermarkText:Null<FlxText> = null;
  public var rightWatermarkText:Null<FlxText> = null;

  public var conductorInUse(get, set):Conductor;

  var _conductorInUse:Null<Conductor>;

  function get_conductorInUse():Conductor
  {
    if (_conductorInUse == null) return Conductor.instance;
    return _conductorInUse;
  }

  function set_conductorInUse(value:Conductor):Conductor
  {
    return _conductorInUse = value;
  }

  var controls(get, never):Controls;

  inline function get_controls():Controls
    return PlayerSettings.player1.controls;

  #if mobile
  public var hitbox:Null<FunkinHitbox>;
  public var backButton:Null<FunkinBackButton>;
  public var camControls:Null<FunkinCamera>;

  public function addHitbox(visible:Bool = true, initInput:Bool = true, ?schemeOverride:String, ?directionsOverride:Array<NoteDirection>,
      ?colorsOverride:Array<FlxColor>):Void
  {
    if (hitbox != null)
    {
      hitbox.kill();
      remove(hitbox);
      hitbox.destroy();
    }

    if (camControls == null)
    {
      camControls = new FunkinCamera('camControls');
      FlxG.cameras.add(camControls, false);
      camControls.bgColor = 0x0;
    }

    hitbox = new FunkinHitbox(schemeOverride, directionsOverride, colorsOverride);
    hitbox.cameras = [camControls];
    hitbox.visible = visible;
    add(hitbox);

    if (initInput) PreciseInputHandler.initializeHitbox(hitbox);
  }

  public function addBackButton(?xPos:Float = 0, ?yPos:Float = 0, ?color:FlxColor = FlxColor.WHITE, ?confirmCallback:Void->Void = null,
      ?restOpacity:Float = 0.3, ?instant:Bool = false):Void
  {
    if (backButton != null) remove(backButton);

    if (camControls == null)
    {
      camControls = new FunkinCamera('camControls');
      FlxG.cameras.add(camControls, false);
      camControls.bgColor = 0x0;
    }

    backButton = new FunkinBackButton(xPos, yPos, color, confirmCallback, restOpacity, instant);
    backButton.cameras = [camControls];
    add(backButton);
  }
  #end

  public function new(bgColor:FlxColor = FlxColor.TRANSPARENT)
  {
    super();
    this.bgColor = bgColor;

    initCallbacks();
  }

  function initCallbacks()
  {
    subStateOpened.add(onOpenSubStateComplete);
    subStateClosed.add(onCloseSubStateComplete);
  }

  override function create():Void
  {
    super.create();

    createWatermarkText();

    Conductor.beatHit.add(this.beatHit);
    Conductor.stepHit.add(this.stepHit);

    initConsoleHelpers();
  }

  public override function destroy():Void
  {
    super.destroy();

    #if mobile
    if (camControls != null) FlxG.cameras.remove(camControls);
    #end

    Conductor.beatHit.remove(this.beatHit);
    Conductor.stepHit.remove(this.stepHit);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Emergency exit button.
    if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new MainMenuState());

    // Display Conductor info in the watch window.
    FlxG.watch.addQuick("musicTime", FlxG.sound.music?.time ?? 0.0);
    Conductor.watchQuick(conductorInUse);

    dispatchEvent(new UpdateScriptEvent(elapsed));
  }

  override function onFocus():Void
  {
    super.onFocus();

    dispatchEvent(new FocusScriptEvent(FOCUS_GAINED));
  }

  override function onFocusLost():Void
  {
    super.onFocusLost();

    dispatchEvent(new FocusScriptEvent(FOCUS_LOST));
  }

  public function initConsoleHelpers():Void {}

  function reloadAssets()
  {
    PolymodHandler.forceReloadAssets();

    // Restart the current state, so old data is cleared.
    FlxG.resetState();
  }

  /**
   * Refreshes the state, by redoing the render order of all sprites.
   * It does this based on the `zIndex` of each prop.
   */
  public function refresh()
  {
    sort(SortUtil.byZIndex, FlxSort.ASCENDING);
  }

  /**
   * Called when a step is hit in the current song.
   * Continues outside of PlayState, for things like animations in menus.
   * @return Whether the event should continue (not canceled).
   */
  public function stepHit():Bool
  {
    var event:ScriptEvent = new SongTimeScriptEvent(SONG_STEP_HIT, conductorInUse.currentBeat, conductorInUse.currentStep);

    dispatchEvent(event);

    if (event.eventCanceled) return false;

    return true;
  }

  /**
   * Called when a beat is hit in the current song.
   * Continues outside of PlayState, for things like animations in menus.
   * @return Whether the event should continue (not canceled).
   */
  public function beatHit():Bool
  {
    var event:ScriptEvent = new SongTimeScriptEvent(SONG_BEAT_HIT, conductorInUse.currentBeat, conductorInUse.currentStep);

    dispatchEvent(event);

    if (event.eventCanceled) return false;

    return true;
  }

  public function dispatchEvent(event:ScriptEvent)
  {
    ModuleHandler.callEvent(event);
  }

  function createWatermarkText():Void
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
    leftWatermarkText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    rightWatermarkText.setFormat('VCR OSD Mono', 16, FlxColor.WHITE, RIGHT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);

    add(leftWatermarkText);
    add(rightWatermarkText);
  }

  /**
   * Close this substate and replace it with a different one.
   */
  public function switchSubState(substate:FlxSubState):Void
  {
    this.close();
    this._parentState.openSubState(substate);
  }

  @:nullSafety(Off)
  override function startOutro(onComplete:() -> Void):Void
  {
    var event = new StateChangeScriptEvent(STATE_CHANGE_BEGIN, null, true);

    dispatchEvent(event);

    if (event.eventCanceled)
    {
      return;
    }
    else
    {
      FunkinSound.stopAllAudio();

      onComplete();
    }
  }

  public override function openSubState(targetSubState:FlxSubState):Void
  {
    var event = new SubStateScriptEvent(SUBSTATE_OPEN_BEGIN, targetSubState, true);

    dispatchEvent(event);

    if (event.eventCanceled) return;

    super.openSubState(targetSubState);
  }

  function onOpenSubStateComplete(targetState:FlxSubState):Void
  {
    dispatchEvent(new SubStateScriptEvent(SUBSTATE_OPEN_END, targetState, true));
  }

  public override function closeSubState():Void
  {
    var event = new SubStateScriptEvent(SUBSTATE_CLOSE_BEGIN, this.subState, true);

    dispatchEvent(event);

    if (event.eventCanceled) return;

    super.closeSubState();
  }

  function onCloseSubStateComplete(targetState:FlxSubState):Void
  {
    dispatchEvent(new SubStateScriptEvent(SUBSTATE_CLOSE_END, targetState, true));
  }
}
