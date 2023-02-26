package animate;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import openfl.geom.Matrix;

class FlxSymbol extends FlxSprite
{
	public var coolParse:Parsed;
	public var oldMatrix:Array<Float> = [];

	private var hasFrameByPass:Bool = false;

	public function new(x:Float, y:Float, coolParsed:Parsed)
	{
		super(x, y);

		this.coolParse = coolParsed;

		var hasSymbolDictionary:Bool = Reflect.hasField(coolParse, "SD");

		if (hasSymbolDictionary)
			symbolAtlasShit = parseSymbolDictionary(coolParse);
	}

	var symbolAtlasShit:Map<String, String> = new Map();

	override function draw()
	{
		super.draw();
	}

	public static var nestedShit:Map<Int, Array<FlxSymbol>> = new Map();

	var symbolMap:Map<String, Animation> = new Map();

	var drawQueue:Array<FlxSymbol> = [];

	public var daFrame:Int = 0;
	public var nestDepth:Int = 0;

	public var transformMatrix:Matrix = new Matrix();

	function renderFrame(TL:Timeline, coolParsed:Parsed, ?isMainLoop:Bool = false)
	{
		drawQueue = [];

		for (layer in TL.L)
		{
			// layer.FR.reverse();
			// var frame = layer.FR[0]

			for (frame in layer.FR)
			{
				if (daFrame >= frame.I && daFrame < frame.I + frame.DU)
				{
					for (element in frame.E)
					{
						if (Reflect.hasField(element, 'ASI'))
						{
							var m3d = element.ASI.M3D;
							var dumbassMatrix:Matrix = new Matrix(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);

							var spr:FlxSymbol = new FlxSymbol(0, 0, coolParsed);
							matrixExposed = true;
							spr.frames = frames;
							spr.frame = spr.frames.getByName(element.ASI.N);

							// dumbassMatrix.translate(origin.x, origin.y);

							dumbassMatrix.concat(_matrix);
							spr.matrixExposed = true;
							spr.transformMatrix.concat(dumbassMatrix);
							// spr._matrix.concat(spr.transformMatrix);

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

							var swagMatrix:FlxMatrix = new FlxMatrix(element.SI.M3D[0], element.SI.M3D[1], element.SI.M3D[4], element.SI.M3D[5],
								element.SI.M3D[12], element.SI.M3D[13]);

							swagMatrix.concat(_matrix);

							nestedShit._matrix.concat(swagMatrix);
							nestedShit.origin.set(element.SI.TRP.x, element.SI.TRP.y);
							// nestedShit.angle += ((180 / Math.PI) * Math.atan2(swagMatrix.b, swagMatrix.a));
							// nestedShit.angle += angle;

							if (symbolAtlasShit.exists(nestedSymbol.SN))
							{
								// nestedShit.frames.getByName(symbolAtlasShit.get(nestedSymbol.SN));
								// nestedShit.draw();
							}

							// scale.y = Math.sqrt(_matrix.c * _matrix.c + _matrix.d * _matrix.d);
							// scale.x = Math.sqrt(_matrix.a * _matrix.a + _matrix.b * _matrix.b);

							// nestedShit.oldMatrix = element.SI.M3D;

							nestedShit.hasFrameByPass = true;
							nestedShit.nestDepth = nestDepth + 1;
							nestedShit.renderFrame(nestedSymbol.TL, coolParsed);

							// renderFrame(nestedSymbol.TL, coolParsed);
						}
					}
				}
			}
		}

		// drawQueue.reverse();
		//
		// for (thing in drawQueue)
		// thing.draw();
	}

	function setDaMap(spr:FlxSymbol):Void
	{
		if (!nestedShit.exists(nestDepth))
			nestedShit.set(nestDepth, [spr]);
		else
			nestedShit.get(nestDepth).push(spr);
	}

	function changeFrame(frameChange:Int = 0):Void
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
		{
			_matrix.concat(transformMatrix);
		}
		else
		{
			if (bakedRotationAngle <= 0)
			{
				updateTrig();

				if (angle != 0)
					_matrix.rotateWithTrig(_cosAngle, _sinAngle);
			}

			// updateSkewMatrix();
			_matrix.concat(_skewMatrix);
		}

		_point.addPoint(origin);
		if (isPixelPerfectRender(camera))
			_point.floor();

		_matrix.translate(_point.x, _point.y);
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing);
	}

	var _skewMatrix:Matrix = new Matrix();

	// public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = false;

	public var skew(default, null):FlxPoint = FlxPoint.get();

	function updateSkewMatrix():Void
	{
		_skewMatrix.identity();

		if (skew.x != 0 || skew.y != 0)
		{
			_skewMatrix.b = Math.tan(skew.y * FlxAngle.TO_RAD);
			_skewMatrix.c = Math.tan(skew.x * FlxAngle.TO_RAD);
		}
	}
}

// TYPEDEFS FOR ANIMATION.JSON PARSING

typedef Parsed =
{
	var MD:Metadata;
	var AN:Animation;
	var SD:SymbolDictionary; // Doesn't always have symbol dictionary!!
}

typedef Metadata =
{
	/** Framerate */
	var FRT:Int;
}

/** Basically treated like one big symbol*/
typedef Animation =
{
	/** symbolName */
	var SN:String;

	var TL:Timeline;

	/** IDK what STI stands for, Symbole Type Instance?
		Anyways, it is NOT used in SYMBOLS, only the main AN animation    
	 */
	var STI:Dynamic;
}

/** DISCLAIMER, MAY NOT ACTUALLY BE CALLED
	SYMBOL TYPE ISNTANCE, IM JUST MAKING ASSUMPTION!! */
typedef SymbolTypeInstance =
{
	// var TL:Timeline;
	// var SN:String;
}

typedef SymbolDictionary =
{
	var S:Array<Animation>;
}

typedef Timeline =
{
	/** Layers */
	var L:Array<Layer>;
}

// Singular layer, not to be confused with LAYERS
typedef Layer =
{
	var LN:String;

	/** Frames */
	var FR:Array<Frame>;
}

typedef Frame =
{
	var I:Int;

	/** Duration, in frames*/
	var DU:Int;

	/** Elements*/
	var E:Array<Element>;
}

typedef Element =
{
	var SI:SymbolInstance;
	var ASI:AtlasSymbolInstance;
}

/**
	Symbol instance, for SYMBOLS and refers to SYMBOLS    
 */
typedef SymbolInstance =
{
	var SN:String;

	/** SymbolType (Graphic, Movieclip, Button)*/
	var ST:String;

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
