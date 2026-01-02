package funkin.play.notes;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.notestyle.NoteStyle;

/**
 * The sprite group that contains the health bar and background, and updates dynamically based on the player's health.
 */
class HealthBar extends FlxSpriteGroup
{
  final noteStyle:NoteStyle;

  /**
   * The FlxBar that reflects the value of the player's health.
   */
  public var healthBar:FlxBar;

  /**
   * The sprite that the health bar uses for it's background
   */
  public var healthBarBG:FunkinSprite;

  /**
   * The value of the player's health.
   */
  public var healthLerp:Float;

  public var value(get, set):Float;

  public var isBotPlayMode:Bool;

  final isDownscroll:Bool;

  public function new(noteStyle, isBotPlayMode:Bool):Void
  {
    super(0, 0);
    this.noteStyle = noteStyle;
    this.isBotPlayMode = isBotPlayMode;
    this.isDownscroll = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
      && !ControlsHandler.usingExternalInputDevice)
      || #end Preferences.downscroll;
    this.healthLerp = Constants.HEALTH_STARTING;

    var padding = noteStyle.getHealthBarPadding();
    var assetPath = noteStyle.getHealthBarAssetPath();
    var scale = noteStyle.getHealthBarScale();

    healthBarBG = FunkinSprite.create(0, 0, assetPath ?? "healthBar");
    healthBarBG.scale.set(scale, scale);
    healthBarBG.y = isDownscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set(0, 0);
    healthBarBG.zIndex = 800;
    this.add(healthBarBG);

    healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int((healthBarBG.width - padding[0]) * scale), Std.int((healthBarBG.height - padding[1]) * scale), this,
      'healthLerp', 0, 2);
    healthBar.x = healthBarBG.x / scale + padding[0] / 2;
    healthBar.y = healthBarBG.y + padding[1] / 2;
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    healthBar.zIndex = 801;
    this.value = healthBar.value;
    this.add(healthBar);

    noteStyle.applyHealthBarOffsets(this);
  }

  /**
   * Updates the values of the health bar.
   * @param health The health value that the bar should reflect
   */
  public function updateHealthBar(health:Float):Void
  {
    if (isBotPlayMode)
    {
      healthLerp = Constants.HEALTH_MAX;
    }
    else
    {
      healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
    }
  }

  function get_value():Float
  {
    return healthBar.value;
  }

  function set_value(newValue:Float):Float
  {
    healthBar.value = newValue;
    return value;
  }
}
