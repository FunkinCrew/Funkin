package funkin.ui.freeplay.dj;

import flixel.util.FlxSignal;
import funkin.graphics.FunkinSprite;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.data.freeplay.player.PlayerData.PlayerFreeplayDJData;
import funkin.modding.IScriptedClass.IFreeplayScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.freeplay.charselect.PlayableCharacter;

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
   * Player has selected a song.
   */
  Confirm;

  /**
   * Character preps to play the fist pump animation; plays after the Results screen.
   * The actual animation that gets played may vary based on the player's success.
   */
  FistPumpIntro;

  /**
   * Character plays the fist pump animation.
   * The actual animation that gets played may vary based on the player's success.
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

  /**
   * Doesn't play an animation by default, scripts can implement their own animations.
   */
  Custom;
}

enum abstract FreeplayDJAnimation(String) to String
{
  public var INTRO = 'intro';
  public var IDLE = 'idle';
  public var FISTPUMP = 'fistPump';
  public var CONFIRM = 'confirm';
  public var FISTPUMPLOSS = 'loss';
  public var NEWUNLOCK = 'newUnlock';
  public var CHARSELECT = 'charSelect';
  public var IDLEEASTEREGG = 'idleEasterEgg';
}

@:nullSafety
class BaseFreeplayDJ extends FunkinSprite implements IFreeplayScriptedClass
{
  /**
   * The amount of time (in seconds) that must pass before the easter egg animation can be played.
   */
  public static final IDLE_EGG_PERIOD:Float = 60.0;

  /**
   * The character ID of the Freeplay DJ.
   */
  public final characterId:String = Constants.DEFAULT_CHARACTER;

  /**
   * The current state of the Freeplay DJ.
   */
  public var currentState(default, set):FreeplayDJState = Custom;

  function set_currentState(value:FreeplayDJState):FreeplayDJState
  {
    currentState = value;

    switch (value)
    {
      case Intro:
        playAnimation(INTRO, true);

        timeIdling = 0;
      case Idle:
        playAnimation(IDLE, true, false, true);
      case NewUnlock:
        if (!hasAnimation(NEWUNLOCK))
        {
          currentState = Idle;
          return value;
        }

        playAnimation(NEWUNLOCK, true, false, true);
      case Confirm:
        playAnimation(CONFIRM, false);

        timeIdling = 0;
      case IdleEasterEgg:
        seenIdleEasterEgg = true;
        onIdleEasterEgg.dispatch();

        playAnimation(IDLEEASTEREGG, false);

        timeIdling = 0;
      default:
        // Do nothing.
    }

    return value;
  }

  /**
   * A callback activated when the intro animation finishes.
   */
  public var onIntroDone:FlxSignal = new FlxSignal();

  /**
   * A callback activated when the idle easter egg plays.
   */
  public var onIdleEasterEgg:FlxSignal = new FlxSignal();

  final playableCharData:Null<PlayerFreeplayDJData>;
  var seenIdleEasterEgg:Bool = false;
  var timeIdling:Float = 0;

  public function new(x:Float, y:Float, characterId:String)
  {
    this.characterId = characterId;

    var playableCharacter:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(characterId);
    playableCharData = playableCharacter?.getFreeplayDJData();

    super(x, y);

    if (this.animation != null)
    {
      animation.onFinish.add(onAnimationFinished);
      animation.onLoop.add(onAnimationFinished);
      animation.onFrameChange.add(onAnimationFrame);
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (currentState == FreeplayDJState.Idle)
    {
      timeIdling += elapsed;
    }
  }

  function onAnimationFinished(name:String):Void
  {
    switch (name)
    {
      case INTRO:
        if (PlayerRegistry.instance.hasNewCharacter())
        {
          currentState = NewUnlock;
        }
        else
        {
          currentState = Idle;
        }
        onIntroDone.dispatch();
      case IDLE:
        if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg && hasAnimation(IDLEEASTEREGG))
        {
          currentState = IdleEasterEgg;
        }
      case FISTPUMP | FISTPUMPLOSS | IDLEEASTEREGG:
        currentState = Idle;
      case CHARSELECT:
        onCharSelectComplete();
    }
  }

