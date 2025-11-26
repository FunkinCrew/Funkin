package funkin.play.character;

import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import animate.FlxAnimateFrames;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;
import flixel.math.FlxPoint;

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
  var originalSizes(default, never):FlxPoint = new FlxPoint(0, 0);

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

    try
    {
      trace('Loading assets for Multi-Animate Atlas character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));
      loadAtlases();
      loadAnimations();
    }
    catch (e)
    {
      throw "Exception thrown while building sprite: " + e;
    }

    trace('[MULTIATLASCHAR] Successfully loaded texture atlases for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);

    originalSizes.set(this.width, this.height);
  }

  function loadAtlases():Void
  {
    trace('[MULTIATLASCHAR] Loading sprite atlases for ${characterId}.');

    var assetList:Array<String> = [];
    for (anim in _data.animations)
    {
      if (anim.assetPath != null && !assetList.contains(anim.assetPath))
      {
        assetList.push(anim.assetPath);
      }
    }

    var baseAssetLibrary:String = Paths.getLibrary(_data.assetPath);
    var baseAssetPath:String = Paths.stripLibrary(_data.assetPath);

    loadTextureAtlas(baseAssetPath, baseAssetLibrary, getAtlasSettings());

    for (asset in assetList)
    {
      var subAssetLibrary:String = Paths.getLibrary(asset);
      var subAssetPath:String = Paths.stripLibrary(asset);

      var clone:FunkinSprite = FunkinSprite.createTextureAtlas(0, 0, subAssetPath, subAssetLibrary, cast _data.atlasSettings);
      var subTexture:FlxAnimateFrames = clone.library;

      trace('Concatenating texture atlas: ${asset}');
      subTexture.parent.destroyOnNoUse = false;

      this.library.addAtlas(subTexture);
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

    this.setScale(_data.scale);
  }

  function loadAnimations():Void
  {
    trace('[MULTIATLASCHAR] Loading ${_data.animations.length} animations for ${characterId}');

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

    var animNames = this.anim.getNameList();
    trace('[MULTIATLASCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  override function get_width():Float
  {
    return originalSizes.x;
  }

  override function get_height():Float
  {
    return originalSizes.y;
  }

  /**
   * Get the configuration for the texture atlas.
   * @return The configuration for the texture atlas.
   */
  public function getAtlasSettings():AtlasSpriteSettings
  {
    return cast _data.atlasSettings;
  }
}
