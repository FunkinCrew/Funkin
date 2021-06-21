package;

import openfl.Lib;

class GlobalVideo
{
	private static var video:VideoHandler;
	private static var webm:WebmHandler;
	public static var isWebm:Bool = false;
	public static var isAndroid:Bool = false;
	public static var daAlpha1:Float = 0.2;
	public static var daAlpha2:Float = 1;

	public static function setVid(vid:VideoHandler):Void
	{
		video = vid;
	}
	
	public static function getVid():VideoHandler
	{
		return video;
	}
	
	public static function setWebm(vid:WebmHandler):Void
	{
		webm = vid;
		isWebm = true;
	}
	
	public static function getWebm():WebmHandler
	{
		return webm;
	}
	
	public static function get():Dynamic
	{
		if (isWebm)
		{
			return getWebm();
		} else {
			return getVid();
		}
	}
	
	public static function calc(ind:Int):Dynamic
	{
		var stageWidth:Int = Lib.current.stage.stageWidth;
		var stageHeight:Int = Lib.current.stage.stageHeight;

		var width:Float = GameDimensions.width;
		var height:Float = GameDimensions.height;
		
		//trace("AH: " + stageWidth);
		//trace(width);
		
		var ratioX:Float = height / width;
		var ratioY:Float = width / height;
		var appliedWidth:Float = stageHeight * ratioY;
		var appliedHeight:Float = stageWidth * ratioX;
		//trace(appliedWidth);
		var remainingX:Float = stageWidth - appliedWidth;
		var remainingY:Float = stageHeight - appliedHeight;
		remainingX = remainingX / 2;
		remainingY = remainingY / 2;
		
		appliedWidth = Std.int(appliedWidth);
		appliedHeight = Std.int(appliedHeight);
		
		if (appliedHeight > stageHeight)
		{
			remainingY = 0;
			appliedHeight = stageHeight;
		}
		
		if (appliedWidth > stageWidth)
		{
			remainingX = 0;
			appliedWidth = stageWidth;
		}
		
		switch(ind)
		{
			case 0:
				return remainingX;
			case 1:
				return remainingY;
			case 2:
				return appliedWidth;
			case 3:
				return appliedHeight;
		}
		
		return null;
	}
}