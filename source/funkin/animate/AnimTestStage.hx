package funkin.animate;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;

class AnimTestStage extends FlxState
{
  var tl:AnimateTimeline;
  var swag:FlxAnimate;

  override function create()
  {
    var bg:FlxSprite = FlxGridOverlay.create(32, 32);
    add(bg);
    bg.scrollFactor.set();

    swag = new FlxAnimate(200, 200);
    add(swag);

    tl = new AnimateTimeline(Paths.file('images/tightBarsLol/Animation.json'));
    add(tl);

    super.create();
  }

  override function update(elapsed:Float)
  {
    tl.curFrame = swag.daFrame;

    CoolUtil.mouseWheelZoom();
    CoolUtil.mouseCamDrag();

    super.update(elapsed);
  }
}
