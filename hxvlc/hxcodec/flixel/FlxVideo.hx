package hxcodec.flixel;

class FlxVideo extends hxvlc.flixel.FlxVideo
{
  public function new()
  {
    super(true);

    onTextureSetup = new lime.app.Event<Void->Void>();
    onFormatSetup.add(onTextureSetup.dispatch);
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
