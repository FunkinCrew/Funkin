package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class ScreenWipeShader extends FlxShader
{
  public var daAlphaShit(default, set):Float = 0;

  function set_daAlphaShit(alpha:Float):Float
  {
    alphaShit.value[0] = alpha;

    return alpha;
  }

  @:glFragmentSource('
        #pragma header

        uniform float alphaShit;
		uniform float yPos;
		uniform float xPos;

		uniform sampler2D funnyShit;


        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        vec3 hsv2rgb(vec3 c)
        {
            vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
            vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
            return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
        }

        void main()
        {
			vec2 funnyUv = openfl_TextureCoordv;
            vec4 color = flixel_texture2D(bitmap, funnyUv);

			vec2 reallyFunnyUv = vec2(vec2(0.0, 0.0) - gl_FragCoord.xy / openfl_TextureSize.xy);

			vec4 gf = flixel_texture2D(funnyShit, openfl_TextureCoordv);


            vec3 hsvTypeBeat = rgb2hsv(vec3(gf.r, gf.g, gf.b));

			vec4 output = color;

            // .b here actually means value?
			if (hsvTypeBeat.b <= alphaShit)
				color = vec4(0.0, 0.0, 0.0, 0.0);


            gl_FragColor = color;
        }
    ')
  public function new()
  {
    super();

    alphaShit.value = [0];
  }
}
