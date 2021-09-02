package animate;

import animate.ParseAnimate.AnimJson;
import animate.ParseAnimate.Animation;
import animate.ParseAnimate.Frame;
import animate.ParseAnimate.Sprite;
import animate.ParseAnimate.Spritemap;
import animate.ParseAnimate.SymbolDictionary;
import animate.ParseAnimate.Timeline;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.graphics.frames.FlxFrame.FlxFrameAngle;
import flixel.math.FlxAngle;
import flixel.math.FlxMath;
import flixel.math.FlxMatrix;
import flixel.math.FlxPoint;
import lime.system.System;
import openfl.Assets;
import openfl.geom.Matrix;

class FlxSymbol extends FlxSprite
{
	public var oldMatrix:Array<Float> = [];

	// Loop types shit
	public static inline var LOOP:String = 'LP';
	public static inline var PLAY_ONCE:String = 'PO';
	public static inline var SINGLE_FRAME:String = 'SF';

	/**
	 * This gets set in some nest animation bullshit in animation render code
	 */
	public var firstFrame:Int = 0;

	public var daLoopType:String = 'LP'; // LP by default, is set below!!!

	public function new(x:Float, y:Float)
	{
		super(x, y);

		var spritemap:Map<String, Sprite> = ParseAnimate.genSpritemap(Assets.getText(Paths.file('images/tightestBars/spritemap1.json')));
	}

	var symbolAtlasShit:Map<String, String> = new Map();

	public static var nestedShit:Map<Int, Array<FlxSymbol>> = new Map();

	var symbolMap:Map<String, Animation> = new Map();

	public var daFrame:Int = 0;

	override function update(elapsed:Float)
	{
		super.update(elapsed);
	}

	public var transformMatrix:Matrix = new Matrix();

	function renderFrame(TL:Timeline, ?traceShit:Bool = false)
	{
		for (layer in TL.L)
		{
			if (FlxG.keys.justPressed.TWO)
				trace(layer.LN);

			// layer.FR.reverse();

			// for (frame in layer.FR)
			// {

			var keyFrames:Array<Int> = [];
			var keyFrameMap:Map<Int, Frame> = new Map();

			// probably dumb to generate this every single frame for every layer?
			// prob want to generate it first when loading
			for (frm in layer.FR)
			{
				keyFrameMap[frm.I] = frm;
				keyFrames.push(frm.I);

				for (thing in 0...frm.DU - 1)
					keyFrames.push(frm.I);
			}

			if (FlxG.keys.justPressed.THREE)
			{
				trace(layer.LN);
				trace(keyFrames);
			}

			var newFrameNum:Int = daFrame;

			// need to account for movie clip / Graphic bullshit?

			switch (daLoopType)
			{
				case LOOP:
					var tempFrame = layer.FR[newFrameNum + firstFrame % layer.FR.length];
					// trace(tempFrame);
					// newFrameNum += firstFrame;
					// newFrameNum = newFrameNum % (tempFrame.I + tempFrame.DU);
					// newFrameNum = FlxMath.wrap(newFrameNum, tempFrame.I, tempFrame.I + tempFrame.DU);

					// trace(newFrameNum % keyFrames.length);
					// trace(newFrameNum);
					// trace(keyFrames);
					newFrameNum = keyFrames[newFrameNum % keyFrames.length]; // temp, fix later for good looping
				case PLAY_ONCE:
					// trace(newFrameNum);
					// trace(keyFrames.length - 1);
					// trace(keyFrameMap.get(newFrameNum + firstFrame));
					// trace(keyFrameMap.get(keyFrames[keyFrames.length - 1]));
					// trace(layer.LN);
					// trace(keyFrames);
					newFrameNum = Std.int(Math.min(newFrameNum + firstFrame, keyFrames.length - 1));
				case SINGLE_FRAME:
					// trace(layer);
					// trace(firstFrame);
					// trace(newFrameNum);
					// trace(layer.LN);
					// trace(keyFrames);
					newFrameNum = keyFrames[firstFrame];
			}

			// trace(daLoopType);
			// trace(newFrameNum);
			// trace(layer.FR.length);

			// trace(newFrameNum % layer.FR.length);

			// var swagFrame:Frame = layer.FR[newFrameNum % layer.FR.length]; // has modulo just in case????
			// doesnt actually use position in the array?3
			var swagFrame:Frame = keyFrameMap.get(newFrameNum);

			// get frame by going through

			// if (newFrameNum >= frame.I && newFrameNum < frame.I + frame.DU)
			// {
			// trace(daLoopType);
			for (element in swagFrame.E)
			{
				if (Reflect.hasField(element, 'ASI'))
				{
					var m3d = element.ASI.M3D;
					var dumbassMatrix:Matrix = new Matrix(m3d[0], m3d[1], m3d[4], m3d[5], m3d[12], m3d[13]);

					var spr:FlxSymbol = new FlxSymbol(0, 0);
					spr.setPosition(x, y);
					matrixExposed = true;
					spr.frames = frames;
					spr.frame = spr.frames.getByName(element.ASI.N);

					// dumbassMatrix.translate(origin.x, origin.y);

					dumbassMatrix.concat(_matrix);
					spr.matrixExposed = true;
					spr.transformMatrix.concat(dumbassMatrix);
					// spr._matrix.concat(spr.transformMatrix);

					spr.origin.set();
					// Prob dont need these offset thingies???
					// spr.origin.x += origin.x;
					// spr.origin.y += origin.y;

					spr.antialiasing = true;
					spr.draw();
				}
				else
				{
					var nestedSymbol = symbolMap.get(element.SI.SN);
					var nestedShit:FlxSymbol = new FlxSymbol(x, y);
					nestedShit.frames = frames;

					var swagMatrix:FlxMatrix = new FlxMatrix(element.SI.M3D[0], element.SI.M3D[1], element.SI.M3D[4], element.SI.M3D[5], element.SI.M3D[12],
						element.SI.M3D[13]);

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

					if (FlxG.keys.justPressed.ONE)
					{
						trace("SI - " + layer.LN + ": " + element.SI.SN + " - LOOP TYPE: " + element.SI.LP);
					}

					nestedShit.firstFrame = element.SI.FF;
					// nestedShit.daFrame += nestedShit.firstFrame;
					nestedShit.daLoopType = element.SI.LP;
					nestedShit.daFrame = daFrame;
					nestedShit.scrollFactor.set(1, 1);
					nestedShit.renderFrame(nestedSymbol.TL);

					// renderFrame(nestedSymbol.TL, coolParsed);
				}
			}
			// }
			// }
		}
	}

