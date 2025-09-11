package funkin.ui.title;

import flixel.FlxSprite;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import funkin.ui.FullScreenScaleMode;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxDirectionFlags;
import flixel.util.FlxTimer;
import funkin.util.HapticUtil;
import flixel.util.typeLimit.NextState;
import funkin.audio.visualize.SpectogramSprite;
import funkin.graphics.shaders.ColorSwap;
import funkin.graphics.shaders.LeftMaskShader;
import funkin.graphics.FunkinSprite;
import funkin.ui.MusicBeatState;
import funkin.graphics.shaders.TitleOutline;
import funkin.audio.FunkinSound;
import funkin.ui.AtlasText;
import openfl.Assets;
import openfl.display.Sprite;
import openfl.events.AsyncErrorEvent;
import funkin.ui.mainmenu.MainMenuState;
import openfl.events.MouseEvent;
import openfl.events.NetStatusEvent;
import openfl.media.Video;
import openfl.net.NetStream;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
import funkin.ui.freeplay.FreeplayState;
import openfl.display.BlendMode;
import funkin.save.Save;
#if mobile
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
#end

class TitleState extends MusicBeatState
{
  /**
   * Only play the credits once per session.
   */
  public static var initialized:Bool = false;

  /**
   * The currently active TitleState.
   * There should be only one TitleState in existance at a time, we can use a singleton.
   */
  public static var instance:TitleState = null;

  /**
   * This is a group holding the `blackScreen` sprite and `textGroup` group.
   *
   * This allows for both to disappear when needed
   */
  public var credGroup:FlxGroup;

  /**
   * This is a black screen covering up gf and the "press enter to play" text
   */
  public var blackScreen:FlxSprite;

  /**
   * This is a group containing the text that displays all the intro messages
   */
  public var textGroup:FlxGroup;

  /**
   * This is the sprite that displays after the
   * "In association with" text alongside the "newgrounds" text
   */
  public var ngSpr:FlxSprite;

  /**
   * An array of all the intro text strings from `introText.txt`
   */
  public var introTextList:Array<String>;

  /**
   * This is obviously the previous beat, used to help incase some beats are missed
   * not a public var to avoid absolutely any softlocks caused by scripts
   */
  var lastBeat:Int;

  /**
   * This is the shader that enables after inputing the secret code (hint: what does girlfriend say in the tutorial?)
   */
  public var girlfriendShader:ColorSwap;

  override public function create():Void
  {
    super.create();
    lastBeat = 0;

    girlfriendShader = new ColorSwap();

    introTextList = FlxG.random.getObject(getIntroTextShit());
    funkin.FunkinMemory.cacheSound(Paths.music('girlfriendsRingtone/girlfriendsRingtone'));

    // DEBUG BULLSHIT

    if (!initialized) new FlxTimer().start(1, function(tmr:FlxTimer) {
      startIntro();
    });
    else
      startIntro();
    if (innstance != null)
    {
      trace('WARNING: TitleState instance already exists. This should not happen.');
      instance = null;
    }
    instance = this;
  }

  /**
   * This is the game logo sprite
   */
  public var logoBl:FlxSprite;

  /**
   * Interactable color shader via the `D` key
   */
  public var InteractableColorShader:TitleOutline;

  /**
   * The girlfriend sprite
   */
  public var gfDance:FlxSpriteOverlay;

  /**
   * This controls what dance animation girlfriend plays
   */
  public var danceLeft:Bool = false;

  /**
   * This is the sprite for the "Press Enter to Begin" text
   */
  var titleText:FlxSprite;
  /**
   * Unused shader
   */
  var maskShader = new LeftMaskShader();

  /**
   * This is the timer for the `AttractState` activation / the idle timer
   */
  public var attractTimer:FlxTimer;

