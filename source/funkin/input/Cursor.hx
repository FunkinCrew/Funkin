package funkin.input;

#if FEATURE_HAXEUI
import haxe.ui.backend.flixel.CursorHelper;
#end
import lime.app.Future;
import openfl.display.BitmapData;

@:nullSafety
class Cursor
{
  /**
   * The current cursor mode.
   * Set this value to change the cursor graphic.
   */
  public static var cursorMode(default, set):Null<CursorMode> = null;

  /**
   * Show the cursor.
   */
  public static inline function show():Void
  {
    FlxG.mouse.visible = true;
    // Reset the cursor mode.
    Cursor.cursorMode = Default;
  }

  /**
   * Hide the cursor.
   */
  public static inline function hide():Void
  {
    FlxG.mouse.visible = false;
    // Reset the cursor mode.
    Cursor.cursorMode = null;
  }

  public static inline function toggle():Void
  {
    if (FlxG.mouse.visible)
    {
      hide();
    }
    else
    {
      show();
    }
  }

  public static final CURSOR_DEFAULT_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-default.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorDefault:Null<BitmapData> = null;

  public static final CURSOR_CROSS_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-cross.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorCross:Null<BitmapData> = null;

  public static final CURSOR_ERASER_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-eraser.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorEraser:Null<BitmapData> = null;

