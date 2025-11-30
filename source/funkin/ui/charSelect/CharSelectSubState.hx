package funkin.ui.charSelect;

import flixel.util.FlxDirectionFlags;
import flixel.FlxObject;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData.PlayerCharSelectData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.BlueFade;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.PixelatedIcon;
import funkin.util.FramesJSFLParser;
import funkin.util.FramesJSFLParser.FramesJSFLInfo;
import funkin.util.HapticUtil;
import funkin.util.MathUtil;
import funkin.vis.dsp.SpectralAnalyzer;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
#if FEATURE_TOUCH_CONTROLS
import funkin.util.TouchUtil;
#end

@:nullSafety
class CharSelectSubState extends MusicBeatSubState
{
  var cursors:CharSelectCursors;

  var cursorX:Int = 0;
  var cursorY:Int = 0;
  var cursorFactor:Float = 110;
  var cursorOffsetX:Float = -16;
  var cursorOffsetY:Float = -48;
  var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);

  var playerChill:CharSelectPlayer;
  var playerChillOut:CharSelectPlayer;
  var gfChill:CharSelectGF;
  var barthing:FunkinSprite;
  var dipshitBacking:FunkinSprite;
  var chooseDipshit:FunkinSprite;
  var dipshitBlur:FunkinSprite;
  var transitionGradient:FunkinSprite;
  var curChar(default, set):String = Constants.DEFAULT_CHARACTER;
  var rememberedChar:String;
  var nametag:Nametag;
  var camFollow:FlxObject = new FlxObject(0, 0, 1, 1);
  var autoFollow:Bool = false;
  var availableChars:Map<Int, String> = new Map<Int, String>();
  var pressedSelect:Bool = false;
  var selectTimer:FlxTimer = new FlxTimer();
  var allowInput:Bool = false;

  var selectSound:FunkinSound = new FunkinSound();
  var unlockSound:FunkinSound = new FunkinSound();
  var lockedSound:FunkinSound = new FunkinSound();
  var introSound:FunkinSound = new FunkinSound();
  var staticSound:FunkinSound = new FunkinSound();

  var selectedBizz:Array<BitmapFilter> = [
    new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
    new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
  ];

  var bopInfo:Null<Null<FramesJSFLInfo>>;

  // var blackScreen:FunkinSprite;
  var charHitbox:FlxObject = new FlxObject();

  var cutoutSize:Float = 0;

  var fadeShader:BlueFade = new BlueFade();

  public function new(?params:CharSelectSubStateParams)
  {
    super();
    rememberedChar = params?.character ?? "";

    cutoutSize = FullScreenScaleMode.gameCutoutSize.x / 2;

    cursors = new CharSelectCursors();
    grpHitboxes = new FlxTypedGroup<FlxObject>();

    gfChill = new CharSelectGF(cutoutSize, 0);
    playerChillOut = new CharSelectPlayer(cutoutSize, 0);
    playerChill = new CharSelectPlayer(cutoutSize, 0);

    dipshitBlur = new FunkinSprite(cutoutSize + 419, -65);
    dipshitBacking = new FunkinSprite(cutoutSize + 423, -17);
    chooseDipshit = new FunkinSprite(cutoutSize + 426, -13);

    nametag = new Nametag(rememberedChar);

    charHitbox = new FlxObject(FlxG.width * 0.65, FlxG.height * 0.2, 300, 500);

    transitionGradient = new FunkinSprite(0, 0);
    barthing = new FunkinSprite(0, 0);

    selectSound = new FunkinSound();
    unlockSound = new FunkinSound();
    lockedSound = new FunkinSound();
    staticSound = new FunkinSound();
  }

  function loadAvailableCharacters():Void
  {
    var playerIds:Array<String> = PlayerRegistry.instance.listEntryIds();

    for (playerId in playerIds)
    {
      var playerData:Null<PlayerCharSelectData> = PlayerRegistry.instance.fetchEntry(playerId)?.getCharSelectData();
      if (playerData == null) continue;

      var targetPosition:Int = playerData.position ?? 0;
      while (availableChars.exists(targetPosition))
      {
        targetPosition += 1;
      }

      trace('Placing player ${playerId} at position ${targetPosition}');
      availableChars.set(targetPosition, playerId);

      CharSelectAtlasHandler.loadAtlas('charSelect/${playerId}Chill');

      var gfPath:Null<String> = playerData.gf?.assetPath;
      if (gfPath != null)
      {
        CharSelectAtlasHandler.loadAtlas(gfPath);
      }
    }

    // Mr. Static also needs some caching...
    CharSelectAtlasHandler.loadAtlas('charSelect/lockedChill', {filterQuality: LOW, cacheOnLoad: true});
  }

  override public function create():Void
  {
    super.create();

    loadAvailableCharacters();

    bopInfo = FramesJSFLParser.parse(Paths.file("images/charSelect/iconBopInfo/iconBopInfo.txt"));
    if (bopInfo == null)
    {
      trace(" ERROR ".bg_red().bold() + " Failed to load data for bopInfo, is the path provided correct?");
    }

    var bg:FunkinSprite = new FunkinSprite(cutoutSize + -153, -140);
    bg.loadGraphic(Paths.image('charSelect/charSelectBG'));
    bg.scrollFactor.set(0.1, 0.1);
    add(bg);

    var crowd:FunkinSprite = FunkinSprite.createTextureAtlas(cutoutSize, 0, "charSelect/crowd",
      {
        applyStageMatrix: true
      });
    crowd.anim.play('');
    crowd.anim.curAnim.looped = true;
    crowd.scrollFactor.set(0.3, 0.3);
    add(crowd);

    var stageSpr:FunkinSprite = FunkinSprite.createTextureAtlas(cutoutSize - 2, 1, "charSelect/charSelectStage",
      {
        applyStageMatrix: true
      });
    stageSpr.anim.play('');
    stageSpr.anim.curAnim.looped = true;
    add(stageSpr);

    var curtains:FunkinSprite = new FunkinSprite(cutoutSize + -212, -99);
    curtains.loadGraphic(Paths.image('charSelect/curtains'));
    curtains.scrollFactor.set(1.4, 1.4);
    add(curtains);

    barthing.loadTextureAtlas("charSelect/barThing",
      {
        applyStageMatrix: true
      });
    barthing.anim.play('');
    barthing.anim.curAnim.looped = true;
    barthing.blend = BlendMode.MULTIPLY;
    barthing.scale.x = 2.5;
    barthing.scrollFactor.set(0, 0);
    add(barthing);

    barthing.y += 80;
    FlxTween.tween(barthing, {y: barthing.y - 80}, 1.3, {ease: FlxEase.expoOut});

    var charLight:FunkinSprite = new FunkinSprite(cutoutSize + 800, 250);
    charLight.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLight);

    var charLightGF:FunkinSprite = new FunkinSprite(cutoutSize + 180, 240);
    charLightGF.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLightGF);

    function setupPlayerChill(character:String)
    {
      gfChill.switchGF(character);
      add(gfChill);

      playerChillOut.switchChar(character, false);
      playerChillOut.visible = false;
      add(playerChillOut);

      playerChill.switchChar(character, false);
      add(playerChill);
    }

    // I think I can do the character preselect thing here? This better work
    // Edit: [UH-OH!] yes! It does!
    if (rememberedChar != null && rememberedChar != Constants.DEFAULT_CHARACTER)
    {
      setupPlayerChill(rememberedChar);
      for (pos => charId in availableChars)
      {
        if (charId == rememberedChar)
        {
          setCursorPosition(pos);
          break;
        }
      }
      @:bypassAccessor curChar = rememberedChar;
    }
    else
      setupPlayerChill(Constants.DEFAULT_CHARACTER);

    var speakers:FunkinSprite = FunkinSprite.createTextureAtlas(cutoutSize - 10, 0, "charSelect/charSelectSpeakers",
      {
        applyStageMatrix: true
      });
    speakers.anim.play('');
    speakers.anim.curAnim.looped = true;
    speakers.scrollFactor.set(1.8, 1.8);
    speakers.scale.set(1.05, 1.05);
    add(speakers);

    var fgBlur:FunkinSprite = new FunkinSprite(cutoutSize + -125, 170);
    fgBlur.loadGraphic(Paths.image('charSelect/foregroundBlur'));
    fgBlur.blend = BlendMode.MULTIPLY;
    add(fgBlur);

    dipshitBlur.frames = Paths.getSparrowAtlas("charSelect/dipshitBlur");
    dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical offset instance 1", 24, true);
    dipshitBlur.blend = BlendMode.ADD;
    dipshitBlur.animation.play("idle");
    add(dipshitBlur);

    dipshitBacking.frames = Paths.getSparrowAtlas("charSelect/dipshitBacking");
    dipshitBacking.animation.addByPrefix('idle', "CHOOSE horizontal offset instance 1", 24, true);
    dipshitBacking.blend = BlendMode.ADD;
    dipshitBacking.animation.play("idle");
    add(dipshitBacking);

    dipshitBacking.y += 210;
    FlxTween.tween(dipshitBacking, {y: dipshitBacking.y - 210}, 1.1, {ease: FlxEase.expoOut});

    chooseDipshit.loadGraphic(Paths.image('charSelect/chooseDipshit'));
    add(chooseDipshit);

    chooseDipshit.y += 200;
    FlxTween.tween(chooseDipshit, {y: chooseDipshit.y - 200}, 1, {ease: FlxEase.expoOut});

    dipshitBlur.y += 220;
    FlxTween.tween(dipshitBlur, {y: dipshitBlur.y - 220}, 1.2, {ease: FlxEase.expoOut});

    chooseDipshit.scrollFactor.set();
    dipshitBacking.scrollFactor.set();
    dipshitBlur.scrollFactor.set();

    nametag.midpointX += cutoutSize;
    add(nametag);

    @:privateAccess
    {
      nametag.midpointY += 200;
      FlxTween.tween(nametag, {midpointY: nametag.midpointY - 200}, 1, {ease: FlxEase.expoOut});
    }

    nametag.scrollFactor.set();

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FunkinSprite, ["x", "y", "alpha", "scale", "blend"]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSound, ["pitch", "volume"]));

    add(cursors);

    charHitbox.active = false;
    charHitbox.scrollFactor.set();

    selectSound.loadEmbedded(Paths.sound('CS_select'));
    selectSound.pitch = 1;
    selectSound.volume = 0.7;

    FlxG.sound.defaultSoundGroup.add(selectSound);
    FlxG.sound.list.add(selectSound);

    unlockSound.loadEmbedded(Paths.sound('CS_unlock'));
    unlockSound.pitch = 1;

    unlockSound.volume = 0;
    unlockSound.play(true);

    FlxG.sound.defaultSoundGroup.add(unlockSound);
    FlxG.sound.list.add(unlockSound);

    lockedSound.loadEmbedded(Paths.sound('CS_locked'));
    lockedSound.pitch = 1;

    lockedSound.volume = 1.;

    FlxG.sound.defaultSoundGroup.add(lockedSound);
    FlxG.sound.list.add(lockedSound);

    staticSound.loadEmbedded(Paths.sound('static loop'));
    staticSound.pitch = 1;

    staticSound.looped = true;

    staticSound.volume = 0.6;

    FlxG.sound.defaultSoundGroup.add(staticSound);
    FlxG.sound.list.add(staticSound);

    // playing it here to preload it. not doing this makes a super awkward pause at the end of the intro
    // TODO: probably make an intro thing for funkinSound itself that preloads the next audio?
    FunkinSound.playMusic('stayFunky',
      {
        startingVolume: 0,
        overrideExisting: true,
        restartTrack: true,
      });

    initLocks();

    for (index => member in grpIcons.members)
    {
      member.y += 300;
      FlxTween.tween(member, {y: member.y - 300}, 1, {ease: FlxEase.expoOut});
    }

    FlxG.debugger.addTrackerProfile(new TrackerProfile(CharSelectSubState, ["curChar", "grpXSpread", "grpYSpread"]));
    FlxG.debugger.track(this);

    add(camFollow);
    camFollow.screenCenter();

    FlxG.camera.follow(camFollow, LOCKON);

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    FlxG.camera.filters = [fadeShaderFilter];

    Conductor.stepHit.add(spamOnStep);
    // FlxG.debugger.track(temp, "tempBG");

    #if FEATURE_TOUCH_CONTROLS
    addBackButton(FlxG.width, FlxG.height - 200, FlxColor.WHITE, goBack, 0.3, true);

    if (backButton != null)
    {
      backButton.enabled = false;
      backButton.cameras = [FlxG.camera];
    }

    FlxTween.tween(backButton, {x: FlxG.width - 230}, 0.5,
      {
        ease: FlxEase.expoOut,
        onComplete: (_) -> {
          if (backButton != null) backButton.enabled = true;
        }
      });
    #end

    transitionGradient.loadGraphic(Paths.image('freeplay/transitionGradient'));
    transitionGradient.scale.set(1280, 1);
    transitionGradient.flipY = true;
    transitionGradient.updateHitbox();
    FlxTween.tween(transitionGradient, {y: -720}, 1, {ease: FlxEase.expoOut});
    add(transitionGradient);

    camFollow.screenCenter();
    camFollow.y -= 150;
    fadeShader.fade(0.0, 1.0, 0.8, {ease: FlxEase.quadOut});
    FlxTween.tween(camFollow, {y: camFollow.y + 150}, 1.5,
      {
        ease: FlxEase.expoOut,
        onComplete: function(_) {
          autoFollow = true;
          FlxG.camera.follow(camFollow, LOCKON, 0.01);
        }
      });

    var blackScreen = new FunkinSprite().makeSolidColor(FlxG.width * 2, FlxG.height * 2, 0xFF000000);
    blackScreen.x = -(FlxG.width * 0.5);
    blackScreen.y = -(FlxG.height * 0.5);
    add(blackScreen);

    introSound = new FunkinSound();
    introSound.loadEmbedded(Paths.sound('CS_Lights'));
    introSound.pitch = 1;
    introSound.volume = 0;

    FlxG.sound.defaultSoundGroup.add(introSound);
    FlxG.sound.list.add(introSound);

    openSubState(new IntroSubState());

    subStateClosed.addOnce((_) -> {
      remove(blackScreen);
      if (!Save.instance.oldChar.value)
      {
        camera.flash();

        introSound.volume = 1;
        introSound.play(true);
      }
      checkNewChar();

      Save.instance.oldChar.value = true;
    });
  }

  override public function destroy():Void
  {
    CharSelectAtlasHandler.clearAtlasCache();
    super.destroy();
  }

  function checkNewChar():Void
  {
    if (nonLocks.length > 0) selectTimer.start(2, (_) -> {
      unLock();
    });
    else
    {
      #if FEATURE_NEWGROUNDS
      // Make the character unlock medal retroactive.
      if (availableChars.size() > 1) Medals.award(CharSelect);
      #end

      FunkinSound.playMusic('stayFunky',
        {
          startingVolume: 1,
          overrideExisting: true,
          restartTrack: true,
          onLoad: function() {
            allowInput = true;

            @:privateAccess
            gfChill.analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
            #if sys
            // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
            // So we want to manually change it!
            @:privateAccess
            gfChill.analyzer.fftN = 512;
            #end
          }
        });
    }
  }

  var grpIcons:FlxSpriteGroup = new FlxSpriteGroup();
  var grpHitboxes:FlxTypedGroup<FlxObject>;
  var grpXSpread(default, set):Float = 107;
  var grpYSpread(default, set):Float = 127;
  var nonLocks = [];

  function initLocks():Void
  {
    add(grpIcons);

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSpriteGroup, ["x", "y"]));

    for (i in 0...9)
    {
      if (availableChars.exists(i) && PlayerRegistry.instance.isCharacterSeen(availableChars.get(i) ?? Constants.DEFAULT_CHARACTER))
      {
        var path:Null<String> = availableChars.get(i) ?? Constants.DEFAULT_CHARACTER;
        var temp:PixelatedIcon = new PixelatedIcon(0, 0);
        temp.setCharacter(path);
        temp.setGraphicSize(128, 128);
        temp.updateHitbox();
        temp.ID = 0;
        grpIcons.add(temp);
      }
      else
      {
        var playableCharacterId:Null<String> = availableChars.get(i) ?? Constants.DEFAULT_CHARACTER;
        var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playableCharacterId);
        var isPlayerUnlocked:Bool = player?.isUnlocked() ?? false;
        if (availableChars.exists(i) && isPlayerUnlocked) nonLocks.push(i);

        var temp:Lock = new Lock(0, 0, i,
          {
            swfMode: true,
            uniqueInCache: true
          });

        temp.ID = 1;

        grpIcons.add(temp);
      }

      var hitTemp:FlxObject = new FlxObject(grpIcons.members[i].x, grpIcons.members[i].y, 86, 86);
      hitTemp.active = false;
      hitTemp.scrollFactor.set();
      grpHitboxes.add(hitTemp);
    }

    updateIconPositions();

    grpIcons.scrollFactor.set();
  }

  function unLock():Void
  {
    var index = nonLocks[0];

    pressedSelect = true;

    var copy = 3;

    var yThing = -1;

    while ((index + 1) > copy)
    {
      yThing++;
      copy += 3;
    }

    var xThing = (copy - index - 2) * -1;
    cursorY = yThing;
    cursorX = xThing;

    selectSound.play(true);

    nonLocks.shift();

    selectTimer.start(0.5, function(_) {
      var lock:Lock = cast grpIcons.group.members[index];

      lock.anim.play("unlock");
      lock.anim.onFrameChange.add(function(animName:String, frame:Int, index:Int) {
        if (frame == 40)
        {
          playerChillOut.anim.play("death");
        }
      });

      unlockSound.volume = 0.7;
      unlockSound.play(true);

      lock.anim.onFinish.addOnce(function(_) {
        var char:String = availableChars.get(index) ?? Constants.DEFAULT_CHARACTER;
        camera.flash(0xFFFFFFFF, 0.1);
        playerChill.anim.play("unlock");
        playerChill.visible = true;

        var id = grpIcons.members.indexOf(lock);

        nametag.switchChar(char);
        gfChill.switchGF(char);
        gfChill.visible = true;

        var icon = new PixelatedIcon(0, 0);
        icon.setCharacter(char);
        icon.setGraphicSize(128, 128);
        icon.updateHitbox();
        grpIcons.insert(id, icon);
        grpIcons.remove(lock, true);
        icon.ID = 0;

        bopPlay = true;

        updateIconPositions();
        playerChillOut.anim.onFinish.addOnce((_) -> if (_ == "death")
        {
          // sync = false;
          playerChillOut.visible = false;
          playerChillOut.switchChar(char);
        });

        #if FEATURE_NEWGROUNDS
        // Grant the medal when the player unlocks a character.
        Medals.award(CharSelect);
        #end

        Save.instance.addCharacterSeen(char);
        if (nonLocks.length == 0)
        {
          pressedSelect = false;
          @:bypassAccessor curChar = char;

          staticSound.stop();

          FunkinSound.playMusic('stayFunky',
            {
              startingVolume: 1,
              overrideExisting: true,
              restartTrack: true,
              onLoad: function() {
                allowInput = true;

                @:privateAccess
                gfChill.analyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);
                #if sys
                // On native it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
                // So we want to manually change it!
                @:privateAccess
                gfChill.analyzer.fftN = 512;
                #end
              }
            });
        }
        else
          playerChill.anim.onFinish.addOnce((_) -> unLock());
      });

      playerChill.visible = false;
      playerChill.switchChar(availableChars[index] ?? Constants.DEFAULT_CHARACTER);

      playerChillOut.visible = true;
    });
  }

  function updateIconPositions()
  {
    grpIcons.x = cutoutSize + 450;
    grpIcons.y = 120;

    for (index => member in grpIcons.members)
    {
      var posX:Float = (index % 3);
      var posY:Float = Math.floor(index / 3);

      member.x = posX * grpXSpread;
      member.y = posY * grpYSpread;

      member.x += grpIcons.x;
      member.y += grpIcons.y;
    }

    for (index => member in grpHitboxes.members)
    {
      var posX:Float = (index % 3);
      var posY:Float = Math.floor(index / 3);

      member.x = posX * grpXSpread;
      member.y = posY * grpYSpread;

      member.x += grpIcons.x + 20;
      member.y += grpIcons.y + 20;
    }
  }

  function goToFreeplay():Void
  {
    allowInput = false;
    autoFollow = false;

    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      FlxTween.tween(backButton, {alpha: 0}, 0.2);
    }
    #end

    FlxTween.tween(cursors, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});

    FlxTween.tween(barthing, {y: barthing.y + 80}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(nametag, {y: nametag.y + 80}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(dipshitBacking, {y: dipshitBacking.y + 210}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(chooseDipshit, {y: chooseDipshit.y + 200}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(dipshitBlur, {y: dipshitBlur.y + 220}, 0.8, {ease: FlxEase.backIn});
    for (index => member in grpIcons.members)
    {
      FlxTween.tween(member, {y: member.y + 300}, 0.8, {ease: FlxEase.backIn});
    }
    FlxG.camera.follow(camFollow, LOCKON);
    // going to freeplay so fast makes the fade effects and the camera to bug, that's why we cancel the tweens
    FlxTween.cancelTweensOf(transitionGradient);
    FlxTween.cancelTweensOf(fadeShader);
    FlxTween.cancelTweensOf(camFollow);

    FlxTween.tween(transitionGradient, {y: -150}, 0.8, {ease: FlxEase.backIn});
    fadeShader.fade(1.0, 0, 0.8, {ease: FlxEase.quadIn});
    FlxTween.tween(camFollow, {y: camFollow.y - 150}, 0.8,
      {
        ease: FlxEase.backIn,
        onComplete: function(_) {
          FlxG.switchState(() -> FreeplayState.build(
            {
              {
                character: wentBackToFreeplay ? rememberedChar : curChar,
                fromCharSelect: true
              }
            }));
        }
      });
  }

  var holdTmrUp:Float = 0;
  var holdTmrDown:Float = 0;
  var holdTmrLeft:Float = 0;
  var holdTmrRight:Float = 0;
  var spamDirections:FlxDirectionFlags = NONE;

  var mobileDeny:Bool = false;
  var mobileAccept:Bool = false;

  var wentBackToFreeplay:Bool = false;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    mobileAccept = false;

    if (controls.UI_UP_R || controls.UI_DOWN_R || controls.UI_LEFT_R || controls.UI_RIGHT_R #if FEATURE_TOUCH_CONTROLS || TouchUtil.justReleased #end)
      selectSound.pitch = 1;

    if (allowInput && !pressedSelect)
    {
      #if FEATURE_TOUCH_CONTROLS
      if (TouchUtil.pressed || TouchUtil.justReleased)
      {
        for (i => hitbox in grpHitboxes.members)
        {
          if (hitbox == null || !TouchUtil.overlaps(hitbox)) continue;

          final indexCX:Int = (i % 3) - 1;
          final indexCY:Int = Math.floor(i / 3) - 1;

          if (indexCY != cursorY || indexCX != cursorX)
          {
            cursorX = indexCX;
            cursorY = indexCY;
            cursors.resetDeny();
            selectSound.play(true);
          }
          else if (TouchUtil.justPressed)
          {
            mobileAccept = true;
          }

          trace("Index: " + i + ", Row: " + cursorY + ", Column: " + cursorX);
          break;
        }
      }

      if (TouchUtil.pressAction(charHitbox, null, false))
      {
        mobileAccept = true;
      }
      #end

      if (controls.UI_UP) holdTmrUp += elapsed;
      if (controls.UI_UP_R)
      {
        holdTmrUp = 0;
        spamDirections = spamDirections.without(UP);
      }

      if (controls.UI_DOWN) holdTmrDown += elapsed;
      if (controls.UI_DOWN_R)
      {
        holdTmrDown = 0;
        spamDirections = spamDirections.without(DOWN);
      }

      if (controls.UI_LEFT) holdTmrLeft += elapsed;
      if (controls.UI_LEFT_R)
      {
        holdTmrLeft = 0;
        spamDirections = spamDirections.without(LEFT);
      }

      if (controls.UI_RIGHT) holdTmrRight += elapsed;
      if (controls.UI_RIGHT_R)
      {
        holdTmrRight = 0;
        spamDirections = spamDirections.without(RIGHT);
      }

      var initSpam = 0.5;

      if (holdTmrUp >= initSpam) spamDirections = spamDirections.with(UP);
      if (holdTmrDown >= initSpam) spamDirections = spamDirections.with(DOWN);
      if (holdTmrLeft >= initSpam) spamDirections = spamDirections.with(LEFT);
      if (holdTmrRight >= initSpam) spamDirections = spamDirections.with(RIGHT);

      if (controls.UI_UP_P)
      {
        cursorY -= 1;
        cursors.resetDeny();

        holdTmrUp = 0;

        selectSound.play(true);
      }
      if (controls.UI_DOWN_P)
      {
        cursorY += 1;
        cursors.resetDeny();
        holdTmrDown = 0;
        selectSound.play(true);
      }
      if (controls.UI_LEFT_P)
      {
        cursorX -= 1;
        cursors.resetDeny();

        holdTmrLeft = 0;
        selectSound.play(true);
      }
      if (controls.UI_RIGHT_P)
      {
        cursorX += 1;
        cursors.resetDeny();
        holdTmrRight = 0;
        selectSound.play(true);
      }

      if (controls.BACK_P) goBack();
    }

    cursorX = FlxMath.wrap(cursorX, -1, 1);
    cursorY = FlxMath.wrap(cursorY, -1, 1);

    var currentCharacter:String = availableChars[getCurrentSelected()] ?? Constants.DEFAULT_CHARACTER;
    if (availableChars.exists(getCurrentSelected()) && PlayerRegistry.instance.isCharacterSeen(currentCharacter))
    {
      var charId:String = availableChars.get(getCurrentSelected()) ?? Constants.DEFAULT_CHARACTER;
      if (charId != null) curChar = charId;

      if (allowInput && pressedSelect && (controls.BACK_P #if FEATURE_TOUCH_CONTROLS || (mobileDeny && TouchUtil.justReleased) #end))
      {
        mobileDeny = false;
        cursors.unconfirm();

        dispatchEvent(new CharacterSelectScriptEvent(CHARACTER_DESELECTED, curChar));

        #if FEATURE_TOUCH_CONTROLS
        if (backButton != null)
        {
          backButton.enabled = true;
        }
        #end

        FlxTween.globalManager.cancelTweensOf(FlxG.sound.music);
        FlxTween.tween(FlxG.sound.music, {pitch: 1.0, volume: 1.0}, 1, {ease: FlxEase.quartInOut});
        playerChill.anim.play("deselect");
        gfChill.anim.play("deselect");
        pressedSelect = false;
        FlxTween.tween(FlxG.sound.music, {pitch: 1.0}, 1,
          {
            ease: FlxEase.quartInOut,
            onComplete: (_) -> {
              if (playerChill.getCurrentAnimation() == "deselect loop start" || playerChill.getCurrentAnimation() == "deselect")
              {
                playerChill.anim.play("idle", true);
                playerChill.anim.curAnim.looped = true;
                gfChill.anim.play("idle", true);
                gfChill.anim.curAnim.looped = true;
              }
            }
          });
        selectTimer.cancel();
      }

      if (allowInput && !pressedSelect && (controls.ACCEPT_P || mobileAccept))
      {
        mobileDeny = false;
        spamDirections = NONE;

        cursors.confirm();

        FlxG.sound.play(Paths.sound('CS_confirm'));

        dispatchEvent(new CharacterSelectScriptEvent(CHARACTER_CONFIRMED, curChar));

        #if FEATURE_TOUCH_CONTROLS
        if (backButton != null)
        {
          backButton.enabled = false;
        }
        #end

        FlxTween.tween(FlxG.sound.music, {pitch: 0.1}, 1, {ease: FlxEase.quadInOut});
        FlxTween.tween(FlxG.sound.music, {volume: 0.0}, 1.5, {ease: FlxEase.quadInOut});

        playerChill.anim.play("select");
        gfChill.anim.play("confirm", true);
        gfChill.anim.curAnim.looped = true;

        pressedSelect = true;
        selectTimer.start(1.5, (_) -> {
          goToFreeplay();
        });
      }
      #if FEATURE_TOUCH_CONTROLS
      else if (pressedSelect && TouchUtil.justReleased) mobileDeny = true;
      #end

      mobileAccept = false;
    }
    else
    {
      curChar = "locked";

      gfChill.visible = false;

      if (allowInput && (controls.ACCEPT_P || mobileAccept))
      {
        playerChill.anim.play("cannot select Label", true);
        lockedSound.play(true);
        HapticUtil.vibrate(0, 0.2);

        cursors.deny();
      }
    }

    updateLockAnims();

    if (autoFollow)
    {
      camFollow.screenCenter();
      camFollow.x += cursorX * 10;
      camFollow.y += cursorY * 10;
    }

    cursorLocIntended.x = (cursorFactor * cursorX) + (FlxG.width / 2) - cursors.main.width / 2;
    cursorLocIntended.y = (cursorFactor * cursorY) + (FlxG.height / 2) - cursors.main.height / 2;

    cursorLocIntended.x += cursorOffsetX;
    cursorLocIntended.y += cursorOffsetY;

    cursors.lerpToLocation(cursorLocIntended);
  }

  function goBack():Void
  {
    #if FEATURE_TOUCH_CONTROLS
    if (backButton != null)
    {
      backButton.enabled = false;
      backButton.alpha = 1;
      backButton.animation.play("confirm");
    }
    #end

    wentBackToFreeplay = true;
    FunkinSound.playOnce(Paths.sound('cancelMenu'));
    FlxTween.tween(FlxG.sound.music, {volume: 0.0}, 0.7, {ease: FlxEase.quadInOut});
    goToFreeplay();
  }

  var bopTimer:Float = 0;
  var delay = 1 / 24;
  var bopFr = 0;
  var bopPlay:Bool = false;
  var bopRefX:Float = 0;
  var bopRefY:Float = 0;

  function doBop(icon:PixelatedIcon, elapsed:Float):Void
  {
    if (bopInfo == null) return;
    if (bopFr >= bopInfo.frames.length)
    {
      bopRefX = 0;
      bopRefY = 0;
      bopPlay = false;
      bopFr = 0;
      return;
    }
    bopTimer += elapsed;

    if (bopTimer >= delay)
    {
      bopTimer -= bopTimer;

      var refFrame = bopInfo.frames[bopInfo.frames.length - 1];
      var curFrame = bopInfo.frames[bopFr];
      if (bopFr >= 13) icon.filters = selectedBizz;

      var scaleXDiff:Float = curFrame.scaleX - refFrame.scaleX;
      var scaleYDiff:Float = curFrame.scaleY - refFrame.scaleY;

      icon.scale.set(2.6, 2.6);
      icon.scale.add(scaleXDiff, scaleYDiff);

      bopFr++;
    }
  }

  public override function dispatchEvent(event:ScriptEvent):Void
  {
    // super.dispatchEvent(event) dispatches event to module scripts.
    super.dispatchEvent(event);

    // Dispatch events (like onBeatHit) to props
    ScriptEventDispatcher.callEvent(playerChill, event);
    ScriptEventDispatcher.callEvent(gfChill, event);
  }

  function spamOnStep():Void
  {
    if (spamDirections.hasAny(ANY))
    {
      if (selectSound.pitch > 5) selectSound.pitch = 5;
      selectSound.play(true);

      cursors.resetDeny();

      if (spamDirections.has(UP))
      {
        cursorY -= 1;
        holdTmrUp = 0;
      }
      if (spamDirections.has(DOWN))
      {
        cursorY += 1;
        holdTmrDown = 0;
      }
      if (spamDirections.has(LEFT))
      {
        cursorX -= 1;
        holdTmrLeft = 0;
      }
      if (spamDirections.has(RIGHT))
      {
        cursorX += 1;
        holdTmrRight = 0;
      }
    }
  }

  private function updateLockAnims():Void
  {
    for (index => member in grpIcons.group.members)
    {
      switch (member.ID)
      {
        case 1:
          var lock:Lock = cast member;
          if (index == getCurrentSelected())
          {
            switch (lock.getCurrentAnimation())
            {
              case "idle":
                lock.anim.play("selected");
              case "selected" | "clicked":
                if (controls.ACCEPT_P) lock.anim.play("clicked", true);
            }
          }
          else
          {
            lock.anim.play("idle");
          }
        case 0:
          var memb:PixelatedIcon = cast member;

          if (index == getCurrentSelected())
          {
            if (bopPlay)
            {
              if (bopRefX == 0)
              {
                bopRefX = memb.x;
                bopRefY = memb.y;
              }
              doBop(memb, FlxG.elapsed);
            }
            else
            {
              memb.filters = selectedBizz;
              memb.scale.set(2.6, 2.6);
            }
            if (pressedSelect && memb.animation.curAnim?.name == 'idle') memb.animation.play('confirm');
            if (autoFollow && !pressedSelect && memb.animation.curAnim?.name != 'idle')
            {
              memb.animation.play("confirm", false, true);
              var onFinish:String->Void = (_) -> {
                member.animation.play('idle');
                member.animation.onFinish.removeAll();
              };
              member.animation.onFinish.add(onFinish);
            }
          }
          else
          {
            memb.filters = null;
            memb.scale.set(2, 2);
          }
      }
    }
  }

  function getCurrentSelected():Int
  {
    var tempX:Int = cursorX + 1;
    var tempY:Int = cursorY + 1;
    var gridPosition:Int = tempX + tempY * 3;
    return gridPosition;
  }

  // Moved this code into a function because is now used twice
  function setCursorPosition(index:Int)
  {
    var copy = 3;
    var yThing = -1;

    while ((index + 1) > copy)
    {
      yThing++;
      copy += 3;
    }

    var xThing = (copy - index - 2) * -1;

    // Look, I'd write better code but I had better aneurysms, my bad - Cheems
    cursorY = yThing;
    cursorX = xThing;
  }

  function set_curChar(value:String):String
  {
    if (curChar == value) return value;

    curChar = value;

    if (value == "locked") staticSound.play();
    else
      staticSound.stop();

    dispatchEvent(new CharacterSelectScriptEvent(CHARACTER_SELECTED, value));

    nametag.switchChar(value);
    gfChill.visible = false;
    playerChill.visible = false;
    playerChillOut.visible = true;
    playerChillOut.anim.play("slideout");

    playerChillOut.anim.onFrameChange.removeAll();
    playerChillOut.anim.onFrameChange.add(function(animName:String, frameNumber:Int, index:Int) {
      if (!playerChill.visible)
      {
        playerChill.visible = true;
        playerChill.switchChar(value);
        gfChill.switchGF(value);
        gfChill.visible = true;
      }
    });

    playerChillOut.anim.onFinish.addOnce(function(animName:String) {
      playerChillOut.switchChar(value);
      playerChillOut.visible = false;
      playerChillOut.anim.onFrameChange.removeAll();
    });

    return value;
  }

  function set_grpXSpread(value:Float):Float
  {
    grpXSpread = value;
    updateIconPositions();
    return value;
  }

  function set_grpYSpread(value:Float):Float
  {
    grpYSpread = value;
    updateIconPositions();
    return value;
  }
}

/**
 * Parameters used to initialize the CharSelectSubState.
 */
typedef CharSelectSubStateParams =
{
  ?character:String
};
