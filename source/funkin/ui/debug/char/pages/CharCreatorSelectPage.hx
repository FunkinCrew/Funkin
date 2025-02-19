package funkin.ui.debug.char.pages;

import haxe.ui.components.Label;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuCheckBox;
import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.graphics.shaders.MosaicEffect;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.ui.debug.char.pages.subpages.CharSelectIndexSubPage;
import funkin.ui.debug.char.components.dialogs.select.*;
import funkin.ui.debug.char.components.dialogs.DefaultPageDialog;
import funkin.util.FileUtil;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import funkin.ui.charSelect.Lock;
import funkin.util.MathUtil;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.FlxG;
import flixel.text.FlxText;
import funkin.vis.dsp.SpectralAnalyzer;
import flixel.util.FlxColor;

using StringTools;

@:allow(funkin.ui.debug.char.pages.subpages.CharSelectIndexSubPage)
class CharCreatorSelectPage extends CharCreatorDefaultPage
{
  public var ownedCharacters(get, never):Array<String>;

  function get_ownedCharacters():Array<String>
  {
    return cast(dialogMap[SettingsDialog], PlayableCharacterSettingsDialog).ownedCharacters;
  }

  public var position(get, never):Int;

  function get_position():Int
  {
    return selectedIndexData;
  }

  public var data:WizardGenerateParams;

  var nametag:FlxSprite;
  var nametagShader:MosaicEffect = new MosaicEffect();
  var nametagFile:WizardFile;

  var gf:CharSelectAtlasSprite;
  var bf:CharSelectAtlasSprite;

  var transitionGradient:FlxSprite;
  var autoFollow:Bool = false;
  var availableChars:Map<Int, String> = new Map<Int, String>();

  // used for `PlayableCharacter` generation
  var selectedIndexData:Int = 0;
  var pixelIconFiles:Array<WizardFile> = [];

  var gfFile:WizardFile = null;
  var gfUsesVis:Bool = false;
  var gfAnalyzer:SpectralAnalyzer;

  var dialogMap:Map<PlayCharDialogType, DefaultPageDialog>;
  var subPages:Map<CharCreatorSelectSubPage, FlxSpriteGroup>;

  var handleInput:Bool = true;

  var playerPivotPointer:FlxShapeCircle;
  var playerBasePointer:FlxShapeCircle;
  var gfPivotPointer:FlxShapeCircle;
  var gfBasePointer:FlxShapeCircle;
  var playerFrameTxt:FlxText;
  var gfFrameTxt:FlxText;

