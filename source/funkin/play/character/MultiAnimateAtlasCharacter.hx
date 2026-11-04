package funkin.play.character;

import animate.FlxAnimateFrames;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;

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

  /**
   * Retrieve a list of all the asset paths required to load the character.
   *
   * If you have a scripted class which initializes sprites, or plays sounds or something,
   * make sure you add them here so they get cached in the loading screen.
   *
   * @param type The type of asset to query
   * @param charId The character ID, used to look up the specific assets.
   * @return An array of asset paths, or empty if no assets of that type are required.
   */
  public static function queryAssets(type:funkin.assets.Assets.AssetType,
    entryId:String,
    ?params:CharacterEntryParams):Array<funkin.assets.Paths.AssetPath>
  {
    trace('ASSETS: Querying assets for Multi-Animate Atlas character "$entryId"');
    // Specific implementations handle figuring out which assets to load.
    var results:Array<AssetPath> = BaseCharacter.queryBaseAssets(type, entryId, params);

    var _data:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(entryId);
    if (_data == null) return results;

    switch (type)
    {
      case IMAGE:
        var assetPath = funkin.assets.Paths.animateAtlas(_data.assetPath);
        results.append(assetPath.image());

        for (animation in _data.animations)
        {
          if (animation.assetPath == null) continue;

          switch (animation.renderType)
          {
            case 'sparrow':
              results.push(funkin.assets.Paths.image(animation.assetPath));
            default:
              var assetPath = funkin.assets.Paths.animateAtlas(animation.assetPath);
              results.append(assetPath.image());
          }
        }

      case XML:
        for (animation in _data.animations)
        {
          if (animation.assetPath == null) continue;

          switch (animation.renderType)
          {
            case 'sparrow':
              results.push(funkin.assets.Paths.xml(animation.assetPath));
            default:
              // Nothing
          }
        }

      case JSON:
        var assetPath = funkin.assets.Paths.animateAtlas(_data.assetPath);
        results.appendUnique(assetPath.json());

        for (animation in _data.animations)
        {
          if (animation.assetPath == null) continue;

          switch (animation.renderType)
          {
            default:
              var assetPath = funkin.assets.Paths.animateAtlas(animation.assetPath);
              results.appendUnique(assetPath.json());
          }
        }

      default:
        // Nothing
    }

    return results;
  }

  public function new(id:String)
  {
    super(id, {
      renderType: CharacterRenderType.MultiAnimateAtlas
    });
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
    log('Loading texture atlases for ${characterId}.');

    var textureList:Array<FlxAtlasFrames> = [];
    var addedAssetPaths:Array<String> = [];

    var assetPath:String = funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId');

    var baseAssetLibrary:String = Paths.getLibrary(assetPath);
    var baseAssetPath:String = Paths.stripLibrary(assetPath);

    var mainTexture:FlxAnimateFrames = Paths.getAnimateAtlas(baseAssetPath, baseAssetLibrary, getAtlasSettings());
    textureList.push(mainTexture);

    this.useRenderTexture = getAtlasSettings().useRenderTexture;
    this.applyStageMatrix = getAtlasSettings().applyStageMatrix;

    mainTexture.parent.destroyOnNoUse = false;

    for (animation in _data.animations)
    {
      if (animation.assetPath == null) continue;
      if (addedAssetPaths.contains(animation.assetPath)) continue;

      switch (animation.renderType)
      {
        case "sparrow":
          var sparrowPath:String = funkin.assets.Paths.formatRelative(animation.assetPath, 'gameplay/characters/$characterId', Constants.EXT_IMAGE);
          var subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(sparrowPath);
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
            // funkin.assets.Assets.cacheFlxGraphic(Paths.image(animation.assetPath));
          }

          textureList.push(subTexture);

          if (!_usedAtlases.contains(subTexture)) _usedAtlases.push(subTexture);
        default:
          var atlasPath:String = funkin.assets.Paths.formatRelative(animation.assetPath, 'gameplay/characters/$characterId');

          var subAssetLibrary:String = Paths.getLibrary(atlasPath);
          var subAssetPath:String = Paths.stripLibrary(atlasPath);

          var subTexture:FlxAnimateFrames = Paths.getAnimateAtlas(subAssetPath, subAssetLibrary, cast animation.atlasSettings ?? getAtlasSettings());

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
    log('Loading ${_data.animations.length} animations for ${characterId}');

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
    log('Successfully loaded ${animationNames.length} animations for ${characterId}');
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

  public override function toString():String
  {
    return 'MultiAnimateAtlasCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}
