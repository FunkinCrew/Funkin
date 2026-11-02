package funkin.ui.transition.loading;

import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.ui.transition.Transition.TransitionParams;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.ui.transition.progress.FunkinProgressBar;

/**
 * A loading state which displays a graphic with a progress bar instead of a black screen.
 */
@:nullSafety
@:allow(funkin.ui.transition.Transition)
class FunkayLoadingState extends LoadingState
{
  /**
   * The progress bar instance.
   */
  var progressBar:FunkinProgressBar;

  /**
   * The main camera used to render the loading screen.
   */
  var mainCamera:FunkinCamera;

  public function new(target:TransitionTarget, params:TransitionParams)
  {
    super(FlxColor.BLACK, target, params);

    progressBar = new FunkinProgressBar();

    mainCamera = new FunkinCamera('itIsParis');
    mainCamera.bgColor = this.bgColor;
  }

  override public function create():Void
  {
    super.create();

    // Set up our own camera to ensure consistent rendering.
    FlxG.cameras.add(mainCamera, false);

    progressBar.build();
    progressBar.cameras = [mainCamera];
    add(progressBar);

    refresh();
  }

  override public function destroy():Void
  {
    if (mainCamera != null && FlxG.cameras.list.contains(mainCamera))
    {
      FlxG.cameras.remove(mainCamera);
    }

    super.destroy();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    progressBar.updateProgress(Std.int(this.currentProgress * 10), 10);
  }
}
