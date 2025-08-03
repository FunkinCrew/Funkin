package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;
import flixel.FlxSprite;
import flixel.math.FlxAngle;
import flixel.graphics.frames.FlxFrame;
import openfl.display.BitmapData;

/*
  A screenspace version of the DropShadowShader.. currently the only way to use this effect with
  FlxAnimate :(
 */
class DropShadowScreenspace extends DropShadowShader
{
  /*
    The current zoom of the camera. Needed to figure out how much to multiply the drop shadow size.
   */
  public var curZoom(default, set):Float;

  function set_curZoom(val:Float):Float
  {
    curZoom = val;
    zoom.value = [val];
    return val;
  }

  @:glFragmentSource('
      #pragma header

      // This shader aims to mostly recreate how Adobe Animate/Flash handles drop shadows, but its main use here is for rim lighting.

      // this shader also includes a recreation of the Animate/Flash "Adjust Color" filter,
      // which was kindly provided and written by Rozebud https://github.com/ThatRozebudDude ( thank u rozebud :) )
      // Adapted from Andrey-Postelzhuks shader found here: https://forum.unity.com/threads/hue-saturation-brightness-contrast-shader.260649/
      // Hue rotation stuff is from here: https://www.w3.org/TR/filter-effects/#feColorMatrixElement

      // equals (frame.left, frame.top, frame.right, frame.bottom)
      uniform vec4 uFrameBounds;

      uniform float ang;
      uniform float dist;
      uniform float str;
      uniform float thr;

      // need to account for rotated frames... oops
      uniform float angOffset;

      uniform sampler2D altMask;
      uniform bool useMask;
      uniform float thr2;

      uniform vec3 dropColor;

      uniform float hue;
      uniform float saturation;
      uniform float brightness;
      uniform float contrast;

      uniform float zoom;

      uniform float AA_STAGES;

      const vec3 grayscaleValues = vec3(0.3098039215686275, 0.607843137254902, 0.0823529411764706);
		  const float e = 2.718281828459045;

		  vec3 applyHueRotate(vec3 aColor, float aHue){
			  float angle = radians(aHue);

			  mat3 m1 = mat3(0.213, 0.213, 0.213, 0.715, 0.715, 0.715, 0.072, 0.072, 0.072);
			  mat3 m2 = mat3(0.787, -0.213, -0.213, -0.715, 0.285, -0.715, -0.072, -0.072, 0.928);
			  mat3 m3 = mat3(-0.213, 0.143, -0.787, -0.715, 0.140, 0.715, 0.928, -0.283, 0.072);
			  mat3 m = m1 + cos(angle) * m2 + sin(angle) * m3;

			  return m * aColor;
		  }

		  vec3 applySaturation(vec3 aColor, float value){
			  if(value > 0.0){ value = value * 3.0; }
			  value = (1.0 + (value / 100.0));
			  vec3 grayscale = vec3(dot(aColor, grayscaleValues));
        return clamp(mix(grayscale, aColor, value), 0.0, 1.0);
		  }

		  vec3 applyContrast(vec3 aColor, float value){
			  value = (1.0 + (value / 100.0));
			  if(value > 1.0){
				  value = (((0.00852259 * pow(e, 4.76454 * (value - 1.0))) * 1.01) - 0.0086078159) * 10.0; //Just roll with it...
				  value += 1.0;
			  }
        return clamp((aColor - 0.25) * value + 0.25, 0.0, 1.0);
		  }

      vec3 applyHSBCEffect(vec3 color){

			  //Brightness
			  color = color + ((brightness) / 255.0);

			  //Hue
			  color = applyHueRotate(color, hue);

			  //Contrast
			  color = applyContrast(color, contrast);

			  //Saturation
        color = applySaturation(color, saturation);

        return color;
      }

      vec2 hash22(vec2 p) {
        vec3 p3 = fract(vec3(p.xyx) * vec3(.1031, .1030, .0973));
        p3 += dot(p3, p3.yzx + 33.33);
        return fract((p3.xx + p3.yz) * p3.zy);
      }

      float intensityPass(vec2 fragCoord, float curThreshold, bool useMask) {
        vec4 col = texture2D(bitmap, fragCoord);

        float maskIntensity = 0.0;
        if(useMask == true){
          maskIntensity = mix(0.0, 1.0, texture2D(altMask, fragCoord).b);
        }

        if(col.a == 0.0){
          return 0.0;
        }

        float intensity = dot(col.rgb, vec3(0.3098, 0.6078, 0.0823));

        intensity = maskIntensity > 0.0 ? float(intensity > thr2) : float(intensity > thr);

        return intensity;
      }

       // essentially just stole this from the AngleMask shader but repurposed it to smooth
      // the threshold because without any sort of smoothing it produces horrible edges
      float antialias(vec2 fragCoord, float curThreshold, bool useMask) {
        if (AA_STAGES == 0.0) {
          return intensityPass(fragCoord, curThreshold, useMask);
        }

        // In GLSL 100, we need to use constant loop bounds
        // Well assume a reasonable maximum for AA_STAGES and use a fixed loop
        // The actual number of iterations will be controlled by a condition inside
        const int MAX_AA = 8; // This should be large enough for most uses

        float AA_TOTAL_PASSES = AA_STAGES * AA_STAGES + 1.0;
        const float AA_JITTER = 0.5;

        // Run the shader multiple times with a random subpixel offset each time and average the results
        float color = intensityPass(fragCoord, curThreshold, useMask);
        for (int i = 0; i < MAX_AA * MAX_AA; i++) {
          // Calculate x and y from i
          int x = i / MAX_AA;
          int y = i - (MAX_AA * int(i/MAX_AA)); // poor mans modulus

          // Skip iterations beyond our desired AA_STAGES
          if (float(x) >= AA_STAGES || float(y) >= AA_STAGES) {
            continue;
          }

          vec2 offset = AA_JITTER * (2.0 * hash22(vec2(float(x), float(y))) - 1.0) / openfl_TextureSize.xy;
          color += intensityPass(fragCoord + offset, curThreshold, useMask);
        }

        return color / AA_TOTAL_PASSES;
      }

      vec3 createDropShadow(vec3 col, float curThreshold, bool useMask) {

        // essentially a mask so that areas under the threshold dont show the rimlight (mainly the outlines)
        float intensity = antialias(openfl_TextureCoordv, curThreshold, useMask);

        // the distance the dropshadow moves needs to be correctly scaled based on the texture size
        vec2 imageRatio = vec2(1.0/openfl_TextureSize.x, 1.0/openfl_TextureSize.y);

        // check the pixel in the direction and distance specified
        vec2 checkedPixel = vec2(openfl_TextureCoordv.x + ((dist*zoom) * cos(ang + angOffset) * imageRatio.x), openfl_TextureCoordv.y - ((dist*zoom) * sin(ang + angOffset) * imageRatio.y));

        // multiplier for the intensity of the drop shadow
        float dropShadowAmount = 0.0;

        dropShadowAmount = texture2D(bitmap, checkedPixel).a;

        // add the dropshadow color  based on the amount, strength, and intensity
        col.rgb += dropColor.rgb * ((1.0 - (dropShadowAmount * str))*intensity);

        return col;
      }

      void main()
      {
        vec4 col = texture2D(bitmap, openfl_TextureCoordv);

        vec3 unpremultipliedColor = col.a > 0.0 ? col.rgb / col.a : col.rgb;

        vec3 outColor = applyHSBCEffect(unpremultipliedColor);

        outColor = createDropShadow(outColor, thr, useMask);

        gl_FragColor = vec4(outColor.rgb * col.a, col.a);
      }

    ')
  override public function new()
  {
    super();

    angle = 90;
    strength = 1;
    distance = 15;
    threshold = 0.1;

    baseHue = 0;
    baseSaturation = 0;
    baseBrightness = 0;
    baseContrast = 0;

    useAltMask = false;

    color = 0xFFDFEF3C;

    antialiasAmt = 2;

    curZoom = 1;

    angOffset.value = [0];
  }
}
