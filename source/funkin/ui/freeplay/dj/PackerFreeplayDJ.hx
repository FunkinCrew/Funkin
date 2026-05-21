package funkin.ui.freeplay.dj;

import flixel.graphics.frames.FlxFramesCollection;
import funkin.util.assets.FlxAnimationUtil;
import funkin.data.freeplay.player.PlayerRegistry;

/**
 * A script that can be tied to a PackerFreeplayDJ.
 * Create a scripted class that extends PackerFreeplayDJ to use this.
 */
@:hscriptClass
class ScriptedPackerFreeplayDJ extends PackerFreeplayDJ implements polymod.hscript.HScriptedClass
{
}

/**
 * A PackerFreeplayDJ is a Freeplay DJ which is rendered by
 * displaying an animation derived from a Packer spritesheet file.
 *
 * BaseFreeplayDJ has game logic, PackerFreeplayDJ has only rendering logic.
 * KEEP THEM SEPARATE!
 */
class PackerFreeplayDJ extends BaseFreeplayDJ
{
  public function new(x:Float, y:Float, characterId:String)
  {
    super(x, y, characterId);

    loadFrames();
    loadAnimations();

    currentState = Intro;
  }

  public function loadFrames():Void
  {
    final tex:FlxFramesCollection = Paths.getPackerAtlas(playableCharData.getAssetPath());
    if (tex == null)
    {
      log('Could not load sparrow sprite: ' + playableCharData.getAssetPath());
      return;
    }
    this.frames = tex;
  }

  public function loadAnimations():Void
  {
    log('[PACKERDJ] Loading ${playableCharData.getAnimationsList().length} animations for ${characterId}');

    FlxAnimationUtil.addAtlasAnimations(this, playableCharData.getAnimationsList());

    var animationList:Array<String> = this.animation.getNameList();
    log('[PACKERDJ] Successfully loaded ${animationList.length} animations for ${characterId}');
  }

  static function log(message:String):Void
  {
    trace(' PACKERDJ '.bold().bg_blue() + ' $message');
  }
}