  function onAnimationFrame(name:String, frameNumber:Int, frameIndex:Int):Void
  {
    if (name != FISTPUMP && name != FISTPUMPLOSS) return;

    var isIntro:Bool = (currentState == FistPumpIntro);
    var startFrame:Int = -1;
    var endFrame:Int = -1;

    if (name == FISTPUMPLOSS)
    {
      endFrame = isIntro ? playableCharData?.getFistPumpIntroBadEndFrame() ?? 0 : playableCharData?.getFistPumpLoopBadEndFrame() ?? 0;
      startFrame = isIntro ? playableCharData?.getFistPumpIntroBadStartFrame() ?? 0 : playableCharData?.getFistPumpLoopBadStartFrame() ?? 0;
    }
    else
    {
      endFrame = isIntro ? playableCharData?.getFistPumpIntroEndFrame() ?? 0 : playableCharData?.getFistPumpLoopEndFrame() ?? 0;
      startFrame = isIntro ? playableCharData?.getFistPumpIntroStartFrame() ?? 0 : playableCharData?.getFistPumpLoopStartFrame() ?? 0;
    }

    if (endFrame > -1 && frameNumber > endFrame)
    {
      playAnimation(name, true, false, false, startFrame);
    }
  }

  /**
   * @param id The animation to play.
   * @param restart Whether to restart the animation if it is already playing.
   * @param reverse Whether to play the animation backwards, from the last frame to the first.
   * @param loop Whether to loop the animation.
   * @param frame The specific frame to play.
   */
  @:haxe.warning('-WDeprecated')
  public function playAnimation(id:String, restart:Bool = false, reverse:Bool = false, loop:Bool = false, frame:Int = 0, _runByCompat:Bool = false):Void
  {
    if (animation == null)
    {
      FlxG.log.warn('Freeplay DJ ${characterId} has no graphics loaded!');
      return;
    }

    // Backwards compatibility: Run `playFlashAnimation()` instead since old scripts might override it.
    if (__backwardsCompatibility && !_runByCompat)
    {
      playFlashAnimation(id, restart, reverse, loop, frame);
      return;
    }

    // We really don't want to play anything but the new character animation if we have one.
    if (PlayerRegistry.instance.hasNewCharacter() && currentState == NewUnlock && getCurrentAnimation() == NEWUNLOCK)
    {
      return;
    }

    animation.play(id, restart, reverse, frame);

    if (animation.curAnim == null)
    {
      FlxG.log.error('Freeplay DJ ${characterId} failed to play animation ${id}!');
      return;
    }

    animation.curAnim.looped = loop;

    applyAnimationOffset();
  }

  @:deprecated('Use playAnimation() instead')
  function playFlashAnimation(id:String, force:Bool = false, reverse:Bool = false, loop:Bool = false, frame:Int = 0):Void
  {
    playAnimation(id, force, reverse, loop, frame, true);
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
    currentState = Confirm;
  }

  public function toCharSelect():Void
  {
    if (hasAnimation(CHARSELECT))
    {
      currentState = CharSelect;
      playAnimation(CHARSELECT, true, false, false, 0);
    }
    else
    {
      FlxG.log.warn("Freeplay character does not have 'charSelect' animation!");

      currentState = Confirm;
      // Call this immediately; otherwise, we get locked out of Character Select.
      onCharSelectComplete();
    }
  }

  public function onCharSelectComplete():Void
  {
    trace('onCharSelectComplete()');
  }

  public function fistPumpIntro():Void
  {
    currentState = FistPumpIntro;

    if (hasAnimation(FISTPUMP))
    {
      playAnimation(FISTPUMP, true, false, false, playableCharData?.getFistPumpIntroStartFrame());
    }
  }

