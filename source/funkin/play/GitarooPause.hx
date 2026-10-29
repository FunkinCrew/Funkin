package funkin.play;

import funkin.ui.transition.Transition;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import funkin.play.PlayState.PlayStateParams;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import funkin.ui.mainmenu.MainMenuState;
import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.assets.ValidatedPaths as Paths;
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end

class GitarooPause extends MusicBeatState
{
  var replayButton:FlxSprite;
  var cancelButton:FlxSprite;
  var replaySelect(default, set):Bool = false;
  var previousParams:Null<PlayStateParams>;
  var lock:Bool = false;

  public static function queryAssets(type:AssetType):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];

    switch (type)
    {
      case IMAGE:
        results.appendUnique([
          Paths.image('ui/pause/alternate/pause-bg'),
          Paths.image('ui/pause/alternate/bf-lol'),
          Paths.image('ui/pause/alternate/pause-ui')
        ]);
      case XML:
        results.appendUnique([
          Paths.xml('ui/pause/alternate/bf-lol'),
          Paths.xml('ui/pause/alternate/pause-ui')
        ]);
      default:
    }

    return results;
  }

  public function new(?previousParams:PlayStateParams):Void
  {
    super();

    this.previousParams = previousParams;
  }

  override function create():Void
  {
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    var bg:FunkinSprite = new FunkinSprite().loadTexture('ui/pause/alternate/pause-bg');
    bg.setGraphicSize(Std.int(FlxG.width));
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    var bf:FunkinSprite = new FunkinSprite(0, 30).loadSparrow('ui/pause/alternate/bf-lol');
    bf.animation.addByPrefix('lol', "funnyThing", 13);
    bf.animation.play('lol');
    bf.screenCenter(X);
    add(bf);

    replayButton = new FunkinSprite(FlxG.width * 0.25, FlxG.height * 0.7).loadSparrow('ui/pause/alternate/pause-ui');
    replayButton.animation.addByPrefix('selected', 'bluereplay', 0, false);
    replayButton.animation.appendByPrefix('selected', 'yellowreplay');
    replayButton.animation.play('selected');
    replayButton.updateHitbox();
    add(replayButton);

    cancelButton = new FunkinSprite(FlxG.width * 0.58, replayButton.y).loadSparrow('ui/pause/alternate/pause-ui');
    cancelButton.animation.addByPrefix('selected', 'bluecancel', 0, false);
    cancelButton.animation.appendByPrefix('selected', 'cancelyellow');
    cancelButton.animation.play('selected');
    cancelButton.updateHitbox();
    add(cancelButton);

    changeThing();

    super.create();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (lock) return;

    if (controls.UI_LEFT_P || controls.UI_RIGHT_P) changeThing();

    if (controls.ACCEPT_P)
    {
      selectThing();
    }

    #if FEATURE_TOUCH_CONTROLS
    handleTouch();
    #end
  }

  #if FEATURE_TOUCH_CONTROLS
  function handleTouch():Void
  {
    if (TouchUtil.pressAction(replayButton))
    {
      if (replaySelect)
      {
        selectThing();

        return;
      }

      replaySelect = true;
    }
    else if (TouchUtil.pressAction(cancelButton))
    {
      if (!replaySelect)
      {
        selectThing();

        return;
      }

      replaySelect = false;
    }
  }
  #end

  function selectThing():Void
  {
    lock = true;

    if (replaySelect)
    {
      if (funkin.ui.FullScreenScaleMode.instance != null) funkin.ui.FullScreenScaleMode.instance.onMeasurePostAwait();

      funkin.ui.transition.Transition.openPlayState(previousParams, {
        transition: None
      }, false);
    }
    else
    {
      Transition.switchState(() -> new MainMenuState(), {
        assetQuery: MainMenuState.queryAssets,
        transition: BlackScreen(None, None)
      });
    }
  }

  function changeThing():Void
  {
    replaySelect = !replaySelect;
  }

  function set_replaySelect(value:Bool):Bool
  {
    replaySelect = value;

    if (replaySelect)
    {
      cancelButton.animation.curAnim.curFrame = 0;
      replayButton.animation.curAnim.curFrame = 1;
    }
    else
    {
      cancelButton.animation.curAnim.curFrame = 1;
      replayButton.animation.curAnim.curFrame = 0;
    }

    return replaySelect;
  }
}
