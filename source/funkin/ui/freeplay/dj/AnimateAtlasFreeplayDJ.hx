package funkin.ui.freeplay.dj;

import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a AnimateAtlasFreeplayDJ.
 * Create a scripted class that extends AnimateAtlasFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedAnimateAtlasFreeplayDJ extends AnimateAtlasFreeplayDJ implements polymod.hscript.HScriptedClass {}

/**
 * An AnimateAtlasFreeplayDJ is a Freeplay DJ which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseFreeplayDJ has game logic, AnimateAtlasFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadTextureAtlas(playableCharData?.getAssetPath(),
      {
        swfMode: true
      });

    if (playableCharData?.useApplyStageMatrix() ?? false)
    {
      this.applyStageMatrix = true;
    }

    animation.onFinish.add(onFinishAnim);
    animation.onLoop.add(onFinishAnim);
  }

  public override function update(elapsed:Float):Void
  {
    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        var animPrefix = playableCharData?.getAnimationPrefix('intro');
        if (animPrefix != null && (getCurrentAnimation() != animPrefix))
        {
          playFlashAnimation(animPrefix, true);
        }
        timeIdling = 0;
      case Idle:
        // We are in this state the majority of the time.
        var animPrefix = playableCharData?.getAnimationPrefix('idle');
        if (animPrefix != null && getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
        timeIdling += elapsed;
      case NewUnlock:
        var animPrefix = playableCharData?.getAnimationPrefix('newUnlock');
        if (animPrefix != null && !hasAnimation(animPrefix))
        {
          currentState = Idle;
        }
        if (animPrefix != null && getCurrentAnimation() != animPrefix)
        {
          playFlashAnimation(animPrefix, true, false, true);
        }
      case Confirm:
        var animPrefix = playableCharData?.getAnimationPrefix('confirm');
        if (animPrefix != null && getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, false);
        timeIdling = 0;
      case FistPumpIntro:
        var animPrefixA = playableCharData?.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData?.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData?.getFistPumpIntroEndFrame() ?? 0;
          if (endFrame > -1 && anim.curAnim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpIntroStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpIntroBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curAnim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData?.getFistPumpIntroBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPumpIntro: " + getCurrentAnimation());
        }

      case FistPump:
        var animPrefixA = playableCharData?.getAnimationPrefix('fistPump');
        var animPrefixB = playableCharData?.getAnimationPrefix('loss');

        if (getCurrentAnimation() == animPrefixA)
        {
          var endFrame = playableCharData?.getFistPumpLoopEndFrame() ?? 0;
          if (endFrame > -1 && anim.curAnim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpLoopStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpLoopBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curAnim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixB, true, false, false, playableCharData?.getFistPumpLoopBadStartFrame());
          }
        }
        else
        {
          FlxG.log.warn("Unrecognized animation in FistPump: " + getCurrentAnimation());
        }

      case IdleEasterEgg:
        var animPrefix = playableCharData?.getAnimationPrefix('idleEasterEgg');
        if (animPrefix != null && getCurrentAnimation() != animPrefix)
        {
          onIdleEasterEgg.dispatch();
          playFlashAnimation(animPrefix, false);
          seenIdleEasterEgg = true;
        }
        timeIdling = 0;
      case Cartoon:
        var animPrefix = playableCharData?.getAnimationPrefix('cartoon');
        if (animPrefix == null)
        {
          currentState = IdleEasterEgg;
        }
        else
        {
          if (getCurrentAnimation() != animPrefix) playFlashAnimation(animPrefix, true);
          timeIdling = 0;
        }
      default:
        // I shit myself.
    }

    // Call the superclass function AFTER updating the current state and playing the next animation.
    // This ensures that flixel-animate starts rendering the new animation immediately.
    super.update(elapsed);
  }

  override function onFinishAnim(name:String):Void
  {
    if (name == playableCharData?.getAnimationPrefix('intro'))
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
    else if (name == playableCharData?.getAnimationPrefix('idle'))
    {
      // trace('Finished idle');

      if (timeIdling >= IDLE_EGG_PERIOD && !seenIdleEasterEgg)
      {
        currentState = IdleEasterEgg;
      }
      else if (timeIdling >= IDLE_CARTOON_PERIOD)
      {
        currentState = Cartoon;
      }
    }
    else if (name == playableCharData?.getAnimationPrefix('confirm'))
    {
      // trace('Finished confirm');
    }
    else if (name == playableCharData?.getAnimationPrefix('fistPump'))
    {
      // trace('Finished fist pump');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('idleEasterEgg'))
    {
      // trace('Finished spook');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('loss'))
    {
      // trace('Finished loss reaction');
      currentState = Idle;
    }
    else if (name == playableCharData?.getAnimationPrefix('newUnlock'))
    {
      // Animation should loop.
    }
    else if (name == playableCharData?.getAnimationPrefix('charSelect'))
    {
      onCharSelectComplete();
    }
    else
    {
      trace('Finished ${name}');
    }
  }

  override public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    animation.play(id, Force, Reverse, Frame);

    if (animation.curAnim != null)
    {
      animation.curAnim.looped = Loop;
    }
    applyAnimationOffset();
  }
}
