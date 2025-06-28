package funkin.ui.charSelect;

import openfl.filters.BitmapFilter;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.sound.FlxSound;
import flixel.system.debug.watch.Tracker.TrackerProfile;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.util.FlxColor;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import openfl.filters.DropShadowFilter;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.BlueFade;
import funkin.modding.events.ScriptEvent;
import funkin.modding.events.ScriptEventDispatcher;
import funkin.play.stage.Stage;
import funkin.save.Save;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.ui.freeplay.FreeplayState;
import funkin.ui.PixelatedIcon;
import funkin.util.MathUtil;
import funkin.vis.dsp.SpectralAnalyzer;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import funkin.util.FramesJSFLParser;
import funkin.util.FramesJSFLParser.FramesJSFLInfo;
import funkin.graphics.FunkinSprite;
#if FEATURE_NEWGROUNDS
import funkin.api.newgrounds.Medals;
#end
import funkin.util.TouchUtil;
import funkin.util.SwipeUtil;
import funkin.util.HapticUtil;

class CharSelectSubState extends MusicBeatSubState
{
  // what the actual hell
  // having a hard time trying to make my changes work so i chose to be less stubborn and just remove them for now. - Zack
  // Left this here so somebody can remind me
  var cursor:FlxSprite;

  var cursorBlue:FlxSprite;
  var cursorDarkBlue:FlxSprite;
  var grpCursors:FlxTypedGroup<FlxSprite>;
  var cursorConfirmed:FlxSprite;
  var cursorDenied:FlxSprite;
  var cursorX:Int = 0;
  var cursorY:Int = 0;
  var cursorFactor:Float = 110;
  var cursorOffsetX:Float = -16;
  var cursorOffsetY:Float = -48;
  var cursorLocIntended:FlxPoint = new FlxPoint(0, 0);
  var tmrFrames:Int = 60;
  var currentStage:Stage;
  var playerChill:CharSelectPlayer;
  var playerChillOut:CharSelectPlayer;
  var gfChill:CharSelectGF;
  var gfChillOut:CharSelectGF;
  var barthing:FlxAtlasSprite;
  var dipshitBacking:FlxSprite;
  var chooseDipshit:FlxSprite;
  var dipshitBlur:FlxSprite;
  var transitionGradient:FlxSprite;
  var curChar(default, set):String = Constants.DEFAULT_CHARACTER;
  var rememberedChar:String;
  var nametag:Nametag;
  var camFollow:FlxObject;
  var autoFollow:Bool = false;
  var availableChars:Map<Int, String> = new Map<Int, String>();
  var pressedSelect:Bool = false;
  var selectTimer:FlxTimer = new FlxTimer();
  var allowInput:Bool = false;

  var selectSound:FunkinSound;
  var unlockSound:FunkinSound;
  var lockedSound:FunkinSound;
  var introSound:FunkinSound;
  var staticSound:FunkinSound;

  var charSelectCam:FunkinCamera;

  var selectedBizz:Array<BitmapFilter> = [
    new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
    new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
  ];

  var bopInfo:Null<FramesJSFLInfo>;
  var blackScreen:FunkinSprite;

  var charHitbox:FlxObject;

  var cutoutSize:Float = 0;

  public function new(?params:CharSelectSubStateParams)
  {
    super();
    rememberedChar = params?.character;
    loadAvailableCharacters();
  }

