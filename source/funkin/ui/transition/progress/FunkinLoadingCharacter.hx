package funkin.ui.transition.progress;

import funkin.assets.FunkinAssetCache;
import funkin.data.loading.LoadingCharacterData;
import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;

/**
 * The character sprite that appears in the loading screen.
 *
 * TODO: Consolidate this with `ModMenuCharacter`, and `CharSelectCharacter`!
 * They all share similar functionality which can be reduced.
 * - Abnormal
 */
// @:nullSafety
class FunkinLoadingCharacter extends FunkinSprite
{
  /**
   * The default animation this character plays.
   */
  public static final DEFAULT_ANIMATION:String = 'idle';

  /**
   * The default animation prefix this character uses.
   */
  public static final DEFAULT_ANIMATION_PREFIX:String = 'run';

  /**
   * If the render type is an Adobe Animate Texture Atlas and no atlas settings are provided, use these.
   */
  public static final DEFAULT_ATLAS_SETTINGS = {
    swfMode: true,
    cacheOnLoad: false,
    filterQuality: 1,
    applyStageMatrix: false,
    useRenderTexture: false,
    postStageMatrixApply: false
  };

  var data:Null<LoadingCharacterData> = null;
  var offsets:Array<Float> = [0, 0];

  public function new()
  {
    super();
  }

  /**
   * Loads the specified character from a parsed data structure.
   * @param newData The new character data to load.
   * @param graphicPath The path to the character's graphic.
   * @param modId The ID of the mod that this character belongs to.
   */
  public function loadCharacter(newData:LoadingCharacterData, characterId:String, modId:String):Void
  {
    data = newData;

    var graphicPath:String = '${FunkinProgressBar.CHARACTER_PATH}$characterId/$characterId';
    switch (data.renderType)
    {
      case 'animateatlas':
        loadTextureAtlas(graphicPath, null, getAtlasSettings(), modId);
      case 'packer':
        loadPacker(graphicPath, modId);
      default:
        loadSparrow(graphicPath, modId);
    }

    // Hacky fix for modded characters not being cached properly
    if (this.graphic != null)
    {
      switch (data.renderType)
      {
        case 'animateatlas':
          FunkinAssetCache.instance.permaCacheFlxGraphic('$graphicPath/spritemap1', this.graphic);
        default:
          FunkinAssetCache.instance.permaCacheFlxGraphic(graphicPath, this.graphic);
      }
    }

    scale.set(data.scale, data.scale);
    updateHitbox();

    this.setPosition(FlxG.width - (this.width + data.offsets[0]), FlxG.height - (this.height + data.offsets[1]));

    switch (data.renderType)
    {
      case 'animateatlas':
        FlxAnimationUtil.addTextureAtlasAnimation(this, {
          name: DEFAULT_ANIMATION,
          prefix: DEFAULT_ANIMATION_PREFIX,
          looped: true,
        });
      default:
        FlxAnimationUtil.addAtlasAnimation(this, {
          name: DEFAULT_ANIMATION,
          prefix: DEFAULT_ANIMATION_PREFIX,
          looped: true,
        });
    }
    this.animation.play(DEFAULT_ANIMATION);
  }

  public function getAtlasSettings():AtlasSpriteSettings
  {
    return cast data.atlasSettings ?? DEFAULT_ATLAS_SETTINGS;
  }
}
