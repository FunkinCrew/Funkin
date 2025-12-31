package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.data.freeplay.player.PlayerRegistry;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.FlxBasic;

/**
 * A script that can be tied to a MultiSparrowFreeplayDJ.
 * Create a scripted class that extends MultiSparrowFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedMultiSparrowFreeplayDJ extends MultiSparrowFreeplayDJ implements polymod.hscript.HScriptedClass {}

class MultiSparrowFreeplayDJ extends BaseFreeplayDJ.FlixelFramedFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);
  }

  override public function loadFrames():Void
  {
    trace('Loading assets for Multi-Sparrow character "${characterId}"', flixel.util.FlxColor.fromString("#89CFF0"));

    var assetList = [];
    for (anim in playableCharData.getAnimationsList())
      if (anim.assetPath != null && !assetList.contains(anim.assetPath)) assetList.push(anim.assetPath);

    var texture:FlxAtlasFrames = Paths.getSparrowAtlas(playableCharData.getAssetPath());

    if (texture == null)
    {
      trace('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      FlxG.log.error('Multi-Sparrow atlas could not load PRIMARY texture: ${playableCharData.getAssetPath()}');
      return;
    }
    else
    {
      trace('Creating multi-sparrow atlas: ${playableCharData.getAssetPath()}');
      texture.parent.destroyOnNoUse = false;
    }

    for (asset in assetList)
    {
      final subTexture:FlxAtlasFrames = Paths.getSparrowAtlas(asset);
      if (subTexture == null) trace('Multi-Sparrow atlas could not load subtexture: ${asset}');
      else
      {
        trace('Concatenating multi-sparrow atlas: ${asset}');
        subTexture.parent.destroyOnNoUse = false;
        FunkinMemory.cacheTexture(Paths.image(asset));
      }
      texture.addAtlas(subTexture);
    }
    this.frames = texture;
  }
}
