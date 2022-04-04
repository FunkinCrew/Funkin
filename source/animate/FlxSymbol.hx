package animate;

import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxMatrix;
import flixel.FlxCamera;
import openfl.geom.Matrix;
import flixel.FlxSprite;

class FlxSymbol extends FlxSprite
{
	var hasFrameByPass:Bool;
	var symbolAtlasShit:Map<String, String> = new Map();
	var symbolMap:Map<String, Animation> = new Map();
	public var drawQueue:Array<Dynamic> = [];
	public var daFrame:Int;
	public var nestDepth:Int;
	public var transformMatrix:Matrix = new Matrix();
	
	var _skewMatrix = new Matrix();
	
	public var matrixExposed:Bool;
	public var coolParse:Parsed;

	public static var nestedShit:Map<Int, Array<FlxSymbol>> = new Map<Int, Array<FlxSymbol>>();
	
	public function new(x:Float, y:Float, coolParsed:Parsed)
	{
		super(x, y);

		this.coolParse = coolParsed;

		var hasSymbolDictionary:Bool = Reflect.hasField(coolParse, "SD");

		if (hasSymbolDictionary)
			symbolAtlasShit = parseSymbolDictionary(coolParse);
	}

	public override function draw()
	{
		super.draw();
	}

	function renderFrame(TL:Timeline, coolParsed:Parsed, ?traceShit:Bool = false)
	{
		drawQueue = [];
		for (layer in TL.L)
		{
			for (swagFrame in layer.FR)
			{
				if (daFrame >= swagFrame.I && daFrame < swagFrame.I + swagFrame.DU)
				{
					for (element in swagFrame.E)
					{
						if (Reflect.hasField(element, 'ASI'))
						{
							var m3d = element.ASI.M3D;
							var dumbassMatrix:Matrix = new Matrix(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);
	
							var spr:FlxSymbol = new FlxSymbol(0, 0, coolParsed);
							matrixExposed = true;
							spr.frames = frames;
							spr.frame = spr.frames.getByName(element.ASI.N);
	
							dumbassMatrix.concat(_matrix);
							spr.matrixExposed = true;
							spr.transformMatrix.concat(dumbassMatrix);
	
							spr.origin.set();

							spr.origin.x += origin.x;
							spr.origin.y += origin.y;
							
							spr.antialiasing = true;
							spr.draw();
						}
						else
						{
							var nestedSymbol = symbolMap.get(element.SI.SN);
							var nestedShit:FlxSymbol = new FlxSymbol(0, 0, coolParse);
							nestedShit.frames = frames;
	
							var swagMatrix:FlxMatrix = new FlxMatrix(element.SI.M3D[0], element.SI.M3D[1], element.SI.M3D[4], element.SI.M3D[5], element.SI.M3D[12], element.SI.M3D[13]);

							swagMatrix.concat(_matrix);

							nestedShit._matrix.concat(swagMatrix);
							nestedShit.origin.set(element.SI.TRP.x, element.SI.TRP.y);

							if (symbolAtlasShit.exists(nestedSymbol.SN))
							{
								// empty if statement???
								// perhaps it was later commented out code, idfk
							}

							nestedShit.hasFrameByPass = true;
							nestedShit.nestDepth = nestDepth + 1;
							nestedShit.renderFrame(nestedSymbol.TL, coolParsed);
						}
					}
				}
			}
		}
	}

	public function changeFrame(frameChange:Int = 0):Void
	{
		daFrame += frameChange;
	}

	function parseSymbolDictionary(coolParsed:Parsed):Map<String, String>
	{
		var awesomeMap:Map<String, String> = new Map();

		for (symbol in coolParsed.SD.S)
		{
			symbolMap.set(symbol.SN, symbol);

			var symbolName = symbol.SN;

			for (layer in symbol.TL.L)
			{
				for (frame in layer.FR)
				{
					for (element in frame.E)
					{
						if (Reflect.hasField(element, 'ASI'))
						{
							awesomeMap.set(symbolName, element.ASI.N);
						}
					}
				}
			}
		}

		return awesomeMap;
	}

	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed)
			_matrix.concat(transformMatrix);
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();
	
				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}
			_matrix.concat(_skewMatrix);
		}
		
		_point.addPoint(origin);

		if (isPixelPerfectRender(camera))
		{
			_point.x = Math.floor(_point.x);
			_point.y = Math.floor(_point.y);
		}

		_matrix.translate(_point.x, _point.y);

		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing);
	}
}

typedef Parsed =
{
	var AN:Animation;
	var SD:SymbolDictionary;
	var MD:AtlasMetaData;
}

/**
 * Basically treated like one big symbol
 */
 typedef Animation =
 {
	 /**
	  * Symbol Name
	  */
	 var SN:String;
 
	 var TL:Timeline;
 
	 /**
	  * Symbol Type Instance
	  * NOT used in symbols, only the main AN animation.
	  */
	 var STI:Dynamic;
 }
 
 typedef SymbolDictionary =
 {
	 var S:Array<Animation>;
 }
 
 typedef Timeline =
 {
	 /**
	  * Layers
	  */
	 var L:Array<Layer>;
 }
 
 typedef Layer =
 {
	 var LN:String;
 
	 /**
	  * Frames
	  */
	 var FR:Array<Frame>;
 }
 
 typedef Frame =
 {
	 var I:Int;
 
	 /**
	  * Duration, in frames
	  */
	 var DU:Int;
 
	 /**
	  * Elements
	  */
	 var E:Array<Element>;
 }
 
 typedef Element =
 {
	 var SI:SymbolInstance;
	 var ASI:AtlasSymbolInstance;
 }
 
 /**
  * Symbol instance, for SYMBOLS and refers to SYMBOLS
  */
 typedef SymbolInstance =
 {
	 var SN:String;
 
	 /**
	  * SymbolType (Graphic, Movieclip, Button)
	  */
	 var ST:String;
 
	 var FFP:Int;
	 var LP:String;
	 var TRP:TransformationPoint;
	 var M3D:Array<Float>;
 }
 
 typedef AtlasSymbolInstance =
 {
	 var N:String;
	 var M3D:Array<Float>;
 }
 
 typedef TransformationPoint =
 {
	 var x:Float;
	 var y:Float;
 }
 
 typedef AtlasMetaData =
 {
	 var FRT:Int;
 }