package funkin.play.notes;

import flixel.group.FlxSpriteGroup;
import flixel.math.FlxMath;
import flixel.ui.FlxBar;
import funkin.graphics.FunkinSprite;
import funkin.play.notes.notestyle.NoteStyle;

class HealthBar extends FlxSpriteGroup
{
  final noteStyle:NoteStyle;

  public var healthBar:FlxBar;
  public var healthBarBG:Null<FunkinSprite>;
  public var isBotPlayMode:Bool;

  final isDownscroll:Bool = #if mobile (Preferences.controlsScheme == FunkinHitboxControlSchemes.Arrows
    && !ControlsHandler.usingExternalInputDevice)
    || #end Preferences.downscroll;

  public var healthLerp:Float = Constants.HEALTH_STARTING;

  public function new(noteStyle, isBotPlayMode:Bool = false):Void
  {
    super(0, 0);
    this.noteStyle = noteStyle;
    this.isBotPlayMode = isBotPlayMode;
    var padding = noteStyle.getHealthBarPadding();
    trace(Paths.image(noteStyle.getHealthBarAssetPath()));
    healthBarBG = FunkinSprite.create(0, 0, "healthBar");
    healthBar = new FlxBar(0, 0, RIGHT_TO_LEFT, Std.int(healthBarBG.width - padding[0]), Std.int(healthBarBG.height - padding[1]), this, 'healthLerp', 0, 2);
    var scale = noteStyle.getHealthBarScale();
    if (healthBarBG != null)
    {
      healthBarBG.scale.set(scale, scale);
      healthBarBG.y = isDownscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
      healthBarBG.screenCenter(X);
      healthBarBG.scrollFactor.set(0, 0);
      healthBarBG.zIndex = 800;
      noteStyle.applyHealthBarOffsets(this);
      this.add(healthBarBG);
    }
    else
    {
      healthBarBG = FunkinSprite.create(0, 0, 'healthBar');
      healthBarBG.scale.set(scale, scale);
      healthBarBG.y = isDownscroll ? FlxG.height * 0.1 : FlxG.height * 0.9;
      healthBarBG.screenCenter(X);
      healthBarBG.scrollFactor.set(0, 0);
      healthBarBG.zIndex = 800;
      noteStyle.applyHealthBarOffsets(this);
      this.add(healthBarBG);
    }

    healthBar.x = healthBarBG.x + padding[0] / 2;
    healthBar.y = healthBarBG.y + padding[1] / 2;
    healthBar.scrollFactor.set();
    healthBar.createFilledBar(Constants.COLOR_HEALTH_BAR_RED, Constants.COLOR_HEALTH_BAR_GREEN);
    healthBar.zIndex = 801;
    this.add(healthBar);
  }

  /**
   * Updates the values of the health bar.
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
}
