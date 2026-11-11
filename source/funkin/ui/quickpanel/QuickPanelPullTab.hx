package funkin.ui.quickpanel;

import funkin.graphics.FunkinSprite;
import funkin.ui.UIStateMachine;

/**
 * The tab sticking out of the panel's edge. On touch builds it's the grabbable.
 */
class QuickPanelPullTab extends FunkinSprite
{
  /**
   * Makes a new QuickPanelPullTab
   * @param y The Y pos
   * @param x The X pos
   * @param keyboard Whether we're on keys or not
   */
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

  /**
   * Presses the pull-tab
   * @param state The current ui-state.
   */
  public function press(state:UIState):Void
  {
    switch (state)
    {
      case PanelClosed:
        playAnimation('pressLeft');
      case PanelOpen:
        playAnimation('pressRight');
      default:
        // No press animation in other states.
    }
  }

  /**
   * Grabs the pull-tab
   * @param state The current ui-state.
   */
  public function grab(state:UIState):Void
  {
    playAnimation('held');
  }

  /**
   * Releases the pull-tab.
   * @param state The current ui-state.
   */
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

  /**
   * Plays the idle anim
   * @param state The current ui-state.
   */
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

  /**
   * Callback used when the animation is done.
   * @param name Anim name
   */
  function onAnimationFinished(name:String):Void
  {
    if (name == 'release') playIdle(PanelOpen);
  }
}
