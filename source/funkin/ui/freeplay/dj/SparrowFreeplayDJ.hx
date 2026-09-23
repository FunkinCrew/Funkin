package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.assets.Assets;
import funkin.assets.Paths;
import funkin.data.freeplay.player.PlayerData;

/**
 * A SparrowFreeplayDJ is a Freeplay DJ which is rendered by
 * displaying an animation derived from a SparrowV2 atlas spritesheet file.
 *
 * BaseFreeplayDJ has game logic, SparrowFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class SparrowFreeplayDJ extends BaseFreeplayDJ
{
  public static function queryAssets(type:funkin.assets.Assets.AssetType,
    characterId:String):Array<funkin.assets.Paths.AssetPath>
  {
    var playableChar = PlayerRegistry.instance.fetchEntry(characterId);
    if (playableChar == null) return [];
    var playableCharData:Null<PlayerFreeplayDJData> = playableChar.getFreeplayDJData();

    if (playableCharData == null)
    {
      return [];
    }

    var results:Array<AssetPath> = [];
    switch (type)
    {
      case IMAGE:
        results.pushUnique(Paths.image(playableCharData.getAtlasPath()));
      case XML:
        results.pushUnique(Paths.xml(playableCharData.getAtlasPath()));
      default:
        // Nothing
    }
    return results;
  }

  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadFrames();
    loadAnimations();

    currentState = Intro;
  }

  public function loadFrames():Void
  {
    var assetPath:String = funkin.assets.Paths.formatRelative(
      playableCharData.getAssetPath(),
      'gameplay/playable-characters/$characterId',
      Constants.EXT_IMAGE
    );
    final tex:FlxFramesCollection = Paths.getSparrowAtlas(assetPath);
    if (tex == null)
    {
      log('Could not load sparrow sprite: ' + playableCharData.getAssetPath());
      return;
    }
    this.frames = tex;
  }

  public function loadAnimations():Void
  {
    log('[SPARROWDJ] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animationList:Array<String> = this.animation.getNameList();
    log('[SPARROWDJ] Successfully loaded ${animationList.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' SPARROWDJ '.bold().bg_blue() + ' $message');
  }
}