  function startIntro():Void
  {
    if (!initialized || FlxG.sound.music == null) playMenuMusic();

    persistentUpdate = true;

    var bg:FunkinSprite = new FunkinSprite(-1).makeSolidColor(FlxG.width + 2, FlxG.height, FlxColor.BLACK);
    bg.screenCenter();
    add(bg);

    logoBl = new FlxSprite(-150 + (FullScreenScaleMode.gameCutoutSize.x / 2.5), -100);
    logoBl.frames = Paths.getSparrowAtlas('logoBumpin');
    logoBl.animation.addByPrefix('bump', 'logo bumpin', 24);
    logoBl.animation.play('bump');
    logoBl.shader = girlfriendShader.shader;
    logoBl.updateHitbox();

    InteractableColorShader = new TitleOutline();

    gfDance = new FlxSpriteOverlay((FlxG.width * 0.4) + FullScreenScaleMode.gameCutoutSize.x / 2.5, FlxG.height * 0.07);
    gfDance.frames = Paths.getSparrowAtlas('gfDanceTitle');
    gfDance.animation.addByIndices('danceLeft', 'gfDance', [30, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14], "", 24, false);
    gfDance.animation.addByIndices('danceRight', 'gfDance', [15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29], "", 24, false);

    // maskShader.swagSprX = gfDance.x;
    // maskShader.swagMaskX = gfDance.x + 200;
    // maskShader.frameUV = gfDance.frame.uv;
    // gfDance.shader = maskShader;

    gfDance.shader = girlfriendShader.shader;

    // gfDance.shader = new TitleOutline();

    add(logoBl);

    add(gfDance);

    #if mobile
    // shift it a bit more to the left on mobile!!
    titleText = new FlxSprite(50 + (FullScreenScaleMode.gameCutoutSize.x / 2), FlxG.height * 0.8);
    titleText.frames = Paths.getSparrowAtlas('titleEnter_mobile');
    #else
    titleText = new FlxSprite(100 + (FullScreenScaleMode.gameCutoutSize.x / 2), FlxG.height * 0.8);
    titleText.frames = Paths.getSparrowAtlas('titleEnter');
    #end
    titleText.animation.addByPrefix('idle', "Press Enter to Begin", 24);
    titleText.animation.addByPrefix('press', "ENTER PRESSED", 24);
    titleText.animation.play('idle');
    titleText.updateHitbox();
    titleText.shader = girlfriendShader.shader;
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

    trace('Starting attract timer');
    attractTimer = new FlxTimer().start(Constants.TITLE_ATTRACT_DELAY, (_:FlxTimer) -> moveToAttract());
  }

