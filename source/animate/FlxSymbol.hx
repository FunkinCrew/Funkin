package animate;

import flixel.FlxCamera;
import haxe.ds.IntMap;
import openfl.geom.Matrix;
import haxe.ds.StringMap;
import flixel.FlxSprite;

using StringTools;

class FlxSymbol extends FlxSprite
{
	public var hasFrameByPass = false;
	public var symbolAtlasShit = new StringMap<Dynamic>();
	public var symbolMap = new StringMap<Dynamic>();
	public var drawQueue = [];
	public var nestDepth = 0;
	public var daFrame = 0;
	public var transformMatrix = new Matrix();
	
	var _skewMatrix = new Matrix();
	
	public var matrixExposed = false;
	public var coolParse:Dynamic;

	public static var nestedShit = new IntMap();
	
	/* override public function new(X:Float, Y:Float, someshit:Dynamic)
	{
		super(X, Y);
		coolParse = someshit;
		if (coolParse.contains('SD'))
			symbolAtlasShit = parseSymbolDictionary(coolParse);
	}

	override function draw()
	{
		super.draw();
	}

	function renderFrame(a, b, c)
	{
		drawQueue = [];
	}

	function changeFrame(?change:Int = 0)
	{
		daFrame += change;
	}

	function parseSymbolDictionary(a)
	{

	}

	override function drawComplex(a:FlxCamera)
	{

	} */
}