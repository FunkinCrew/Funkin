package funkin.ui.title;

import flixel.FlxSprite;
import flixel.FlxState;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import flixel.util.typeLimit.NextState;
import funkin.audio.visualize.SpectogramSprite;
import funkin.graphics.shaders.ColorSwap;
import funkin.graphics.shaders.LeftMaskShader;
import funkin.data.song.SongRegistry;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import funkin.data.song.SongData.SongMusicData;
import funkin.graphics.shaders.TitleOutline;
import funkin.audio.FunkinSound;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.AtlasText;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import funkin.ui.mainmenu.MainMenuState;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import funkin.ui.freeplay.FreeplayState;
import openfl.media.Video;
import openfl.net.NetStream;
import funkin.api.newgrounds.NGio;
import openfl.display.BlendMode;
import funkin.save.Save;

#if desktop
#end
class TitleState extends MusicBeatState
{
  /**
   * Only play the credits once per session.
   */
  public static var initialized:Bool = false;

  var blackScreen:FlxSprite;
  var credGroup:FlxGroup;
  var textGroup:FlxGroup;
  var ngSpr:FlxSprite;

  var curWacky:Array<String> = [];
  var lastBeat:Int = 0;
  var swagShader:ColorSwap;

  var video:Video;
  var netStream:NetStream;
  var overlay:Sprite;

  override public function create():Void
  {
    super.create();
    swagShader = new ColorSwap();

    curWacky = FlxG.random.getObject(getIntroTextShit());
    FlxG.sound.cache(Paths.music('freakyMenu/freakyMenu'));
    FlxG.sound.cache(Paths.music('girlfriendsRingtone/girlfriendsRingtone'));

    // DEBUG BULLSHIT

    // netConnection.addEventListener(MouseEvent.MOUSE_DOWN, overlay_onMouseDown);
    if (!initialized) new FlxTimer().start(1, function(tmr:FlxTimer) {
      startIntro();
    });
    else
      startIntro();
  }

  function client_onMetaData(metaData:Dynamic)
  {
    video.attachNetStream(netStream);

    video.width = video.videoWidth;
    video.height = video.videoHeight;
    // video.
  }

  function netStream_onAsyncError(event:AsyncErrorEvent):Void
  {
    trace("Error loading video");
  }

  function netConnection_onNetStatus(event:NetStatusEvent):Void
  {
    if (event.info.code == 'NetStream.Play.Complete')
    {
      // netStream.dispose();
      // FlxG.stage.removeChild(video);

      startIntro();
    }

    trace(event.toString());
  }

  function overlay_onMouseDown(event:MouseEvent):Void
  {
    netStream.soundTransform.volume = 0.2;
    netStream.soundTransform.pan = -1;
    // netStream.play(Paths.file('music/kickstarterTrailer.mp4'));

    FlxG.stage.removeChild(overlay);
  }

  var logoBl:FlxSprite;
  var outlineShaderShit:TitleOutline;

  var gfDance:FlxSpriteOverlay;
  var danceLeft:Bool = false;
  var titleText:FlxSprite;
  var maskShader = new LeftMaskShader();

