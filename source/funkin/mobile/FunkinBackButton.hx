package funkin.mobile;

import funkin.mobile.FunkinButton;

/**
 * A button to go back to a previous screen.
 */
class FunkinBackButton extends FunkinButton
{
  /**
   * Constructor for creating a new FunkinBackButton instance.
   * 
   * @param X The x position of the button.
   * @param Y The y position of the button.
   */
  public function new(?x:Float = 0, ?y:Float = 0):Void
  {
    super(x, y, ACTION_BUTTON);

    frames = Paths.getSparrowAtlas('fonts/default');
    animation.addByPrefix('less', '-less than-', 24);
    animation.play('less');
  }
}
