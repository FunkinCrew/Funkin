package funkin.ui.transition.loading;

import funkin.graphics.FunkinSprite;
import funkin.graphics.FunkinCamera;
import flixel.util.FlxColor;
import funkin.ui.transition.Transition.TransitionTarget;
import funkin.ui.transition.Transition.TransitionParams;
import funkin.util.MathUtil;
//
// ~PATHS~
//
import funkin.assets.Assets;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AnimateAtlasAssetPathBuilder;
import funkin.assets.Paths.AssetPath;
import funkin.assets.Paths.MusicAssetPathBuilder;
import funkin.assets.ValidatedPaths as Paths;

/**
 * A loading state which displays a graphic with a progress bar instead of a black screen.
 */
@:nullSafety
@:allow(funkin.ui.transition.Transition)
class FunkayLoadingState extends LoadingState
{
  static final OFFLIME = FlxColor.fromString("#CAFF4D");
  static final BAR_HEIGHT:Int = 12;
  static final BAR_EASE_TIME:Float = 0.12;

  var progressBar:FunkinSprite;
  var mainCamera:FunkinCamera;

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
        return [Paths.image('ui/loading/funkay')];
      default:
        return [];
    }
  }

  function new(target:TransitionTarget, params:TransitionParams)
  {
    super(OFFLIME, target, params);

    progressBar = new FunkinSprite(0, FlxG.height - 24).makeSolidColor(1, BAR_HEIGHT, 0xFFFF16D2);
    mainCamera = new FunkinCamera('loadingFunkay');
    mainCamera.bgColor = this.bgColor; //just in case ig
  }

  override public function create():Void
  {
    super.create();

    buildDisplay();
  }

  function buildDisplay():Void
  {
    // Set up our own camera to ensure consistent rendering.
    FlxG.cameras.add(mainCamera, false);

    var loadingSprite:FunkinSprite = new FunkinSprite().loadTexture('ui/loading/funkay');
    loadingSprite.cameras = [mainCamera];
    loadingSprite.setGraphicSize(0, FlxG.height);
    loadingSprite.updateHitbox();
    loadingSprite.scrollFactor.set();
    loadingSprite.screenCenter();
    loadingSprite.zIndex = 100;
    add(loadingSprite);

    loadingSprite.scrollFactor.set();
    progressBar.cameras = [mainCamera];
    progressBar.zIndex = 200;
    add(progressBar);
  }

  override public function destroy():Void
  {
    if (mainCamera != null && FlxG.cameras.list.contains(mainCamera))
    {
      FlxG.cameras.remove(mainCamera);
    }

    super.destroy();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // Update progress bar display.
    var currentWidth:Float = progressBar.width;
    var targetWidth:Float = FlxG.width * this.currentProgress;
    var displayWidth:Float = MathUtil.smoothLerpPrecision(currentWidth, targetWidth, elapsed, BAR_EASE_TIME);

    progressBar.x = 0;
    progressBar.y = FlxG.height - 20;
    progressBar.setGraphicSize(displayWidth, BAR_HEIGHT);
    progressBar.updateHitbox();
  }
}
