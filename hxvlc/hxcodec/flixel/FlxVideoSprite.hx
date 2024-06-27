package hxcodec.flixel;

class FlxVideoSprite extends hxvlc.flixel.FlxVideoSprite
{
  public function new(?x:Float = 0.0, ?y:Float = 0.0)
  {
    super(x, y);

    bitmap.onTextureSetup = new lime.app.Event<Void->Void>();
    bitmap.onFormatSetup.add(bitmap.onTextureSetup.dispatch);
  }

  override public function play(?location:String, ?shouldLoop:Bool):Bool
  {
    if (shouldLoop == null) shouldLoop = false;

    if (load(location, shouldLoop ? [":input-repeat=65535"] : null))
    {
      super.play();
      return true;
    }

    return false;
  }
}
