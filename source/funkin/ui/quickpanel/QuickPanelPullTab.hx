package funkin.ui.quickpanel;

import funkin.graphics.FunkinSprite;
import funkin.ui.quickpanel.QuickPanelTypes;

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

  public function press(state:PanelState):Void
  {
    switch (state)
    {
      case CLOSED:
        playAnimation('pressLeft');
      case OPENING:
        // No press animation mid-drag.
      case OPEN:
        playAnimation('pressRight');
      default:
    }
  }

  public function grab(state:PanelState):Void
  {
    playAnimation('held');
  }

  public function release(state:PanelState):Void
  {
    switch (state)
    {
      case OPEN:
        playAnimation('release');
      default:
        playAnimation('idleLeft');
    }
  }

  public function playIdle(state:PanelState):Void
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
    if (name == 'release') playIdle(OPEN);
  }
}
