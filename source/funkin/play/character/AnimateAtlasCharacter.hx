package funkin.play.character;

import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.data.character.CharacterData;
import funkin.graphics.FunkinSprite;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.character.CharacterRegistry;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

/**
 * An AnimateAtlasCharacter is a Character which is rendered by
 * displaying an animation derived from an Adobe Animate texture atlas spritesheet file.
 *
 * BaseCharacter has game logic, AnimateAtlasCharacter has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class AnimateAtlasCharacter extends BaseCharacter
{
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
  public static function queryAssets(type:AssetType, entryId:String, ?params:CharacterEntryParams):Array<AssetPath>
  {
    // trace('ASSETS: Querying assets for Animate Atlas character "${charId}"')
    // Specific implementations handle figuring out which assets to load.
    var results:Array<AssetPath> = BaseCharacter.queryBaseAssets(type, entryId, params);

    var _data:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(entryId);
    if (_data == null) return results; // No assets if data couldn't be parsed.

    var assetPath = Paths.animateAtlas(_data.assetPath);

    switch (type)
    {
      case IMAGE:
        results.append(assetPath.image());
      case JSON:
        results.append(assetPath.json());

        var atlasDir:String = Paths.stripLibrary(funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$entryId'));
        var animJson = Paths.json('$atlasDir/Animation', false).orNull();
        var mapJson = Paths.json('$atlasDir/spritemap1', false).orNull();
        if (animJson != null) results.append([animJson]);
        if (mapJson != null) results.append([mapJson]);
      default:
        // Nothing
    }

    return results;
  }

  public function new(id:String)
  {
    super(id, {
      renderType: CharacterRenderType.AnimateAtlas
    });
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
    var assetPath:String = Paths.stripLibrary(funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId'));

    loadTextureAtlas(assetPath, getAtlasSettings());

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

  public override function toString():String
  {
    return 'AnimateAtlasCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}
