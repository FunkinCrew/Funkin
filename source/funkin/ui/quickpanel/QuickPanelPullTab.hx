package funkin.ui.quickpanel;

import funkin.graphics.FunkinSprite;
import funkin.ui.UIStateMachine;

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
    anim.play(name);
  }

  public function press(state:UIState):Void
  {
    switch (state)
    {
      case PanelClosed:
        playAnimation('pressLeft');
      case PanelOpen:
        playAnimation('pressRight');
      default:
        // Nothin'
    }
  }

  public function grab(state:UIState):Void
  {
    playAnimation('held');
  }

  public function release(state:UIState):Void
  {
    switch (state)
    {
      case PanelOpen:
        playAnimation('release');
      default:
        playAnimation('idleLeft');
    }
  }

  public function playIdle(state:UIState):Void
  {
    switch (state)
    {
      case PanelDragging:
        playAnimation('held');
      case PanelOpen | PanelConfirming:
        playAnimation('idleRight');
      default:
        playAnimation('idleLeft');
    }
  }

  function onAnimationFinished(name:String):Void
  {
    if (name == 'release') playIdle(PanelOpen);
  }
}
