package funkin.input;

import openfl.utils.Assets;
import lime.app.Future;
import openfl.display.BitmapData;

class Cursor
{
	public static var cursorMode(default, set):CursorMode;

	static final ASSET_PATH_CURSOR_DEFAULT:String = "assets/images/cursor/cursor-default.png";
	static var ASSET_CURSOR_DEFAULT:BitmapData = null;
	static final ASSET_PATH_CURSOR_POINTER:String = "assets/images/cursor/cursor-pointer.png";
	static var ASSET_CURSOR_POINTER:BitmapData = null;
	static final ASSET_PATH_CURSOR_GRABBING:String = "assets/images/cursor/cursor-grabbing.png";
	static var ASSET_CURSOR_GRABBING:BitmapData = null;

	static function set_cursorMode(value:CursorMode):CursorMode
	{
		if (cursorMode != value)
		{
			cursorMode = value;
			setCursorGraphic(cursorMode);
		}
		return cursorMode;
	}

	public static function show():Void
	{
		FlxG.mouse.visible = true;
	}

	public static function hide():Void
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
				if (ASSET_CURSOR_DEFAULT == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(ASSET_PATH_CURSOR_DEFAULT);
					future.onComplete(function(bitmapData:BitmapData)
					{
						ASSET_CURSOR_DEFAULT = bitmapData;
						FlxG.mouse.load(ASSET_CURSOR_DEFAULT);
					});
				}
				else
				{
					FlxG.mouse.load(ASSET_CURSOR_DEFAULT);
				}

			case Pointer:
				if (ASSET_CURSOR_POINTER == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(ASSET_PATH_CURSOR_POINTER);
					future.onComplete(function(bitmapData:BitmapData)
					{
						ASSET_CURSOR_POINTER = bitmapData;
						FlxG.mouse.load(ASSET_CURSOR_POINTER);
					});
				}
				else
				{
					FlxG.mouse.load(ASSET_CURSOR_POINTER);
				}
			case Grabbing:
				if (ASSET_CURSOR_GRABBING == null)
				{
					var future:Future<BitmapData> = Assets.loadBitmapData(ASSET_PATH_CURSOR_GRABBING);
					future.onComplete(function(bitmapData:BitmapData)
					{
						ASSET_CURSOR_GRABBING = bitmapData;
						FlxG.mouse.load(ASSET_CURSOR_GRABBING);
					});
				}
				else
				{
					FlxG.mouse.load(ASSET_CURSOR_GRABBING);
				}
			default:
				setCursorGraphic(null);
		}
	}
}

// https://developer.mozilla.org/en-US/docs/Web/CSS/cursor
enum CursorMode
{
	Default;
	Pointer;
	// Grab;
	Grabbing;
	// Help;
	// Progress;
	// Wait;
	// Crosshair;
	// Text;
	// Move;
	// ZoomIn;
	// ZoomOut;
}
