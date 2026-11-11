package funkin.play.character;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.modding.events.ScriptEvent;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.ValidatedPaths as Paths;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Assets.AssetType;

/**
 * A PackerCharacter is a Character which is rendered by
 * displaying an animation derived from a Packer spritesheet file.
 */
class PackerCharacter extends BaseCharacter
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
    trace('ASSETS: Querying assets for Packer character "$entryId"');
    // Specific implementations handle figuring out which assets to load.
    var results:Array<AssetPath> = BaseCharacter.queryBaseAssets(type, entryId, params);

    var _data:Null<CharacterData> = CharacterRegistry.instance.fetchCharacterData(entryId);
    if (_data == null) return results;

    switch (type)
    {
      case IMAGE:
        results.push(Paths.image(_data.assetPath));
      case TEXT:
        results.push(Paths.txt(_data.assetPath));
      default:
        // Nothing
    }

    return results;
  }

  public function new(id:String)
  {
    super(id, {
      renderType: CharacterRenderType.Packer
    });
  }

  override function onCreate(event:ScriptEvent):Void
  {
    // Display a custom scope for debugging purposes.
    #if FEATURE_DEBUG_TRACY
    cpp.vm.tracy.TracyProfiler.zoneScoped('PackerCharacter.create(${this.characterId})');
    #end

    loadSpritesheet();
    loadAnimations();

    super.onCreate(event);
  }

  function loadSpritesheet():Void
  {
    trace('Loading assets for Packer character "${characterId}"');

    var assetPath:String = funkin.assets.Paths.formatRelative(_data.assetPath, 'gameplay/characters/$characterId', Constants.EXT_IMAGE);

    var tex:FlxFramesCollection = Paths.getPackerAtlas(assetPath);
    if (tex == null)
    {
      trace('Could not load Packer sprite: ${_data.assetPath}');
      return;
    }

    this.frames = tex;

    if (_data.isPixel)
    {
      this.isPixel = true;
      this.antialiasing = false;
      // pixelPerfectRender = true;
      // pixelPerfectPosition = true;
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
    trace('[PACKERCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, _data.animations);

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

    var animNames = this.animation.getNameList();
    trace('[PACKERCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  public override function toString():String
  {
    return 'PackerCharacter($characterName ($characterId), pos=[$x, $y])';
  }
}
