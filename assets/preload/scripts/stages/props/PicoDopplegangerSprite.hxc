import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.math.FlxPoint;
import flixel.FlxSprite;
import funkin.graphics.FunkinSprite;
import funkin.play.PlayState;
import flixel.util.FlxTimer;
import flixel.util.FlxTimerManager;
import flixel.FlxG;
import funkin.audio.FunkinSound;

class PicoDopplegangerSprite extends FlxAtlasSprite
{

  public var isPlayer:Bool = false;
  var suffix:String = '';

  public function new(x:Float, y:Float)
  {
    super(x, y, Paths.animateAtlas("philly/erect/pico_doppleganger", "week3"), {
      FrameRate: 24.0,
      Reversed: false,
      // ?OnComplete:Void -> Void,
      ShowPivot: false,
      Antialiasing: true,
      ScrollFactor: new FlxPoint(1, 1),
    });
  }

  var cutsceneSounds:FunkinSound = null;

  public function cancelSounds(){
    if(cutsceneSounds != null) cutsceneSounds.destroy();
  }

  public function doAnim(_suffix:String, shoot:Bool = false, explode:Bool = false, timerManager:FlxTimerManager){
    suffix = _suffix;

    trace('Doppelganger: doAnim(' + suffix + ', ' + shoot + ', ' + explode + ')');

    new FlxTimer(timerManager).start(0.3, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoGasp'), 1.0, false, true, true);});

    if(shoot == true){
      playAnimation("shoot" + suffix, true, false, false);

      new FlxTimer(timerManager).start(6.29, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoShoot'), 1.0, false, true, true);});
      new FlxTimer(timerManager).start(10.33, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoSpin'), 1.0, false, true, true);});
    }else{
      if(explode == true){
        playAnimation("explode" + suffix, true, false, false);

        onAnimationComplete.add(startLoop);

        new FlxTimer(timerManager).start(3.7, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoCigarette2'), 1.0, false, true, true);});
        new FlxTimer(timerManager).start(8.75, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoExplode'), 1.0, false, true, true);});
      }else{
        playAnimation("cigarette" + suffix, true, false, false);

        new FlxTimer(timerManager).start(3.7, _ -> {cutsceneSounds = FunkinSound.load(Paths.sound('cutscene/picoCigarette'), 1.0, false, true, true);});
      }
    }
  }

  function startLoop(){
    playAnimation("loop" + suffix, true, false, true);
  }
}
