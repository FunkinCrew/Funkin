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
	// Loop types shit
	public static inline var LOOP:String = 'LP';
	public static inline var PLAY_ONCE:String = 'PO';
	public static inline var SINGLE_FRAME:String = 'SF';

	public var transformMatrix:Matrix = new Matrix();
	public var daLoopType:String = 'LP'; // LP by default, is set below!!!

	/**
	 * Bool flag showing whether transformMatrix is used for rendering or not.
	 * False by default, which means that transformMatrix isn't used for rendering
	 */
	public var matrixExposed:Bool = true;

	public function new(x:Float, y:Float)
	{
		super(x, y);

		var spritemap:Map<String, Sprite> = ParseAnimate.genSpritemap(Assets.getText(Paths.file('images/tightestBars/spritemap1.json')));
	}

	var symbolAtlasShit:Map<String, String> = new Map();
	var symbolMap:Map<String, Animation> = new Map();

	public var daFrame:Int = 0;

	function changeFrame(frameChange:Int = 0):Void
	{
		daFrame += frameChange;
	}

	/**
	 * custom "homemade" (nabbed from FlxSkewSprite) draw function, to make having a matrix transform slightly 
	 * less painful
	 */
	override function drawComplex(camera:FlxCamera):Void
	{
		_frame.prepareMatrix(_matrix, FlxFrameAngle.ANGLE_0, checkFlipX(), checkFlipY());
		_matrix.translate(-origin.x, -origin.y);
		_matrix.scale(scale.x, scale.y);

		if (matrixExposed)
		{
			_matrix.concat(transformMatrix);
		}

		if (bakedRotationAngle <= 0)
		{
			updateTrig();

			if (angle != 0)
				_matrix.rotateWithTrig(_cosAngle, _sinAngle);
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
}
