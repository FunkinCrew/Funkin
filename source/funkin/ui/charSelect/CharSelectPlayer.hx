package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class CharSelectPlayer extends FlxAtlasSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("charSelect/bfChill"));

    onAnimationComplete.add(function(animLabel:String) {
      switch (animLabel)
      {
        case "slidein":
          if (hasAnimation("slidein idle point")) playAnimation("slidein idle point", true, false, false);
          else
            playAnimation("idle", true, false, true);
        case "slidein idle point":
          playAnimation("idle", true, false, true);
        case "select":
          anim.pause();
        case "deselect":
          playAnimation("deselect loop start", true, false, true);
      }
    });
  }

  public function updatePosition(str:String)
  {
    switch (str)
    {
      case "bf":
        x = 0;
        y = 0;
      case "pico":
        x = 0;
        y = 0;
      case "random":
    }
  }

  public function switchChar(str:String)
  {
    switch str
    {
      default:
        loadAtlas(Paths.animateAtlas("charSelect/" + str + "Chill"));
    }

    anim.play("");
    playAnimation("slidein", true, false, false);

    updateHitbox();

    updatePosition(str);
  }
}
