package animate;

import flixel.math.FlxMatrix;
import flixel.FlxCamera;
import haxe.ds.IntMap;
import openfl.geom.Matrix;
import haxe.ds.StringMap;
import flixel.FlxSprite;

// I sincerely apologize for the rather shitty variable names and the error preventers.
// The variables are not named in the code, and I have no fucking idea what they are doing. Typedefs don't exist either.
// If you have a general understanding of the variables and have good names, please reach out to me via an issue marked as an "enhancement", or a pull request.
// 
// - AngelDTF, programmer of the Newgrounds Port
// https://github.com/AngelDTF/FNF-NewgroundsPort

class FlxSymbol extends FlxSprite
{
	public var hasFrameByPass:Bool = false;
	public var symbolAtlasShit:StringMap<Dynamic> = new StringMap<Dynamic>();
	public var symbolMap:StringMap<Dynamic> = new StringMap<Dynamic>();
	public var drawQueue:Array<Dynamic> = [];
	public var daFrame:Int = 0;
	public var nestDepth:Int = 0;
	public var transformMatrix:Matrix = new Matrix();
	
	var _skewMatrix = new Matrix();
	
	public var matrixExposed = false;
	public var coolParse:Dynamic;

	public static var nestedShit:IntMap<Array<FlxSymbol>> = new IntMap<Array<FlxSymbol>>();
	
	override public function new(x:Float, y:Float, c:Dynamic)
	{
		super(x, y);
		coolParse = c;
		if (Reflect.hasField(coolParse, 'SD'))
			symbolAtlasShit = parseSymbolDictionary(coolParse);
	}

	override public function draw()
	{
		super.draw();
	}

	public function renderFrame(a, b, ?c:Bool)
	{
		drawQueue = [];
		var _a_L:Array<Dynamic> = a.L; // error preventer, sorry I don't have the typedefs
		for (d in _a_L)
		{
			var _d_FR:Array<Dynamic> = d.FR; // another error preventer
			for (f in _d_FR)
			{
				if (daFrame >= f.I && daFrame < f.I + f.DU)
				{
					var _f_E:Array<Dynamic> = f.E; // last error preventer for this function
					for (m in _f_E)
					{
						if (Reflect.hasField(m, 'ASI'))
						{
							var n1 = m.ASI.M3D;
							var k = new Matrix(n1[0], n1[1], n1[4], n1[5], n1[12], n1[13]);
							var n2 = new FlxSymbol(0, 0, b);
							matrixExposed = true;
							n2.frames = frames;
							n2.frame = n2.frames.framesHash.get(m.ASI.N);
							k.concat(_matrix);
							n2.matrixExposed = true;
							n2.transformMatrix.concat(k);
							n2.origin.set();
							n2.origin.x += origin.x;
							n2.origin.y += origin.y;
							n2.antialiasing = true;
							n2.draw();
						}
						else
						{
							var n = symbolMap.get(m.SI.SN);
							var k = new FlxSymbol(0, 0, coolParse);
							k.frames = frames;
							var g = new FlxMatrix(m.SI.M3D[0], m.SI.M3D[1], m.SI.M3D[4], m.SI.M3D[5], m.SI.M3D[12], m.SI.M3D[13]);
							g.concat(_matrix);
							k._matrix.concat(g);
							k.origin.set(m.SI.TRP.x, m.SI.TRP.y);
							if (symbolAtlasShit.exists(n.SN))
							{
								// empty if statement???
								// perhaps it was later commented out code, idfk
							}
							k.hasFrameByPass = true;
							k.nestDepth = nestDepth + 1;
							k.renderFrame(n.TL, b);
						}
					}
				}
			}
		}
	}

	private function changeFrame(?change:Int = 0)
	{
		daFrame += change;
	}

	private function parseSymbolDictionary(a):StringMap<Dynamic>
	{
		var b = new StringMap<Dynamic>();
		var _a_SD_S:Array<Dynamic> = a.SD.S; // error preventer
		for (d in _a_SD_S)
		{
			symbolMap.set(d.SN, d);
			var e = d.SN;
			var _d_TL_L:Array<Dynamic> = d.TL.L; // error preventer
			for (h in _d_TL_L)
			{
				var _h_FR:Array<Dynamic> = h.FR; // error preventer
				for (n in _h_FR)
				{
					var _n_E:Array<Dynamic> = n.E; // error preventer
					for (g in _n_E)
					{
						if (Reflect.hasField(g, 'ASI'))
							b.set(e, g.ASI.N);
					}
				}
			}
		}
		return b;
	}

	override public function drawComplex(a:FlxCamera)
	{
		var b1 = flipX != _frame.flipX;
		var c1 = flipY != _frame.flipY;
		_frame.prepareMatrix(_matrix, 0, animation.curAnim != null ? b1 != animation.curAnim.flipX : b1, animation.curAnim != null ? c1 != animation.curAnim.flipY : c1);
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
				if (_angleChanged)
				{
					var b = Math.PI / 180 * angle;
					_sinAngle = Math.sin(b);
					_cosAngle = Math.cos(b);
					_angleChanged = false;
				}
				if (angle != 0)
				{
					// this looks like actual fucking shit
					var b = _matrix;
					var c = _cosAngle;
					var d = _sinAngle;
					var e = b.a * c - b.b * d;
					b.b = b.a * d + b.b * c;
					b.a = e;
					e = b.c * c - b.d * d;
					b.d = b.c * d + b.d * c;
					b.c = e;
					e = b.tx * c - b.ty * d;
					b.ty = b.tx * d + b.ty * c;
					b.tx = e;
				}
			}
			_matrix.concat(_skewMatrix);
		}
		_point.addPoint(origin);
		if (isPixelPerfectRender(a))
		{
			_point.x = Math.floor(_point.x);
			_point.y = Math.floor(_point.y);
		}
		_matrix.translate(_point.x, _point.y);
		a.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing);
	}
}