package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a MultiSparrowFreeplayDJ.
 * Create a scripted class that extends MultiSparrowFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedMultiSparrowFreeplayDJ extends MultiSparrowFreeplayDJ implements polymod.hscript.HScriptedClass {}

/**
 * For some Freeplay DJs which use Sparrow atlases, the spritesheets need to be split
 * into multiple files. This Freeplay DJ renderer concatenates these together into a single sprite.
 *
 * BaseFreeplayDJ has game logic, MultiSparrowFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class MultiSparrowFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadFrames();
    loadAnimations();

    animation.onFinish.add(onFinishAnim);
    animation.onLoop.add(onFinishAnim);
  }

  public function loadFrames():Void
  {
    trace('Loading assets for Multi-Sparrow character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));

    var assetList = [];
    for (anim in playableCharData.getAnimationsList())
      if (anim.assetPath != null && !assetList.contains(anim.assetPath)) assetList.push(anim.assetPath);

    var texture:FlxAtlasFrames = Paths.getSparrowAtlas(playableCharData.getAssetPath());

    if (texture == null)
    {
      trace('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      return;
    }
    else
    {
      trace('Creating multi-sparrow atlas: ${playableCharData.getAssetPath()}');
      texture.parent.destroyOnNoUse = false;
    }

    for (asset in assetList)
    {
      final subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(asset);
      if (subTexture == null) trace('Multi-Sparrow atlas could not load subtexture: ${asset}');
      else
      {
        trace('Concatenating multi-sparrow atlas: ${asset}');
        subTexture.parent.destroyOnNoUse = false;
        FunkinMemory.cacheTexture(Paths.image(asset));
      }
      texture.addAtlas(subTexture);
    }
    this.frames = texture;
  }

  public function loadAnimations():Void
  {
    trace('[MULTISPARROWDJ] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animationList:Array<String> = this.animation.getNameList();
    trace('[MULTISPARROWDJ] Successfully loaded ${animationList.length} animations for ${characterId}');
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
