package funkin.ui.freeplay.dj;

import flixel.util.FlxSignal;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a AnimateAtlasFreeplayDJ.
 * Create a scripted class that extends AnimateAtlasFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedAnimateAtlasFreeplayDJ extends AnimateAtlasFreeplayDJ implements polymod.hscript.HScriptedClass {}

class AnimateAtlasFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);
    loadAtlas(Paths.animateAtlas(playableCharData.getAssetPath()));

    onAnimationComplete.add(onFinishAnim);
    onAnimationLoop.add(onFinishAnim);
  }

  public override function update(elapsed:Float):Void
  {
    switch (currentState)
    {
      case Intro:
        // Play the intro animation then leave this state immediately.
        var animPrefix = playableCharData?.getAnimationPrefix('intro');
        if (animPrefix != null && (getCurrentAnimation() != animPrefix || !this.anim.isPlaying))
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
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpIntroStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpIntroBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
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
          if (endFrame > -1 && anim.curFrame >= endFrame)
          {
            playFlashAnimation(animPrefixA, true, false, false, playableCharData?.getFistPumpLoopStartFrame());
          }
        }
        else if (getCurrentAnimation() == animPrefixB)
        {
          var endFrame = playableCharData?.getFistPumpLoopBadEndFrame() ?? 0;
          if (endFrame > -1 && anim.curFrame >= endFrame)
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
    // This ensures that FlxAnimate starts rendering the new animation immediately.
    super.update(elapsed);
  }

  override function onFinishAnim(name:String):Void
  {
    // var name = anim.curSymbol.name;

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
    else if (name == playableCharData?.getAnimationPrefix('cartoon'))
    {
      // trace('Finished cartoon');

      var frame:Int = FlxG.random.bool(33) ? (playableCharData?.getCartoonLoopBlinkFrame() ?? 0) : (playableCharData?.getCartoonLoopFrame() ?? 0);

      // Character switches channels when the video ends, or at a 10% chance each time his idle loops.
      if (FlxG.random.bool(5))
      {
        frame = playableCharData?.getCartoonChannelChangeFrame() ?? 0;
        // boyfriend switches channel code?
        // Transefer into bf.hxc in scripts/freeplay/dj
        // runTvLogic();
      }
      trace('Replay idle: ${frame}');
      var animPrefix = playableCharData?.getAnimationPrefix('cartoon');
      if (animPrefix != null) playFlashAnimation(animPrefix, true, false, false, frame);
      // trace('Finished confirm');
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

  override public function listAnimations():Array<String>
  {
    var anims:Array<String> = [];
    @:privateAccess
    for (animKey in anim.symbolDictionary)
      anims.push(animKey.name);

    return anims;
  }

  override public function getCurrentAnimation():String
  {
    if (this.anim == null || this.anim.curSymbol == null) return "";
    return this.anim.curSymbol.name;
  }

  override public function playFlashAnimation(id:String, Force:Bool = false, Reverse:Bool = false, Loop:Bool = false, Frame:Int = 0):Void
  {
    playAnimation(id, Force, Reverse, Loop, Frame);
    applyAnimOffset();
  }
}
