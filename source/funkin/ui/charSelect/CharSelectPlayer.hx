package funkin.ui.charSelect;

import funkin.graphics.FunkinSprite;
import funkin.modding.IScriptedClass.IBPMSyncedScriptedClass;
import funkin.modding.events.ScriptEvent;

@:nullSafety
class CharSelectPlayer extends FunkinSprite implements IBPMSyncedScriptedClass
{
  static final DEFAULT_PATH = "charSelect/bfChill";

  var initialX:Float = 0;
  var initialY:Float = 0;

  var currentBFPath:Null<String>;

  public function new(x:Float, y:Float)
  {
    initialX = x;
    initialY = y;

    super(x, y);

    loadTextureAtlas(DEFAULT_PATH,
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

          // TODO: once char select data is refactored, add a `shouldBop` field or something IDK
          if (currentBFPath != null)
          {
            if (currentBFPath.endsWith("locked"))
            {
              anim.curAnim.looped = true;
            }
          }
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
    if (getCurrentAnimation() == "idle" && isAnimationFinished())
    {
      anim.play("idle", true);
    }
  };

  public function switchChar(str:String, playSlideAnim:Bool = true):Void
  {
    var texture:Null<animate.FlxAnimateFrames> = CharSelectAtlasHandler.loadAtlas('charSelect/${str}Chill');

    if (texture != null)
    {
      frames = texture;
    }
    else
    {
      trace('Failed to load character atlas for ${str}');
      return;
    }

    final animName:String = playSlideAnim ? "slidein" : "idle";
    anim.play(animName, true);

    updateHitbox();
  }

  public function onScriptEvent(event:ScriptEvent):Void {};

  public function onCreate(event:ScriptEvent):Void {};

  public function onDestroy(event:ScriptEvent):Void {};

  public function onUpdate(event:UpdateScriptEvent):Void {};
}
