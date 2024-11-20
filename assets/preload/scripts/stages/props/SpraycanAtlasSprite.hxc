import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;

class SpraycanAtlasSprite extends FlxAtlasSprite
{
	public var STATE_ARCING:Int = 2; // In the air.
	public var STATE_SHOT:Int = 3; // Hit by the player.
	public var STATE_IMPACTED:Int = 4; // Impacted the player.

  public var currentState:Int = 2;

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("spraycanAtlas", "weekend1"), {
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: new FlxPoint(1, 1),
    });

    onAnimationComplete.add(finishCanAnimation);
  }

  public function finishCanAnimation(name:String) {
    switch(name) {
      case 'Can Start':
        playHitPico();
      case 'Can Shot':
        this.kill();
      case 'Hit Pico':
        playHitExplosion();
        this.kill();
    }
  }

  public function playHitExplosion():Void {
    var explodeEZ:FunkinSprite = FunkinSprite.createSparrow(this.x + 1050, this.y + 150, "spraypaintExplosionEZ");
		explodeEZ.animation.addByPrefix("idle", "explosion round 1 short0", 24, false);
		explodeEZ.animation.play("idle");

		PlayState.instance.currentStage.add(explodeEZ);
		explodeEZ.animation.finishCallback = () -> {
      explodeEZ.kill();
    };
  }

  public function playCanStart():Void {
    this.playAnimation('Can Start');
  }

  public function playCanShot():Void {
    this.playAnimation('Can Shot');
  }

  public function playHitPico():Void {
    this.playAnimation('Hit Pico');
  }
}
