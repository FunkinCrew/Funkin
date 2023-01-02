package funkin.input;

import openfl.utils.Assets;
import lime.app.Future;
import openfl.display.BitmapData;

class Cursor
{
	public static var cursorMode(default, set):CursorMode;

	static final CURSOR_DEFAULT_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-default.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorDefault:BitmapData = null;

	static final CURSOR_CROSS_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-cross.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorCross:BitmapData = null;

	static final CURSOR_ERASER_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-eraser.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorEraser:BitmapData = null;

	static final CURSOR_GRABBING_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-grabbing.png",
		scale: 1.0,
		offsetX: 32,
		offsetY: 0,
	};
	static var assetCursorGrabbing:BitmapData = null;

	static final CURSOR_HOURGLASS_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-hourglass.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorHourglass:BitmapData = null;

	static final CURSOR_POINTER_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-pointer.png",
		scale: 1.0,
		offsetX: 8,
		offsetY: 0,
	};
	static var assetCursorPointer:BitmapData = null;

	static final CURSOR_TEXT_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-text.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorText:BitmapData = null;

	static final CURSOR_ZOOM_IN_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-zoom-in.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorZoomIn:BitmapData = null;

	static final CURSOR_ZOOM_OUT_PARAMS:CursorParams = {
		graphic: "assets/images/cursor/cursor-zoom-out.png",
		scale: 1.0,
		offsetX: 0,
		offsetY: 0,
	};
	static var assetCursorZoomOut:BitmapData = null;

	static function set_cursorMode(value:CursorMode):CursorMode
	{
		if (cursorMode != value)
		{
			cursorMode = value;
			setCursorGraphic(cursorMode);
		}
		return cursorMode;
	}

	public static inline function show():Void
	{
		FlxG.mouse.visible = true;
	}

	public static inline function hide():Void
	{
		FlxG.mouse.visible = false;
	}

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
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_DEFAULT_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorDefault = bitmapData;
						applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorDefault, CURSOR_DEFAULT_PARAMS);
				}

			case Cross:
				if (assetCursorCross == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_CROSS_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorCross = bitmapData;
						applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorCross, CURSOR_CROSS_PARAMS);
				}

			case Eraser:
				if (assetCursorEraser == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ERASER_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorEraser = bitmapData;
						applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorEraser, CURSOR_ERASER_PARAMS);
				}

			case Grabbing:
				if (assetCursorGrabbing == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_GRABBING_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorGrabbing = bitmapData;
						applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorGrabbing, CURSOR_GRABBING_PARAMS);
				}

			case Hourglass:
				if (assetCursorHourglass == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_HOURGLASS_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorHourglass = bitmapData;
						applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorHourglass, CURSOR_HOURGLASS_PARAMS);
				}

			case Pointer:
				if (assetCursorPointer == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_POINTER_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorPointer = bitmapData;
						applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorPointer, CURSOR_POINTER_PARAMS);
				}

			case Text:
				if (assetCursorText == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_TEXT_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorText = bitmapData;
						applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorText, CURSOR_TEXT_PARAMS);
				}

			case ZoomIn:
				if (assetCursorZoomIn == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ZOOM_IN_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorZoomIn = bitmapData;
						applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorZoomIn, CURSOR_ZOOM_IN_PARAMS);
				}

			case ZoomOut:
				if (assetCursorZoomOut == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(CURSOR_ZOOM_OUT_PARAMS.graphic);
					future.onComplete(function(bitmapData:BitmapData)
					{
						assetCursorZoomOut = bitmapData;
						applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
					});
				}
				else
				{
					applyCursorParams(assetCursorZoomOut, CURSOR_ZOOM_OUT_PARAMS);
				}

			default:
				setCursorGraphic(null);
		}
	}

	static inline function applyCursorParams(graphic:BitmapData, params:CursorParams):Void
	{
		FlxG.mouse.load(graphic, params.scale, params.offsetX, params.offsetY);
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
