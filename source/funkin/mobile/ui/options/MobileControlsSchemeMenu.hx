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

// This is kinda BAD, will be remade later
class MobileControlsSchemeMenu extends MusicBeatSubState
{
  // Cameras
  var mainCamera:FunkinCamera;
  var camButtons:FunkinCamera;

  // Objects
  var menuBG:FunkinSprite;
  var curSchemeText:AtlasText;

  // Groups
  var buttonGroup:FlxTypedGroup<SchemeMenuButton>;

  // Variables
  final availableSchemes:Array<String> = [
    FunkinHitboxControlSchemes.FourLanes,
    FunkinHitboxControlSchemes.DoubleThumbTriangle,
    FunkinHitboxControlSchemes.DoubleThumbSquare,
    FunkinHitboxControlSchemes.DoubleThumbDPad
  ];
  final schemeNames:Array<String> = [
    'Four Lanes',
    'Double Thumb Triangle',
    'Double Thumb Square',
    'Double Thumb DPad'
  ];
  var anyButtonBusy:Bool = false;
  var curSelected:Int = 0;
  var isDemoScreen:Bool;

  // stores values of what the previous persistent draw/update stuff was, example if opened
  // from pause menu, we want to NOT draw persistently, but then resume drawing once closed
  var prevPersistentDraw:Bool;
  var prevPersistentUpdate:Bool;

  override function create()
  {
    super.create();

    prevPersistentDraw = FlxG.state.persistentDraw;
    prevPersistentUpdate = FlxG.state.persistentUpdate;

    FlxG.state.persistentDraw = false;
    FlxG.state.persistentUpdate = false;

    setupCameras();

    var colorShader = new AdjustColorShader();
    colorShader.brightness = -200;

    menuBG = FunkinSprite.create('menuDesat');
    menuBG.shader = colorShader;
    menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
    menuBG.updateHitbox();
    menuBG.screenCenter();
    menuBG.scrollFactor.set(0, 0);
    add(menuBG);

    for (i in 0...availableSchemes.length)
    {
      if (availableSchemes[i] == Preferences.controlsScheme) curSelected = i;
    }

    addSchemeMenuButtons();
    createHitboxCamera(availableSchemes[curSelected]);
  }

  function setupCameras()
  {
    mainCamera = new FunkinCamera('mobileControlsSchemeMainCamera');
    mainCamera.bgColor = FlxColor.BLACK;
    FlxG.cameras.add(mainCamera);

    camButtons = new FunkinCamera('camButtons');
    FlxG.cameras.add(camButtons, false);
    camButtons.bgColor = 0x0;
  }

  function createHitboxCamera(controlsScheme:String)
  {
    var h:HitboxShowcase = new HitboxShowcase(-200, 0, 0, curSelected, controlsScheme);
    add(h);
  }

  function createSchemeMenuButton(xPos:Float, yPos:Float, name:String, ?onClick:Void->Void = null)
  {
    var button:SchemeMenuButton = new SchemeMenuButton(xPos, yPos, name, onClick);
    button.cameras = [camButtons];

    buttonGroup.add(button);
  }

  function addSchemeMenuButtons(isDemoScreen:Bool = false)
  {
    buttonGroup = new FlxTypedGroup<SchemeMenuButton>();

    if (isDemoScreen)
    {
      createSchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.1, 'BACK', onHitboxDemoBack);
    }
    else
    {
      createSchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.1, 'DEMO', onHitboxDemo);
      createSchemeMenuButton(FlxG.width * 0.83, FlxG.height * 0.82, 'EXIT', onExitButtonPressed);
    }

    add(buttonGroup);
  }

  function removeSchemeMenuButtons()
  {
    anyButtonBusy = false;

    buttonGroup.forEachAlive(function(button:SchemeMenuButton) {
      buttonGroup.remove(button);
    });

    remove(buttonGroup);
  }

  function onHitboxDemo()
  {
    curSchemeText.visible = false;
    isDemoScreen = true;

    addHitbox(true, false, availableSchemes[curSelected]);
    removeSchemeMenuButtons();
    addSchemeMenuButtons(true);

    hitbox.forEachAlive(function(hint:FunkinHint) {
      buttonGroup.forEachAlive(function(button:SchemeMenuButton) {
        if (!hint.deadZones.contains(cast(button.body, FunkinSprite))) hint.deadZones.push(cast(button.body, FunkinSprite));
      });
    });

    if (hitbox != null) hitbox.active = hitbox.visible = true;
  }

  function onHitboxDemoBack()
  {
    curSchemeText.visible = true;
    isDemoScreen = false;

    removeSchemeMenuButtons();
    addSchemeMenuButtons();

    // (hitboxCamera != null) hitboxCamera.visible = true;
    if (hitbox != null) hitbox.active = hitbox.visible = false;
  }

  function onExitButtonPressed()
  {
    Preferences.controlsScheme = availableSchemes[curSelected];
    FlxG.switchState(() -> new MainMenuState());
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (buttonGroup != null)
    {
      buttonGroup.forEachAlive(function(button:SchemeMenuButton) {
        if (anyButtonBusy)
        {
          button.busy = true;
          return;
        }
        anyButtonBusy = button.busy;
      });
    }
  }
}
