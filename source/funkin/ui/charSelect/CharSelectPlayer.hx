package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class CharSelectPlayer extends FlxAtlasSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("charSelect/bfChill"));

    trace('Initialized CharSelectPlayer');

    trace(listAnimations());

    onAnimationComplete.add(function(animLabel:String) {
      trace('Completed CharSelectPlayer animation: ' + animLabel);
      switch (animLabel)
      {
        case "slidein":
          // Completed the slide-in.
          if (hasAnimation("slidein idle point"))
          {
            // Play the idle animation from a specific spot.
            playAnimation("slidein idle point", true, false, false);
          }
          else
          {
            // Play the idle animation.
            playAnimation("idle", true, false, true);
          }
        case "slidein idle point":
          // Play the idle animation.
          playAnimation("idle", true, false, true);
        case "select":
          trace('Pausing animation...');
          // Pause the animation on the last frame (don't loop).
          anim.pause();
        case "deselect":
          // Go to the deselect loop point.
          playAnimation("deselect loop start", true, false, true);
        default:
          // Do nothing.
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
    switch (str)
    {
      default:
        loadAtlas(Paths.animateAtlas('charSelect/${str}Chill'));
    }

    anim.play("");

    playAnimation("slidein", true, false, false);

    updateHitbox();

    updatePosition(str);
  }
}
