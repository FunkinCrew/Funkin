package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flxanimate.animate.FlxKeyFrame;

class CharSelectPlayer extends FlxAtlasSprite
{
  var desLp:FlxKeyFrame = null;

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("charSelect/bfChill"));

    desLp = anim.getFrameLabel("deselect loop start");

    onAnimationComplete.add(function(animLabel:String) {
      switch (animLabel)
      {
        case "slidein":
          if (hasAnimation("slidein idle point")) playAnimation("slidein idle point", true, false, false);
          else
            playAnimation("idle", true, false, true);
        case "slidein idle point", "cannot select", "unlock":
          playAnimation("idle", true, false, true);
      }
    });

    onAnimationFrame.add(function(animLabel:String, frame:Int) {
      if (animLabel == "deselect" && desLp != null && frame >= desLp.index) playAnimation("deselect loop start", true, false, true);
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

    playAnimation("slidein", true, false, false);

    desLp = anim.getFrameLabel("deselect loop start");

    updateHitbox();

    updatePosition(str);
  }
}