	function changeFrame(frameChange:Int = 0):Void
	{
		daFrame += frameChange;
	}

	function getFrame() {}

	/**
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
		}

		_point.add(origin.x, origin.y);


		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);**/
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

			updateSkewMatrix();
			_matrix.concat(_skewMatrix);
		}

		_point.addPoint(origin);
		_matrix.translate(_point.x, _point.y);

		if (isPixelPerfectRender(camera))
		{
			_matrix.tx = Math.floor(_matrix.tx);
			_matrix.ty = Math.floor(_matrix.ty);
		}
		camera.drawPixels(_frame, framePixels, _matrix, colorTransform, blend, antialiasing, shader);
	}

	var _skewMatrix:Matrix = new Matrix();

	// public var transformMatrix(default, null):Matrix = new Matrix();

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = true;

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
// typedef Parsed =
// {
// 	var MD:Metadata;
// 	var AN:Animation;
// 	var SD:SymbolDictionary; // Doesn't always have symbol dictionary!!
// }
// typedef Metadata =
// {
// 	/** Framerate */
// 	var FRT:Int;
// }
// /** Basically treated like one big symbol*/
// typedef Animation =
// {
// 	/** symbolName */
// 	var SN:String;
// 	var TL:Timeline;
// 	/** IDK what STI stands for, Symbole Type Instance?
// 		Anyways, it is NOT used in SYMBOLS, only the main AN animation
// 	 */
// 	var STI:Dynamic;
// }
// /** DISCLAIMER, MAY NOT ACTUALLY BE CALLED
// 	SYMBOL TYPE ISNTANCE, IM JUST MAKING ASSUMPTION!! */
// typedef SymbolTypeInstance =
// {
// 	// var TL:Timeline;
// 	// var SN:String;
// }
// typedef SymbolDictionary =
// {
// 	var S:Array<Animation>;
// }
// typedef Timeline =
// {
// 	/** Layers */
// 	var L:Array<Layer>;
// }
// // Singular layer, not to be confused with LAYERS
// typedef Layer =
// {
// 	var LN:String;
// 	/** Frames */
// 	var FR:Array<Frame>;
// }
// typedef Frame =
// {
// 	/** Frame index*/
// 	var I:Int;
// 	/** Duration, in frames*/
// 	var DU:Int;
// 	/** Elements*/
// 	var E:Array<Element>;
// }
// typedef Element =
// {
// 	var SI:SymbolInstance;
// 	var ASI:AtlasSymbolInstance;
// }
// /**
// 	Symbol instance, for SYMBOLS and refers to SYMBOLS
//  */
// typedef SymbolInstance =
// {
// 	var SN:String;
// 	/** SymbolType (Graphic, Movieclip, Button)*/
// 	var ST:String;
// 	/** First frame*/
// 	var FF:Int;
// 	/** Loop type (Loop, play once, single frame)*/
// 	var LP:String;
// 	var TRP:TransformationPoint;
// 	var M3D:Array<Float>;
// }
// typedef AtlasSymbolInstance =
// {
// 	var N:String;
// 	var M3D:Array<Float>;
// }
// typedef TransformationPoint =
// {
// 	var x:Float;
// 	var y:Float;
// }
