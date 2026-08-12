package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

class MultiBufferShader extends FlxGraphicsShader
{
  @:glFragmentSource('
		#pragma header

		void main()
		{
			vec4 color = flixel_texture2D(bitmap, openfl_TextureCoordv);
      gl_FragData[0] = color;

      if (sampleAttachment)
      {
        gl_FragData[1] = color;
      }
      else
      {
        gl_FragData[1] = vec4(0.0, 0.0, 0.0, 0.0);
      }
		}')
  public function new()
  {
    super();
  }
}
