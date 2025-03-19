package funkin.ui.debug.char.pages;

import haxe.ui.components.Label;
import haxe.ui.components.VerticalRule;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuCheckBox;
import funkin.ui.freeplay.LetterSort;
import funkin.ui.freeplay.CapsuleText;
import flixel.text.FlxText;
import funkin.ui.freeplay.FreeplayState.DifficultySprite;
import funkin.ui.debug.char.components.dialogs.freeplay.*;
import funkin.ui.debug.char.components.dialogs.DefaultPageDialog;
import funkin.graphics.FunkinSprite;
import funkin.ui.freeplay.FreeplayScore;
import funkin.ui.freeplay.FreeplayStyle;
import funkin.data.animation.AnimationData;
import funkin.data.freeplay.style.FreeplayStyleData;
import funkin.data.freeplay.style.FreeplayStyleRegistry;
import funkin.graphics.shaders.AngleMask;
import funkin.graphics.shaders.Grayscale;
import funkin.graphics.shaders.StrokeShader;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.ui.freeplay.BGScrollingText;
import funkin.ui.AtlasText;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxSpriteGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.util.FlxSpriteUtil;
import flixel.FlxSprite;
import openfl.display.BlendMode;

// mainly used for dj animations and style
class CharCreatorFreeplayPage extends CharCreatorDefaultPage
{
  public var bgText1(get, never):String;

  function get_bgText1():String
  {
    return cast(dialogMap[FreeplayDJSettings], FreeplayDJSettingsDialog).bgText1;
  }

  public var bgText2(get, never):String;

  function get_bgText2():String
  {
    return cast(dialogMap[FreeplayDJSettings], FreeplayDJSettingsDialog).bgText2;
  }

  public var bgText3(get, never):String;

  function get_bgText3():String
  {
    return cast(dialogMap[FreeplayDJSettings], FreeplayDJSettingsDialog).bgText3;
  }

  var dialogMap:Map<FreeplayDialogType, DefaultPageDialog>;

  var data:WizardGenerateParams;
  var loadedSprFreeplayPath:String = ""; // failsafe for when we're importing data instead of creating it

  public var useStyle:Null<String> = null;
  public var customStyleData:FreeplayStyleData =
    {
      version: FreeplayStyleRegistry.FREEPLAYSTYLE_DATA_VERSION,
      bgAsset: 'freeplay/freeplayBGdad',
      selectorAsset: 'freeplay/freeplaySelector',
      numbersAsset: "digital_numbers",
      capsuleAsset: "freeplay/freeplayCapsule/capsule/freeplayCapsule",
      capsuleTextColors: ["#00ccff", "#00ccff"],
      startDelay: 1.0
    }
  public var styleFiles:Array<WizardFile> = [];

  var dj:CharSelectAtlasSprite;
  var djAnims:Array<AnimationData> = [];
  var currentDJAnimation:Int = 0;

  var pivotPointer:FlxShapeCircle;
  var basePointer:FlxShapeCircle;
  var frameTxt:FlxText;

