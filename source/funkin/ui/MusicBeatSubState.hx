package funkin.ui;

import flixel.addons.transition.FlxTransitionableState;
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
import flixel.input.actions.FlxActionInput;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
import funkin.mobile.FunkinHitbox;
import funkin.mobile.FunkinVirtualPad;
#end

/**
 * MusicBeatSubState reincorporates the functionality of MusicBeatState into an FlxSubState.
 */
class MusicBeatSubState extends FlxSubState implements IEventHandler
{
  public var leftWatermarkText:FlxText = null;
  public var rightWatermarkText:FlxText = null;

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

  public function new(bgColor:FlxColor = FlxColor.TRANSPARENT)
  {
    super();
    this.bgColor = bgColor;
  }

  var controls(get, never):Controls;

  inline function get_controls():Controls
    return PlayerSettings.player1.controls;

  #if mobile
  var hitbox:FunkinHitbox;
  var vPad:FunkinVirtualPad;

  var trackedInputsHitbox:Array<FlxActionInput> = [];
  var trackedInputsVirtualPad:Array<FlxActionInput> = [];

  public function addVPad(dPad:FunkinDPadMode, action:FunkinActionMode, ?visible:Bool = true):Void
  {
    if (vPad != null)
      removeVPad();

    vPad = new FunkinVirtualPad(dPad, action);
    vPad.visible = visible;
    add(vPad);

    controls.setVPad(vPad, dPad, action);
    trackedInputsVirtualPad = controls.trackedInputs;
    controls.trackedInputs = [];
  }

  public function addVPadCamera(defaultDrawTarget:Bool = true):Void
  {
    if (vPad != null)
    {
      var camControls:FlxCamera = new FlxCamera();
      FlxG.cameras.add(camControls, defaultDrawTarget);
      camControls.bgColor.alpha = 0;
      vPad.cameras = [camControls];
    }
  }

  public function removeVPad():Void
  {
    if (trackedInputsVirtualPad.length > 0)
      controls.removeVControlsInput(trackedInputsVirtualPad);

    if (vPad != null)
      remove(vPad);
  }

  public function addHitbox(?visible:Bool = true):Void
  {
    if (hitbox != null)
      removeHitbox();

    hitbox = new FunkinHitbox(4, Std.int(FlxG.width / 4), FlxG.height, [0xC34B9A, 0x00FFFF, 0x12FB06, 0xF9393F]);
    hitbox.visible = visible;
    add(hitbox);

    controls.setHitbox(hitbox);
    trackedInputsHitbox = controls.trackedInputs;
    controls.trackedInputs = [];
  }

  public function addHitboxCamera(DefaultDrawTarget:Bool = true):Void
  {
    if (hitbox != null)
    {
      var camControls:FlxCamera = new FlxCamera();
      FlxG.cameras.add(camControls, DefaultDrawTarget);
      camControls.bgColor.alpha = 0;
      hitbox.cameras = [camControls];
    }
  }

  public function removeHitbox():Void
  {
    if (trackedInputsHitbox.length > 0)
      controls.removeVControlsInput(trackedInputsHitbox);

    if (hitbox != null)
      remove(hitbox);
  }
  #end

  override function create():Void
  {
    super.create();

    createWatermarkText();

    Conductor.beatHit.add(this.beatHit);
    Conductor.stepHit.add(this.stepHit);
  }

  public override function destroy():Void
	{
		#if mobile
		if (trackedInputsHitbox.length > 0)
			controls.removeVControlsInput(trackedInputsHitbox);

		if (trackedInputsVirtualPad.length > 0)
			controls.removeVControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobile
		if (vPad != null)
			vPad = FlxDestroyUtil.destroy(vPad);

		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
		#end

    Conductor.beatHit.remove(this.beatHit);
    Conductor.stepHit.remove(this.stepHit);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Emergency exit button.
    if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new MainMenuState());

    // This can now be used in EVERY STATE YAY!
    if (FlxG.keys.justPressed.F5) debug_refreshModules();

    // Display Conductor info in the watch window.
    FlxG.watch.addQuick("musicTime", FlxG.sound.music?.time ?? 0.0);
    Conductor.watchQuick(conductorInUse);

    dispatchEvent(new UpdateScriptEvent(elapsed));
  }

  function debug_refreshModules()
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
