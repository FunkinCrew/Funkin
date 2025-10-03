package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;

/**
 * A script that can be tied to a PackerFreeplayDJ.
 * Create a scripted class that extends PackerFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedPackerFreeplayDJ extends PackerFreeplayDJ implements polymod.hscript.HScriptedClass {}

class PackerFreeplayDJ extends BaseFreeplayDJ.FlixelFramedFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);
  }

  override public function loadFrames()
  {
    final tex:FlxFramesCollection = Paths.getPackerAtlas(playableCharData.getAssetPath());
    if (tex == null)
    {
      trace('Could not load Packer sprite: ${playableCharData.getAssetPath()}');
      return;
    }
    this.frames = tex;
  }
}
