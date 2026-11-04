package funkin.ui.debug.charting.util;

#if FEATURE_CHART_EDITOR
import flixel.system.scaleModes.BaseScaleMode;
import funkin.ui.FullScreenScaleMode;
import haxe.ui.backend.flixel.HiResFlxText;

/**
 * Custom scale mode for the chart editor that respects a minimum size and a user-defined UI scale.
 */
class ChartEditorScaleMode extends BaseScaleMode
{
  /**
   * The smallest size the editor is laid out at, in game pixels.
   */
  static final MIN_WIDTH:Int = 1280;
  static final MIN_HEIGHT:Int = 720;

  public static final MIN_UI_SCALE:Float = 0.5;
  public static final MAX_UI_SCALE:Float = 2.0;

  static var instance:Null<ChartEditorScaleMode> = null;
  static var previous:Null<BaseScaleMode> = null;

  public var uiScale:Float;

  function new(uiScale:Float)
  {
    super();
    this.uiScale = uiScale;
    horizontalAlign = LEFT;
    verticalAlign = TOP;
  }

  /**
   * Switch to the editor's scale mode, or update the scale if it's already in use.
   */
  public static function apply(uiScale:Float):Void
  {
    uiScale = Math.min(Math.max(uiScale, MIN_UI_SCALE), MAX_UI_SCALE);
    if (instance == null)
    {
      previous = FlxG.scaleMode;
      instance = new ChartEditorScaleMode(uiScale);
    }
    else
    {
      instance.uiScale = uiScale;
    }
    // The setter resizes the game.
    FlxG.scaleMode = instance;
  }

  /**
   * Put the scale mode from before `apply` back, at the game's normal size.
   */
  public static function restore():Void
  {
    if (instance == null) return;
    var target:Null<BaseScaleMode> = previous;
    instance = null;
    previous = null;
    HiResFlxText.resolution = 1;
    if (target == null) return;

    untyped FlxG.width = FlxG.initialWidth;
    untyped FlxG.height = FlxG.initialHeight;
    @:bypassAccessor FlxG.scaleMode = target;

    var width:Int = FlxG.stage.stageWidth;
    var height:Int = FlxG.stage.stageHeight;
    if (target is FullScreenScaleMode) cast(target, FullScreenScaleMode).onMeasureInstant(width, height);
    else
      target.onMeasure(width, height);

    @:privateAccess FlxG.cameras.resize();
    FlxG.signals.gameResized.dispatch(width, height);
  }

  override public function onMeasure(width:Int, height:Int):Void
  {
    var fit:Float = Math.min(uiScale, Math.min(width / MIN_WIDTH, height / MIN_HEIGHT));
    if (fit <= 0) fit = 1;
    setGlobalSize(Std.int(Math.max(1, Math.round(width / fit))), Std.int(Math.max(1, Math.round(height / fit))));

    updateGameSize(width, height);
    updateDeviceSize(width, height);
    updateScaleOffset();
    updateGamePosition();

    HiResFlxText.resolution = scale.x;
  }
}
#end
