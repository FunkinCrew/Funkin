package funkin.play.character;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFramesCollection;
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
    trace('Creating Multi-Sparrow character: ' + this.characterId);

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
      pixelPerfectRender = true;
      pixelPerfectPosition = true;
    }
    else
    {
      this.isPixel = false;
      this.antialiasing = true;
    }
  }

  function buildSpritesheet():Void
  {
    var texture:FlxAtlasFrames = Paths.getSparrowAtlas(_data.assetPaths[0]);

    if (texture == null)
    {
      trace('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPaths[0]}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${_data.assetPaths[0]}');
      return;
    }
    else
    {
      trace('Creating multi-sparrow atlas: ${_data.assetPaths[0]}');
      texture.parent.destroyOnNoUse = false;
    }

    for (i => asset in _data.assetPaths)
    {
      if (i == 0)
      {
        continue;
      }

      var subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(asset);
      // If we don't do this, the unused textures will be removed as soon as they're loaded.

      if (subTexture == null)
      {
        trace('Multi-Sparrow atlas could not load subtexture: ${asset}');
        continue;
      }
      else
      {
        trace('Concatenating multi-sparrow atlas: ${asset}');
      }

      texture.addAtlas(subTexture);
    }

    this.frames = texture;
    this.setScale(_data.scale);
  }

  function buildAnimations()
  {
    trace('[MULTISPARROWCHAR] Loading ${_data.animations.length} animations for ${characterId}');

    // We need to swap to the proper frame collection before adding the animations, I think?
    for (anim in _data.animations)
    {
      FlxAnimationUtil.addAtlasAnimation(this, anim);

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
    trace('[MULTISPARROWCHAR] Successfully loaded ${animNames.length} animations for ${characterId}');
  }

  public override function playAnimation(name:String, restart:Bool = false, ignoreOther:Bool = false, reverse:Bool = false):Void
  {
    // Make sure we ignore other animations if we're currently playing a forced one,
    // unless we're forcing a new animation.
    if (!this.canPlayOtherAnims && !ignoreOther) return;

    super.playAnimation(name, restart, ignoreOther, reverse);
  }
}