  function startIntro():Void
  {
    if (!initialized || FlxG.sound.music == null) playMenuMusic();

    persistentUpdate = true;

    var bg:FunkinSprite = new FunkinSprite(-1).makeSolidColor(FlxG.width + 2, FlxG.height, FlxColor.BLACK);
    bg.screenCenter();
    add(bg);

    logoBl = new FlxSprite(-150, -100);
    logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
    logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
    logoBl.animation.play('bump');
    logoBl.shader = swagShader.shader;
    logoBl.updateHitbox();

    outlineShaderShit = new TitleOutline();

    gfDance = new FlxSpriteOverlay(FlxG.width * 0.4, FlxG.height * 0.07);
    gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
    gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
    gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

    // maskShader.swagSprX = gfDance.x;
    // maskShader.swagMaskX = gfDance.x + 200;
    // maskShader.frameUV = gfDance.frame.uv;
    // gfDance.shader = maskShader;

    // gfDance.shader = swagShader.shader;

    gfDance.shader = new TitleOutline();

    add(logoBl);

    add(gfDance);

    titleText = new FlxSprite(100, FlxG.height * 0.8);
    titleText.frames = Paths.getSparrowAtlas('titleEnter');
    titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
    titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
    titleText.animation.play('idle');
    titleText.updateHitbox();
    titleText.shader = swagShader.shader;
    // titleText.screenCenter(X);
    add(titleText);

    if (!initialized) // Fix an issue where returning to the credits would play a black screen.
    {
      credGroup = new FlxGroup();
      add(credGroup);
    }

    textGroup = new FlxGroup();

    blackScreen = bg.clone();
    if (credGroup != null)
    {
      credGroup.add(blackScreen);
      credGroup.add(textGroup);
    }

    ngSpr = new FlxSprite(0, FlxG.height * 0.52);

    if (FlxG.random.bool(1))
    {
      ngSpr.loadGraphic(Paths.image('newgrounds_logo_classic'));
    }
    else if (FlxG.random.bool(30))
    {
      ngSpr.loadGraphic(Paths.image('newgrounds_logo_animated'), true, 600);
      ngSpr.animation.add('idle', [0, 1], 4);
      ngSpr.animation.play('idle');
      ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.55));
      ngSpr.y += 25;
    }
    else
    {
      ngSpr.loadGraphic(Paths.image('newgrounds_logo'));
      ngSpr.setGraphicSize(Std.int(ngSpr.width * 0.8));
    }

    add(ngSpr);
    ngSpr.visible = false;

    ngSpr.updateHitbox();
    ngSpr.screenCenter(X);

    FlxG.mouse.visible = false;

    if (initialized) skipIntro();
    else
      initialized = true;

    if (FlxG.sound.music != null) FlxG.sound.music.onComplete = moveToAttract;
  }

  /**
   * After sitting on the title screen for a while, transition to the attract screen.
   */
  function moveToAttract():Void
  {
    FlxG.switchState(() -> new AttractState());
  }

  function playMenuMusic():Void
  {
    var shouldFadeIn:Bool = (FlxG.sound.music == null);
    // Load music. Includes logic to handle BPM changes.
    FunkinSound.playMusic('freakyMenu',
      {
        startingVolume: 0.0,
        overrideExisting: true,
        restartTrack: false,
        // Continue playing this music between states, until a different music track gets played.
        persist: true
      });
    // Fade from 0.0 to 1 over 4 seconds
    if (shouldFadeIn) FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);
  }

  function getIntroTextShit():Array<Array<String>>
  {
    var fullText:String = Assets.getText(Paths.txt('introText'));

    // Split into lines and remove empty lines
    var firstArray:Array<String> = fullText.split('\n').filter(function(s:String) return s != '');
    var swagGoodArray:Array<Array<String>> = [];

    for (i in firstArray)
    {
      swagGoodArray.push(i.split('--'));
    }

    return swagGoodArray;
  }

  var transitioning:Bool = false;

  override function update(elapsed:Float):Void
  {
    FlxG.bitmapLog.add(FlxG.camera.buffer);

    #if HAS_PITCH
    if (FlxG.keys.pressed.UP) FlxG.sound.music.pitch += 0.5 * elapsed;

    if (FlxG.keys.pressed.DOWN) FlxG.sound.music.pitch -= 0.5 * elapsed;
    #end

    #if desktop
    if (FlxG.keys.justPressed.ESCAPE)
    {
      openfl.Lib.application.window.close();
    }
    #end

    Conductor.instance.update();

    /* if (FlxG.onMobile)
          {
      if (gfDance != null)
      {
        gfDance.x = (FlxG.width / 2) + (FlxG.accelerometer.x * (FlxG.width / 2));
        // gfDance.y = (FlxG.height / 2) + (FlxG.accelerometer.y * (FlxG.height / 2));
      }
          }
     */
    if (FlxG.keys.justPressed.I)
    {
      FlxTween.tween(outlineShaderShit, {funnyX: 50, funnyY: 50}, 0.6, {ease: FlxEase.quartOut});
    }
    if (FlxG.keys.pressed.D) outlineShaderShit.funnyX += 1;
    // outlineShaderShit.xPos.value[0] += 1;

    if (FlxG.keys.justPressed.Y)
    {
      FlxTween.cancelTweensOf(FlxG.stage.window, ['x', 'y']);
      FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.35});
      FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: PINGPONG});
    }

    if (FlxG.sound.music != null) Conductor.instance.update(FlxG.sound.music.time);

    // do controls.PAUSE | controls.ACCEPT instead?
    var pressedEnter:Bool = FlxG.keys.justPressed.ENTER;

    var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

    if (gamepad != null)
    {
      if (gamepad.justPressed.START) pressedEnter = true;
      #if switch
      if (gamepad.justPressed.B) pressedEnter = true;
      #end
    }

    // If you spam Enter, we should skip the transition.
    if (pressedEnter && transitioning && skippedIntro)
    {
      FlxG.switchState(() -> new MainMenuState());
    }

    if (pressedEnter && !transitioning && skippedIntro)
    {
      if (FlxG.sound.music != null) FlxG.sound.music.onComplete = null;
      // netStream.play(Paths.file('music/kickstarterTrailer.mp4'));
      NGio.unlockMedal(60960);
      // If it's Friday according to da clock
      if (Date.now().getDay() == 5) NGio.unlockMedal(61034);
      titleText.animation.play('press');
      FlxG.camera.flash(FlxColor.WHITE, 1);
      FunkinSound.playOnce(Paths.sound('confirmMenu'), 0.7);
      transitioning = true;

      var targetState:NextState = () -> new MainMenuState();

      new FlxTimer().start(2, function(tmr:FlxTimer) {
        // These assets are very unlikely to be used for the rest of gameplay, so it unloads them from cache/memory
        // Saves about 50mb of RAM or so???
        // TODO: This BREAKS the title screen if you return back to it! Figure out how to fix that.
        // Assets.cache.clear(Paths.image('gfDanceTitle'));
        // Assets.cache.clear(Paths.image('logoBumpin'));
        // Assets.cache.clear(Paths.image('titleEnter'));
        // ngSpr??
        FlxG.switchState(targetState);
      });
      // FunkinSound.playOnce(Paths.music('titleShoot'), 0.7);
    }
    if (pressedEnter && !skippedIntro && initialized) skipIntro();

    if (controls.UI_LEFT) swagShader.update(-elapsed * 0.1);
    if (controls.UI_RIGHT) swagShader.update(elapsed * 0.1);
    if (!cheatActive && skippedIntro) cheatCodeShit();
    super.update(elapsed);
  }

  override function draw()
  {
    super.draw();
  }

  var cheatArray:Array<Int> = [0x0001, 0x0010, 0x0001, 0x0010, 0x0100, 0x1000, 0x0100, 0x1000];
  var curCheatPos:Int = 0;
  var cheatActive:Bool = false;

  function cheatCodeShit():Void
  {
    if (FlxG.keys.justPressed.ANY)
    {
      if (controls.NOTE_DOWN_P || controls.UI_DOWN_P) codePress(FlxDirectionFlags.DOWN);
      if (controls.NOTE_UP_P || controls.UI_UP_P) codePress(FlxDirectionFlags.UP);
      if (controls.NOTE_LEFT_P || controls.UI_LEFT_P) codePress(FlxDirectionFlags.LEFT);
      if (controls.NOTE_RIGHT_P || controls.UI_RIGHT_P) codePress(FlxDirectionFlags.RIGHT);
    }
  }

  function codePress(input:Int)
  {
    if (input == cheatArray[curCheatPos])
    {
      curCheatPos += 1;
      if (curCheatPos >= cheatArray.length) startCheat();
    }
    else
      curCheatPos = 0;

    trace(input);
  }

  function startCheat():Void
  {
    cheatActive = true;

    var spec:SpectogramSprite = new SpectogramSprite(FlxG.sound.music);

    FunkinSound.playMusic('girlfriendsRingtone',
      {
        startingVolume: 0.0,
        overrideExisting: true,
        restartTrack: true
      });

    FlxG.sound.music.fadeIn(4.0, 0.0, 1.0);

    FlxG.camera.flash(FlxColor.WHITE, 1);
    FunkinSound.playOnce(Paths.sound('confirmMenu'), 0.7);
  }

  function createCoolText(textArray:Array<String>)
  {
    if (credGroup == null || textGroup == null) return;

    for (i in 0...textArray.length)
    {
      var money:AtlasText = new AtlasText(0, 0, textArray[i], AtlasFont.BOLD);
      money.screenCenter(X);
      money.y += (i * 60) + 200;
      // credGroup.add(money);
      textGroup.add(money);
    }
  }

  function addMoreText(text:String)
  {
    if (credGroup == null || textGroup == null) return;

    lime.ui.Haptic.vibrate(100, 100);

    var coolText:AtlasText = new AtlasText(0, 0, text.trim(), AtlasFont.BOLD);
    coolText.screenCenter(X);
    coolText.y += (textGroup.length * 60) + 200;
    textGroup.add(coolText);
  }

  function deleteCoolText()
  {
    if (credGroup == null || textGroup == null) return;

    while (textGroup.members.length > 0)
    {
      // credGroup.remove(textGroup.members[0], true);
      textGroup.remove(textGroup.members[0], true);
    }
  }

  var isRainbow:Bool = false;
  var skippedIntro:Bool = false;

  override function beatHit():Bool
  {
    // super.beatHit() returns false if a module cancelled the event.
    if (!super.beatHit()) return false;

    if (!skippedIntro)
    {
      // FlxG.log.add(Conductor.instance.currentBeat);
      // if the user is draggin the window some beats will
      // be missed so this is just to compensate
      if (Conductor.instance.currentBeat > lastBeat)
      {
        // TODO: Why does it perform ALL the previous steps each beat?
        for (i in lastBeat...Conductor.instance.currentBeat)
        {
          switch (i + 1)
          {
            case 1:
              createCoolText(['The', 'Funkin Crew Inc']);
            case 3:
              addMoreText('presents');
            case 4:
              deleteCoolText();
            case 5:
              createCoolText(['In association', 'with']);
            case 7:
              addMoreText('newgrounds');
              if (ngSpr != null) ngSpr.visible = true;
            case 8:
              deleteCoolText();
              if (ngSpr != null) ngSpr.visible = false;
            case 9:
              createCoolText([curWacky[0]]);
            case 11:
              addMoreText(curWacky[1]);
            case 12:
              deleteCoolText();
            case 13:
              addMoreText('Friday');
            case 14:
              // easter egg for when the game is trending with the wrong spelling
              // the random intro text would be "trending--only on x"

              if (curWacky[0] == "trending") addMoreText('Nigth');
              else
                addMoreText('Night');
            case 15:
              addMoreText('Funkin');
            case 16:
              skipIntro();
          }
        }
      }
      lastBeat = Conductor.instance.currentBeat;
    }
    if (skippedIntro)
    {
      if (cheatActive && Conductor.instance.currentBeat % 2 == 0) swagShader.update(0.125);

      if (logoBl != null && logoBl.animation != null) logoBl.animation.play('bump', true);

      danceLeft = !danceLeft;

      if (gfDance != null && gfDance.animation != null)
      {
        if (danceLeft) gfDance.animation.play('danceRight');
        else
          gfDance.animation.play('danceLeft');
      }
    }

    return true;
  }

  function skipIntro():Void
  {
    if (!skippedIntro)
    {
      remove(ngSpr);

      FlxG.camera.flash(FlxColor.WHITE, initialized ? 1 : 4);

      if (credGroup != null) remove(credGroup);
      skippedIntro = true;
    }
  }
}
