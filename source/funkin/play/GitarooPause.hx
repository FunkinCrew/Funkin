package funkin.play;

import flixel.FlxSprite;
import flixel.graphics.frames.FlxAtlasFrames;
import funkin.play.PlayState;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import flixel.addons.transition.FlxTransitionableState;
import funkin.ui.mainmenu.MainMenuState;

class GitarooPause extends MusicBeatState
{
  var replayButton:FlxSprite;
  var cancelButton:FlxSprite;

  var replaySelect:Bool = false;

  var previousParams:PlayStateParams;

  public function new(previousParams:PlayStateParams):Void
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

    var bg:FunkinSprite = FunkinSprite.create('pauseAlt/pauseBG');
    add(bg);

    var bf:FunkinSprite = FunkinSprite.createSparrow(0, 30, 'pauseAlt/bfLol');
    bf.animation.addByPrefix('lol', "funnyThing", 13);
    bf.animation.play('lol');
    add(bf);
    bf.screenCenter(X);

    replayButton = FunkinSprite.createSparrow(FlxG.width * 0.28, FlxG.height * 0.7, 'pauseAlt/pauseUI');
    replayButton.animation.addByPrefix('selected', 'bluereplay', 0, false);
    replayButton.animation.appendByPrefix('selected', 'yellowreplay');
    replayButton.animation.play('selected');
    add(replayButton);

    cancelButton = FunkinSprite.createSparrow(FlxG.width * 0.58, replayButton.y, 'pauseAlt/pauseUI');
    cancelButton.animation.addByPrefix('selected', 'bluecancel', 0, false);
    cancelButton.animation.appendByPrefix('selected', 'cancelyellow');
    cancelButton.animation.play('selected');
    add(cancelButton);

    changeThing();

    super.create();
  }

  override function update(elapsed:Float):Void
  {
    if (controls.UI_LEFT_P || controls.UI_RIGHT_P) changeThing();

    if (controls.ACCEPT)
    {
      if (replaySelect)
      {
        FlxTransitionableState.skipNextTransIn = false;
        FlxTransitionableState.skipNextTransOut = false;
        FlxG.switchState(() -> new PlayState(previousParams));
      }
      else
      {
        FlxG.switchState(() -> new MainMenuState());
      }
    }

    super.update(elapsed);
  }

  function changeThing():Void
  {
    replaySelect = !replaySelect;

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
  }
}
