package animate;

import flixel.FlxSprite;
import flixel.math.FlxAngle;

class FlxSymbol extends FlxSprite
{
	public var coolParse:Parsed;
	public var oldMatrix:Array<Float> = [];

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

	var swagX:Float = 0;
	var swagY:Float = 0;

	var symbolMap:Map<String, Animation> = new Map();

	var drawQueue:Array<FlxSymbol> = [];

	function renderFrame(TL:Timeline, coolParsed:Parsed, ?isMainLoop:Bool = false)
	{
		drawQueue = [];

		for (layer in TL.L)
		{
			var frameInfo:Frame = layer.FR[0];

			if (isMainLoop)
				frameInfo = layer.FR[0];

			// frameInfo.E.reverse();

			for (element in frameInfo.E)
			{
				if (Reflect.hasField(element, 'ASI'))
				{
					var spr:FlxSymbol = new FlxSymbol(x + element.ASI.M3D[12], y + element.ASI.M3D[13], coolParsed);

					if (oldMatrix != null)
					{
						// spr.x += oldMatrix[12];
						// spr.y += oldMatrix[13];
					}
					// trace(element.ASI.M3D[12] + element.ASI.N);

					spr.frames = frames;
					// spr.animation.addByPrefix('swag',)

					spr.frame = spr.frames.getByName(element.ASI.N);

					// spr.flipX = true;

					var m3d = element.ASI.M3D;
					_matrix.identity();
					_matrix.setTo(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);

					// spr.scale.x = m3d[0];
					spr.scale.y = Math.sqrt(_matrix.c * _matrix.c + _matrix.d * _matrix.d);
					spr.scale.x = Math.sqrt(_matrix.a * _matrix.a + _matrix.b * _matrix.b);
					spr.origin.set();
					spr.origin.x += origin.x;
					spr.origin.y += origin.y;
					spr.angle = FlxAngle.asDegrees(Math.atan2(m3d[1], m3d[0])) + angle;
					spr.antialiasing = true;

					// spr.scale.y = m3d[5];

					// if (flipX || m3d[0] == -1)
					// spr.flipX = true;

					// _matrix.identity();

					// _matrix.setTo(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);
					// spr.x = _matrix.tx + swagX;
					// spr.y = _matrix.ty + swagY;

					// spr._matrix.setTo(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);

					drawQueue.push(spr);
					// spr.draw();

					// swagX = 0;
				}
				else
				{
					var nestedSymbol = symbolMap.get(element.SI.SN);
					// trace(element.SI.M3D[12]);
					// swagX = x +;
					// swagY =;

					if (oldMatrix != null)
					{
						// x += oldMatrix[12];
						// y += oldMatrix[13];
					}

					// if (symbolAtlasShit.exists(nestedSymbol.SN))
					// {
					// nestedShit.frames.getByName(symbolAtlasShit.get(nestedSymbol.SN));
					// nestedShit.draw();
					// }

					// nestedSymbol

					// if (element.SI.M3D[0] == -1 || flipX)
					// nestedShit.flipX = true;

					// nestedSymbol.TL.L.reverse();

					_matrix.identity();
					_matrix.setTo(element.SI.M3D[0], element.SI.M3D[1], element.SI.M3D[4], element.SI.M3D[5], element.SI.M3D[12], element.SI.M3D[13]);
					// _matrix.scale(1, 1);

					var nestedShit:FlxSymbol = new FlxSymbol(x + _matrix.tx, y + _matrix.ty, coolParse);
					nestedShit.frames = frames;

					nestedShit.scale.x = Math.sqrt(_matrix.a * _matrix.a + _matrix.b + _matrix.b);
					nestedShit.scale.y = Math.sqrt(_matrix.a * _matrix.a + _matrix.b * _matrix.b);
					nestedShit.origin.set(element.SI.TRP.x, element.SI.TRP.y);

					nestedShit.angle = FlxAngle.asDegrees(Math.atan2(_matrix.b, _matrix.a));

					// scale.y = Math.sqrt(_matrix.c * _matrix.c + _matrix.d * _matrix.d);
					// scale.x = Math.sqrt(_matrix.a * _matrix.a + _matrix.b * _matrix.b);

					// nestedShit.oldMatrix = element.SI.M3D;

					nestedShit.renderFrame(nestedSymbol.TL, coolParsed);

					// renderFrame(nestedSymbol.TL, coolParsed);
				}
			}
		}

		// drawQueue.reverse();
		//
		for (thing in drawQueue)
			thing.draw();
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
