package funkin.play.character;

import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * An AnimateAtlasCharacter is a Character which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseCharacter has game logic, AnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasCharacter extends BaseCharacter
{
  public function new(id:String)
  {
    super(id, CharacterRenderType.AnimateAtlas);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('AnimateAtlasCharacter.create(${this.characterId})');
    #end

    log('Loading assets for Animate Atlas character "${characterId}"');
    loadAtlas();
    loadAnimations();

    log('Successfully loaded texture atlas for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);
  }

  function loadAtlas():Void
  {
    log('Loading sprite atlas for ${characterId}.');
    var assetLibrary:String = Paths.getLibrary(_data.assetPath);
    var assetPath:String = Paths.stripLibrary(_data.assetPath);

    loadTextureAtlas(assetPath, assetLibrary, getAtlasSettings());

    if (_data.isPixel)
    {
      this.isPixel = true;
      this.antialiasing = false;
    }
    else
    {
      this.isPixel = false;
      this.antialiasing = true;
    }

    this.setScale(_data.scale);
  }

  function loadAnimations():Void
  {
    log('Loading ${_data.animations.length} animations for ${characterId}');

    FlxAnimationUtil.addTextureAtlasAnimations(this, _data.animations);

    for (anim in _data.animations)
    {
      if (anim.offsets == null)
      {
        setAnimationOffsets(anim.name, 0, 0);
      }
      else
      {
        setAnimationOffsets(anim.name, anim.offsets[0], anim.offsets[1]);
      }
    }

    var animationNames:Array<String> = this.animation.getNameList();
    log('[ATLASCHAR] Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    return cast _data.atlasSettings;
  }

  static function log(message:String):Void
  {
    trace(' ATLASCHAR '.bold().bg_blue() + ' $message');
  }
}
