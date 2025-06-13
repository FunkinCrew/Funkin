package funkin.ui.charSelect;

import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;

class CharSelectPlayer extends FlxAtlasSprite implements IBPMSyncedScriptedClass
{
  var initialX:Float = 0;
  var initialY:Float = 0;

  public function new(x:Float, y:Float)
  {
    initialX = x;
    initialY = y;

    super(x, y, Paths.animateAtlas("charSelect/bfChill"));

    onAnimationComplete.add(function(animLabel:String) {
      switch (animLabel)
      {
        case "slidein":
          if (hasAnimation("slidein idle point"))
          {
            playAnimation("slidein idle point", true, false, false);
          }
          else
          {
            playAnimation("idle", true, false, false);
          }
        case "deselect":
          playAnimation("deselect loop start", true, false, true);

        case "slidein idle point", "cannot select Label", "unlock":
          playAnimation("idle", true, false, false);
        case "idle":
          trace('Waiting for onBeatHit');
      }
    });
  }

  public function onStepHit(event:SongTimeScriptEvent):Void {}

  public function onBeatHit(event:SongTimeScriptEvent):Void
  {
    // TODO: There's a minor visual bug where there's a little stutter.
    // This happens because the animation is getting restarted while it's already playing.
    // I tried make this not interrupt an existing idle,
    // but isAnimationFinished() and isLoopComplete() both don't work! What the hell?
    // danceEvery isn't necessary if that gets fixed.
    //
    if (getCurrentAnimation() == "idle")
    {
      playAnimation("idle", true, false, false);
    }
  };

  public function updatePosition(str:String)
  {
    switch (str)
    {
      case "bf" | 'pico' | "random":
        x = initialX;
        y = initialY;
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

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};
}
