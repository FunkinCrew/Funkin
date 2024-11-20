import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import flixel.FlxG;

// a unique object for santa getting KILLED

class DadShootsSprite extends FlxAtlasSprite
{

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("christmas/parents_shoot_assets", "week5"), {
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
    this.playAnimation("parents whole scene", false, false, false, 0);
    this.onAnimationComplete.add(onFinishAnim);

  }

  function onFinishAnim():Void
  {
    this.anim.pause();
  }
}
