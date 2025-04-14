package funkin.mobile.ui.options;

import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.util.FlxColor;
import flixel.FlxG;
import funkin.mobile.ui.options.objects.SchemeMenuButton;
import funkin.mobile.ui.options.objects.HitboxShowcase;
import funkin.mobile.ui.FunkinHitbox;
import funkin.mobile.util.TouchUtil;
import funkin.mobile.util.SwipeUtil;
import funkin.ui.MusicBeatSubState;
import funkin.ui.AtlasText;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.FunkinSprite;
import funkin.graphics.FunkinCamera;
import funkin.audio.FunkinSound;
import funkin.Preferences;

/**
 * Represents the mobile controls scheme menu.
 * In this menu, you can change your controls scheme.
 */
class MobileControlsSchemeMenu extends MusicBeatSubState
{
  /**
   * Text that displays current scheme's name.
   */
  private var schemeNameText:AtlasText;

  /**
   * A camera for buttons.
   */
  private var camButtons:FunkinCamera;

  /**
   * A button that is changed depending if you are in the hitbox demo or not.
   */
  private var currentButton:SchemeMenuButton;

  /**
   * Group of hitbox showcase selection items.
   */
  private var hitboxShowcases:FlxTypedGroup<HitboxShowcase>;

  /**
   * An object used for selecting the current hitbox scheme.
   */
  private var theCenterHitbox:FunkinSprite;

  /**
   * Returns true, if player is currently in hitbox demonstration.
   */
  private var isInDemo:Bool;

  /**
   * An array of every single scheme.
   */
  final availableSchemes:Array<String> = [
    FunkinHitboxControlSchemes.FourLanes,
    FunkinHitboxControlSchemes.DoubleThumbTriangle,
    FunkinHitboxControlSchemes.DoubleThumbSquare,
    FunkinHitboxControlSchemes.DoubleThumbDPad
  ];

  /**
   * Current selected index
   */
  private var currentIndex:Int = 0;

  override function create()
  {
    super.create();

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    final menuBG:FunkinSprite = FunkinSprite.create('menuBG');
    var hsv = new HSVShader();
    hsv.hue = -0.6;
    hsv.saturation = 0.9;
    hsv.value = 3.6;
    menuBG.shader = hsv;
    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
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

  /**
   * Setups every needed camera.
   */
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

  /**
   * Setups the hitbox showcase items.
   */
  function setupHitboxShowcases()
  {
    hitboxShowcases = new FlxTypedGroup<HitboxShowcase>();
    for (i in 0...availableSchemes.length)
    {
      var hitboxShowcase:HitboxShowcase = new HitboxShowcase(Std.int(FlxG.width * -0.16 + (1500 * i)), 0, i, currentIndex, availableSchemes[i], onSelectHitbox);
      hitboxShowcases.add(hitboxShowcase);
    }
    add(hitboxShowcases);

    theCenterHitbox = new FunkinSprite(FlxG.width * 0.295).makeSolidColor(Std.int(FlxG.width * 0.25), Std.int(FlxG.height * 0.25), FlxColor.GREEN);
    theCenterHitbox.cameras = [camButtons];
    theCenterHitbox.updateHitbox();
    theCenterHitbox.screenCenter(Y);
    theCenterHitbox.visible = false;
    add(theCenterHitbox);
  }

  /**
   * Creates or recreates a scheme menu button.
   * @param isDemoScreen Returns true, if player is currently in hitbox demo.
   */
  function createButton(isDemoScreen:Bool)
  {
    if (currentButton != null) remove(currentButton);

    if (isDemoScreen)
    {
      currentButton = new SchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.03, 'BACK', onHitboxDemoBack);
      currentButton.text.x -= 5;
    }
    else
    {
      currentButton = new SchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.83, 'DEMO', onHitboxDemo);
      currentButton.text.x -= 10;
    }
    add(currentButton);
  }

  /**
   * Called when current hitbox has been selected.
   */
  function onSelectHitbox()
  {
    currentButton.busy = true;

    Preferences.controlsScheme = availableSchemes[currentIndex];

    FlxTransitionableState.skipNextTransIn = true;
    FlxTransitionableState.skipNextTransOut = true;

    FlxG.switchState(() -> new funkin.ui.options.OptionsState());
  }

  /**
   * Called when the current button is pressed and player is not in demo right now.
   */
  function onHitboxDemo()
  {
    isInDemo = true;

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.visible = false;
    });

    schemeNameText.visible = false;

    createButton(true);

    addHitbox(true, false, availableSchemes[currentIndex]);

    hitbox.forEachAlive(function(hint:FunkinHint) {
      if (!hint.deadZones.contains(cast(currentButton.body, FunkinSprite))) hint.deadZones.push(cast(currentButton.body, FunkinSprite));
    });
  }

  /**
   * Called when the current button is pressed and player is in demo right now.
   */
  function onHitboxDemoBack()
  {
    isInDemo = false;

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.visible = true;
    });

    schemeNameText.visible = true;

    createButton(false);

    if (hitbox != null) hitbox.exists = false;
  }

  /**
   * Updates selection using currentIndex.
   * @param change Used to change currentIndex.
   */
  function updateSelection(change:Int)
  {
    currentIndex += change;

    if (currentIndex < 0) currentIndex = hitboxShowcases.length - 1;
    if (currentIndex >= hitboxShowcases.length) currentIndex = 0;

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    schemeNameText.text = getCurrentSchemeName();

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.selectionIndex = currentIndex;
    });
  }

  /**
   * Gets current scheme's name.
   * Needed for schemeNameText.
   * @return String
   */
  function getCurrentSchemeName():String
  {
    var scheme:String = availableSchemes[currentIndex];

    // Make first character capital.
    scheme = scheme.charAt(0).toUpperCase() + scheme.substr(1);

    // Begin word separation process.
    var regex = ~/[A-Z]/;
    var wordsSeperated:Array<String> = [];
    var word = "";
    for (i in 0...scheme.length)
    {
      var char = scheme.charAt(i);

      // Push the current word and move to next one if current character is capital.
      if (regex.match(char) && word.length != 0)
      {
        wordsSeperated.push(word);
        word = "";
      }
      word += char;
    }

    wordsSeperated.push(word);

    return wordsSeperated.join(" ");
  }

  /**
   * Handles all the touch inputs.
   */
  function handleInputs()
  {
    if (isInDemo) return;

    if (currentButton.busy) return;

    if (SwipeUtil.swipeRight)
    {
      updateSelection(1);
      return;
    }

    if (SwipeUtil.swipeLeft)
    {
      updateSelection(-1);
      return;
    }

    if (TouchUtil.justPressed && TouchUtil.overlapsComplex(theCenterHitbox) && !SwipeUtil.swipeAny)
    {
      hitboxShowcases.members[currentIndex].onPress();
      currentButton.busy = true;
      return;
    }
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleInputs();
  }
}