  public static final CURSOR_GRABBING_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-grabbing.png",
    scale: 1.0,
    offsetX: -8,
    offsetY: 0,
  };
  static var assetCursorGrabbing:Null<BitmapData> = null;

  public static final CURSOR_HOURGLASS_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-hourglass.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorHourglass:Null<BitmapData> = null;

  public static final CURSOR_POINTER_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-pointer.png",
    scale: 1.0,
    offsetX: -8,
    offsetY: 0,
  };
  static var assetCursorPointer:Null<BitmapData> = null;

  public static final CURSOR_TEXT_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-text.png",
    scale: 0.2,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorText:Null<BitmapData> = null;

  public static final CURSOR_TEXT_VERTICAL_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-text-vertical.png",
    scale: 0.2,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorTextVertical:Null<BitmapData> = null;

  public static final CURSOR_ZOOM_IN_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-zoom-in.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorZoomIn:Null<BitmapData> = null;

  public static final CURSOR_ZOOM_OUT_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-zoom-out.png",
    scale: 1.0,
    offsetX: 0,
    offsetY: 0,
  };
  static var assetCursorZoomOut:Null<BitmapData> = null;

  public static final CURSOR_CROSSHAIR_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-crosshair.png",
    scale: 1.0,
    offsetX: -16,
    offsetY: -16,
  };
  static var assetCursorCrosshair:Null<BitmapData> = null;

  public static final CURSOR_CELL_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-cell.png",
    scale: 1.0,
    offsetX: -16,
    offsetY: -16,
  };
  static var assetCursorCell:Null<BitmapData> = null;

  public static final CURSOR_SCROLL_PARAMS:CursorParams = {
    graphic: "assets/images/cursor/cursor-scroll.png",
    scale: 0.2,
    offsetX: -15,
    offsetY: -15,
  };
  static var assetCursorScroll:Null<BitmapData> = null;

  static function set_cursorMode(value:Null<CursorMode>):Null<CursorMode>
  {
    if (value != null && cursorMode != value)
    {
      cursorMode = value;
      loadCursorGraphicSync(cursorMode);
    }
    return cursorMode;
  }

  /**
   * Loads the cursor graphic synchronously.
   *
   * @param value The cursor mode to load. If null, the cursor is unloaded.
   */
  static function loadCursorGraphicSync(?value:CursorMode = null):Void
  {
    applyCursorParams(value);
  }

  /**
   * Loads the cursor graphic asynchronously.
   *
   * @param value The cursor mode to load. If null, the cursor is unloaded.
   */
  static function loadCursorGraphicAsync(?value:CursorMode = null):Void
  {
    applyCursorParams(value, true);
  }

  static function applyCursorParams(mode:Null<CursorMode>, async:Bool = false)
  {
    if (mode == null)
    {
      FlxG.mouse.unload();
      return;
    }

    var data = switch (mode)
    {
      case Default: { cache: assetCursorDefault, params: CURSOR_DEFAULT_PARAMS, set: (bmp) -> assetCursorDefault = bmp };
      case Cross: { cache: assetCursorCross, params: CURSOR_CROSS_PARAMS, set: (bmp) -> assetCursorCross = bmp };
      case Eraser: { cache: assetCursorEraser, params: CURSOR_ERASER_PARAMS, set: (bmp) -> assetCursorEraser = bmp };
      case Grabbing: { cache: assetCursorGrabbing, params: CURSOR_GRABBING_PARAMS, set: (bmp) -> assetCursorGrabbing = bmp };
      case Hourglass: { cache: assetCursorHourglass, params: CURSOR_HOURGLASS_PARAMS, set: (bmp) -> assetCursorHourglass = bmp };
      case Pointer: { cache: assetCursorPointer, params: CURSOR_POINTER_PARAMS, set: (bmp) -> assetCursorPointer = bmp };
      case Text: { cache: assetCursorText, params: CURSOR_TEXT_PARAMS, set: (bmp) -> assetCursorText = bmp };
      case TextVertical: { cache: assetCursorTextVertical, params: CURSOR_TEXT_VERTICAL_PARAMS, set: (bmp) -> assetCursorTextVertical = bmp };
      case ZoomIn: { cache: assetCursorZoomIn, params: CURSOR_ZOOM_IN_PARAMS, set: (bmp) -> assetCursorZoomIn = bmp };
      case ZoomOut: { cache: assetCursorZoomOut, params: CURSOR_ZOOM_OUT_PARAMS, set: (bmp) -> assetCursorZoomOut = bmp };
      case Crosshair: { cache: assetCursorCrosshair, params: CURSOR_CROSSHAIR_PARAMS, set: (bmp) -> assetCursorCrosshair = bmp };
      case Cell: { cache: assetCursorCell, params: CURSOR_CELL_PARAMS, set: (bmp) -> assetCursorCell = bmp };
      case Scroll: { cache: assetCursorScroll, params: CURSOR_SCROLL_PARAMS, set: (bmp) -> assetCursorScroll = bmp };
      default: null;
    }

    if (data == null)
    {
      FlxG.mouse.unload();
      return;
    }

    if (data.cache != null)
    {
      applyGraphic(data.cache, data.params);
      return;
    }

    if (async)
    {
      var future:Future<BitmapData> = Assets.loadBitmapData(data.params.graphic);
      future.onComplete((bmp:BitmapData) -> {
        data.set(bmp);
        applyGraphic(bmp, data.params);
      });
      future.onError(onCursorError.bind(mode));
    }
    else
    {
      var bitmapData:BitmapData = Assets.getBitmapData(data.params.graphic);
      data.set(bitmapData);
      applyGraphic(bitmapData, data.params);
    }
  }

  private static inline function applyGraphic(graphic:BitmapData, params:CursorParams):Void
  {
    FlxG.mouse.load(graphic, params.scale, params.offsetX, params.offsetY);
  }

  static function onCursorError(cursorMode:CursorMode, error:String):Void
  {
    trace("Failed to load cursor graphic for cursor mode " + cursorMode + ": " + error);
  }

  #if FEATURE_HAXEUI
  public static function registerHaxeUICursors():Void
  {
    CursorHelper.useCustomCursors = true;
    registerHaxeUICursor('default', CURSOR_DEFAULT_PARAMS);
    registerHaxeUICursor('cross', CURSOR_CROSS_PARAMS);
    registerHaxeUICursor('eraser', CURSOR_ERASER_PARAMS);
    registerHaxeUICursor('grabbing', CURSOR_GRABBING_PARAMS);
    registerHaxeUICursor('hourglass', CURSOR_HOURGLASS_PARAMS);
    registerHaxeUICursor('pointer', CURSOR_POINTER_PARAMS);
    registerHaxeUICursor('move', CURSOR_POINTER_PARAMS);
    registerHaxeUICursor('text', CURSOR_TEXT_PARAMS);
    registerHaxeUICursor('text-vertical', CURSOR_TEXT_VERTICAL_PARAMS);
    registerHaxeUICursor('zoom-in', CURSOR_ZOOM_IN_PARAMS);
    registerHaxeUICursor('zoom-out', CURSOR_ZOOM_OUT_PARAMS);
    registerHaxeUICursor('crosshair', CURSOR_CROSSHAIR_PARAMS);
    registerHaxeUICursor('cell', CURSOR_CELL_PARAMS);
    registerHaxeUICursor('scroll', CURSOR_SCROLL_PARAMS);
  }

  public static function registerHaxeUICursor(id:String, params:CursorParams):Void
  {
    CursorHelper.registerCursor(id, params.graphic, params.scale, params.offsetX, params.offsetY);
  }
  #end
}

// https://developer.mozilla.org/en-US/docs/Web/CSS/cursor
enum CursorMode
{
  Default;
  Cross;
  Eraser;
  Grabbing;
  Hourglass;
  Pointer;
  Text;
  TextVertical;
  ZoomIn;
  ZoomOut;
  Crosshair;
  Cell;
  Scroll;
}

/**
 * Static data describing how a cursor should be rendered.
 */
typedef CursorParams =
{
  graphic:String,
  scale:Float,
  offsetX:Int,
  offsetY:Int,
}
