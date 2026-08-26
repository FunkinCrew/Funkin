package funkin.graphics;

import lime.graphics.opengl.GLTexture;
import openfl.display3D.Context3D;
import openfl.display3D.textures.TextureBase;

/**
 * The few things about the graphics card the engine keeps to itself.
 */
class GpuTexture
{
  public static function handleOf(texture:TextureBase):Null<GLTexture>
  {
    if (texture == null) return null;
    return @:privateAccess texture.__textureID;
  }

  /**
   * Makes the renderer stop trusting what it remembers about the card.
   */
  public static function forgetBindings(context:Context3D):Void
  {
    if (context == null) return;

    @:privateAccess
    {
      var state = context.__contextState;
      if (state == null) return;

      state.__currentGLArrayBuffer = null;
      state.__currentGLElementArrayBuffer = null;
      state.__currentGLFramebuffer = null;
      state.__currentGLTexture2D = null;
      state.__currentGLTextureCubeMap = null;
      state.program = null;
      state.shader = null;
    }
  }
}
