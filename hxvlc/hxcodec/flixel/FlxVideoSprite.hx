package hxcodec.flixel;

class FlxVideoSprite extends hxvlc.flixel.FlxVideoSprite
{
  public function new(x:Float = 0.0, y:Float = 0.0)
  {
    super(x, y);

    bitmap.onTextureSetup = new lime.app.Event<Void->Void>();
    bitmap.onFormatSetup.add(bitmap.onTextureSetup.dispatch);
  }

  overload extern inline public function play(location:String, shouldLoop:Bool = false):Int
  {
    if (load(location, shouldLoop ? [":input-repeat=65535"] : null))
    {
      playVideo();
      return 0;
    }

    return 1;
  }

  @:noCompletion
  private function playVideo()
  {
    super.play();
  }
}
