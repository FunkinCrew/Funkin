import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import flixel.FlxG;

// a unique object for santa getting KILLED

class SantaDiesSprite extends FlxAtlasSprite
{

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("christmas/santa_speaks_assets", "week5"), {
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: new FlxPoint(1, 1),
    });

   // onAnimationFinish.add(finishCanAnimation);
  }

  public function playCutscene():Void {
    //this.visible = true;
    this.playAnimation("santa whole scene", false, false, false, 0);
    onAnimationComplete.add(onFinishAnim);

  }

  function onFinishAnim():Void
  {
    this.anim.pause();
  }
}
