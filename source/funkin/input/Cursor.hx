package funkin.input;

import haxe.ui.backend.flixel.CursorHelper;
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

  public static final CURSOR_DEFAULT_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-default.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorDefault:Null<BitmapData> = null;

  public static final CURSOR_CROSS_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-cross.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorCross:Null<BitmapData> = null;

  public static final CURSOR_ERASER_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-eraser.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorEraser:Null<BitmapData> = null;

  public static final CURSOR_GRABBING_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-grabbing.png",
      scale: 1.0,
      offsetX: -8,
      offsetY: 0,
    };
  static var assetCursorGrabbing:Null<BitmapData> = null;

  public static final CURSOR_HOURGLASS_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-hourglass.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorHourglass:Null<BitmapData> = null;

  public static final CURSOR_POINTER_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-pointer.png",
      scale: 1.0,
      offsetX: -8,
      offsetY: 0,
    };
  static var assetCursorPointer:Null<BitmapData> = null;

  public static final CURSOR_TEXT_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-text.png",
      scale: 0.2,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorText:Null<BitmapData> = null;

  public static final CURSOR_TEXT_VERTICAL_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-text-vertical.png",
      scale: 0.2,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorTextVertical:Null<BitmapData> = null;

  public static final CURSOR_ZOOM_IN_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-zoom-in.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorZoomIn:Null<BitmapData> = null;

  public static final CURSOR_ZOOM_OUT_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-zoom-out.png",
      scale: 1.0,
      offsetX: 0,
      offsetY: 0,
    };
  static var assetCursorZoomOut:Null<BitmapData> = null;

  public static final CURSOR_CROSSHAIR_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-crosshair.png",
      scale: 1.0,
      offsetX: -16,
      offsetY: -16,
    };
  static var assetCursorCrosshair:Null<BitmapData> = null;

  public static final CURSOR_CELL_PARAMS:CursorParams =
    {
      graphic: "assets/images/cursor/cursor-cell.png",
      scale: 1.0,
      offsetX: -16,
      offsetY: -16,
    };
  static var assetCursorCell:Null<BitmapData> = null;

  public static final CURSOR_SCROLL_PARAMS:CursorParams =
    {
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
      setCursorGraphic(cursorMode);
    }
    return cursorMode;
  }

  /**
   * Synchronous.
   */
  static function setCursorGraphic(?value:CursorMode = null):Void
  {
    if (value == null)
    {
      FlxG.mouse.unload();
      return;
    }

    switch (value)
    {
      case Default:
        if (assetCursorDefault == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_DEFAULT_PARAMS.graphic);
          assetCursorDefault = bitmapData;
          applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
        }

      case Cross:
        if (assetCursorCross == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_CROSS_PARAMS.graphic);
          assetCursorCross = bitmapData;
          applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
        }

      case Eraser:
        if (assetCursorEraser == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_ERASER_PARAMS.graphic);
          assetCursorEraser = bitmapData;
          applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
        }

      case Grabbing:
        if (assetCursorGrabbing == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_GRABBING_PARAMS.graphic);
          assetCursorGrabbing = bitmapData;
          applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
        }

      case Hourglass:
        if (assetCursorHourglass == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_HOURGLASS_PARAMS.graphic);
          assetCursorHourglass = bitmapData;
          applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
        }

      case Pointer:
        if (assetCursorPointer == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_POINTER_PARAMS.graphic);
          assetCursorPointer = bitmapData;
          applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
        }

      case Text:
        if (assetCursorText == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_TEXT_PARAMS.graphic);
          assetCursorText = bitmapData;
          applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
        }

      case ZoomIn:
        if (assetCursorZoomIn == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_ZOOM_IN_PARAMS.graphic);
          assetCursorZoomIn = bitmapData;
          applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
        }

      case ZoomOut:
        if (assetCursorZoomOut == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_ZOOM_OUT_PARAMS.graphic);
          assetCursorZoomOut = bitmapData;
          applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
        }

      case Crosshair:
        if (assetCursorCrosshair == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_CROSSHAIR_PARAMS.graphic);
          assetCursorCrosshair = bitmapData;
          applyCursorParams(assetCursorCrosshair, CURSOR_CROSSHAIR_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorCrosshair, CURSOR_CROSSHAIR_PARAMS);
        }

      case Cell:
        if (assetCursorCell == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_CELL_PARAMS.graphic);
          assetCursorCell = bitmapData;
          applyCursorParams(assetCursorCell, CURSOR_CELL_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorCell, CURSOR_CELL_PARAMS);
        }

      case Scroll:
        if (assetCursorScroll == null)
        {
          var bitmapData:BitmapData = Assets.getBitmapData(CURSOR_SCROLL_PARAMS.graphic);
          assetCursorScroll = bitmapData;
          applyCursorParams(assetCursorScroll, CURSOR_SCROLL_PARAMS);
        }
        else
        {
          applyCursorParams(assetCursorScroll, CURSOR_SCROLL_PARAMS);
        }

      default:
        setCursorGraphic(null);
    }
  }

  /**
   * Asynchronous.
   */
  static function loadCursorGraphic(?value:CursorMode = null):Void
  {
    if (value == null)
    {
      FlxG.mouse.unload();
      return;
    }

    switch (value)
    {
      case Default:
        if (assetCursorDefault == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_DEFAULT_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorDefault = bitmapData;
            applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
          });
          future.onError(onCursorError.bind(Default));
        }
        else
        {
          applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
        }

      case Cross:
        if (assetCursorCross == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_CROSS_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorCross = bitmapData;
            applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
          });
          future.onError(onCursorError.bind(Cross));
        }
        else
        {
          applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
        }

      case Eraser:
        if (assetCursorEraser == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ERASER_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorEraser = bitmapData;
            applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
          });
          future.onError(onCursorError.bind(Eraser));
        }
        else
        {
          applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
        }

      case Grabbing:
        if (assetCursorGrabbing == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_GRABBING_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorGrabbing = bitmapData;
            applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
          });
          future.onError(onCursorError.bind(Grabbing));
        }
        else
        {
          applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
        }

      case Hourglass:
        if (assetCursorHourglass == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_HOURGLASS_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorHourglass = bitmapData;
            applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
          });
          future.onError(onCursorError.bind(Hourglass));
        }
        else
        {
          applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
        }

      case Pointer:
        if (assetCursorPointer == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_POINTER_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorPointer = bitmapData;
            applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
          });
          future.onError(onCursorError.bind(Pointer));
        }
        else
        {
          applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
        }

      case Text:
        if (assetCursorText == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_TEXT_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorText = bitmapData;
            applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
          });
          future.onError(onCursorError.bind(Text));
        }
        else
        {
          applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
        }

      case ZoomIn:
        if (assetCursorZoomIn == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ZOOM_IN_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorZoomIn = bitmapData;
            applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
          });
          future.onError(onCursorError.bind(ZoomIn));
        }
        else
        {
          applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
        }

      case ZoomOut:
        if (assetCursorZoomOut == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ZOOM_OUT_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorZoomOut = bitmapData;
            applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
          });
          future.onError(onCursorError.bind(ZoomOut));
        }
        else
        {
          applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
        }

      case Crosshair:
        if (assetCursorCrosshair == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_CROSSHAIR_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorCrosshair = bitmapData;
            applyCursorParams(assetCursorCrosshair, CURSOR_CROSSHAIR_PARAMS);
          });
          future.onError(onCursorError.bind(Crosshair));
        }
        else
        {
          applyCursorParams(assetCursorCrosshair, CURSOR_CROSSHAIR_PARAMS);
        }

      case Cell:
        if (assetCursorCell == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_CELL_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorCell = bitmapData;
            applyCursorParams(assetCursorCell, CURSOR_CELL_PARAMS);
          });
          future.onError(onCursorError.bind(Cell));
        }
        else
        {
          applyCursorParams(assetCursorCell, CURSOR_CELL_PARAMS);
        }

      case Scroll:
        if (assetCursorScroll == null)
        {
          var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_SCROLL_PARAMS.graphic);
          future.onComplete(function(bitmapData:BitmapData) {
            assetCursorScroll = bitmapData;
            applyCursorParams(assetCursorScroll, CURSOR_SCROLL_PARAMS);
          });
          future.onError(onCursorError.bind(Scroll));
        }
        else
        {
          applyCursorParams(assetCursorScroll, CURSOR_SCROLL_PARAMS);
        }

      default:
        loadCursorGraphic(null);
    }
  }

  static inline function applyCursorParams(graphic:BitmapData, params:CursorParams):Void
  {
    FlxG.mouse.load(graphic, params.scale, params.offsetX, params.offsetY);
  }

  static function onCursorError(cursorMode:CursorMode, error:String):Void
  {
    trace("Failed to load cursor graphic for cursor mode " + cursorMode + ": " + error);
  }

  public static function registerHaxeUICursors():Void
  {
    CursorHelper.useCustomCursors = true;
    registerHaxeUICursor('default', CURSOR_DEFAULT_PARAMS);
    registerHaxeUICursor('cross', CURSOR_CROSS_PARAMS);
    registerHaxeUICursor('eraser', CURSOR_ERASER_PARAMS);
    registerHaxeUICursor('grabbing', CURSOR_GRABBING_PARAMS);
    registerHaxeUICursor('hourglass', CURSOR_HOURGLASS_PARAMS);
    registerHaxeUICursor('pointer', CURSOR_POINTER_PARAMS);
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
