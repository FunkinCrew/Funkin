package funkin.play.notes;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.notestyle.NoteStyle;

class HealthBar extends FlxSpriteGroup
{
  /**
   * The bar which displays the player's health.
   * Dynamically updated based on the value of `healthLerp` (which is based on `health`).
   */
  public var healthBar:FlxBar;

  /**
   * The background image used for the health bar.
   * Emma says the image is slightly skewed so I'm leaving it as an image instead of a `createGraphic`.
   */
  public var healthBarBG:FunkinSprite;

  /**
   * The displayed value of the player's health.
   * Used to provide smooth animations based on linear interpolation of the player's health.
   */
  public var healthLerp:Float;

  /**
   * The current health bar value.
   */
  public var value(get, never):Float;

  function get_value():Float
  {
    return healthBar?.value ?? 0;
  }

  final isDownscroll:Bool;
  final noteStyle:NoteStyle;

  public function new(noteStyle:NoteStyle):Void
  {
    super(0, 0);

    isDownscroll = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
      && !ControlsHandler.usingExternalInputDevice)
      || #end Preferences.downscroll;
    healthLerp = Constants.HEALTH_STARTING;

    this.noteStyle = noteStyle;
    var assetPath:String = noteStyle.getHealthBarAssetPath();
    var scale:Float = noteStyle.getHealthBarScale();
    var padding:Array<Float> = noteStyle.getHealthBarPadding();

    healthBarBG = FunkinSprite.create(0, 0, assetPath);
    healthBarBG.scale.set(scale, scale);
    healthBarBG.y = isDownscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
    healthBarBG.screenCenter(X);
    healthBarBG.scrollFactor.set(0, 0);
    healthBarBG.zIndex = 100;
    this.add(healthBarBG);

    healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - padding[0]), Std.int(healthBarBG.height - padding[1]), this, 'healthLerp', 0, 2);
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    healthBar.zIndex = 200;
    this.add(healthBar);
  }

  /**
   * Updates the values of the health bar.
   * @param health Current health.
   * @param skipLerp If enabled, the lerp will be entirely skipped.
   */
  public function updateHealthBar(health:Float, ?skipLerp:Bool = false):Void
  {
    if (skipLerp)
    {
      healthLerp = health;
    }
    else
    {
      healthLerp = FlxMath.lerp(healthLerp, health, 0.15);
    }
  }
}
