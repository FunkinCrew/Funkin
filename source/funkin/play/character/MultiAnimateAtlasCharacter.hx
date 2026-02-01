package funkin.play.character;

import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * This render type is the most complex, and is used by characters which use
 * multiple Adobe Animate texture atlases. This render type concatenates multiple
 * texture atlases into a single sprite.
 *
 * BaseCharacter has game logic, MultiAnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class MultiAnimateAtlasCharacter extends BaseCharacter
{
  var _usedAtlases:Array<FlxAtlasFrames> = [];

  public function new(id:String)
  {
    super(id, CharacterRenderType.MultiAnimateAtlas);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('MultiAnimateAtlasCharacter.create(${this.characterId})');
    #end

    log('Loading assets for Multi-Animate Atlas character "${characterId}"');
    loadAtlases();
    loadAnimations();

    log('Successfully loaded texture atlases for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);
  }

  function loadAtlases():Void
  {
    log('Loading sprite atlases for ${characterId}.');

    var textureList:Array<FlxAtlasFrames> = [];
    var addedAssetPaths:Array<String> = [];

    var baseAssetLibrary:String = Paths.getLibrary(_data.assetPath);
    var baseAssetPath:String = Paths.stripLibrary(_data.assetPath);

    var mainTexture:FlxAnimateFrames = Paths.getAnimateAtlas(baseAssetPath, baseAssetLibrary, cast _data.atlasSettings);
    textureList.push(mainTexture);

    mainTexture.parent.destroyOnNoUse = false;

    for (animation in _data.animations)
    {
      if (animation.assetPath == null) continue;
      if (addedAssetPaths.contains(animation.assetPath)) continue;

      switch (animation.renderType)
      {
        case "sparrow":
          var subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(animation.assetPath);
          // If we don't do this, the unused textures will be removed as soon as they're loaded.

          if (subTexture == null)
          {
            log('Multi-Animate atlas could not load subtexture: ${animation.assetPath}');
            FlxG.log.error('Multi-Animate atlas could not load subtexture: ${animation.assetPath}');
            return;
          }
          else
          {
            log('Concatenating sparrow atlas: ${animation.assetPath}');
            subTexture.parent.destroyOnNoUse = false;
            // This breaks mix-and-match for some reason.
            // TODO: Re-enable this line once a proper fix is found.
            // - Abnormal
            // FunkinMemory.cacheTexture(Paths.image(animation.assetPath));
          }

          textureList.push(subTexture);

          if (!_usedAtlases.contains(subTexture)) _usedAtlases.push(subTexture);
        default:
          var subAssetLibrary:String = Paths.getLibrary(animation.assetPath);
          var subAssetPath:String = Paths.stripLibrary(animation.assetPath);

          var subTexture:FlxAnimateFrames = Paths.getAnimateAtlas(subAssetPath, subAssetLibrary, cast animation.atlasSettings ?? _data.atlasSettings);

          log('Concatenating texture atlas: ${animation.assetPath}');
          subTexture.parent.destroyOnNoUse = false;

          textureList.push(subTexture);
      }

      addedAssetPaths.push(animation.assetPath);
    }

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

    this.frames = FlxAnimateFrames.combineAtlas(textureList);
    this.setScale(_data.scale);
  }

  function loadAnimations():Void
  {
    log('[MULTIATLASCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    for (anim in _data.animations)
    {
      switch (anim.renderType)
      {
        case "sparrow":
          FlxAnimationUtil.addAtlasAnimation(this, anim);
        default:
          FlxAnimationUtil.addTextureAtlasAnimation(this, anim);
      }

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
    log('[MULTIATLASCHAR] Successfully loaded ${animationNames.length} animations for ${characterId}');
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
    trace(' MULTIATLASCHAR '.bold().bg_blue() + ' $message');
  }

  override function destroy():Void
  {
    for (atlas in _usedAtlases)
    {
      if (atlas.parent == null) continue;
      atlas.parent.destroyOnNoUse = true;
    }

    _usedAtlases.clear();

    super.destroy();
  }
}
