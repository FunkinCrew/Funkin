package funkin.mobile.ui.options;

import flixel.addons.transition.FlxTransitionableState;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.FlxG;
import funkin.mobile.ui.options.objects.SchemeMenuButton;
import funkin.mobile.ui.options.objects.HitboxShowcase;
import funkin.mobile.ui.FunkinHitbox;
import funkin.util.TouchUtil;
import funkin.util.MathUtil;
import funkin.ui.MusicBeatSubState;
import funkin.ui.AtlasText;
import funkin.ui.FullScreenScaleMode;
import funkin.graphics.shaders.HSVShader;
import funkin.graphics.FunkinSprite;
import funkin.graphics.FunkinCamera;
import funkin.audio.FunkinSound;
import funkin.Preferences;

/**
 * Represents the controls scheme menu.
 * In this menu, you can change your controls scheme.
 */
class ControlsSchemeMenu extends MusicBeatSubState
{
  /**
   * Text that displays current scheme's name.
   */
  var schemeNameText:AtlasText;

  /**
   * A camera for buttons.
   */
  var camButtons:FunkinCamera;

  /**
   * A camera for hitbox showcases group.
   */
  var camHitboxes:FunkinCamera;

  /**
   * A button that is changed depending if you are in the hitbox demo or not.
   */
  var currentButton:SchemeMenuButton;

  /**
   * Group of hitbox showcase selection items.
   */
  var hitboxShowcases:FlxTypedSpriteGroup<HitboxShowcase>;

  /**
   * An object used for selecting the current hitbox scheme.
   */
  var itemNavHitbox:FunkinSprite;

  /**
   * Returns true, if player is currently in hitbox demonstration.
   */
  var isInDemo:Bool;

  /**
   * An array of every single scheme.
   */
  final availableSchemes:Array<String> = [
    FunkinHitbox.FunkinHitboxControlSchemes.Arrows,
    FunkinHitbox.FunkinHitboxControlSchemes.FourLanes,
    FunkinHitbox.FunkinHitboxControlSchemes.DoubleThumbTriangle,
    FunkinHitbox.FunkinHitboxControlSchemes.DoubleThumbSquare,
    FunkinHitbox.FunkinHitboxControlSchemes.DoubleThumbDPad
  ];

  /**
   * Current selected index
   */
  var currentIndex:Int = 0;

  /**
   * Touch X position when touch was just pressed. Resets on release.
   */
  var dragStartingX:Int;

  /**
   * Touch X distance between dragStartingX and current touch position. Resets on release.
   */
  var dragDistance:Int;

  /**
   * Represents the background shader for the menu, utilizing HSV color adjustments.
   */
  var hsv:HSVShader = new HSVShader();

  public override function create():Void
  {
    super.create();

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    hsv.hue = -0.6;
    hsv.saturation = 0.9;
    hsv.value = 3.6;

    final menuBG:FunkinSprite = FunkinSprite.create('menuBG');
    menuBG.shader = hsv;
    menuBG.setGraphicSize(Std.int(FlxG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    for (i in 0...availableSchemes.length)
    {
      if (availableSchemes[i] == Preferences.controlsScheme)
      {
        currentIndex = i;
        break;
      }
    }

    schemeNameText = new AtlasText(FlxG.width * 0.05, FlxG.height * 0.05, availableSchemes[currentIndex], AtlasFont.BOLD);
    add(schemeNameText);

    setupCameras();

    setupHitboxShowcases();

    createButton(false);
  }

  /**
   * Setups every needed camera.
   */
  function setupCameras():Void
  {
    final mainCamera:FunkinCamera = new FunkinCamera('SchemeMenuCamera');
    mainCamera.bgColor = FlxColor.BLACK;
    FlxG.cameras.add(mainCamera);

    if (camControls != null) FlxG.cameras.remove(camControls);

    camControls = new FunkinCamera('camControls');
    camControls.bgColor = 0x0;
    FlxG.cameras.add(camControls, false);

    camButtons = new FunkinCamera('camButtons');
    camButtons.bgColor = 0x0;
    FlxG.cameras.add(camButtons, false);

    camHitboxes = new FunkinCamera('camHitboxes');
    camHitboxes.setScale(0.5, 0.5);
    camHitboxes.bgColor = 0x0;
    FlxG.cameras.add(camHitboxes, false);
  }

  /**
   * Setups the hitbox showcase items.
   */
  function setupHitboxShowcases():Void
  {
    hitboxShowcases = new FlxTypedSpriteGroup<HitboxShowcase>();
    hitboxShowcases.x = (-1500 * currentIndex) + (-1500 / (availableSchemes.length + 1) * currentIndex);

    for (i in 0...availableSchemes.length)
    {
      final hitboxShowcase:HitboxShowcase = new HitboxShowcase(0, 0, i, currentIndex, availableSchemes[i], onSelectHitbox);
      hitboxShowcase.x = Math.floor(FlxG.width * -0.16 + (1500 * (i * FullScreenScaleMode.wideScale.x)));
      hitboxShowcases.add(hitboxShowcase);
    }

    hitboxShowcases.cameras = [camHitboxes];
    add(hitboxShowcases);

    itemNavHitbox = new FunkinSprite(FlxG.width * 0.295).makeSolidColor(Std.int(FlxG.width * 0.25), Std.int(FlxG.height * 0.25), FlxColor.GREEN);
    itemNavHitbox.cameras = [camButtons];
    itemNavHitbox.updateHitbox();
    itemNavHitbox.screenCenter(Y);
    itemNavHitbox.visible = false;
    add(itemNavHitbox);
  }

  /**
   * Creates or recreates a scheme menu button.
   * @param isDemoScreen Returns true, if player is currently in hitbox demo.
   */
  function createButton(isDemoScreen:Bool):Void
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
  function onSelectHitbox():Void
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
  function onHitboxDemo():Void
  {
    isInDemo = true;

    FlxTween.tween(hsv, {hue: 0, saturation: 0, value: 0.5}, 0.5);

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.visible = false;
    });

    schemeNameText.visible = false;

    createButton(true);

    addHitbox(true, false, availableSchemes[currentIndex]);

    hitbox.forEachAlive(function(hint:FunkinHint) {
      if (availableSchemes[currentIndex] == FunkinHitboxControlSchemes.Arrows) hint.alpha = 1;

      if (!hint.deadZones.contains(cast(currentButton.body, FunkinSprite))) hint.deadZones.push(cast(currentButton.body, FunkinSprite));
    });
  }

