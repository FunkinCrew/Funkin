package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.FlxBasic;
import flixel.util.FlxSignal;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.player.PlayerData.PlayerFreeplayDJData;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.modding.IScriptedClass.IFreeplayScriptedClass;

enum FreeplayDJState
{
  /**
   * Character enters the frame and transitions to Idle.
   */
  Intro;

  /**
   * Character loops in idle.
   */
  Idle;

  /**
   * Plays an easter egg animation after a period in Idle, then reverts to Idle.
   */
  IdleEasterEgg;

  /**
   * Plays an elaborate easter egg animation. Does not revert until another animation is triggered.
   */
  Cartoon;

  /**
   * Player has selected a song.
   */
  Confirm;

  /**
   * Character preps to play the fist pump animation; plays after the Results screen.
   * The actual frame label that gets played may vary based on the player's success.
   */
  FistPumpIntro;

  /**
   * Character plays the fist pump animation.
   * The actual frame label that gets played may vary based on the player's success.
   */
  FistPump;

  /**
   * Plays an animation to indicate that the player has a new unlock in Character Select.
   * Overrides all idle animations as well as the fist pump. Only Confirm and CharSelect will override this.
   */
  NewUnlock;

  /**
   * Plays an animation to transition to the Character Select screen.
   */
  CharSelect;
}

@:nullSafety
class BaseFreeplayDJ extends FlxAtlasSprite implements IFreeplayScriptedClass
{
  public var IDLE_EGG_PERIOD:Float = 60.0;
  public var IDLE_CARTOON_PERIOD:Float = 120.0;

  // Represents the sprite's current status.
  // Without state machines I would have driven myself crazy years ago.
  // Made this PRIVATE so we can keep track of everything that can alter the state!
  //   Add a function to this class if you want to edit this value from outside.
  private var currentState:FreeplayDJState = Intro;

  // A callback activated when the intro animation finishes.
  public var onIntroDone:FlxSignal = new FlxSignal();

  // A callback activated when the idle easter egg plays.
  public var onIdleEasterEgg:FlxSignal = new FlxSignal();

  var seenIdleEasterEgg:Bool = false;

  final characterId:String = Constants.DEFAULT_CHARACTER;
  final playableCharData:Null<PlayerFreeplayDJData>;

  var timeIdling:Float = 0;
  var lowPumpLoopPoint:Int = 4;

  public function new(x:Float, y:Float, characterId:String)
  {
    this.characterId = characterId;

    final playableChar = PlayerRegistry.instance.fetchEntry(characterId);
    playableCharData = playableChar?.getFreeplayDJData();

    super(x, y, null, null, false);
  }

  function onFinishAnim(name:String):Void {}

  public function onCharSelectComplete():Void
  {
    trace('onCharSelectComplete()');
  }

  public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    // playAnimationSimple(id, Force, Reverse, Loop, Frame);
    applyAnimOffset();
  }

  public function onPlayerAction():Void
  {
    resetAFKTimer();
  }

  public function resetAFKTimer():Void
  {
    timeIdling = 0;
    seenIdleEasterEgg = false;
  }

  public function getMusicPreviewMult():Float
  {
    return 1;
  }

  public function onConfirm():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = Confirm;
  }

  public function toCharSelect():Void
  {
    var animPrefix = playableCharData?.getAnimationPrefix('charSelect');
    if (animPrefix != null && hasAnimation(animPrefix))
    {
      currentState = CharSelect;
      playFlashAnimation(animPrefix, true, false, false, 0);
    }
    else
    {
      FlxG.log.warn("Freeplay character does not have 'charSelect' animation!");
      currentState = Confirm;
      // Call this immediately; otherwise, we get locked out of Character Select.
      onCharSelectComplete();
    }
  }

  public function fistPumpIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData?.getAnimationPrefix('fistPump');
    if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, playableCharData?.getFistPumpIntroStartFrame());
  }

  public function fistPump():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData?.getAnimationPrefix('fistPump');
    if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, playableCharData?.getFistPumpLoopStartFrame());
  }

  public function fistPumpLossIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    var animPrefix = playableCharData?.getAnimationPrefix('loss');
    if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, playableCharData?.getFistPumpIntroBadStartFrame());
  }

  public function fistPumpLoss():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    var animPrefix = playableCharData?.getAnimationPrefix('loss');
    if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, playableCharData?.getFistPumpLoopBadStartFrame());
  }

  override public function listAnimations():Array<String>
  {
    // this is base dj dum dum, there's no animations
    return [];
  }

  override public function getCurrentAnimation():String
  {
    // this is base dj dum dum, there's no animations
    return "";
  }

  function applyAnimOffset()
  {
    var animName = getCurrentAnimation();
    trace(animName);
    var daOffset = playableCharData?.getAnimationOffsetsByPrefix(animName);
    trace(daOffset);
    if (daOffset != null)
    {
      final xValue = daOffset[0];
      final yValue = daOffset[1];
      offset.set(xValue, yValue);
    }
    else
      offset.set(0, 0);
  }

  public function onScriptEvent(event:ScriptEvent) {}

  public function onCreate(event:ScriptEvent) {}

  public function onDestroy(event:ScriptEvent):Void {}

  public function onUpdate(event:UpdateScriptEvent):Void {}

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  public function onBeatHit(event:SongTimeScriptEvent):Void {}

  public function onStateChangeBegin(event:StateChangeScriptEvent):Void {}

  public function onStateChangeEnd(event:StateChangeScriptEvent):Void {}

  public function onSubStateOpenBegin(event:SubStateScriptEvent):Void {}

  public function onSubStateOpenEnd(event:SubStateScriptEvent):Void {}

  public function onSubStateCloseBegin(event:SubStateScriptEvent):Void {}

  public function onSubStateCloseEnd(event:SubStateScriptEvent):Void {}

  public function onFocusLost(event:FocusScriptEvent):Void {}

  public function onFocusGained(event:FocusScriptEvent):Void {}

  /**
   * Called when a capsule is selected.
   */
  public function onCapsuleSelected(event:CapsuleScriptEvent):Void {}

  /**
   * Called when the current difficulty is changed.
   */
  public function onDifficultySwitch(event:CapsuleScriptEvent):Void {}

  /**
   * Called when a song is selected.
   */
  public function onSongSelected(event:CapsuleScriptEvent):Void {}

  /**
   * Called when the intro for Freeplay finishes.
   */
  public function onFreeplayIntroDone(event:FreeplayScriptEvent):Void {}

  /**
   * Called when the Freeplay outro begins.
   */
  public function onFreeplayOutro(event:FreeplayScriptEvent):Void {}

  /**
   * Called when Freeplay is closed.
   */
  public function onFreeplayClose(event:FreeplayScriptEvent):Void {}
}

