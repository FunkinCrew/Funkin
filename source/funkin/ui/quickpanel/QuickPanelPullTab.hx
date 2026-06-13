package funkin.ui.quickpanel;

import flixel.math.FlxPoint;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import flixel.util.FlxTimer;
import funkin.ui.quickpanel.QuickPanelGroup;
import funkin.audio.FunkinSound;

class QuickPanelPullTab extends FunkinSprite
{
  public function new(x:Float, y:Float, keyboard:Bool = false)
  {
    super(x, y);

    loadTextureAtlas('ui/quick-panel/${keyboard ? 'tabSquareKeyboard' : 'tabSquare'}');
    loadAnimations();

    this.animation.onFinish.add(onAnimationFinished);
  }

  function loadAnimations():Void
  {
    anim.addByFrameLabel('idleLeft', 'idleLeft', 24, true);
    anim.addByFrameLabel('idleRight', 'idleRight', 24, true);
    anim.addByFrameLabel('held', 'held', 30, true);
    anim.addByFrameLabel('release', 'release', 30, false);
    anim.addByFrameLabel('pressRight', 'pressRight', 24, false);
    anim.addByFrameLabel('pressLeft', 'pressLeft', 24, false);
  }

  public function playAnimation(name:String):Void
  {
    this.animation.play(name);
  }

  public function press(state:PanelState)
  {
    switch (state)
    {
      case CLOSED:
        playAnimation('pressLeft');
      case OPENING:
        // ???
      case OPEN:
        playAnimation('pressRight');
      default:
    }
  }

  public function grab(state:PanelState)
  {
    playAnimation('held');
  }

  public function release(state:PanelState)
  {
    switch (state)
    {
      case OPEN:
        playAnimation('release');
      default:
        playAnimation('idleLeft');
    }
  }

  public function playIdle(state:PanelState)
  {
    switch (state)
    {
      case CLOSED:
        playAnimation('idleLeft');
      case OPENING:
        playAnimation('held');
      case OPEN:
        playAnimation('idleRight');
      default:
    }
  }

  function onAnimationFinished(name:String):Void
  {
    switch (name)
    {
      case 'release':
        playIdle(OPEN);
      default:
    }
  }
}
