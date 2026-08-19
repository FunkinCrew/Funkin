package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;

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

    currentState = Intro;
  }

  public function loadFrames():Void
  {
    log('Loading assets for Multi-Sparrow Freeplay DJ "${characterId}"');

    var assetList = [];
    for (anim in playableCharData.getAnimationsList())
    {
      if (anim.assetPath != null && !assetList.contains(anim.assetPath)) assetList.push(anim.assetPath);
    }

    var texture:FlxAtlasFrames = Paths.getSparrowAtlas(playableCharData.getAssetPath());

    if (texture == null)
    {
      log('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      return;
    }
    else
    {
      texture.parent.destroyOnNoUse = false;
    }

    for (asset in assetList)
    {
      final subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(asset);
      if (subTexture == null) log('Multi-Sparrow atlas could not load subtexture: ${asset}');
      else
      {
        log('Concatenating multi-sparrow atlas: ${asset}');
        subTexture.parent.destroyOnNoUse = false;
        funkin.assets.Assets.cacheFlxGraphic(funkin.assets.Paths.image(asset));
      }
      texture.addAtlas(subTexture);
    }

    this.frames = texture;
  }

  public function loadAnimations():Void
  {
    log('[MULTISPARROWDJ] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animationList:Array<String> = this.animation.getNameList();
    log('[MULTISPARROWDJ] Successfully loaded ${animationList.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' MULTISPARROWDJ '.bold().bg_blue() + ' $message');
  }
}