// Class for all non-atalas DJ's
class FlixelFramedFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadFrames();
    loadAnimations();

    animation.onFinish.add(onFinishAnim);
    animation.onLoop.add(onFinishAnim);

    // animation.onFrameChange.add((name, num, index) -> trace('name:$name, num:$num, index:$index'));
  }

  public function loadFrames():Void
  {
    trace("OVERRIDE ME");
    trace("LOADING FRAMES FUNC");
  }

  public function loadAnimations():Void
  {
    trace('[SPARROWCHAR] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animNames = this.animation.getNameList();
    trace('[SPARROWCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  override function applyAnimOffset()
  {
    var animName = getCurrentAnimation();
    trace(animName);
    var daOffset = playableCharData?.getAnimationOffsets(animName);
    trace(daOffset);
    if (daOffset != null)
    {
      final xValue = daOffset[0];
      final yValue = daOffset[1];
      offset.set(xValue, yValue);
    }
    else
      offset.set(0, 0);
  }

  override public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    // No LOOP logic, because default Flixel's FlxAnimationController can normaly work with LOOPED animations
    animation.play(id, Force, Reverse, Frame);
    applyAnimOffset();
  }

  override public function listAnimations():Array<String>
  {
    return animation.getNameList() ?? [];
  }

  override public function getCurrentAnimation():String
  {
    return animation?.curAnim?.name ?? "";
  }

  override function updateAnimation(elapsed:Float):Void
  {
    animation.update(elapsed);
  }

  override public function hasAnimation(anim:String):Bool
  {
    return listAnimations().contains(anim);
  }

  override public function toCharSelect():Void
  {
    if (hasAnimation('charSelect'))
    {
      currentState = CharSelect;
      playFlashAnimation('charSelect', true, false, false, 0);
    }
    else
    {
      FlxG.log.warn("Freeplay character does not have 'charSelect' animation!");
      currentState = Confirm;
      // Call this immediately; otherwise, we get locked out of Character Select.
      onCharSelectComplete();
    }
  }

  override public function fistPumpIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    playFlashAnimation('fistPumpIntro', true, false, false);
  }

  override public function fistPump():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    playFlashAnimation('fistPump', true, false, false);
  }

  override public function fistPumpLossIntro():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPumpIntro;
    playFlashAnimation('lossIntro', true, false, false);
  }

  override public function fistPumpLoss():Void
  {
    // We really don't want to play anything but the new character animation here.
    if (PlayerRegistry.instance.hasNewCharacter())
    {
      currentState = NewUnlock;
      return;
    }

    currentState = FistPump;
    playFlashAnimation('loss', true, false, false);
  }

  public override function update(elapsed:Float):Void
  {
    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        if (hasAnimation('intro') && (getCurrentAnimation() != 'intro' || this.animation.finished)) playFlashAnimation('intro', true);
        timeIdling = 0;
      case Idle:
        // We are in this state the majority of the time.
        if (hasAnimation('idle') && getCurrentAnimation() != 'idle') playFlashAnimation('idle', true, false, true);

        timeIdling += elapsed;
      case NewUnlock:
        if (!hasAnimation('newUnlock'))
        {
          currentState = Idle;
        }
        if (hasAnimation('newUnlock') && getCurrentAnimation() != 'newUnlock')
        {
          playFlashAnimation('newUnlock', true, false, true);
        }
      case Confirm:
        if (hasAnimation('confirm') && getCurrentAnimation() != 'confirm') playFlashAnimation('confirm', false);
        timeIdling = 0;
      case FistPumpIntro:
        // I shit my self - PurSnake
      case FistPump:
        // Twice
      case IdleEasterEgg:
        if (hasAnimation('idleEasterEgg') && getCurrentAnimation() != 'idleEasterEgg')
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation('idleEasterEgg', false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        if (!hasAnimation('cartoon'))
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != 'cartoon') playFlashAnimation('cartoon', true);
          timeIdling = 0;
        }
      default:
        // I shit myself.
    }

    super.update(elapsed);
  }

  override function onFinishAnim(name:String):Void
  {
    if (name == 'intro')
    {
      if (PlayerRegistry.instance.hasNewCharacter())
      {
        currentState = NewUnlock;
      }
      else
      {
        currentState = Idle;
      }
      onIntroDone.dispatch();
    }
    else if (name == 'idle')
    {
      // trace('Finished idle')
      if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg)
      {
        currentState = IdleEasterEgg;
      }
      else if (timeIdling >= IDLE_CARTOON_PERIOD)
      {
        currentState = Cartoon;
      }
    }
    else if (name == 'confirm')
    {
      // trace('Finished confirm');
    }
    else if (name == 'fistPump')
    {
      // trace('Finished fist pump');
      currentState = Idle;
    }
    else if (name == 'idleEasterEgg')
    {
      // trace('Finished spook');
      currentState = Idle;
    }
    else if (name == 'loss')
    {
      // trace('Finished loss reaction');
      currentState = Idle;
    }
    else if (name == 'cartoon')
    {
      // trace('Finished cartoon');

      // var frame:Int = FlxG.random.bool(33) ? (playableCharData?.getCartoonLoopBlinkFrame() ?? 0) : (playableCharData?.getCartoonLoopFrame() ?? 0);

      // Character switches channels when the video ends, or at a 10% chance each time his idle loops.
      /*if (FlxG.random.bool(5))
        {
          frame = playableCharData?.getCartoonChannelChangeFrame() ?? 0;
          // boyfriend switches channel code?
          // Transefer into bf.hxc in scripts/freeplay/dj
          // runTvLogic();
        }
          trace('Replay idle: ${frame}'); */
      playFlashAnimation('cartoon', true, false, false);
      // YOU BETTER REDO THIS IN YOUR SCRIPT WITH DIFFERENT ANIMATIONS
      // trace('Finished confirm');
    }
    else if (name == 'newUnlock')
    {
      // Animation should loop.
    }
    else if (name == 'charSelect')
    {
      onCharSelectComplete();
    }
    else
    {
      trace('Finished ${name}');
    }
  }

  /// Draw - Logic
  override public function draw():Void
  {
    checkEmptyFrame();

    if (alpha == 0 || _frame.type == FlxFrameType.EMPTY) return;

    if (dirty) // rarely
      calcFrame(useFramePixels);

    for (camera in getCamerasLegacy())
    {
      if (!camera.visible || !camera.exists || !isOnScreen(camera)) continue;

      if (isSimpleRender(camera)) drawSimple(camera);
      else
        drawComplex(camera);

      #if FLX_DEBUG
      FlxBasic.visibleCount++;
      #end
    }

    #if FLX_DEBUG
    if (FlxG.debugger.drawDebug) drawDebug();
    #end
  }

  @:noCompletion
  override function drawSimple(camera:FlxCamera):Void
  {
    getScreenPosition(_point, camera).subtract(offset);
    if (isPixelPerfectRender(camera)) _point.floor();

    _point.copyTo(_flashPoint);
    camera.copyPixels(_frame, framePixels, _flashRect, _flashPoint, colorTransform, blend, antialiasing);
  }

  @:noCompletion
  override function drawComplex(camera:FlxCamera):Void
  {
    _frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
    _matrix.translate(-origin.x, -origin.y);
    _matrix.scale(scale.x, scale.y);

    if (bakedRotationAngle <= 0)
    {
      updateTrig();

      if (angle != 0) _matrix.rotateWithTrig(_cosAngle, _sinAngle);
    }

    getScreenPosition(_point, camera).subtract(offset);
    _point.add(origin.x, origin.y);
    _matrix.translate(_point.x, _point.y);

    if (isPixelPerfectRender(camera))
    {
      _matrix.tx = Math.floor(_matrix.tx);
      _matrix.ty = Math.floor(_matrix.ty);
    }

    camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
  }
}
