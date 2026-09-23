package funkin.graphics.shaders;

import flixel.graphics.tile.FlxGraphicsShader;

// It's not used anywhere, but i'll just leave it.
class MultiBufferShader extends FlxGraphicsShader
{
  @:glFragmentSource('
    #pragma header

    void main()
    {
      gl_FragColor = flixel_texture2D(bitmap, openfl_TextureCoordv);
    }')
  public function new()
  {
    super();
  }
}
