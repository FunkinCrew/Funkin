package funkin.ui.charSelect;

import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;

@:nullSafety
class CharSelectPlayer extends FunkinSprite implements IBPMSyncedScriptedClass
{
  static final DEFAULT_PATH = 'ui/character-select/characters/bf';

  var initialX:Float = 0;
  var initialY:Float = 0;
  var currentBFPath:Null<String>;

  public function new(x:Float, y:Float)
  {
    initialX = x;
    initialY = y;

    super(x, y);

    loadTextureAtlas(DEFAULT_PATH, {
      applyStageMatrix: true,
      swfMode: true
    });

    loadAnimations(false);

    animation.onFinish.add(function(animLabel:String)
    {
      switch (animLabel)
      {
        case 'slideIn':
          if (hasAnimation('slideInPoint'))
          {
            animation.play('slideInPoint', true);
          }
          else
          {
            animation.play('idle', true);
          }
        case 'deselect':
          animation.play('deselect-loop', true);
        case 'slideInPoint', 'cannotSelect', 'unlock':
          animation.play('idle', true);
      }
    });
  }

  public function onStepHit(event:SongTimeScriptEvent):Void
  {
  }

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    if (getCurrentAnimation() == 'idle' && isAnimationFinished())
    {
      animation.play('idle', true);
    }
  };

  public function switchChar(str:String, playSlideAnim:Bool = true):Void
  {
    var texture:Null<animate.FlxAnimateFrames> = CharSelectAtlasHandler.loadAtlas('ui/character-select/characters/${str}');

    if (texture != null)
    {
      frames = texture;
      loadAnimations(str == 'locked');
    }
    else
    {
      trace('Failed to load character atlas for ${str}');
      return;
    }

    final animName:String = playSlideAnim ? 'slideIn' : 'idle';
    animation.play(animName, true);

    updateHitbox();
  }

  function loadAnimations(locked:Bool):Void
  {
    anim.addByFrameLabel('slideIn', 'slidein', 24, false);
    anim.addByFrameLabel('slideInPoint', 'slidein idle point', 24, false);
    anim.addByFrameLabel('slideout', 'slideout', 24, false);

    if (locked)
    {
      anim.addByFrameLabel('idle', 'idle', 24);
      anim.addByFrameLabel('cannotSelect', 'cannot select Label', 24, false);
      anim.addByFrameLabel('death', 'death', 24, false);
    }
    else
    {
      // TODO: Refactor Character Select data so these animations can be defined from JSON
      anim.addByFrameLabel('idle', 'idle', 24, false);
      anim.addByFrameLabel('unlock', 'unlock', 24, false);
      anim.addByFrameLabel('select', 'select', 24, false);
      anim.addByFrameLabel('deselect', 'deselect', 24, false);
      anim.addByFrameLabel('deselect-loop', 'deselect loop start', 24);
    }
  }

  override function checkRenderTexture():Bool
  {
    // BF and Pico have an overlay blend on their deselect animation
    // We enable render texture here on devices that don't support KHR_blend_equation_advanced to save on performance
    // TODO: Softcode this in scripts when character select data is refactored!!
    if (!FunkinCamera.hasKhronosExtension && animation.curAnim.name.startsWith('deselect'))
    {
      return true;
    }

    return super.checkRenderTexture();
  }

  public function onScriptEvent(event:ScriptEvent):Void
  {
  };

  public function onCreate(event:ScriptEvent):Void
  {
  };

  public function onDestroy(event:ScriptEvent):Void
  {
  };

  public function onUpdate(event:UpdateScriptEvent):Void
  {
  };

  public function onCustom(event:CustomScriptEvent):Void
  {
  };
}
