package funkin.mobile.ui.options;

import flixel.FlxG;
import flixel.util.FlxColor;
import flixel.group.FlxGroup.FlxTypedGroup;
import funkin.ui.MusicBeatSubState;
import funkin.ui.AtlasText;
import funkin.ui.mainmenu.MainMenuState;
import funkin.graphics.FunkinSprite;
import funkin.graphics.FunkinCamera;
import funkin.graphics.shaders.AdjustColorShader;
import funkin.audio.FunkinSound;
import funkin.mobile.ui.options.objects.SchemeMenuButton;
import funkin.mobile.ui.options.objects.HitboxShowcase;
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.util.SwipeUtil;
import funkin.util.MathUtil;
import flixel.math.FlxMath;

class MobileControlsSchemeMenu extends MusicBeatSubState
{
  var schemeNameText:AtlasText;

  var camButtons:FunkinCamera;

  var currentButton:SchemeMenuButton;

  var hitboxShowcases:FlxTypedGroup<HitboxShowcase>;

  final availableSchemes:Array<String> = [
    FunkinHitboxControlSchemes.FourLanes,
    FunkinHitboxControlSchemes.DoubleThumbTriangle,
    FunkinHitboxControlSchemes.DoubleThumbSquare,
    FunkinHitboxControlSchemes.DoubleThumbDPad
  ];

  var currentIndex:Int = 0;

  var currentHitboxBusy(get, never):Bool;

  override function create()
  {
    super.create();

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    var colorShader = new AdjustColorShader();
    colorShader.brightness = -200;

    final menuBG:FunkinSprite = FunkinSprite.create('menuDesat');
    menuBG.shader = colorShader;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    for (i in 0...availableSchemes.length)
    {
      if (availableSchemes[i] == Preferences.controlsScheme) currentIndex = i;
    }

    schemeNameText = new AtlasText(FlxG.width * 0.05, FlxG.height * 0.05, getCurrentSchemeName(), AtlasFont.BOLD);
    add(schemeNameText);

    setupCameras();

    setupHitboxShowcases();

    createButton(false);
  }

  function setupCameras()
  {
    final mainCamera:FunkinCamera = new FunkinCamera('mobileControlsSchemeMainCamera');
    mainCamera.bgColor = FlxColor.BLACK;
    FlxG.cameras.add(mainCamera);

    if (camControls != null) FlxG.cameras.remove(camControls);

    camControls = new FunkinCamera('camControls');
    FlxG.cameras.add(camControls, false);
    camControls.bgColor = 0x0;

    camButtons = new FunkinCamera('camButtons');
    FlxG.cameras.add(camButtons, false);
    camButtons.bgColor = 0x0;
  }

  function setupHitboxShowcases()
  {
    hitboxShowcases = new FlxTypedGroup<HitboxShowcase>();
    for (i in 0...availableSchemes.length)
    {
      var hitboxShowcase:HitboxShowcase = new HitboxShowcase(Std.int(FlxG.width * -0.16 + (1500 * i)), 0, i, currentIndex, availableSchemes[i], onSelectHitbox);
      hitboxShowcases.add(hitboxShowcase);
    }
    add(hitboxShowcases);
  }

  function createButton(isDemoScreen:Bool)
  {
    if (currentButton != null) remove(currentButton);

    if (isDemoScreen)
    {
      currentButton = new SchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.83, 'BACK', onHitboxDemoBack);
    }
    else
    {
      currentButton = new SchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.83, 'DEMO', onHitboxDemo);
    }
    add(currentButton);
  }

  function onSelectHitbox()
  {
    currentButton.busy = true;
    Preferences.controlsScheme = availableSchemes[currentIndex];
    FlxG.switchState(() -> new MainMenuState());
  }

  function onHitboxDemo()
  {
    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.exists = false;
    });

    createButton(true);

    addHitbox(true, false, availableSchemes[currentIndex]);

    hitbox.forEachAlive(function(hint:FunkinHint) {
      if (!hint.deadZones.contains(cast(currentButton.body, FunkinSprite))) hint.deadZones.push(cast(currentButton.body, FunkinSprite));
    });
  }

  function onHitboxDemoBack()
  {
    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.exists = true;
    });

    createButton(false);

    if (hitbox != null) hitbox.exists = false;
  }

  function changeSelection(change:Int)
  {
    currentIndex += change;

    if (currentIndex < 0) currentIndex = hitboxShowcases.length - 1;
    if (currentIndex >= hitboxShowcases.length) currentIndex = 0;

    schemeNameText.text = getCurrentSchemeName();

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.selectionIndex = currentIndex;
    });
  }

  function getCurrentSchemeName():String
  {
    var scheme:String = availableSchemes[currentIndex];

    // Make first character capital
    scheme = scheme.charAt(0).toUpperCase() + scheme.substr(1);

    // Begin word separation process
    var regex = ~/[A-Z]/;
    var wordsSeperated:Array<String> = [];
    var word = "";
    for (i in 0...scheme.length)
    {
      var char = scheme.charAt(i);

      // Push the current word and move to next one if current character is capital
      if (regex.match(char) && word.length != 0)
      {
        wordsSeperated.push(word);
        word = "";
      }
      word += char;
    }
    // Push last matched word
    wordsSeperated.push(word);

    return wordsSeperated.join(" ");
  }

  var currentHitboxExists:Bool;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      if (hitboxShowcase.selected) currentHitboxExists = hitboxShowcase.exists;
    });

    if (!currentHitboxBusy && currentHitboxExists && !currentButton.busy)
    {
      if (SwipeUtil.swipeRight)
      {
        changeSelection(1);
      }
      else if (SwipeUtil.swipeLeft)
      {
        changeSelection(-1);
      }
    }
  }

  function get_currentHitboxBusy()
  {
    var busy:Bool = false;
    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      if (hitboxShowcase.selected) busy = hitboxShowcase.busy;
    });

    return busy;
  }
}