  override public function new(state:CharCreatorState, data:WizardGenerateParams)
  {
    super(state);
    this.data = data;

    dialogMap = new Map<FreeplayDialogType, DefaultPageDialog>();
    dialogMap.set(FreeplayDJAnimations, new FreeplayDJAnimsDialog(this));
    dialogMap.set(FreeplayDJSettings, new FreeplayDJSettingsDialog(this));
    dialogMap.set(FreeplayStyle, new FreeplayStyleDialog(this));

    initBackingCard();

    var playuh = PlayerRegistry.instance.fetchEntry(data.importedPlayerData ?? "");

    dj = new CharSelectAtlasSprite(640, 366, data.freeplayFile?.bytes,
      playuh?.getFreeplayDJData()?.getAtlasPath() != null ? playuh.getFreeplayDJData().getAtlasPath() : null);
    add(dj);

    generateUI();

    if (playuh != null)
    {
      @:privateAccess
      {
        loadedSprFreeplayPath = playuh.getFreeplayDJData().assetPath;
        djAnims = playuh.getFreeplayDJData().animations.copy();
      }

      playDJAnimation();

      var dialog:FreeplayDJAnimsDialog = cast dialogMap[FreeplayDJAnimations];
      for (animData in djAnims)
      {
        dialog.djAnimList.dataSource.add({text: animData.name});
      }

      dialog.djAnimList.selectedIndex = 0;
    }

    initBackground();

    pivotPointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xffff00ff}, 0xffff00ff);
    basePointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xff00ffff}, 0xff00ffff);
    pivotPointer.visible = basePointer.visible = false;
    pivotPointer.alpha = basePointer.alpha = 0.5;

    add(pivotPointer);
    add(basePointer);

    frameTxt = new FlxText(0, 0, 0, "", 48);
    frameTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
    frameTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
    add(frameTxt);
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    var pivotPos = dj.getPivotPosition();
    var basePos = dj.getBasePosition();

    if (pivotPos != null) pivotPointer.setPosition(pivotPos.x - pivotPointer.width / 2, pivotPos.y - pivotPointer.height / 2);
    if (basePos != null) basePointer.setPosition(basePos.x - basePointer.width / 2, basePos.y - basePointer.height / 2);

    pivotPointer.visible = (daState.menubarCheckToolsPivot.selected && pivotPos != null);
    basePointer.visible = (daState.menubarCheckToolsBase.selected && basePos != null);

    frameTxt.visible = daState.menubarCheckToolsFrames.selected;
    frameTxt.text = 'Frame: ${dj.curFrame}/${(dj.totalFrames) - 1}';
    if (pivotPos != null) frameTxt.setPosition(pivotPos.x - frameTxt.width / 2, pivotPos.y - frameTxt.height / 2);

    // no need for handleKeybinds function since these are the only functions in update methinks
    if (!CharCreatorUtil.isHaxeUIDialogOpen)
    {
      if (FlxG.keys.justPressed.SPACE)
      {
        if (!FlxG.keys.pressed.SHIFT && daState.menubarCheckToolsPause.selected && !dj.isAnimationFinished())
        {
          dj.active = !dj.active;
        }
        else
        {
          playDJAnimation();
        }
      }

      if (FlxG.keys.justPressed.W) changeDJAnimation(-1);
      if (FlxG.keys.justPressed.S) changeDJAnimation(1);

      if (FlxG.keys.justPressed.UP) changeDJAnimationOffsets(0, 5);
      if (FlxG.keys.justPressed.DOWN) changeDJAnimationOffsets(0, -5);
      if (FlxG.keys.justPressed.LEFT) changeDJAnimationOffsets(5);
      if (FlxG.keys.justPressed.RIGHT) changeDJAnimationOffsets(-5);
    }
  }

  public function changeDJAnimation(change:Int = 0)
  {
    currentDJAnimation += change;

    if (currentDJAnimation < 0) currentDJAnimation = djAnims.length - 1;
    else if (currentDJAnimation >= djAnims.length) currentDJAnimation = 0;

    var dialog:FreeplayDJAnimsDialog = cast dialogMap[FreeplayDJAnimations];
    if (dialog.djAnimList.selectedIndex != currentDJAnimation) dialog.djAnimList.selectedIndex = currentDJAnimation;

    dialog.djAnimName.text = djAnims[currentDJAnimation]?.name ?? "";
    dialog.djAnimPrefix.text = djAnims[currentDJAnimation]?.prefix ?? "";
    dialog.djAnimLooped.selected = djAnims[currentDJAnimation]?.looped ?? false;

    dialog.djAnimOffsetX.pos = djAnims[currentDJAnimation]?.offsets[0] ?? 0.0;
    dialog.djAnimOffsetY.pos = djAnims[currentDJAnimation]?.offsets[1] ?? 0.0;

    playDJAnimation();
  }

  function playDJAnimation()
  {
    labelAnimName.text = djAnims[currentDJAnimation]?.name ?? "None";
    labelAnimOffsetX.text = "" + (djAnims[currentDJAnimation]?.offsets[0] ?? 0.0);
    labelAnimOffsetY.text = "" + (djAnims[currentDJAnimation]?.offsets[1] ?? 0.0);

    dj.active = true;
    dj.playAnimation(djAnims[currentDJAnimation]?.prefix ?? "", true);
    dj.offset.set(djAnims[currentDJAnimation]?.offsets[0] ?? 0.0, djAnims[currentDJAnimation]?.offsets[1] ?? 0.0);
  }

  function changeDJAnimationOffsets(xOff:Float = 0, yOff:Float = 0)
  {
    if (currentDJAnimation >= djAnims.length) return; // this should in theory detect if we have dj animations loaded from an imported character
    if (djAnims[currentDJAnimation].offsets.length < 2) djAnims[currentDJAnimation].offsets = [0.0, 0.0];

    djAnims[currentDJAnimation].offsets[0] += xOff;
    djAnims[currentDJAnimation].offsets[1] += yOff;

    var dialog:FreeplayDJAnimsDialog = cast dialogMap[FreeplayDJAnimations];
    dialog.djAnimOffsetX.pos = djAnims[currentDJAnimation].offsets[0];
    dialog.djAnimOffsetY.pos = djAnims[currentDJAnimation].offsets[1];

    playDJAnimation();
  }

  override public function fillUpPageSettings(menu:Menu)
  {
    var animsDialog = new MenuCheckBox();
    animsDialog.text = "DJ Animations Settings";
    menu.addComponent(animsDialog);

    animsDialog.onClick = function(_) {
      dialogMap[FreeplayDJAnimations].hidden = !animsDialog.selected;
    }

    var settingsDialog = new MenuCheckBox();
    settingsDialog.text = "Freeplay DJ Settings";
    menu.addComponent(settingsDialog);

    settingsDialog.onClick = function(_) {
      dialogMap[FreeplayDJSettings].hidden = !settingsDialog.selected;
    }

    var styleDialog = new MenuCheckBox();
    styleDialog.text = "Freeplay Style Settings";
    menu.addComponent(styleDialog);

    styleDialog.onClick = function(_) {
      dialogMap[FreeplayStyle].hidden = !styleDialog.selected;
    }
  }

  var labelAnimName:Label = new Label();
  var labelAnimOffsetX:Label = new Label();
  var labelAnimOffsetY:Label = new Label();

  function generateUI()
  {
    labelAnimName.styleNames = labelAnimOffsetX.styleNames = labelAnimOffsetY.styleNames = "infoText";
    labelAnimName.verticalAlign = labelAnimOffsetX.verticalAlign = labelAnimOffsetY.verticalAlign = "center";

    labelAnimName.tooltip = "Left/Right Click to play the Next/Previous Animation";
    labelAnimOffsetX.tooltip = "Left/Right Click to Increase/Decrease the Horizontal Offset.";
    labelAnimOffsetY.tooltip = "Left/Right Click to Increase/Decrease the Vertical Offset.";

    labelAnimName.text = "None";
    labelAnimOffsetX.text = labelAnimOffsetY.text = "0";

    labelAnimName.onClick = _ -> changeDJAnimation(1);
    labelAnimName.onRightClick = _ -> changeDJAnimation(-1);

    labelAnimOffsetX.onClick = _ -> changeDJAnimationOffsets(5);
    labelAnimOffsetX.onRightClick = _ -> changeDJAnimationOffsets(-5);
    labelAnimOffsetY.onClick = _ -> changeDJAnimationOffsets(0, 5);
    labelAnimOffsetY.onRightClick = _ -> changeDJAnimationOffsets(0, -5);
  }

  override public function fillUpBottomBar(left:Box, middle:Box, right:Box)
  {
    var rule1 = new VerticalRule();
    var rule2 = new VerticalRule();
    rule1.percentHeight = rule2.percentHeight = 80;

    middle.addComponent(labelAnimName);
    middle.addComponent(rule1);
    middle.addComponent(labelAnimOffsetX);
    middle.addComponent(rule2);
    middle.addComponent(labelAnimOffsetY);
  }

  var pinkBack:FunkinSprite;
  var orangeBackShit:FunkinSprite;

  function initBackingCard()
  {
    var cardGlow = new FlxSprite(-30, -30).loadGraphic(Paths.image('freeplay/cardGlow'));
    var confirmGlow = new FlxSprite(-30, 240).loadGraphic(Paths.image('freeplay/confirmGlow'));
    var confirmTextGlow = new FlxSprite(-8, 115).loadGraphic(Paths.image('freeplay/glowingText'));

    cardGlow.blend = confirmGlow.blend = confirmTextGlow.blend = BlendMode.ADD;

    pinkBack = FunkinSprite.create('freeplay/pinkBack');
    pinkBack.color = 0xFFFFD863;

    orangeBackShit = new FunkinSprite(84, 440).makeSolidColor(Std.int(pinkBack.width), 75, 0xFFFEDA00);
    FlxSpriteUtil.alphaMaskFlxSprite(orangeBackShit, pinkBack, orangeBackShit);

    var alsoOrangeLOL = new FunkinSprite(0, orangeBackShit.y).makeSolidColor(100, Std.int(orangeBackShit.height), 0xFFFFD400);
    var confirmGlow2 = new FlxSprite(confirmGlow.x, confirmGlow.y).loadGraphic(Paths.image('freeplay/confirmGlow2'));
    var backingTextYeah = new FlxAtlasSprite(640, 370, Paths.animateAtlas("freeplay/backing-text-yeah"),
      {
        FrameRate: 24.0,
        Reversed: false,
        // ?OnComplete:Void -> Void,
        ShowPivot: false,
        Antialiasing: true,
        ScrollFactor: new FlxPoint(1, 1),
      });

    confirmGlow.visible = confirmGlow2.visible = confirmTextGlow.visible = false;
    cardGlow.alpha = 0;

    add(pinkBack);
    add(orangeBackShit);
    add(alsoOrangeLOL);
    add(confirmGlow2);
    add(confirmGlow);
    add(confirmTextGlow);
    add(backingTextYeah);

    initScrollingTexts();
    updateScrollingTexts();

    add(cardGlow);
  }

  function updateScrollingTexts()
  {
    var elderScrolls = [text1, text2, text3, text4, text5, text6];
    var newerStrings = [bgText1, bgText1, bgText2, bgText2, bgText3, bgText1];

    @:privateAccess
    for (i in 0...elderScrolls.length)
    {
      var ogText = elderScrolls[i];
      var ogColor = ogText.grpTexts.members[0].color;
      var ogBold = ogText.grpTexts.members[0].bold;

      ogText.grpTexts.clear();
      ogText.active = false;

      var testText:FlxText = new FlxText(0, 0, 0, newerStrings[i], ogText.size);
      testText.font = "5by7";
      testText.bold = ogBold;
      testText.updateHitbox();
      ogText.grpTexts.add(testText);

      var needed:Int = Math.ceil(ogText.widthShit / testText.frameWidth) + 1;

      for (j in 0...needed)
      {
        var coolText:FlxText = new FlxText(((j + 1) * testText.frameWidth) + ((j + 1) * 20), 0, 0, newerStrings[i], ogText.size);

        coolText.font = "5by7";
        coolText.bold = ogBold;
        coolText.updateHitbox();
        ogText.grpTexts.add(coolText);
      }

      ogText.funnyColor = ogColor;
      ogText.active = true;
    }
  }

  var text1:BGScrollingText;
  var text2:BGScrollingText;
  var text3:BGScrollingText;
  var text4:BGScrollingText;
  var text5:BGScrollingText;
  var text6:BGScrollingText;

  function initScrollingTexts()
  {
    // yanderev moment i think
    text1 = new BGScrollingText(0, 220, bgText1, FlxG.width / 2, false, 60);
    text2 = new BGScrollingText(0, 335, bgText1, FlxG.width / 2, false, 60);
    text3 = new BGScrollingText(0, 160, bgText2, FlxG.width, true, 43);
    text4 = new BGScrollingText(0, 397, bgText2, FlxG.width, true, 43);
    text5 = new BGScrollingText(0, 285, bgText3, FlxG.width / 2, true, 43);
    text6 = new BGScrollingText(0, orangeBackShit.y + 10, bgText1, FlxG.width / 2, 60);

    text1.funnyColor = text2.funnyColor = 0xFFFF9963;
    text3.funnyColor = text4.funnyColor = 0xFFFFF383;
    text6.funnyColor = 0xFFFEA400;

    text1.speed = text2.speed = text6.speed = -3.8;
    text3.speed = text4.speed = 6.8;
    text5.speed = 3.5;

    add(text1);
    add(text2);
    add(text3);
    add(text4);
    add(text5);
    add(text6);

    var glowDark = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/beatglow'));
    glowDark.blend = BlendMode.MULTIPLY;
    add(glowDark);

    var glow = new FlxSprite(-300, 330).loadGraphic(Paths.image('freeplay/beatglow'));
    glow.blend = BlendMode.ADD;
    add(glow);
  }

  var bgDad:FlxSprite;
  var arrowLeft:FlxSprite;
  var arrowRight:FlxSprite;
  var randomCapsule:RandomCapsule;
  var scoreNumbers:FreeplayScore;

  var dumbassTimerThatIGottaClearLater:FlxTimer;

  function initBackground()
  {
    var currentChar = PlayerRegistry.instance.fetchEntry(data.importedPlayerData);
    var stylishSunglasses = FreeplayStyleRegistry.instance.fetchEntry(currentChar?.getFreeplayStyleID() ?? "");

    if (stylishSunglasses != null) useStyle = currentChar.getFreeplayStyleID();

    bgDad = new FlxSprite(pinkBack.width * 0.74)
      .loadGraphic(stylishSunglasses == null ? Paths.image('freeplay/freeplayBGdad') : stylishSunglasses.getBgAssetGraphic());
    bgDad.setGraphicSize(0, FlxG.height);
    bgDad.updateHitbox();

    var blackUnderlay = new FlxSprite(387.76).makeGraphic(Std.int(bgDad.width), Std.int(bgDad.height), FlxColor.BLACK);
    blackUnderlay.setGraphicSize(0, FlxG.height);
    blackUnderlay.updateHitbox();

    var angleMaskShader:AngleMask = new AngleMask();
    bgDad.shader = blackUnderlay.shader = angleMaskShader;
    angleMaskShader.extraColor = FlxColor.WHITE;

    var diffSprite = new DifficultySprite(Constants.DEFAULT_DIFFICULTY);
    diffSprite.setPosition(90, 80);

    randomCapsule = new RandomCapsule(stylishSunglasses);

    var fnfFreeplay:FlxText = new FlxText(8, 8, 0, 'FREEPLAY PAGE', 48);
    fnfFreeplay.font = 'VCR OSD Mono';

    var ostName = new FlxText(8, 8, FlxG.width - 8 - 8, 'OFFICIAL OST', 48); // the text should be original ost methinks
    ostName.font = 'VCR OSD Mono';
    ostName.alignment = RIGHT;

    var sillyStroke:StrokeShader = new StrokeShader(0xFFFFFFFF, 2, 2);
    fnfFreeplay.shader = ostName.shader = sillyStroke;

    var fnfHighscoreSpr:FlxSprite = new FlxSprite(860, 70);
    fnfHighscoreSpr.frames = Paths.getSparrowAtlas('freeplay/highscore');
    fnfHighscoreSpr.animation.addByPrefix('highscore', 'highscore small instance 1', 24, false);
    fnfHighscoreSpr.setGraphicSize(0, Std.int(fnfHighscoreSpr.height * 1));
    fnfHighscoreSpr.updateHitbox();

    scoreNumbers = new FreeplayScore(460, 60, 7, 100, stylishSunglasses);

    arrowLeft = new FlxSprite(20, diffSprite.y - 10);
    arrowRight = new FlxSprite(325, diffSprite.y - 10);
    arrowRight.flipX = true;

    arrowLeft.frames = arrowRight.frames = Paths.getSparrowAtlas(stylishSunglasses == null ? 'freeplay/freeplaySelector' : stylishSunglasses.getSelectorAssetKey());
    arrowLeft.animation.addByPrefix('shine', 'arrow pointer loop', 24);
    arrowRight.animation.addByPrefix('shine', 'arrow pointer loop', 24);
    arrowLeft.animation.play('shine');
    arrowRight.animation.play('shine');

    add(blackUnderlay);
    add(bgDad);
    add(randomCapsule);
    add(diffSprite);
    add(fnfHighscoreSpr);
    add(scoreNumbers);

    add(new FlxSprite(1165, 65).loadGraphic(Paths.image('freeplay/clearBox')));
    add(new AtlasText(1185, 87, '69', AtlasFont.FREEPLAY_CLEAR));
    add(new LetterSort(400, 75));

    add(arrowLeft);
    add(arrowRight);

    add(new FlxSprite(0, -100).makeGraphic(FlxG.width, 164, FlxColor.BLACK));
    add(fnfFreeplay);
    add(ostName);

    dumbassTimerThatIGottaClearLater = new FlxTimer().start(FlxG.random.float(12, 50), function(tmr) {
      fnfHighscoreSpr.animation.play('highscore');
      tmr.time = FlxG.random.float(20, 60);
    }, 0);
  }

  override public function performCleanup()
  {
    dumbassTimerThatIGottaClearLater.cancel();
  }
}

