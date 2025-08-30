package funkin.ui.charSelect;

import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;
import funkin.ui.FullScreenScaleMode;
import flixel.math.FlxPoint;

class CharSelectPlayer extends FunkinSprite implements IBPMSyncedScriptedClass
{
  var initialX:Float = 0;
  var initialY:Float = 0;

  public function new(x:Float, y:Float)
  {
    initialX = x;
    initialY = y;

    super(x, y);

    loadTextureAtlas("charSelect/bfChill",
      {
        applyStageMatrix: true,
        swfMode: true
      });

    anim.onFinish.add(function(animLabel:String) {
      switch (animLabel)
      {
        case "slidein":
          if (hasAnimation("slidein idle point"))
          {
            anim.play("slidein idle point", true);
          }
          else
          {
            anim.play("idle", true);
            anim.curAnim.looped = true;
          }
        case "deselect":
          anim.play("deselect loop start", true);
        case "slidein idle point", "cannot select Label", "unlock":
          anim.play("idle", true);
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
      anim.play("idle", true);
    }
  };

  public function updatePosition():Void
  {
    // offset the position such that it's positioned exactly like in Adobe Animate
    var bounds:FlxPoint = this.timeline.getBoundsOrigin(true);

    x = initialX + bounds.x;
    y = initialY + bounds.y;
  }

  public function switchChar(str:String):Void
  {
    frames = CharSelectAtlasHandler.loadAtlas('charSelect/${str}Chill');

    anim.play("slidein", true);

    updateHitbox();

    updatePosition();
  }

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};
}
