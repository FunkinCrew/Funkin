package funkin.graphics.framebuffer;

import flixel.FlxCamera;
import funkin.graphics.FunkinSprite;

/**
 * Stub. The drop shadow effect of the mod menu is not ported yet, so this layer draws nothing.
 * It keeps the same API so the mod menu compiles.
 */
class DropShadowLayer extends FunkinSprite
{
  public var renderer(default, null):DropShadowRendererStub;

  public function new(camera:FlxCamera, color:Int = 0, distance:Float = 0, alpha:Float = 0)
  {
    super();
    this.renderer = new DropShadowRendererStub();
  }
}

class DropShadowRendererStub
{
  public function new() {}

  public function blacklistSprite(sprite:Dynamic):Void {}

  public function whitelistSprite(sprite:Dynamic):Void {}
}