  public function fistPump():Void
  {
    currentState = FistPump;

    if (hasAnimation(FISTPUMP))
    {
      playAnimation(FISTPUMP, true, false, false, playableCharData?.getFistPumpLoopStartFrame());
    }
  }

  public function fistPumpLossIntro():Void
  {
    currentState = FistPumpIntro;

    if (hasAnimation(FISTPUMPLOSS))
    {
      playAnimation(FISTPUMPLOSS, true, false, false, playableCharData?.getFistPumpIntroBadStartFrame());
    }
  }

  public function fistPumpLoss():Void
  {
    currentState = FistPump;

    if (hasAnimation(FISTPUMPLOSS))
    {
      playAnimation(FISTPUMPLOSS, true, false, false, playableCharData?.getFistPumpLoopBadStartFrame());
    }
  }

  public function resetPosition():Void
  {
    if (playableCharData == null) return;

    if (playableCharData.useAnimatePosition)
    {
      this.x = (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI);
      this.y = 0;
    }
    else
    {
      this.x = (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI) + 640;
      this.y = 366;
    }
  }

  function applyAnimationOffset():Void
  {
    if (playableCharData == null) return;

    var animationName:String = getCurrentAnimation();
    var animationOffsets:Null<Array<Float>> = playableCharData.getAnimationOffsets(animationName);
    var globalOffsets:Array<Float> = [this.x, this.y];

    globalOffsets[0] -= playableCharData.getGlobalOffsets()[0];
    globalOffsets[1] -= playableCharData.getGlobalOffsets()[1];

    if (animationOffsets != null)
    {
      var finalOffsetX:Float = 0;
      var finalOffsetY:Float = 0;

      if (this.applyStageMatrix)
      {
        finalOffsetX = animationOffsets[0];
        finalOffsetY = animationOffsets[1];
      }
      else
      {
        finalOffsetX = globalOffsets[0] - animationOffsets[0] - (FreeplayState.CUTOUT_WIDTH * FreeplayState.DJ_POS_MULTI);
        finalOffsetY = globalOffsets[1] - animationOffsets[1];
      }

      offset.set(finalOffsetX, finalOffsetY);
    }
    else
    {
      offset.set(0, 0);
    }
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  }

  public function onCreate(event:ScriptEvent):Void
  {
  }

  public function onDestroy(event:ScriptEvent):Void
  {
  }

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  }

  public function onCustom(event:CustomScriptEvent):Void
  {
  }

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onStateChangeBegin(event:StateChangeScriptEvent):Void
  {
  }

  public function onStateChangeEnd(event:StateChangeScriptEvent):Void
  {
  }

  public function onSubStateOpenBegin(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateOpenEnd(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateCloseBegin(event:SubStateScriptEvent):Void
  {
  }

  public function onSubStateCloseEnd(event:SubStateScriptEvent):Void
  {
  }

  public function onFocusLost(event:FocusScriptEvent):Void
  {
  }

  public function onFocusGained(event:FocusScriptEvent):Void
  {
  }

  /**
   * Called when a capsule is selected.
   */
  public function onCapsuleSelected(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the current difficulty is changed.
   */
  public function onDifficultySwitch(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when a song is selected.
   */
  public function onSongSelected(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the intro for Freeplay finishes.
   */
  public function onFreeplayIntroDone(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when the Freeplay outro begins.
   */
  public function onFreeplayOutro(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when Freeplay is closed.
   */
  public function onFreeplayClose(event:FreeplayScriptEvent):Void
  {
  }

  /**
   * Called when a capsule receives a new rank.
   */
  public function onCapsuleNewRank(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the rank letter slams down on a freeplay capsule.
   */
  public function onRankSlam(event:CapsuleScriptEvent):Void
  {
  }

  /**
   * Called when the entire capsule slams down, after a new rank has been applied.
   */
  public function onCapsuleSlam(event:CapsuleScriptEvent):Void
  {
  }
}
