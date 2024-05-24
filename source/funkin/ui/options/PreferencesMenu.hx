package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.graphics.FunkinCamera;

class PreferencesMenu extends Page
{
  var curSelected:Int = 0;
  var prefs:FlxTypedSpriteGroup<PreferenceItem>;

  var menuCamera:FlxCamera;
  var camFollow:FlxObject;

  public function new()
  {
    super();

    menuCamera = new FunkinCamera('prefMenu');
    FlxG.cameras.add(menuCamera, false);
    menuCamera.bgColor = 0x0;
    camera = menuCamera;

    prefs = new FlxTypedSpriteGroup<PreferenceItem>();
    add(prefs);

    createPrefItems();

    camFollow = new FlxObject(FlxG.width / 2, 0, 140, 70);

    menuCamera.follow(camFollow, null, 0.06);
    var margin = 160;
    menuCamera.deadzone.set(0, margin, menuCamera.width, 40);
    menuCamera.minScrollY = 0;

    changeSelection(0);
  }

  function addPref(pref:PreferenceItem):Void
  {
    pref.x = 0;
    pref.y = 120 * prefs.length;
    pref.ID = prefs.length;
    prefs.add(pref);
  }

  /**
   * Create the menu items for each of the preferences.
   */
  function createPrefItems():Void
  {
    #if !web
    var pref:NumberedPreferenceItem = new NumberedPreferenceItem("FPS", "The framerate that the game is running on", Preferences.framerate,
      function(value:Float):Void {
        Preferences.framerate = Std.int(value);
      });
    pref.minValue = 60;
    pref.maxValue = 360;
    pref.changeRate = 1;
    pref.changeSpeed = 0.05;
    addPref(pref);
    #end

    // TODO: add these back
    // createPrefItemCheckbox('Naughtyness', 'Toggle displaying raunchy content', function(value:Bool):Void {
    //   Preferences.naughtyness = value;
    // }, Preferences.naughtyness);
    // createPrefItemCheckbox('Downscroll', 'Enable to make notes move downwards', function(value:Bool):Void {
    //   Preferences.downscroll = value;
    // }, Preferences.downscroll);
    // createPrefItemCheckbox('Flashing Lights', 'Disable to dampen flashing effects', function(value:Bool):Void {
    //   Preferences.flashingLights = value;
    // }, Preferences.flashingLights);
    // createPrefItemCheckbox('Camera Zooming on Beat', 'Disable to stop the camera bouncing to the song', function(value:Bool):Void {
    //   Preferences.zoomCamera = value;
    // }, Preferences.zoomCamera);
    // createPrefItemCheckbox('Debug Display', 'Enable to show FPS and other debug stats', function(value:Bool):Void {
    //   Preferences.debugDisplay = value;
    // }, Preferences.debugDisplay);
    // createPrefItemCheckbox('Auto Pause', 'Automatically pause the game when it loses focus', function(value:Bool):Void {
    //   Preferences.autoPause = value;
    // }, Preferences.autoPause);
  }

  function changeSelection(change:Int):Void
  {
    curSelected += change;
    if (curSelected < 0)
    {
      curSelected = prefs.length - 1;
    }
    else if (curSelected >= prefs.length)
    {
      curSelected = 0;
    }

    for (pref in prefs)
    {
      pref.x = 0;
      if (pref.ID == curSelected)
      {
        pref.x = 20;
        camFollow.y = pref.y;
      }
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.UI_DOWN_P)
    {
      changeSelection(1);
    }
    else if (controls.UI_UP_P)
    {
      changeSelection(-1);
    }

    var selectedPref:PreferenceItem = prefs.members[curSelected];
    selectedPref.handleInput(elapsed);
  }
}

class PreferenceItem extends FlxTypedSpriteGroup<FlxSprite>
{
  public var name:String = "";
  public var description:String = "";

  public function handleInput(deltaTime:Float):Void {}
}

class NumberedPreferenceItem extends PreferenceItem
{
  public var onChange:Float->Void;
  public var changeRate:Float = 1.0;
  public var changeSpeed:Float = 0.1;

  public var minValue(default, set):Null<Float>;

  function set_minValue(value:Float):Float
  {
    minValue = value;
    currentValue = currentValue;
    return value;
  }

  public var maxValue(default, set):Null<Float>;

  function set_maxValue(value:Float):Float
  {
    maxValue = value;
    currentValue = currentValue;
    return value;
  }

  public var currentValue(default, set):Float;

  function set_currentValue(value:Float):Float
  {
    currentValue = FlxMath.bound(value, minValue, maxValue);
    onChange(currentValue);
    updateText();
    return currentValue;
  }

  var valueText:AtlasText;
  var preferenceText:AtlasText;

  public function new(name:String, description:String, defaultValue:Float, onChange:Float->Void)
  {
    super();

    this.valueText = new AtlasText(0, 0, '$defaultValue', AtlasFont.DEFAULT);
    add(this.valueText);

    this.preferenceText = new AtlasText(this.valueText.width + 30, 0, '$name', AtlasFont.BOLD);
    add(this.preferenceText);

    this.name = name;
    this.description = description;
    this.onChange = onChange;
    this.currentValue = defaultValue;
  }

  var timeToWait:Float = 0;

  public override function handleInput(deltaTime:Float):Void
  {
    timeToWait -= deltaTime;

    if (timeToWait > 0)
    {
      return;
    }

    if (PlayerSettings.player1.controls.UI_RIGHT)
    {
      currentValue += changeRate;
      timeToWait = changeSpeed;
    }
    else if (PlayerSettings.player1.controls.UI_LEFT)
    {
      currentValue -= changeRate;
      timeToWait = changeSpeed;
    }
  }

  function updateText():Void
  {
    valueText.text = '$currentValue';
    preferenceText.x = valueText.width + 30;
  }
}

class CheckboxPreferenceItem extends FlxSprite
{
  public var currentValue(default, set):Bool;

  public function new(x:Float, y:Float, defaultValue:Bool = false)
  {
    super(x, y);

    frames = Paths.getSparrowAtlas('checkboxThingie');
    animation.addByPrefix('static', 'Check Box unselected', 24, false);
    animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);

    setGraphicSize(Std.int(width * 0.7));
    updateHitbox();

    this.currentValue = defaultValue;
  }

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    switch (animation.curAnim.name)
    {
      case 'static':
        offset.set();
      case 'checked':
        offset.set(17, 70);
    }
  }

  function set_currentValue(value:Bool):Bool
  {
    if (value)
    {
      animation.play('checked', true);
    }
    else
    {
      animation.play('static');
    }

    return currentValue = value;
  }
}