  override public function new(state:CharCreatorState, data:WizardGenerateParams)
  {
    super(state);

    loadAvailableCharacters();
    this.data = data;

    var playuh = PlayerRegistry.instance.fetchEntry(data.importedPlayerData ?? "");
    if (playuh != null)
    {
      gfUsesVis = true;
      selectedIndexData = playuh.getCharSelectData()?.position ?? 0;
    }

    @:privateAccess
    gfAnalyzer = new SpectralAnalyzer(FlxG.sound.music._channel.__audioSource, 7, 0.1);

    #if desktop
    // On desktop it uses FFT stuff that isn't as optimized as the direct browser stuff we use on HTML5
    // So we want to manually change it!
    @:privateAccess
    gfAnalyzer.fftN = 512;
    #end

    // copied sum code LOL
    initBackground();

    // gf and player code doodoo
    var gfPath = playuh?.getCharSelectData()?.gf?.assetPath;
    gf = new CharSelectAtlasSprite(0, 0, null, gfPath != null ? Paths.animateAtlas(gfPath) : null);
    add(gf);

    var bfPath = data.importedPlayerData == null ? null : "charSelect/" + data.importedPlayerData + "Chill";
    bf = new CharSelectAtlasSprite(0, 0, data.charSelectFile?.bytes, bfPath != null ? Paths.animateAtlas(bfPath) : null);
    add(bf);

    gf.playAnimation(ALL_PLAYER_ANIMS[0], true, false, false);
    bf.playAnimation(ALL_GF_ANIMS[0], true, false, false);

    gf.updateHitbox();
    bf.updateHitbox();

    initForeground();

    nametag = new FlxSprite();
    if (data.importedPlayerData != null) nametag.loadGraphic(Paths.image('charSelect/'
      + (data.importedPlayerData == "bf" ? "boyfriend" : data.importedPlayerData) // not too fond of hardcode
      + "Nametag"));
    nametag.updateHitbox();

    nametag.scale.set(0.77, 0.77);
    updateNametagPos();

    nametag.shader = nametagShader; // truly a sight to behold
    setNametagShaderBlockSize(0, 1, 1);
    setNametagShaderBlockSize(1, nametag.width / 27, nametag.height / 26);
    setNametagShaderBlockSize(2, nametag.width / 10, nametag.height / 10);

    setNametagShaderBlockSize(3, 1, 1);

    add(nametag);

    dialogMap = new Map<PlayCharDialogType, DefaultPageDialog>();
    dialogMap.set(SettingsDialog, new PlayableCharacterSettingsDialog(this));

    subPages = new Map<CharCreatorSelectSubPage, FlxSpriteGroup>();
    subPages.set(IndexSubPage, new CharSelectIndexSubPage(this));

    add(subPages[IndexSubPage]);

    playerPivotPointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xffff00ff}, 0xffff00ff);
    playerBasePointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xff00ffff}, 0xff00ffff);
    gfPivotPointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xffff00ff}, 0xffff00ff);
    gfBasePointer = new FlxShapeCircle(0, 0, 16, cast {thickness: 2, color: 0xff00ffff}, 0xff00ffff);
    playerPivotPointer.visible = playerBasePointer.visible = gfPivotPointer.visible = gfBasePointer.visible = false;
    playerPivotPointer.alpha = playerBasePointer.alpha = gfPivotPointer.alpha = gfBasePointer.alpha = 0.5;

    add(playerPivotPointer);
    add(playerBasePointer);
    add(gfPivotPointer);
    add(gfPivotPointer);

    playerFrameTxt = new FlxText(0, 0, 0, "", 48);
    playerFrameTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
    playerFrameTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
    add(playerFrameTxt);

    gfFrameTxt = new FlxText(0, 0, 0, "", 48);
    gfFrameTxt.setFormat(Paths.font("vcr.ttf"), 48, FlxColor.WHITE, LEFT);
    gfFrameTxt.setBorderStyle(OUTLINE, FlxColor.BLACK, 3);
    add(gfFrameTxt);
  }

  // i am unsure whether or not there are more animations than these
  // also why is the gf select animation called confirm and not select grrrrrrrr >:[
  static final ALL_PLAYER_ANIMS:Array<String> = [
    "idle",
    "select",
    "deselect loop start",
    "deselect",
    "unlock",
    "slidein",
    "slidein idle point",
    "slideout"
  ];
  static final ALL_GF_ANIMS:Array<String> = ["idle", "confirm", "deselect"];

  var gfAnimLabel:Label = new Label();
  var bfAnimLabel:Label = new Label();

  override public function fillUpBottomBar(left:Box, middle:Box, right:Box)
  {
    // middle box for anims !!!!
    var midHBox = new HBox();
    middle.add(midHBox);

    var midRule = new haxe.ui.components.VerticalRule();
    midRule.percentHeight = 80;

    gfAnimLabel.styleNames = bfAnimLabel.styleNames = "infoText";
    gfAnimLabel.verticalAlign = bfAnimLabel.verticalAlign = "center";

    gfAnimLabel.text = "GF Anim: " + gf.getCurrentAnimation();
    bfAnimLabel.text = "Player Anim: " + bf.getCurrentAnimation();

    gfAnimLabel.onClick = _ -> changeCharAnim(1, true);
    gfAnimLabel.onRightClick = _ -> changeCharAnim(-1, true);
    bfAnimLabel.onClick = _ -> changeCharAnim(1);
    bfAnimLabel.onRightClick = _ -> changeCharAnim(-1);

    middle.addComponent(gfAnimLabel);
    middle.addComponent(midRule);
    middle.addComponent(bfAnimLabel);
  }

  function changeCharAnim(change:Int = 0, useGF:Bool = false)
  {
    var array = useGF ? ALL_GF_ANIMS : ALL_PLAYER_ANIMS;
    var current = (useGF ? gfAnimLabel : bfAnimLabel).text.split(" Anim: ")[1]; // neat hack for avoiding scenario when a char doesnt have an animation

    var idx = array.indexOf(current);
    if (idx == -1) return;

    idx += change;

    if (idx >= array.length) idx = 0;
    else if (idx < 0) idx = array.length - 1;

      (useGF ? gfAnimLabel : bfAnimLabel).text = (useGF ? "GF" : "Player") + " Anim: " + array[idx];
    playAnimations();
  }

  override public function fillUpPageSettings(menu:Menu)
  {
    var pixelStuff = new Menu();
    pixelStuff.text = "Pixel Icon";

    var openPos = new MenuItem();
    openPos.text = "Set Position";

    var openFile = new MenuItem();
    openFile.text = "Load from File";

    var gfStuff = new Menu();
    gfStuff.text = "Girlfriend";

    var gfFile = new MenuItem();
    gfFile.text = "Load from File";

    var gfVis = new MenuCheckBox();
    gfVis.text = "Update Visualizer";

    var openNametag = new MenuItem();
    openNametag.text = "Load Nametag Image";

    // additions
    menu.addComponent(pixelStuff);
    pixelStuff.addComponent(openFile);
    pixelStuff.addComponent(openPos);

    menu.addComponent(gfStuff);
    gfStuff.addComponent(gfFile);
    gfStuff.addComponent(gfVis);

    menu.addComponent(openNametag);

    var settingsDialog = new MenuCheckBox();
    settingsDialog.text = "Playable Character Settings";
    menu.addComponent(settingsDialog);

    // callbacks
    openPos.onClick = function(_) {
      cast(subPages[IndexSubPage], CharSelectIndexSubPage).open();
    }

    openFile.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load Pixel Icon File", [FileUtil.FILE_EXTENSION_INFO_PNG], function(_) {
        if (_?.fullPath == null) return;

        var daImgPath = _.fullPath;
        var daXmlPath = daImgPath.replace(".png", ".xml");

        pixelIconFiles = [
          {name: daImgPath, bytes: FileUtil.readBytesFromPath(daImgPath)}];

        if (FileUtil.doesFileExist(daXmlPath)) pixelIconFiles.push({name: daXmlPath, bytes: FileUtil.readBytesFromPath(daXmlPath)});

        openFile.tooltip = "File Path: " + daImgPath;

        cast(subPages[IndexSubPage], CharSelectIndexSubPage).resetIconTexture();
      });
    }

    gfFile.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load Girlfriend Atlas File", [FileUtil.FILE_EXTENSION_INFO_ZIP], function(_) {
        if (_?.fullPath == null) return;

        var daZipBytes = FileUtil.readBytesFromPath(_.fullPath);

        gf.loadFromZip(daZipBytes);

        if (gf.anim == null || gf.frames == null)
        {
          return;
        }

        this.gfFile = {name: data.characterID + "-gf.zip", bytes: daZipBytes};

        changeCharAnim(0, true);
      });
    }

    gfVis.onChange = function(_) gfUsesVis = gfVis.selected;
    gfVis.selected = gfUsesVis;

    openNametag.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load Nametag Image", [FileUtil.FILE_EXTENSION_INFO_PNG], function(_) {
        if (_?.fullPath == null) return;

        nametagFile = {name: _.fullPath, bytes: FileUtil.readBytesFromPath(_.fullPath)}

        nametag.loadGraphic(openfl.display.BitmapData.fromBytes(nametagFile.bytes));
        nametag.updateHitbox();

        updateNametagPos();

        setNametagShaderBlockSize(0, 1, 1);
        setNametagShaderBlockSize(1, nametag.width / 27, nametag.height / 26);
        setNametagShaderBlockSize(2, nametag.width / 10, nametag.height / 10);
        setNametagShaderBlockSize(3, 1, 1);
      });
    }

    settingsDialog.onClick = function(_) {
      dialogMap[SettingsDialog].hidden = !settingsDialog.selected;
    }
  }

  function updateNametagPos()
  {
    nametag.x -= (nametag.getMidpoint().x - 1008);
    nametag.y -= (nametag.getMidpoint().y - 100);
  }

  function setNametagShaderBlockSize(frame:Int, ?forceX:Float, ?forceY:Float)
  {
    var daX:Float = 10 * FlxG.random.int(1, 4);
    var daY:Float = 10 * FlxG.random.int(1, 4);

    if (forceX != null) daX = forceX;
    if (forceY != null) daY = forceY;

    new flixel.util.FlxTimer().start(frame / 30, _ -> {
      nametagShader.setBlockSize(daX, daY);
    });
  }

  function initBackground():Void
  {
    var bg:FlxSprite = new FlxSprite(-153, -140);
    bg.loadGraphic(Paths.image('charSelect/charSelectBG'));
    add(bg);

    var crowd:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/crowd"));
    crowd.anim.play();
    crowd.anim.onComplete.add(function() {
      crowd.anim.play();
    });
    add(crowd);

    var stageSpr:FlxSprite = new FlxSprite(-40, 391);
    stageSpr.frames = Paths.getSparrowAtlas("charSelect/charSelectStage");
    stageSpr.animation.addByPrefix("idle", "stage full instance 1", 24, true);
    stageSpr.animation.play("idle");
    add(stageSpr);

    var curtains:FlxSprite = new FlxSprite(-47, -49);
    curtains.loadGraphic(Paths.image('charSelect/curtains'));
    add(curtains);

    var barthing = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/barThing"));
    barthing.anim.play("");
    barthing.anim.onComplete.add(function() {
      barthing.anim.play("");
    });
    barthing.blend = BlendMode.MULTIPLY;
    add(barthing);

    var charLight:FlxSprite = new FlxSprite(800, 250);
    charLight.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLight);

    var charLightGF:FlxSprite = new FlxSprite(180, 240);
    charLightGF.loadGraphic(Paths.image('charSelect/charLight'));
    add(charLightGF);
  }

  function initForeground():Void
  {
    var speakers:FlxAtlasSprite = new FlxAtlasSprite(0, 0, Paths.animateAtlas("charSelect/charSelectSpeakers"));
    speakers.anim.play("");
    speakers.anim.onComplete.add(function() {
      speakers.anim.play("");
    });
    add(speakers);

    var fgBlur:FlxSprite = new FlxSprite(-125, 170);
    fgBlur.loadGraphic(Paths.image('charSelect/foregroundBlur'));
    fgBlur.blend = BlendMode.MULTIPLY;
    add(fgBlur);

    var dipshitBlur = new FlxSprite(419, -65);
    dipshitBlur.frames = Paths.getSparrowAtlas("charSelect/dipshitBlur");
    dipshitBlur.animation.addByPrefix('idle', "CHOOSE vertical offset instance 1", 24, true);
    dipshitBlur.blend = BlendMode.ADD;
    dipshitBlur.animation.play("idle");
    add(dipshitBlur);

    var dipshitBacking = new FlxSprite(423, -17);
    dipshitBacking.frames = Paths.getSparrowAtlas("charSelect/dipshitBacking");
    dipshitBacking.animation.addByPrefix('idle', "CHOOSE horizontal offset instance 1", 24, true);
    dipshitBacking.blend = BlendMode.ADD;
    dipshitBacking.animation.play("idle");
    add(dipshitBacking);

    var chooseDipshit = new FlxSprite(426, -13);
    chooseDipshit.loadGraphic(Paths.image('charSelect/chooseDipshit'));
    add(chooseDipshit);
  }

  function loadAvailableCharacters():Void
  {
    var playerIds:Array<String> = PlayerRegistry.instance.listEntryIds();

    for (playerId in playerIds)
    {
      var player:Null<funkin.ui.freeplay.charselect.PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playerId);
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

  function playAnimations()
  {
    gf.active = bf.active = true;
    gf.playAnimation(gfAnimLabel.text.split(" Anim: ")[1], true);
    bf.playAnimation(bfAnimLabel.text.split(" Anim: ")[1], true);
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!CharCreatorUtil.isHaxeUIDialogOpen && handleInput)
    {
      if (FlxG.keys.justPressed.SPACE)
      {
        if (!FlxG.keys.pressed.SHIFT
          && daState.menubarCheckToolsPause.selected
          && !bf.isAnimationFinished()
          && !gf.isAnimationFinished())
        {
          bf.active = !bf.active;
          gf.active = !gf.active;
        }
        else
        {
          playAnimations();
        }
      }

      // perhaps gonan find a better keybind for this idk
      if (FlxG.keys.justPressed.W) changeCharAnim(-1, FlxG.keys.pressed.SHIFT);
      if (FlxG.keys.justPressed.S) changeCharAnim(1, FlxG.keys.pressed.SHIFT);
    }

    var playerPivotPos = bf.getPivotPosition();
    var playerBasePos = bf.getBasePosition();

    if (playerPivotPos != null) playerPivotPointer.setPosition(playerPivotPos.x - playerPivotPointer.width / 2,
      playerPivotPos.y - playerPivotPointer.height / 2);
    if (playerBasePos != null) playerBasePointer.setPosition(playerBasePos.x - playerBasePointer.width / 2, playerBasePos.y - playerBasePointer.height / 2);

    var gfPivotPos = gf.getPivotPosition();
    var gfBasePos = gf.getBasePosition();

    if (gfPivotPos != null) gfPivotPointer.setPosition(gfPivotPos.x - gfPivotPointer.width / 2, gfPivotPos.y - gfPivotPointer.height / 2);
    if (gfBasePos != null) gfBasePointer.setPosition(gfBasePos.x - gfBasePointer.width / 2, gfBasePos.y - gfBasePointer.height / 2);

    playerPivotPointer.visible = (daState.menubarCheckToolsPivot.selected && playerPivotPos != null);
    playerBasePointer.visible = (daState.menubarCheckToolsBase.selected && playerBasePos != null);
    gfPivotPointer.visible = (daState.menubarCheckToolsPivot.selected && gfPivotPos != null);
    gfBasePointer.visible = (daState.menubarCheckToolsBase.selected && gfBasePos != null);

    playerFrameTxt.visible = gfFrameTxt.visible = daState.menubarCheckToolsFrames.selected;
    playerFrameTxt.text = 'Frame: ${bf.curFrame}/${(bf.totalFrames) - 1}';
    gfFrameTxt.text = 'Frame: ${gf.curFrame}/${(gf.totalFrames) - 1}';

    if (playerPivotPos != null) playerFrameTxt.setPosition(playerPivotPos.x - playerFrameTxt.width / 2, playerPivotPos.y - playerFrameTxt.height / 2);
    if (gfPivotPos != null) gfFrameTxt.setPosition(gfPivotPos.x - gfFrameTxt.width / 2, gfPivotPos.y - gfFrameTxt.height / 2);

    if (gfUsesVis && gf.anim != null && gf.frames != null)
    {
      var levels = gfAnalyzer.getLevels();
      var frame = gf.anim.curSymbol?.timeline?.get("VIZ_bars")?.get(gf.anim.curFrame);

      if (frame == null) return;

      var elements = frame.getList();
      var len:Int = cast Math.min(elements.length, 7);

      for (i in 0...len)
      {
        var animFrame:Int = Math.round(levels[i].value * 12);

        animFrame = Math.floor(Math.min(12, animFrame));
        animFrame = Math.floor(Math.max(0, animFrame));
        animFrame = Std.int(Math.abs(animFrame - 12)); // shitty dumbass flip, cuz dave got da shit backwards lol!

        elements[i].symbol.firstFrame = animFrame;
      }
    }
  }
}

enum CharCreatorSelectSubPage
{
  IndexSubPage;
}

enum PlayCharDialogType
{
  SettingsDialog;
}