  /**
   * After sitting on the title screen for a while, transition to the attract screen.
   */
  function moveToAttract():Void
  {
    FlxG.sound.music.fadeOut(2.0, 0);
    FlxG.camera.fade(FlxColor.BLACK, 2.0, false, function() {
      instance = null;
      FlxG.switchState(() -> new AttractState());
    });
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

  /**
   * This variable answers the question: "Are we going to the main menu"?
   */
  public var transitioning:Bool = false;

  override function update(elapsed:Float):Void
  {
    FlxG.bitmapLog.add(FlxG.camera.buffer);

    #if (desktop || android)
    // Pressing BACK on the title screen should close the game.
    // This lets you exit without leaving fullscreen mode.
    // Only applicable on desktop and Android.
    if (#if android FlxG.android.justReleased.BACK || #end controls.BACK)
    {
      openfl.Lib.application.window.close();
    }
    #end

    Conductor.instance.update();

    funkin.input.Cursor.hide();

    /* if (FlxG.onMobile)
          {
      if (gfDance != null)
      {
        gfDance.x = (FlxG.width / 2) + (FlxG.accelerometer.x * (FlxG.width / 2));
        // gfDance.y = (FlxG.height / 2) + (FlxG.accelerometer.y * (FlxG.height / 2));
      }
          }
     */
    if (InteractableColorShader != null)
    {
      if (FlxG.keys.justPressed.I)
      {
        FlxTween.tween(InteractableColorShader, {funnyX: 50, funnyY: 50}, 0.6, {ease: FlxEase.quartOut});
      }

      if (FlxG.keys.pressed.D)
      {
        InteractableColorShader.funnyX += 1;
      }

      // InteractableColorShader.xPos.value[0] += 1;
    }

    if (FlxG.keys.justPressed.Y)
    {
      FlxTween.cancelTweensOf(FlxG.stage.window, ['x', 'y']);
      FlxTween.tween(FlxG.stage.window, {x: FlxG.stage.window.x + 300}, 1.4, {ease: FlxEase.quadInOut, type: PINGPONG, startDelay: 0.35});
      FlxTween.tween(FlxG.stage.window, {y: FlxG.stage.window.y + 100}, 0.7, {ease: FlxEase.quadInOut, type: PINGPONG});
    }

    if (FlxG.sound.music != null) Conductor.instance.update(FlxG.sound.music.time);

    // do controls.PAUSE | controls.ACCEPT instead?
    var pressedEnter:Bool = FlxG.keys.justPressed.ENTER #if mobile || (TouchUtil.justReleased && !SwipeUtil.justSwipedAny) #end;

    var gamepad:FlxGamepad = FlxG.gamepads.lastActive;

    if (gamepad != null)
    {
      if (gamepad.justPressed.START || gamepad.justPressed.ACCEPT) pressedEnter = true;
    }

    // If you spam Enter, we should skip the transition.
    if (pressedEnter && transitioning && skippedIntro)
    {
      moveToMainMenu();
    }

    if (pressedEnter && !transitioning && skippedIntro)
    {
      if (FlxG.sound.music != null) FlxG.sound.music.onComplete = null;
      titleText.animation.play('press');
      FlxG.camera.flash(FlxColor.WHITE, 1);
      FunkinSound.playOnce(Paths.sound('confirmMenu'), 0.7);
      transitioning = true;

      #if FEATURE_NEWGROUNDS
      // Award the "Start Game" medal.
      Medals.award(Medal.StartGame);
      funkin.api.newgrounds.Events.logStartGame();
      #end

      new FlxTimer().start(2, function(tmr:FlxTimer) {
        moveToMainMenu();
      });
    }
    if (pressedEnter && !skippedIntro && initialized) skipIntro();

    if ((FlxG.sound.music?.volume ?? 1.0) < 0.8 && initialized)
    {
      FlxG.sound.music.volume += 0.5 * elapsed;
    }

    // TODO: Maybe use the dxdy method for swiping instead.
    if (controls.UI_LEFT #if mobile || SwipeUtil.justSwipedLeft #end) girlfriendShader.update(-elapsed * 0.1);
    if (controls.UI_RIGHT #if mobile || SwipeUtil.justSwipedRight #end) girlfriendShader.update(elapsed * 0.1);
    if (!cheatActive && skippedIntro) cheatCodeShit();
    super.update(elapsed);
  }

  function moveToMainMenu():Void
  {
    if (attractTimer != null)
    {
      attractTimer.cancel();
      attractTimer = null;
    }

    funkin.FunkinMemory.purgeCache();
    instance = null;
    FlxG.switchState(() -> new MainMenuState());
  }

  /**
   * This is the array of inputs (in binary...?) for the cheat code
   */
  public var cheatArray:Array<Int> = [0x0001, 0x0010, 0x0001, 0x0010, 0x0100, 0x1000, 0x0100, 0x1000];

  /**
   * This is the current position in the cheat code
   */
  public var curCheatPos:Int = 0;

  /**
   * This is the boolean for if the cheat is active
   */
  public var cheatActive:Bool = false;

  function cheatCodeShit():Void
  {
    if (controls.NOTE_DOWN_P || controls.UI_DOWN_P #if mobile || SwipeUtil.justSwipedUp #end) codePress(FlxDirectionFlags.DOWN.toInt());
    if (controls.NOTE_UP_P || controls.UI_UP_P #if mobile || SwipeUtil.justSwipedDown #end) codePress(FlxDirectionFlags.UP.toInt());
    if (controls.NOTE_LEFT_P || controls.UI_LEFT_P #if mobile || SwipeUtil.justSwipedLeft #end) codePress(FlxDirectionFlags.LEFT.toInt());
    if (controls.NOTE_RIGHT_P || controls.UI_RIGHT_P #if mobile || SwipeUtil.justSwipedRight #end) codePress(FlxDirectionFlags.RIGHT.toInt());
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

    HapticUtil.vibrate();

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

  /**
   * Unused variable: most likely an old version of the `cheatActive` variable
   */
  public var isRainbow:Bool = false;

  /**
   * This is the variable telling the game to hide the `credGroup` group
   */
  public var skippedIntro:Bool = false;

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
              createCoolText([introTextList[0]]);
            case 11:
              addMoreText(introTextList[1]);
            case 12:
              deleteCoolText();
            case 13:
              addMoreText('Friday');
            case 14:
              // easter egg for when the game is trending with the wrong spelling
              // the random intro text would be "trending--only on x"

              if (introTextList[0] == "trending") addMoreText('Nigth');
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
      if (cheatActive && Conductor.instance.currentBeat % 2 == 0) girlfriendShader.update(0.125);

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