  /**
   * Called when the current button is pressed and player is in demo right now.
   */
  function onHitboxDemoBack():Void
  {
    isInDemo = false;

    FlxTween.tween(hsv, {hue: -0.6, saturation: 0.9, value: 3.6}, 0.5);

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
  function setSelection(index:Int):Void
  {
    final newIndex:Int = Math.floor(FlxMath.bound(index, 0, hitboxShowcases.length - 1));

    if (currentIndex != newIndex)
    {
      currentIndex = newIndex;
    }
    else
    {
      return;
    }

    FunkinSound.playOnce(Paths.sound('scrollMenu'), 0.4);

    schemeNameText.text = availableSchemes[currentIndex];

    hitboxShowcases.forEach(function(hitboxShowcase:HitboxShowcase) {
      hitboxShowcase.selectionIndex = currentIndex;
    });
  }

  #if FEATURE_TOUCH_CONTROLS
  /**
   * Handles touch dragging.
   */
  function handleDrag():Void
  {
    if (TouchUtil.justPressed && TouchUtil.touch != null) dragStartingX = TouchUtil.touch.x;

    if (TouchUtil.pressed && TouchUtil.touch != null) dragDistance = TouchUtil.touch.x - dragStartingX;

    if (TouchUtil.justReleased)
    {
      dragStartingX = 0;
      dragDistance = 0;
    }

    // trace(dragDistance);
  }

  /**
   * Handles all the touch inputs.
   */
  function handleInputs():Void
  {
    if (isInDemo) return;

    if (currentButton.busy) return;

    handleDrag();

    if (TouchUtil.pressAction(itemNavHitbox))
    {
      hitboxShowcases.members[currentIndex].onPress();

      currentButton.busy = true;
    }
  }

  /**
   * HitboxShowcases X position when the player just pressed on the screen.
   * Used for dragging.
   */
  var originX:Float;

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleInputs();

    if (TouchUtil.justPressed) originX = hitboxShowcases.x;

    if (TouchUtil.pressed && dragDistance != 0)
    {
      final showcasesTargetX:Float = originX + dragDistance * 10;
      hitboxShowcases.x = MathUtil.smoothLerpPrecision(hitboxShowcases.x, showcasesTargetX, elapsed, 0.5);

      final minShowcasesX:Float = -1500 * availableSchemes.length;
      hitboxShowcases.x = FlxMath.bound(hitboxShowcases.x, minShowcasesX, 400);

      final targetIndex:Int = Math.round(hitboxShowcases.x / -1500);

      if (currentIndex != targetIndex) setSelection(targetIndex);
    }
    else
    {
      hitboxShowcases.x = MathUtil.smoothLerpPrecision(hitboxShowcases.x, (-1500 * currentIndex) + (-1500 / (availableSchemes.length + 1) * currentIndex), elapsed, 0.5);
    }
  #end
  }
}
