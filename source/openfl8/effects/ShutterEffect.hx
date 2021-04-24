package openfl8.effects;

import flixel.FlxG;
import flixel.system.FlxAssets.FlxShader;

class ShutterEffect
{
	public static inline var SHUTTER_TARGET_FLXSPRITE:Int = 0;
	public static inline var SHUTTER_TARGET_FLXCAMERA:Int = 1;

	public var shutterTargetMode(default, set):Int = 0;

	/**
	 * The instance of the actual shader class
	 */
	public var shader(default, null):ShutterShader;

	/**
	 * Size of the circle or "shutter"
	 */
	public var radius(default, set):Float;

	/**
	 * Center point of the "shutter"
	 */
	public var shutterCenterX(default, set):Float;

	public var shutterCenterY(default, set):Float;

	public var isActive(default, set):Bool;

	public function new():Void
	{
		shader = new ShutterShader();
		setResolution();
		isActive = true;
		shutterCenterX = FlxG.width * .5;
		shutterCenterY = FlxG.height * .5;
		shutterTargetMode = SHUTTER_TARGET_FLXSPRITE;
		radius = 0;
	}

	function setResolution():Void
	{
		shader.uResolution.value = [FlxG.width, FlxG.height];
	}

	function set_shutterTargetMode(v:Int):Int
	{
		shutterTargetMode = v;
		shader.shutterTargetMode.value = [shutterTargetMode];
		return v;
	}

	function set_isActive(v:Bool):Bool
	{
		isActive = v;
		shader.shaderIsActive.value = [isActive];
		return v;
	}

	function set_radius(v:Float):Float
	{
		radius = (v <= 0.0 ? 0.0 : v);
		shader.uCircleRadius.value = [radius];
		return v;
	}

	function set_shutterCenterX(v:Float):Float
	{
		shutterCenterX = v;
		shader.centerPtX.value = [v];
		return v;
	}

	function set_shutterCenterY(v:Float):Float
	{
		shutterCenterY = v;
		shader.centerPtY.value = [v];
		return v;
	}
}

class ShutterShader extends FlxShader
{
	@:glFragmentSource('
		#pragma header
		#ifdef GL_ES
			precision mediump float;
		#endif

		const int SHUTTER_TARGET_FLXSPRITE = 0;
		const int SHUTTER_TARGET_FLXCAMERA = 1;
		const float scale = 1.0;

		uniform vec2 uResolution;
		uniform float centerPtX;
		uniform float centerPtY;
		uniform float uCircleRadius;
		uniform int shutterTargetMode;
		uniform bool shaderIsActive;

		vec2 getCoordinates()
		{
			return vec2(
				(openfl_TextureCoordv.x * uResolution.x) / scale,
				(openfl_TextureCoordv.y * uResolution.y) / scale
			);
		}

		float getDist(vec2 pt1, vec2 pt2)
		{
			float dx = pt1.x - pt2.x;
			float dy = pt1.y - pt2.y;

			return sqrt(
				(dx*dx) + (dy*dy)
			);
		}

		void main()
		{
			if (!shaderIsActive)
			{
				gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
				return;
			}

			vec2 centerPt = vec2(centerPtX, centerPtY);

			if (uCircleRadius <= 0.0 || getDist(getCoordinates(), centerPt) > uCircleRadius)
			{
				gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
			}
			else
			{
				/* If this shader is used on a FlxCamera, uncomment the line below to
				draw the underlying pixels inside the shutter (as they would look normally).

				If using this shader on a FlxSprite, keep the line below commented out, to
				draw transparency inside the shutter */

				if (shutterTargetMode == SHUTTER_TARGET_FLXCAMERA)
				{
					gl_FragColor = texture2D(bitmap, openfl_TextureCoordv);
				}
			}
		}')
	public function new()
	{
		super();
	}
}
