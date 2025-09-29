package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.data.freeplay.player.PlayerRegistry;
import flixel.graphics.frames.FlxFrame;
import flixel.FlxCamera;
import flixel.FlxBasic;

/**
 * A script that can be tied to a SparrowFreeplayDJ.
 * Create a scripted class that extends SparrowFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedSparrowFreeplayDJ extends SparrowFreeplayDJ implements polymod.hscript.HScriptedClass {}

class SparrowFreeplayDJ extends BaseFreeplayDJ.FlixelFramedFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);
  }

  override public function loadFrames()
  {
    final tex:FlxFramesCollection = Paths.getSparrowAtlas(playableCharData.getAssetPath());
    if (tex == null)
    {
      trace('Could not load Sparrow sprite: ' + playableCharData.getAssetPath());
      return;
    }
    this.frames = tex;
  }
}
