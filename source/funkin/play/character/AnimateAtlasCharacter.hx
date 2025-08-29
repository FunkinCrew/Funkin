package funkin.play.character;

import funkin.graphics.FunkinSprite;
import funkin.util.assets.FlxAnimationUtil;
import funkin.modding.events.ScriptEvent;
import funkin.data.animation.AnimationData;
import funkin.play.character.CharacterData.CharacterRenderType;

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

    try
    {
      trace('Loading assets for Animate Atlas character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));
      loadAtlas();
      loadAnimations();
    }
    catch (e)
    {
      throw "Exception thrown while building sprite: " + e;
    }

    trace('[ATLASCHAR] Successfully loaded texture atlas for ${characterId} with ${_data.animations.length} animations.');
    super.onCreate(event);
  }

  function loadAtlas()
  {
    trace('[ATLASCHAR] Loading sprite atlas for ${characterId}.');
    var assetLibrary:String = Paths.getLibrary(_data.assetPath);
    var assetPath:String = Paths.stripLibrary(_data.assetPath);

    loadTextureAtlas(assetPath, assetLibrary);

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

  function loadAnimations()
  {
    trace('[ATLASCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    for (anim in _data.animations)
    {
      addAnimation(anim);
    }

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
    trace('[ATLASCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  /**
   * Properly adds an animation to this sprite based on the provided animation data.
   */
  function addAnimation(anim:AnimationData):Void
  {
    if (anim.prefix == null) return;
    var frameRate:Float = anim.frameRate ?? 24;
    var looped:Bool = anim.looped ?? false;
    var flipX:Bool = anim.flipX ?? false;
    var flipY:Bool = anim.flipY ?? false;

    this.addAnimationIfMissing(anim.name, anim.prefix, frameRate, looped, flipX, flipY);
  }
}
