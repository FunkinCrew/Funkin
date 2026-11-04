package funkin.ui.transition.loading;

import flixel.util.FlxColor;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.ui.transition.Transition.TransitionParams;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.ui.transition.Transition.TransitionParams;
import funkin.ui.transition.Transition.TransitionTarget;

/**
 * Parameters for performing a throbber transition.
 */
typedef ThrobberTransitionParams =
{
  /**
   * Whether the background should be transparent.
   *
   * @default `false`
   */
  var ?transparent:Bool;

  /**
   * The delay before the throbber starts fading in, in seconds.
   * In effect, this means the throbber never appears if the loading takes less than this.
   *
   * @default `1.0`
   */
  var ?delay:Float;
}

/**
 * @see https://en.wikipedia.org/wiki/Throbber
 */
@:nullSafety
@:allow(funkin.ui.transition.Transition)
class ThrobberLoadingState extends LoadingState
{
  static final DEFAULT_TRANSPARENT:Bool = false;
  static final DEFAULT_DELAY:Float = 1.0;

  var throbberParams:ThrobberTransitionParams;
  var throbber:FunkinSprite;
  var throbberCamera:FunkinCamera;
  var totalElapsed:Float = 0;
  var fadeInDelayTimer:FlxTimer = new FlxTimer();

  /**
   * Retrieve a list of all the asset paths required to display the loading state.
   *
   * @param type The type of asset to query
   * @return An array of asset paths, or empty if no assets of that type are required.
   */
  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    switch (type)
    {
      case IMAGE:
        return [Paths.image('ui/loading/throbber')];
      default:
        return [];
    }
  }

  function new(target:TransitionTarget,
    params:TransitionParams,
    throbberParams:ThrobberTransitionParams)
  {
    super((throbberParams.transparent ?? DEFAULT_TRANSPARENT) ? FlxColor.TRANSPARENT : FlxColor.BLACK, target, params);

    this.throbberParams = throbberParams;

    throbberCamera = new FunkinCamera('throbberLoading');
    throbberCamera.bgColor = this.bgColor;
    throbber = new FunkinSprite().loadTexture(Paths.image('ui/loading/throbber').toFlxGraphicAsset());

  }

  override public function create():Void
  {
    super.create();

    if (throbberParams?.transparent ?? false)
    {
      // Draw elements underneath.
      FlxG.state.persistentDraw = true;
    }

    fadeInDelayTimer.start(throbberParams.delay ?? DEFAULT_DELAY, (_) ->
    {
      buildDisplay();
    });
  }

  function buildDisplay():Void
  {
    // Render the throbber on its own camera so it never modifies the parent's scroll or zoom and ensure consistent rendering.
    FlxG.cameras.add(throbberCamera, false);
    throbber.cameras = [throbberCamera];
    throbber.scrollFactor.set(0, 0);

    throbber.setGraphicSize(64, 64);
    throbber.updateHitbox();
    throbber.x = FlxG.width - 24 - throbber.width;
    throbber.y = FlxG.height - 24 - throbber.height;
    add(throbber);

    // Fade the throbber in over a short period.
    throbber.alpha = 0;
    FlxTween.tween(throbber, {
      alpha: 1.0
    }, 0.2);
  }

  override public function destroy():Void
  {
    fadeInDelayTimer.cancel();

    if (throbberCamera != null && FlxG.cameras.list.contains(throbberCamera))
    {
      FlxG.cameras.remove(throbberCamera);
    }

    super.destroy();
  }

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    totalElapsed += elapsed;

    var timesPerSecond:Int = 8;
    var angleSnaps:Int = 12;

    var rotation:Float = Math.floor(totalElapsed * timesPerSecond) % angleSnaps;
    throbber.angle = 360 / angleSnaps * rotation;
  }
}
