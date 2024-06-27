package hxcodec.flixel;

class FlxVideo extends hxvlc.flixel.FlxVideo
{
  public function new()
  {
    super(true);

    onTextureSetup = new lime.app.Event<Void->Void>();
    onFormatSetup.add(onTextureSetup.dispatch);
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
