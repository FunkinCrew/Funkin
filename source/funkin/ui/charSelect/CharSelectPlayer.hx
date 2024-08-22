package funkin.ui.charSelect;

import flixel.FlxSprite;
import funkin.graphics.adobeanimate.FlxAtlasSprite;

class CharSelectPlayer extends FlxAtlasSprite
{
  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("charSelect/bfChill"));

    onAnimationComplete.add(function(animLabel:String) {
      if (hasAnimation("slidein idle point")) playAnimation("slidein idle point", true, false, false);
      else
        playAnimation("idle");
    });
  }

  var _addedCall = false;

  override public function playAnimation(id:String, restart:Bool = false, ignoreOther:Bool = false, loop:Bool = false, startFrame:Int = 0):Void
  {
    if (id == null || id == "") id = "idle";
    switch (id)
    {
      case "idle", "slidein idle point":
        if (!_addedCall)
        {
          var fr = anim.getFrameLabel("idle end");
          if (fr != null) fr.add(() -> {
            playAnimation("idle", true, false, false);
          });
        }
        _addedCall = true;

      case "select":
        if (_addedCall)
        {
          anim.getFrameLabel("idle end").removeCallbacks();
          _addedCall = false;
        }

        var fr = anim.getFrameLabel("deselect");

        fr.add(() -> {
          anim.pause();
          anim.curFrame--;
        });

        _addedCall = true;

      case "deselect":
        var og = anim.getFrameLabel("deselect");
        if (_addedCall)
        {
          og.removeCallbacks();
          _addedCall = false;
        }

        var fr = anim.getFrameLabel("deselect loop end");

        fr.removeCallbacks();
        fr.add(() -> playAnimation("deselect loop start", true, false, false));

        _addedCall = true;

      case "slidein", "slideout":
        if (_addedCall)
        {
          anim.getFrameLabel("deselect loop end").removeCallbacks();
          _addedCall = false;
        }
      default:
        if (_addedCall)
        {
          anim.getFrameLabel("idle end").removeCallbacks();
          _addedCall = false;
        }
    }
    super.playAnimation(id, restart, ignoreOther, loop, startFrame);
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

    updateHitbox();

    updatePosition(str);
  }
}