// this is just cuz using the pre-established capsules won't help with creating styles (also we don't need to worry for recycling!)
class RandomCapsule extends FlxSpriteGroup
{
  public var capsule:FlxSprite;
  public var songText:CapsuleText;

  public var grayscaleShader:Grayscale;

  override public function new(?startingData:FreeplayStyle)
  {
    super();

    this.x = 270;
    this.y = (0 * ((height * 0.8) + 10)) + 130;

    capsule = new FlxSprite();
    capsule.frames = Paths.getSparrowAtlas(startingData == null ? 'freeplay/freeplayCapsule/capsule/freeplayCapsule' : startingData.getCapsuleAssetKey());
    capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
    capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);
    add(capsule);

    songText = new CapsuleText(capsule.width * 0.26, 45, 'Random', Std.int(40 * 0.8));
    if (startingData != null) songText.applyStyle(startingData);
    add(songText);

    grayscaleShader = new Grayscale(1);
  }

  public function applyStyle(?style:FreeplayStyle)
  {
    capsule.frames = Paths.getSparrowAtlas(style == null ? 'freeplay/freeplayCapsule/capsule/freeplayCapsule' : style.getCapsuleAssetKey());
    capsule.animation.addByPrefix('selected', 'mp3 capsule w backing0', 24);
    capsule.animation.addByPrefix('unselected', 'mp3 capsule w backing NOT SELECTED', 24);

    if (style != null) songText.applyStyle(style);
    // songText.x = capsule.width * 0.26;
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    var selected = FlxG.mouse.overlaps(this);

    grayscaleShader.setAmount(selected ? 0 : 0.8);
    songText.alpha = selected ? 1 : 0.6;
    songText.blurredText.visible = selected ? true : false;
    capsule.offset.x = selected ? 0 : -5;
    capsule.animation.play(selected ? "selected" : "unselected");

    if (songText.tooLong) songText.resetText();
    if (selected && songText.tooLong) songText.initMove();
  }
}

enum FreeplayDialogType
{
  FreeplayDJAnimations;
  FreeplayDJSettings;
  FreeplayStyle;
}
