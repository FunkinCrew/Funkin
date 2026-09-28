package funkin.play.character;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.animation.AnimationData;
import funkin.data.character.CharacterData.CharacterRenderType;
import funkin.modding.events.ScriptEvent;
import funkin.util.assets.FlxAnimationUtil;

/**
 * A PackerCharacter is a Character which is rendered by
 * displaying an animation derived from a Packer spritesheet file.
 */
class PackerCharacter extends BaseCharacter
{
  public function new(id:String)
  {
    super(id, CharacterRenderType.Packer);
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

    var dataAssetPath:String = getAssetPath();
    var tex:FlxFramesCollection = Paths.getPackerAtlas(dataAssetPath);
    if (tex == null)
    {
      trace('Could not load Packer sprite: ${dataAssetPath}');
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

    this.setScale(getBaseScale());
  }

  function loadAnimations():Void
  {
    var dataAnimations:Array<AnimationData> = getCharacterAnimations();

    trace('[PACKERCHAR] Loading ${dataAnimations.length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, dataAnimations);

    for (anim in dataAnimations)
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
