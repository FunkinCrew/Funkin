package funkin.ui.freeplay.dj;

import funkin.data.freeplay.player.PlayerRegistry;
import funkin.util.assets.FlxAnimationUtil;
import funkin.assets.Assets;
import funkin.assets.Paths;
import funkin.data.freeplay.player.PlayerData;

/**
 * An AnimateAtlasFreeplayDJ is a Freeplay DJ which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseFreeplayDJ has game logic, AnimateAtlasFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasFreeplayDJ extends BaseFreeplayDJ
{
  public static function queryAssets(type:funkin.assets.Assets.AssetType,
    characterId:String):Array<funkin.assets.Paths.AssetPath>
  {
    trace('~~AnimateAtlasFreeplayDJ: ${characterId}:${type}~~');
    var playableChar = PlayerRegistry.instance.fetchEntry(characterId);
    if (playableChar == null)
    {
      trace('~NO PlayableCharacter');
      return [];
    }
    var playableCharData:Null<PlayerFreeplayDJData> = playableChar.getFreeplayDJData();

    if (playableCharData == null)
    {
      trace('~NO FreeplayData');
      return [];
    }

    var results:Array<AssetPath> = [];
    switch (type)
    {
      case IMAGE:
        results.appendUnique(Paths.animateAtlas(playableCharData.getAtlasPath()).image());
      case JSON:
        results.appendUnique(Paths.animateAtlas(playableCharData.getAtlasPath()).json());
      default:
        // Nothing
    }

    trace('Got: ${results.length} assets for ${characterId}');
    return results;
  }

  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    var assetPath:String = funkin.assets.Paths.formatRelative(playableCharData.getAssetPath(), 'gameplay/playable-characters/$characterId');
    loadTextureAtlas(assetPath, playableCharData.getAtlasSettings());
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
