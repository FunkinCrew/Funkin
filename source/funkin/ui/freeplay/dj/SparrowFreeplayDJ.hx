package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a SparrowFreeplayDJ.
 * Create a scripted class that extends SparrowFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedSparrowFreeplayDJ extends SparrowFreeplayDJ implements polymod.hscript.HScriptedClass
{
}

/**
 * A SparrowFreeplayDJ is a Freeplay DJ which is rendered by
 * displaying an animation derived from a SparrowV2 atlas spritesheet file.
 *
 * BaseFreeplayDJ has game logic, SparrowFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class SparrowFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadFrames();
    loadAnimations();
  }

  public function loadFrames():Void
  {
    final tex:FlxFramesCollection = Paths.getSparrowAtlas(playableCharData.getAssetPath());
    if (tex == null)
    {
      log('Could not load sparrow sprite: ' + playableCharData.getAssetPath());
      return;
    }
    this.frames = tex;
  }

  public function loadAnimations():Void
  {
    log('[SPARROWDJ] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animationList:Array<String> = this.animation.getNameList();
    log('[SPARROWDJ] Successfully loaded ${animationList.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' SPARROWDJ '.bold().bg_blue() + ' $message');
  }
}
