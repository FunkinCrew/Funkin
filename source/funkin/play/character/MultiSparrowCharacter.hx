package funkin.play.character;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
import animate.FlxAnimateFrames;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.character.CharacterData.CharacterRenderType;

/**
 * For some characters which use Sparrow atlases, the spritesheets need to be split
 * into multiple files. This character renderer concatenates these together into a single sprite.
 *
 * Examples in base game include BF Holding GF (most of the sprites are in one file
 * but the death animation is in a separate file).
 * Only example I can think of in mods is Tricky (which has a separate file for each animation).
 *
 * BaseCharacter has game logic, MultiSparrowCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class MultiSparrowCharacter extends BaseCharacter
{
  public function new(id:String)
  {
    super(id, CharacterRenderType.MultiSparrow);
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('MultiSparrowCharacter.create(${this.characterId})');
    #end

    buildSprites();
    super.onCreate(event);
  }

  function buildSprites():Void
  {
    buildSpritesheet();
    buildAnimations();

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
  }

  function buildSpritesheet():Void
  {
    log('Loading assets for Multi-Sparrow character "${characterId}"');

    var textureList:Array<FlxAtlasFrames> = [];
    var addedAssetPaths:Array<String> = [];

    var mainTexture:FlxAtlasFrames = Paths.getSparrowAtlas(_data.assetPath);
    if (mainTexture == null)
    {
      log('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPath}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPath}');
      return;
    }
    else
    {
      log('Creating multi-sparrow atlas: ${_data.assetPath}');
      mainTexture.parent.destroyOnNoUse = false;
      textureList.push(mainTexture);
    }

    var hasTextureAtlas:Bool = false;

    for (anim in _data.animations)
    {
      if (anim.renderType == "animateatlas")
      {
        hasTextureAtlas = true;
        break;
      }
    }

    for (animation in _data.animations)
    {
      if (animation.assetPath == null) continue;
      if (addedAssetPaths.contains(animation.assetPath)) continue;

      switch (animation.renderType)
      {
        case "animateatlas":
          var subAssetLibrary:String = Paths.getLibrary(animation.assetPath);
          var subAssetPath:String = Paths.stripLibrary(animation.assetPath);

          var clone:FunkinSprite = FunkinSprite.createTextureAtlas(0, 0, subAssetPath, subAssetLibrary, cast animation.atlasSettings ?? _data.atlasSettings);
          var subTexture:FlxAnimateFrames = clone.library;

          log('Concatenating texture atlas: ${animation.assetPath}');
          subTexture.parent.destroyOnNoUse = false;

          textureList.push(subTexture);
        default:
          var subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(animation.assetPath);
          // If we don't do this, the unused textures will be removed as soon as they're loaded.

          if (subTexture == null)
          {
            log('Multi-Sparrow atlas could not load subtexture: ${animation.assetPath}');
            FlxG.log.error('Multi-Sparrow atlas could not load subtexture: ${animation.assetPath}');
            continue;
          }
          else
          {
            log('Concatenating multi-sparrow atlas: ${animation.assetPath}');
            subTexture.parent.destroyOnNoUse = false;

            // Only cache the texture if we don't have a texture atlas animation.
            // Caching sparrows breaks mix-and-match and I wanna fix it at some point...
            // TODO: Re-enable this line once a proper fix is found.
            // - Abnormal
            if (!hasTextureAtlas)
            {
              FunkinMemory.cacheTexture(Paths.image(animation.assetPath));
            }
          }

          textureList.push(subTexture);
      }

      addedAssetPaths.push(animation.assetPath);
    }

    this.frames = FlxAnimateFrames.combineAtlas(textureList);
    this.setScale(_data.scale);
  }

  function buildAnimations():Void
  {
    log('[MULTISPARROWCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    // We need to swap to the proper frame collection before adding the animations, I think?
    for (anim in _data.animations)
    {
      switch (anim.renderType)
      {
        case "animateatlas":
          FlxAnimationUtil.addTextureAtlasAnimation(this, anim);
        default:
          FlxAnimationUtil.addAtlasAnimation(this, anim);
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
    log('[MULTISPARROWCHAR] Successfully loaded ${animationNames.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' MULTIATLASCHAR '.bold().bg_blue() + ' $message');
  }
}
