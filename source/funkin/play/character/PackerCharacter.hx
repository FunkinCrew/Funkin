package funkin.play.character;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.modding.events.ScriptEvent;
import funkin.play.character.CharacterData.CharacterRenderType;
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
    trace('Loading assets for Packer character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));

    var tex:FlxFramesCollection = Paths.getPackerAtlas(_data.assetPath);
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
}
