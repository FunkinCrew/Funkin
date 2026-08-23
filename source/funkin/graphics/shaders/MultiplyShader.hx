package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;
import flixel.util.FlxColor;

class MultiplyShader extends FlxShader
{
    @:glFragmentSource('
        #pragma header
        uniform vec4 uBlendColor;

        void main()
        {
            vec4 base = texture2D(bitmap, openfl_TextureCoordv);

            vec3 rgb = mix(base.rgb, base.rgb * uBlendColor.rgb, uBlendColor.a);

            gl_FragColor = vec4(rgb, base.a);
        }')

      public function new()
      {
        super();
      }

    public function set_blendColor(color:FlxColor):FlxColor
    {
        uBlendColor.value = [color.red / 255, color.green / 255, color.blue / 255, color.alpha / 255];
        return color;
    }
}