package funkin.graphics.shaders;

import flixel.system.FlxAssets.FlxShader;

class AngleMask extends FlxShader
{
  @:glFragmentSource('
		#pragma header
        uniform vec2 endPosition;
		void main()
		{
			vec4 base = texture2D(bitmap, openfl_TextureCoordv);

            vec2 uv = openfl_TextureCoordv.xy;



            vec2 start = vec2(0.0, 0.0);
            vec2 end = vec2(endPosition.x / openfl_TextureSize.x, 1.0);

            float dx = end.x - start.x;
            float dy = end.y - start.y;

            float angle = atan(dy, dx);

            uv.x -= start.x;
            uv.y -= start.y;

            float uvA = atan(uv.y, uv.x);

            if (uvA < angle)
                gl_FragColor = base;
            else
                gl_FragColor = vec4(0.0);

		}')
  public function new()
  {
    super();

    endPosition.value = [90, 100]; // 100 AS DEFAULT WORKS NICELY FOR FREEPLAY?
  }
}