  function loadAvailableCharacters():Void
  {
    var playerIds:Array<String> = PlayerRegistry.instance.listEntryIds();

    for (playerId in playerIds)
    {
      var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playerId);
      if (player == null) continue;
      var playerData = player.getCharSelectData();
      if (playerData == null) continue;

      var targetPosition:Int = playerData.position ?? 0;
      while (availableChars.exists(targetPosition))
      {
        targetPosition += 1;
      }

      trace('Placing player ${playerId} at position ${targetPosition}');
      availableChars.set(targetPosition, playerId);
    }
  }

  var fadeShader:BlueFade = new BlueFade();

  override public function create():Void
  {
    super.create();

    cutoutSize = FullScreenScaleMode.gameCutoutSize.x / 2;

    bopInfo = FramesJSFLParser.parse(Paths.file("images/charSelect/iconBopInfo/iconBopInfo.txt"));
    if (bopInfo == null)
    {
      trace("[ERROR] Failed to load data for bopInfo, is the path provided correct?");
    }

    var bg:FlxSprite = new FlxSprite(cutoutSize + -153, -140);
    bg.loadGraphic(Paths.image('charSelect/charSelectBG'));
    bg.scrollFactor.set(0.1, 0.1);
    add(bg);

    var crowd:FlxAtlasSprite = new FlxAtlasSprite(cutoutSize, 0, Paths.animateAtlas("charSelect/crowd"));
    crowd.anim.play();
    crowd.anim.onComplete.add(function() {
      crowd.anim.play();
    });
    crowd.scrollFactor.set(0.3, 0.3);
    add(crowd);

    var stageSpr:FlxAtlasSprite = new FlxAtlasSprite(cutoutSize + -2, 1, Paths.animateAtlas("charSelect/charSelectStage"));
    stageSpr.anim.play("");
    stageSpr.anim.onComplete.add(function() {
      stageSpr.anim.play("");
    });
    add(stageSpr);

    var curtains:FlxSprite = new FlxSprite(cutoutSize + (-47 - 165), -49 - 50);
    curtains.loadGraphic(Paths.image('charSelect/curtains'));
    curtains.scrollFactor.set(1.4, 1.4);
    add(curtains);

    barthing = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/barThing"));
    barthing.anim.play("");
    barthing.anim.onComplete.add(function() {
      barthing.anim.play("");
    });
    barthing.blend = BlendMode.MULTIPLY;
    barthing.scale.x = 2.5;
    barthing.scrollFactor.set(0, 0);
    add(barthing);

    barthing.y += 80;
    FlxTween.tween(barthing, {y: barthing.y - 80}, 1.3, {ease: FlxEase.expoOut});

    var charLight:FlxSprite = new FlxSprite(cutoutSize + 800, 250);
    charLight.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLight);

    var charLightGF:FlxSprite = new FlxSprite(cutoutSize + 180, 240);
    charLightGF.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLightGF);

    function setupPlayerChill(character:String)
    {
      gfChill = new CharSelectGF();
      gfChill.switchGF(character);
      gfChill.x += cutoutSize;
      add(gfChill);

      playerChillOut = new CharSelectPlayer(cutoutSize, 0);
      playerChillOut.switchChar(character);
      playerChillOut.visible = false;
      add(playerChillOut);

      playerChill = new CharSelectPlayer(cutoutSize, 0);
      playerChill.switchChar(character);
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

    var speakers:FlxAtlasSprite = new FlxAtlasSprite(cutoutSize - 10, 0, Paths.animateAtlas("charSelect/charSelectSpeakers"));
    speakers.anim.play("");
    speakers.anim.onComplete.add(function() {
      speakers.anim.play("");
    });
    speakers.scrollFactor.set(1.8, 1.8);
    speakers.scale.set(1.05, 1.05);
    add(speakers);

    var fgBlur:FlxSprite = new FlxSprite(cutoutSize + -125, 170);
    fgBlur.loadGraphic(Paths.image('charSelect/foregroundBlur'));
    fgBlur.blend = openfl.display.BlendMode.MULTIPLY;
    add(fgBlur);

    dipshitBlur = new FlxSprite(cutoutSize + 419, -65);
    dipshitBlur.frames = Paths.getSparrowAtlas("charSelect/dipshitBlur");
    dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical offset instance 1", 24, true);
    dipshitBlur.blend = BlendMode.ADD;
    dipshitBlur.animation.play("idle");
    add(dipshitBlur);

    dipshitBacking = new FlxSprite(cutoutSize + 423, -17);
    dipshitBacking.frames = Paths.getSparrowAtlas("charSelect/dipshitBacking");
    dipshitBacking.animation.addByPrefix('idle', "CHOOSE horizontal offset instance 1", 24, true);
    dipshitBacking.blend = BlendMode.ADD;
    dipshitBacking.animation.play("idle");
    add(dipshitBacking);

    dipshitBacking.y += 210;
    FlxTween.tween(dipshitBacking, {y: dipshitBacking.y - 210}, 1.1, {ease: FlxEase.expoOut});

    chooseDipshit = new FlxSprite(cutoutSize + 426, -13);
    chooseDipshit.loadGraphic(Paths.image('charSelect/chooseDipshit'));
    add(chooseDipshit);

    chooseDipshit.y += 200;
    FlxTween.tween(chooseDipshit, {y: chooseDipshit.y - 200}, 1, {ease: FlxEase.expoOut});

    dipshitBlur.y += 220;
    FlxTween.tween(dipshitBlur, {y: dipshitBlur.y - 220}, 1.2, {ease: FlxEase.expoOut});

    chooseDipshit.scrollFactor.set();
    dipshitBacking.scrollFactor.set();
    dipshitBlur.scrollFactor.set();

    nametag = new Nametag(curChar);
    nametag.midpointX += cutoutSize;
    add(nametag);

    nametag.scrollFactor.set();

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSprite, ["x", "y", "alpha", "scale", "blend"]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxAtlasSprite, ["x", "y"]));
    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSound, ["pitch", "volume"]));

    // FlxG.debugger.track(crowd);
    // FlxG.debugger.track(stageSpr, "stageSpr");
    // FlxG.debugger.track(bfChill, "bf chill");
    // FlxG.debugger.track(playerChill, "player");
    // FlxG.debugger.track(nametag, "nametag");
    // FlxG.debugger.track(selectSound, "selectSound");
    // FlxG.debugger.track(chooseDipshit, "choose dipshit");
    // FlxG.debugger.track(barthing, "barthing");
    // FlxG.debugger.track(fgBlur, "fgBlur");
    // FlxG.debugger.track(dipshitBlur, "dipshitBlur");
    // FlxG.debugger.track(dipshitBacking, "dipshitBacking");
    // FlxG.debugger.track(charLightGF, "charLight");
    // FlxG.debugger.track(gfChill, "gfChill");

    grpCursors = new FlxTypedGroup<FlxSprite>();
    add(grpCursors);

    cursor = new FlxSprite(0, 0);
    cursor.loadGraphic(Paths.image('charSelect/charSelector'));
    cursor.color = 0xFFFFFF00;

    // FFCC00

    cursorBlue = new FlxSprite(0, 0);
    cursorBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorBlue.color = 0xFF3EBBFF;

    cursorDarkBlue = new FlxSprite(0, 0);
    cursorDarkBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorDarkBlue.color = 0xFF3C74F7;

    cursorBlue.blend = BlendMode.SCREEN;
    cursorDarkBlue.blend = BlendMode.SCREEN;

    cursorConfirmed = new FlxSprite(0, 0);
    cursorConfirmed.scrollFactor.set();
    cursorConfirmed.frames = Paths.getSparrowAtlas("charSelect/charSelectorConfirm");
    cursorConfirmed.animation.addByPrefix("idle", "cursor ACCEPTED instance 1", 24, true);
    cursorConfirmed.visible = false;
    add(cursorConfirmed);

    cursorDenied = new FlxSprite(0, 0);
    cursorDenied.scrollFactor.set();
    cursorDenied.frames = Paths.getSparrowAtlas("charSelect/charSelectorDenied");
    cursorDenied.animation.addByPrefix("idle", "cursor DENIED instance 1", 24, false);
    cursorDenied.visible = false;
    add(cursorDenied);

    grpCursors.add(cursorDarkBlue);
    grpCursors.add(cursorBlue);
    grpCursors.add(cursor);

    charHitbox = new FlxObject(FlxG.width * 0.65, FlxG.height * 0.2, 300, 500);
    charHitbox.active = false;
    charHitbox.scrollFactor.set();

    selectSound = new FunkinSound();
    selectSound.loadEmbedded(Paths.sound('CS_select'));
    selectSound.pitch = 1;
    selectSound.volume = 0.7;

    FlxG.sound.defaultSoundGroup.add(selectSound);
    FlxG.sound.list.add(selectSound);

    unlockSound = new FunkinSound();
    unlockSound.loadEmbedded(Paths.sound('CS_unlock'));
    unlockSound.pitch = 1;

    unlockSound.volume = 0;
    unlockSound.play(true);

    FlxG.sound.defaultSoundGroup.add(unlockSound);
    FlxG.sound.list.add(unlockSound);

    lockedSound = new FunkinSound();
    lockedSound.loadEmbedded(Paths.sound('CS_locked'));
    lockedSound.pitch = 1;

    lockedSound.volume = 1.;

    FlxG.sound.defaultSoundGroup.add(lockedSound);
    FlxG.sound.list.add(lockedSound);

    staticSound = new FunkinSound();
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

    cursor.scrollFactor.set();
    cursorBlue.scrollFactor.set();
    cursorDarkBlue.scrollFactor.set();

    FlxTween.color(cursor, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: PINGPONG});

    // FlxG.debugger.track(cursor);

    FlxG.debugger.addTrackerProfile(new TrackerProfile(CharSelectSubState, ["curChar", "grpXSpread", "grpYSpread"]));
    FlxG.debugger.track(this);

    camFollow = new FlxObject(0, 0, 1, 1);
    add(camFollow);
    camFollow.screenCenter();

    // FlxG.camera.follow(camFollow, LOCKON, 0.01);
    FlxG.camera.follow(camFollow, LOCKON);

    var fadeShaderFilter:ShaderFilter = new ShaderFilter(fadeShader);
    FlxG.camera.filters = [fadeShaderFilter];

    var temp:FlxSprite = new FlxSprite();
    temp.loadGraphic(Paths.image('charSelect/placement'));
    add(temp);
    temp.alpha = 0.0;

    Conductor.stepHit.add(spamOnStep);
    // FlxG.debugger.track(temp, "tempBG");

    transitionGradient = new FlxSprite(0, 0).loadGraphic(Paths.image('freeplay/transitionGradient'));
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
      if (!Save.instance.oldChar)
      {
        camera.flash();

        introSound.volume = 1;
        introSound.play(true);
      }
      checkNewChar();

      Save.instance.oldChar = true;
    });
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

  var grpIcons:FlxSpriteGroup;
  var grpHitboxes:FlxTypedGroup<FlxObject>;
  var grpXSpread(default, set):Float = 107;
  var grpYSpread(default, set):Float = 127;
  var nonLocks = [];

  function initLocks():Void
  {
    grpIcons = new FlxSpriteGroup();
    add(grpIcons);
    grpHitboxes = new FlxTypedGroup<FlxObject>();

    FlxG.debugger.addTrackerProfile(new TrackerProfile(FlxSpriteGroup, ["x", "y"]));
    // FlxG.debugger.track(grpIcons, "iconGrp");

    for (i in 0...9)
    {
      if (availableChars.exists(i) && PlayerRegistry.instance.isCharacterSeen(availableChars.get(i)))
      {
        var path:String = availableChars.get(i);
        var temp:PixelatedIcon = new PixelatedIcon(0, 0);
        temp.setCharacter(path);
        temp.setGraphicSize(128, 128);
        temp.updateHitbox();
        temp.ID = 0;
        grpIcons.add(temp);
      }
      else
      {
        var playableCharacterId:String = availableChars.get(i);
        var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playableCharacterId);
        var isPlayerUnlocked:Bool = player?.isUnlocked() ?? false;
        if (availableChars.exists(i) && isPlayerUnlocked) nonLocks.push(i);

        var temp:Lock = new Lock(0, 0, i);
        temp.ID = 1;

        // temp.onAnimationComplete.add(function(anim) {
        //   if (anim == "unlock") playerChill.playAnimation("unlock", true);
        // });

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
    // Look, I'd write better code but I had better aneurysms, my bad - Cheems
    // felt - Zack
    cursorY = yThing;
    cursorX = xThing;

    selectSound.play(true);

    nonLocks.shift();

    selectTimer.start(0.5, function(_) {
      var lock:Lock = cast grpIcons.group.members[index];

      lock.anim.getFrameLabel("unlockAnim").add(function() {
        playerChillOut.playAnimation("death");
      });

      lock.playAnimation("unlock");

      unlockSound.volume = 0.7;
      unlockSound.play(true);

      // Do not sync the lock, because otherwise the animation will be out of sync!

      /*syncLock = lock;

        sync = true; */

      lock.onAnimationComplete.addOnce(function(_) {
        // syncLock = null;
        var char = availableChars.get(index);
        camera.flash(0xFFFFFFFF, 0.1);
        playerChill.playAnimation("unlock");
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
        playerChillOut.onAnimationComplete.addOnce((_) -> if (_ == "death")
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
          playerChill.onAnimationComplete.addOnce((_) -> unLock());
      });

      playerChill.visible = false;
      playerChill.switchChar(availableChars[index]);

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

  var sync:Bool = false;
  var syncLock:Lock = null;
  var audioBizz:Float = 0;

  function syncAudio(elapsed:Float):Void
  {
    @:privateAccess
    if (sync && unlockSound.time > 0)
    {
      // if (playerChillOut.anim.framerate > 0)
      // {
      //   if (syncLock != null) syncLock.anim.framerate = 0;
      //   playerChillOut.anim.framerate = 0;
      // }

      playerChillOut.anim._tick = 0;
      if (syncLock != null) syncLock.anim._tick = 0;

      if ((unlockSound.time - audioBizz) >= ((delay) * 100))
      {
        if (syncLock != null) syncLock.anim._tick = delay;

        playerChillOut.anim._tick = delay;
        audioBizz += delay * 100;
      }
    }
  }

  function goToFreeplay():Void
  {
    allowInput = false;
    autoFollow = false;

    FlxTween.tween(cursor, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
    FlxTween.tween(cursorBlue, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
    FlxTween.tween(cursorDarkBlue, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});
    FlxTween.tween(cursorConfirmed, {alpha: 0}, 0.8, {ease: FlxEase.expoOut});

    FlxTween.tween(barthing, {y: barthing.y + 80}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(dipshitBacking, {y: dipshitBacking.y + 210}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(chooseDipshit, {y: chooseDipshit.y + 200}, 0.8, {ease: FlxEase.backIn});
    FlxTween.tween(dipshitBlur, {y: dipshitBlur.y + 220}, 0.8, {ease: FlxEase.backIn});
    for (index => member in grpIcons.members)
    {
      // member.y += 300;
      FlxTween.tween(member, {y: member.y + 300}, 0.8, {ease: FlxEase.backIn});
    }
    FlxG.camera.follow(camFollow, LOCKON);
    FlxTween.tween(transitionGradient, {y: -150}, 0.8, {ease: FlxEase.backIn});
    fadeShader.fade(1.0, 0, 0.8, {ease: FlxEase.quadIn});
    FlxTween.tween(camFollow, {y: camFollow.y - 150}, 0.8,
      {
        ease: FlxEase.backIn,
        onComplete: function(_) {
          FlxG.switchState(() -> FreeplayState.build(
            {
              {
                character: curChar,
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
  var spamUp:Bool = false;
  var spamDown:Bool = false;
  var spamLeft:Bool = false;
  var spamRight:Bool = false;

  var mobileDeny:Bool = false;
  var mobileAccept:Bool = false;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    Conductor.instance.update();

    mobileAccept = false;

    if (controls.UI_UP_R || controls.UI_DOWN_R || controls.UI_LEFT_R || controls.UI_RIGHT_R #if FEATURE_TOUCH_CONTROLS || TouchUtil.justReleased #end)
      selectSound.pitch = 1;

    syncAudio(elapsed);

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
            cursorDenied.visible = false;
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

      //
      if (controls.UI_UP) holdTmrUp += elapsed;
      if (controls.UI_UP_R)
      {
        holdTmrUp = 0;
        spamUp = false;
      }

      if (controls.UI_DOWN) holdTmrDown += elapsed;
      if (controls.UI_DOWN_R)
      {
        holdTmrDown = 0;
        spamDown = false;
      }

      if (controls.UI_LEFT) holdTmrLeft += elapsed;
      if (controls.UI_LEFT_R)
      {
        holdTmrLeft = 0;
        spamLeft = false;
      }

      if (controls.UI_RIGHT) holdTmrRight += elapsed;
      if (controls.UI_RIGHT_R)
      {
        holdTmrRight = 0;
        spamRight = false;
      }

      var initSpam = 0.5;

      if (holdTmrUp >= initSpam) spamUp = true;
      if (holdTmrDown >= initSpam) spamDown = true;
      if (holdTmrLeft >= initSpam) spamLeft = true;
      if (holdTmrRight >= initSpam) spamRight = true;

      if (controls.UI_UP_P)
      {
        cursorY -= 1;
        cursorDenied.visible = false;

        holdTmrUp = 0;

        selectSound.play(true);
      }
      if (controls.UI_DOWN_P)
      {
        cursorY += 1;
        cursorDenied.visible = false;
        holdTmrDown = 0;
        selectSound.play(true);
      }
      if (controls.UI_LEFT_P)
      {
        cursorX -= 1;
        cursorDenied.visible = false;

        holdTmrLeft = 0;
        selectSound.play(true);
      }
      if (controls.UI_RIGHT_P)
      {
        cursorX += 1;
        cursorDenied.visible = false;
        holdTmrRight = 0;
        selectSound.play(true);
      }
    }

    if (cursorX < -1)
    {
      cursorX = 1;
    }
    if (cursorX > 1)
    {
      cursorX = -1;
    }
    if (cursorY < -1)
    {
      cursorY = 1;
    }
    if (cursorY > 1)
    {
      cursorY = -1;
    }

    if (availableChars.exists(getCurrentSelected()) && PlayerRegistry.instance.isCharacterSeen(availableChars[getCurrentSelected()]))
    {
      curChar = availableChars.get(getCurrentSelected());

      if (allowInput && pressedSelect && (controls.BACK #if FEATURE_TOUCH_CONTROLS || (mobileDeny && TouchUtil.justReleased) #end))
      {
        mobileDeny = false;
        cursorConfirmed.visible = false;
        grpCursors.visible = true;

        FlxTween.globalManager.cancelTweensOf(FlxG.sound.music);
        FlxTween.tween(FlxG.sound.music, {pitch: 1.0, volume: 1.0}, 1, {ease: FlxEase.quartInOut});
        playerChill.playAnimation("deselect");
        gfChill.playAnimation("deselect");
        pressedSelect = false;
        FlxTween.tween(FlxG.sound.music, {pitch: 1.0}, 1,
          {
            ease: FlxEase.quartInOut,
            onComplete: (_) -> {
              if (playerChill.getCurrentAnimation() == "deselect loop start" || playerChill.getCurrentAnimation() == "deselect")
              {
                playerChill.playAnimation("idle", true, false, true);
                gfChill.playAnimation("idle", true, false, true);
              }
            }
          });
        selectTimer.cancel();
      }

      if (allowInput && !pressedSelect && (controls.ACCEPT || mobileAccept))
      {
        mobileDeny = false;
        spamUp = false;
        spamDown = false;
        spamLeft = false;
        spamRight = false;

        cursorConfirmed.visible = true;
        cursorConfirmed.animation.play("idle", true);

        grpCursors.visible = false;

        FlxG.sound.play(Paths.sound('CS_confirm'));

        FlxTween.tween(FlxG.sound.music, {pitch: 0.1}, 1, {ease: FlxEase.quadInOut});
        FlxTween.tween(FlxG.sound.music, {volume: 0.0}, 1.5, {ease: FlxEase.quadInOut});
        playerChill.playAnimation("select");
        gfChill.playAnimation("confirm", true, false, true);
        pressedSelect = true;
        selectTimer.start(1.5, (_) -> {
          // pressedSelect = false;
          // FlxG.switchState(FreeplayState.build(
          //   {
          //     {
          //       character: curChar
          //     }
          //   }));
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

      if (allowInput && (controls.ACCEPT || mobileAccept))
      {
        cursorDenied.visible = true;

        playerChill.playAnimation("cannot select Label", true);

        lockedSound.play(true);

        HapticUtil.vibrate(0, 0.2);

        cursorDenied.animation.play('idle', true);
        cursorDenied.animation.onFinish.add((_) -> {
          cursorDenied.visible = false;
        });
      }
    }

    updateLockAnims();

    if (autoFollow == true)
    {
      camFollow.screenCenter();
      camFollow.x += cursorX * 10;
      camFollow.y += cursorY * 10;
    }

    cursorLocIntended.x = (cursorFactor * cursorX) + (FlxG.width / 2) - cursor.width / 2;
    cursorLocIntended.y = (cursorFactor * cursorY) + (FlxG.height / 2) - cursor.height / 2;

    cursorLocIntended.x += cursorOffsetX;
    cursorLocIntended.y += cursorOffsetY;

    cursor.x = MathUtil.snap(MathUtil.smoothLerpPrecision(cursor.x, cursorLocIntended.x, elapsed, 0.1), cursorLocIntended.x, 1);
    cursor.y = MathUtil.snap(MathUtil.smoothLerpPrecision(cursor.y, cursorLocIntended.y, elapsed, 0.1), cursorLocIntended.y, 1);

    cursorBlue.x = MathUtil.smoothLerpPrecision(cursorBlue.x, cursor.x, elapsed, 0.202);
    cursorBlue.y = MathUtil.smoothLerpPrecision(cursorBlue.y, cursor.y, elapsed, 0.202);

    cursorDarkBlue.x = MathUtil.smoothLerpPrecision(cursorDarkBlue.x, cursorLocIntended.x, elapsed, 0.404);
    cursorDarkBlue.y = MathUtil.smoothLerpPrecision(cursorDarkBlue.y, cursorLocIntended.y, elapsed, 0.404);

    cursorConfirmed.x = cursor.x - 2;
    cursorConfirmed.y = cursor.y - 4;

    cursorDenied.x = cursor.x - 2;
    cursorDenied.y = cursor.y - 4;
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
    if (spamUp || spamDown || spamLeft || spamRight)
    {
      // selectSound.changePitchBySemitone(1);
      if (selectSound.pitch > 5) selectSound.pitch = 5;
      selectSound.play(true);

      cursorDenied.visible = false;

      if (spamUp)
      {
        cursorY -= 1;
        holdTmrUp = 0;
      }
      if (spamDown)
      {
        cursorY += 1;
        holdTmrDown = 0;
      }
      if (spamLeft)
      {
        cursorX -= 1;
        holdTmrLeft = 0;
      }
      if (spamRight)
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
                lock.playAnimation("selected");
              case "selected" | "clicked":
                if (controls.ACCEPT) lock.playAnimation("clicked", true);
            }
          }
          else
          {
            lock.playAnimation("idle");
          }
        case 0:
          var memb:PixelatedIcon = cast member;

          if (index == getCurrentSelected())
          {
            // memb.pixels = memb.withDropShadow.clone();

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
            if (pressedSelect && memb.animation.curAnim.name == 'idle') memb.animation.play('confirm');
            if (autoFollow && !pressedSelect && memb.animation.curAnim.name != 'idle')
            {
              memb.animation.play("confirm", false, true);
              var onFinish:String->Void = null;
              onFinish = (_) -> {
                member.animation.play('idle');
                member.animation.onFinish.remove(onFinish);
              };
              member.animation.onFinish.add(onFinish);
            }
          }
          else
          {
            // memb.pixels = memb.noDropShadow.clone();
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

    nametag.switchChar(value);
    gfChill.visible = false;
    playerChill.visible = false;
    playerChillOut.visible = true;
    playerChillOut.playAnimation("slideout");
    var index = playerChillOut.anim.getFrameLabel("slideout").index;
    playerChillOut.onAnimationFrame.removeAll();
    playerChillOut.onAnimationFrame.add((_, frame:Int) -> {
      if (frame >= index + 1)
      {
        playerChill.visible = true;
        playerChill.switchChar(value);
        gfChill.switchGF(value);
        gfChill.visible = true;
      }
      if (frame >= index + 2)
      {
        playerChillOut.switchChar(value);
        playerChillOut.visible = false;
        playerChillOut.onAnimationFrame.removeAll();
      }
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
  ?character:String, // ?fromFreeplaySelect:Bool,
};
