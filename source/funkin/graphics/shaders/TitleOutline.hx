package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class TitleOutline extends FlxShader
{
  public var funnyX(default, set):Float = 0;
  public var funnyY(default, set):Float = 0;

  function set_funnyX(x:Float):Float
  {
    xPos.value[0] = x;

    return x;
  }

  function set_funnyY(y:Float):Float
  {
    yPos.value[0] = y;

    return y;
  }

  @:glFragmentSource('
        #pragma header

        // uniform float alphaShit;
        uniform float xPos;
        uniform float yPos;

        uniform int numoutlines = 1;

        vec3 rgb2hsv(vec3 c)
        {
            vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
            vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
            vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

            float d = q.x - min(q.w, q.y);
            float e = 1.0e-10;
            return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
        }

        void main()
        {
            vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
            vec2 size = vec2(xPos, yPos);

            if (color.a == 0.0) {
                float w = size.x / openfl_TextureSize.x;
                float h = size.y / openfl_TextureSize.y;

                vec4 colorOffset = flixel_texture2D(bitmap, vec2(openfl_TextureCoordv.x - w, openfl_TextureCoordv.y - h));


                vec3 hsvShit = rgb2hsv(vec3(colorOffset.r, colorOffset.g, colorOffset.b));

                if (hsvShit.b <= 0.1 && colorOffset.a != 0.)
                    color = vec4(0.0, 1.0, 0.8, color.a);
            }

            gl_FragColor = color;
        }

    ')
  public function new()
  {
    super();

    xPos.value = [0];
    yPos.value = [0];
  }
}
