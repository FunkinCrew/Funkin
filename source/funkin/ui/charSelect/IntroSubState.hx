package funkin.ui.charSelect;

#if html5
import funkin.graphics.video.FlxVideo;
#end
#if hxvlc
import funkin.graphics.video.FunkinVideoSprite;
#end
import funkin.ui.MusicBeatSubState;
import funkin.save.Save;

/**
 * When you first enter the character select state, it will play an introductory video opening up the lights
 */
class IntroSubState extends MusicBeatSubState
{
  #if html5
  static final LIGHTS_VIDEO_PATH:String = Paths.stripLibrary(Paths.videos('introSelect'));
  #end

  #if hxvlc
  static final LIGHTS_VIDEO_PATH:String = Paths.videos('introSelect');
  #end

  public override function create():Void
  {
    if (Save.instance.oldChar)
    {
      onLightsEnd();
      return;
    }
    // Pause existing music.
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.destroy();
      FlxG.sound.music = null;
    }

    #if html5
    trace('Playing web video ${LIGHTS_VIDEO_PATH}');
    playVideoHTML5(LIGHTS_VIDEO_PATH);
    #end

    #if hxvlc
    trace('Playing native video ${LIGHTS_VIDEO_PATH}');
    playVideoNative(LIGHTS_VIDEO_PATH);
    #end

    // // Im TOO lazy to even care, so uh, yep
    // FlxG.camera.zoom = 0.66666666666666666666666666666667;
    // vid.x = -(FlxG.width - (FlxG.width * FlxG.camera.zoom));
    // vid.y = -((FlxG.height - (FlxG.height * FlxG.camera.zoom)) * 0.75);
  }

  #if html5
  var vid:FlxVideo;

  function playVideoHTML5(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FlxVideo(filePath);

    vid.scrollFactor.set();
    if (vid != null)
    {
      vid.zIndex = 0;

      vid.finishCallback = onLightsEnd;

      add(vid);
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  #if hxvlc
  var vid:FunkinVideoSprite;

  function playVideoNative(filePath:String):Void
  {
    // Video displays OVER the FlxState.
    vid = new FunkinVideoSprite(0, 0);

    vid.scrollFactor.set();

    if (vid != null)
    {
      vid.zIndex = 0;
      vid.active = false;
      vid.bitmap.onEncounteredError.add(function(msg:String):Void {
        trace('[VLC] Encountered an error: $msg');

        onLightsEnd();
      });
      vid.bitmap.onEndReached.add(onLightsEnd);
      vid.bitmap.onFormatSetup.add(() -> {
        vid.setGraphicSize(FlxG.initialWidth, FlxG.initialHeight);
        vid.updateHitbox();
        vid.screenCenter();
      });

      add(vid);
      if (vid.load(filePath)) vid.play();
    }
    else
    {
      trace('ALERT: Video is null! Could not play cutscene!');
    }
  }
  #end

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    // if (!introSound.paused)
    // {
    //   #if html5
    //   @:privateAccess
    //   vid.netStream.seek(introSound.time);
    //   #elseif hxvlc
    //   vid.bitmap.time = Std.int(introSound.time);
    //   #end
    // }
  }

  /**
   * When the lights video finishes, it will close the substate
   */
  function onLightsEnd():Void
  {
    #if (html5 || hxvlc)
    if (vid != null)
    {
      #if hxvlc
      vid.stop();
      #end
      remove(vid);
      vid.destroy();
      vid = null;
    }
    #end

    FlxG.camera.zoom = 1;

    close();
  }
}
