package funkin.ui.freeplay.dj;

import funkin.data.freeplay.player.PlayerRegistry;
import funkin.util.assets.FlxAnimationUtil;

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

    loadTextureAtlas(playableCharData.getAssetPath(), playableCharData.getAtlasSettings());
    loadAnimations();

    if (playableCharData.useApplyStageMatrix() && !this.applyStageMatrix || playableCharData.useAnimatePosition)
    {
      this.applyStageMatrix = true;

      if (playableCharData.useAnimatePosition)
      {
        resetPosition();
      }
    }

    currentState = Intro;
  }

  function loadAnimations():Void
  {
    log('Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addTextureAtlasAnimations(this, playableCharData.getAnimationsList());

    // Fallback: If the animation failed to load, try again with symbol animations.
    // Frame label animations are the default!
    for (animation in playableCharData.getAnimationsList())
    {
      if (!this.hasAnimation(animation.name))
      {
        FlxAnimationUtil.addTextureAtlasAnimation(this, {
          name: animation.name,
          prefix: animation.prefix,
          frameRate: animation.frameRate,
          looped: animation.looped,
          flipX: animation.flipX,
          flipY: animation.flipY,
          animType: 'symbol',
          offsets: animation.offsets,
          frameIndices: animation.frameIndices
        });
      }
    }

    var animationNames:Array<String> = this.animation.getNameList();
    log('Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' ATLASDJ '.bold().bg_blue() + ' $message');
  }
}
