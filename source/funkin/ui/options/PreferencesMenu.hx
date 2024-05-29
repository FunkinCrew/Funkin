package funkin.ui.options;

import flixel.FlxCamera;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.math.FlxMath;
import flixel.effects.FlxFlicker;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import funkin.ui.AtlasText.AtlasFont;
import funkin.ui.options.OptionsState.Page;
import funkin.graphics.FunkinCamera;
import funkin.audio.FunkinSound;

class PreferencesMenu extends Page
{
  /**
   * Wether you can select a different option
   */
  public static var allowScrolling:Bool = true;

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
    pref.changeDelay = 0.05;
    addPref(pref);
    #end

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Naughtyness', 'Toggle displaying raunchy content', Preferences.naughtyness,
      function(value:Bool):Void {
        Preferences.naughtyness = value;
      });
    addPref(pref);

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Downscroll', 'Enable to make notes move downwards', Preferences.downscroll,
      function(value:Bool):Void {
        Preferences.downscroll = value;
      });
    addPref(pref);

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Flashing Lights', 'Disable to dampen flashing effects', Preferences.flashingLights,
      function(value:Bool):Void {
        Preferences.flashingLights = value;
      });
    addPref(pref);

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Camera Zooming on Beat', 'Disable to stop the camera bouncing to the song',
      Preferences.zoomCamera, function(value:Bool):Void {
        Preferences.zoomCamera = value;
    });
    addPref(pref);

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Debug Display', 'Enable to show FPS and other debug stats', Preferences.debugDisplay,
      function(value:Bool):Void {
        Preferences.debugDisplay = value;
      });
    addPref(pref);

    var pref:CheckboxPreferenceItem = new CheckboxPreferenceItem('Auto Pause', 'Automatically pause the game when it loses focus', Preferences.autoPause,
      function(value:Bool):Void {
        Preferences.autoPause = value;
      });
    addPref(pref);
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
      if (pref.ID == curSelected)
      {
        pref.onSelect(true);
        camFollow.y = pref.y;
      }
      else
      {
        pref.onSelect(false);
      }
    }
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (controls.UI_DOWN_P && allowScrolling)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'));
      changeSelection(1);
    }
    else if (controls.UI_UP_P && allowScrolling)
    {
      FunkinSound.playOnce(Paths.sound('scrollMenu'));
      changeSelection(-1);
    }

    var selectedPref:PreferenceItem = prefs.members[curSelected];
    selectedPref?.handleInput(elapsed);
  }
}

class PreferenceItem extends FlxTypedSpriteGroup<FlxSprite>
{
  public var name:String = "";
  public var description:String = "";

  public function handleInput(elapsed:Float):Void {}

  public function onSelect(isSelected:Bool):Void {}
}

class NumberedPreferenceItem extends PreferenceItem
{
  public var onChange:Float->Void;
  public var changeRate:Float = 1.0;
  public var changeDelay:Float = 0.1;

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

    this.valueText = new AtlasText(20, 30, '$defaultValue', AtlasFont.DEFAULT);
    add(this.valueText);

    this.preferenceText = new AtlasText(this.valueText.x + this.valueText.width + 30, 30, '$name', AtlasFont.BOLD);
    add(this.preferenceText);

    this.name = name;
    this.description = description;
    this.onChange = onChange;
    this.currentValue = defaultValue;
  }

  var timeToWait:Float = 0;

  public override function handleInput(elapsed:Float):Void
  {
    timeToWait -= elapsed;

    if (timeToWait > 0)
    {
      return;
    }

    if (PlayerSettings.player1.controls.UI_RIGHT)
    {
      currentValue += changeRate;
      timeToWait = changeDelay;
      // FunkinSound.playOnce(Paths.sound('scrollMenu'));
    }
    else if (PlayerSettings.player1.controls.UI_LEFT)
    {
      currentValue -= changeRate;
      timeToWait = changeDelay;
      // FunkinSound.playOnce(Paths.sound('scrollMenu'));
    }
  }

  var isSelected:Bool = false;

  public override function onSelect(isSelected:Bool):Void
  {
    this.isSelected = isSelected;
    if (isSelected)
    {
      preferenceText.x = valueText.x + valueText.width + 60;
      preferenceText.alpha = 1.0;
    }
    else
    {
      preferenceText.x = valueText.x + valueText.width + 30;
      preferenceText.alpha = 0.6;
    }
  }

  function updateText():Void
  {
    valueText.text = '$currentValue';
    preferenceText.x = valueText.x + valueText.width + (isSelected ? 60 : 30);
  }
}

class CheckboxPreferenceItem extends PreferenceItem
{
  public var onChange:Bool->Void;

  public var currentValue(default, set):Bool;

  function set_currentValue(value:Bool):Bool
  {
    if (value)
    {
      checkBox.animation.play('checked', true);
      checkBox.offset.set(17, 70);
    }
    else
    {
      checkBox.animation.play('static');
      checkBox.offset.set();
    }
    currentValue = value;
    onChange(value);
    return value;
  }

  var checkBox:FlxSprite;
  var preferenceText:AtlasText;

  public function new(name:String, description:String, defaultValue:Bool, onChange:Bool->Void)
  {
    super();

    this.checkBox = new FlxSprite();
    this.checkBox.frames = Paths.getSparrowAtlas('checkboxThingie');
    this.checkBox.animation.addByPrefix('static', 'Check Box unselected', 24, false);
    this.checkBox.animation.addByPrefix('checked', 'Check Box selecting animation', 24, false);
    this.checkBox.setGraphicSize(Std.int(this.checkBox.width * 0.7));
    this.checkBox.updateHitbox();
    add(this.checkBox);

    this.preferenceText = new AtlasText(120, 30, '$name', AtlasFont.BOLD);
    add(this.preferenceText);

    this.name = name;
    this.description = description;
    this.onChange = onChange;
    this.currentValue = defaultValue;
  }

  var isAccepting:Bool = false;

  public override function handleInput(elapsed:Float):Void
  {
    if (PlayerSettings.player1.controls.ACCEPT && !isAccepting)
    {
      isAccepting = true;
      PreferencesMenu.allowScrolling = false;
      FunkinSound.playOnce(Paths.sound('confirmMenu'));
      FlxFlicker.flicker(preferenceText, 1, 0.06, true, false, function(_) {
        isAccepting = false;
        PreferencesMenu.allowScrolling = true;
        currentValue = !currentValue;
      });
    }
  }

  public override function onSelect(isSelected:Bool):Void
  {
    if (isSelected)
    {
      preferenceText.x = 150;
      preferenceText.alpha = 1.0;
    }
    else
    {
      preferenceText.alpha = 0.6;
      preferenceText.x = 120;
    }
  }
}
