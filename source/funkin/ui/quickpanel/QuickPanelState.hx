package funkin.ui.quickpanel;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import openfl.filters.ShaderFilter;
import flixel.util.FlxTimer;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.audio.FunkinSound;
import funkin.ui.quickpanel.QuickPanelButton;
import funkin.input.Controls;
import funkin.util.InputUtil;
import flixel.input.keyboard.FlxKey;
import funkin.group.FunkinGroup;
import funkin.ui.quickpanel.QuickPanelShader;
import funkin.ui.quickpanel.CircleWipeShader;
import funkin.graphics.shaders.BoilShader;
import funkin.util.PropertyAnimator;
import funkin.ui.quickpanel.QuickPanelGroup;

class QuickPanelState extends MusicBeatSubState
{
  /**
   * An extra camera for the state.
   */
  public var panelCam:FunkinCamera;

  public var bg:FunkinSprite;

  var circleWipe:CircleWipeShader;
  var descriptionText:FlxText;
  var descriptionPanel:FunkinSprite;
  var panel:QuickPanelGroup;
  var DESCRIPTION_PANEL_Y:Float = 0;
  var DESCRIPTION_TEXT_Y:Float = 0;
  var DESCRIPTION_OFFSET:Float = 100;

  public var paWipe:PropertyAnimator;
  public var paMiddle:PropertyAnimator;
  public var wipeSprite:FlxSprite;
  public var selectedIcon:FunkinSprite;
  public var selectedSplash:FunkinSprite;

  var left:Bool = false;

  public function repositionSide(_left:Bool = false)
  {
    left = _left;

    var DESCRIPTION_TEXT_BASE_X = left ? FlxG.width + 443 : FlxG.width - 443;

    descriptionText.x = (DESCRIPTION_TEXT_BASE_X / 2) - descriptionText.width / 2;

    wipeSprite.flipX = left;

    panel.repositionSide(left);
  }

  public function new()
  {
    super();
  }

  override function create()
  {
    super.create();

    // dedicated camera for the ability to have our own zoom/scroll
    panelCam = new FunkinCamera('panelCam', 0, 0, FlxG.width, FlxG.height);
    panelCam.bgColor = FlxColor.TRANSPARENT;
    panelCam.zoom = 1;
    FlxG.cameras.add(panelCam, false);

    bg = new FunkinSprite(0, 0);
    bg.makeSolidColor(camera.width * 2, camera.height * 2, 0xFF1A1A1A);
    bg.scrollFactor.set(0, 0);
    bg.alpha = 0;
    bg.updateHitbox();
    bg.screenCenter();
    add(bg);

    descriptionPanel = new FunkinSprite(0, 0);
    descriptionPanel.makeSolidColor(camera.width * 2, 60, 0xFF0B0B0B);
    descriptionPanel.scrollFactor.set(0, 0);
    descriptionPanel.updateHitbox();
    descriptionPanel.screenCenter(X);
    DESCRIPTION_PANEL_Y = FlxG.height - descriptionPanel.height;
    descriptionPanel.y = DESCRIPTION_PANEL_Y + DESCRIPTION_OFFSET;
    add(descriptionPanel);

    descriptionText = new FlxText(0, 0, 800, 'lol', 30);
    descriptionText.setFormat(funkin.assets.Paths.font('ui/fonts/FunkinOptions', 'otf'), 30, 0xFFE6E6E6, CENTER);
    add(descriptionText);

    panel = new QuickPanelGroup(this);
    add(panel);

    DESCRIPTION_TEXT_Y = (DESCRIPTION_PANEL_Y + descriptionPanel.height / 2) - descriptionText.height / 2;
    descriptionText.y = DESCRIPTION_TEXT_Y;

    descriptionText.offset.y = -4;

    wipeSprite = new FlxSprite(0, 0).makeGraphic(camera.width, camera.height, 0x00FFFFFF);
    wipeSprite.scrollFactor.set(0, 0);
    wipeSprite.updateHitbox();
    wipeSprite.screenCenter();
    wipeSprite.visible = false;
    add(wipeSprite);

    circleWipe = new CircleWipeShader();
    wipeSprite.shader = circleWipe;

    selectedIcon = new FunkinSprite(0, 0);
    selectedIcon.scrollFactor.set(0, 0);
    selectedIcon.visible = false;
    add(selectedIcon);

    selectedSplash = new FunkinSprite(0, 0);
    selectedSplash.frames = Paths.getSparrowAtlas('ui/quick-panel/splash');
    selectedSplash.animation.addByPrefix('splash', 'splash0', 24, false);
    selectedSplash.screenCenter();
    selectedSplash.visible = false;
    selectedSplash.scale.set(1.85, 1.85);
    add(selectedSplash);

    selectedIcon.color = 0xFFCCCCCC;
    selectedSplash.color = 0xFFCCCCCC;

    setupAnims();

    forEach(function(obj)
    {
      obj.cameras = [panelCam];
    });

    repositionSide(left);
  }

  public function fadeScreen(out:Bool = false)
  {
    FlxTween.cancelTweensOf(bg);

    FlxTween.tween(bg, {
      alpha: out ? 0.0 : 0.6
    }, 0.3, {
      ease: FlxEase.expoOut
    });

    FlxTween.cancelTweensOf(descriptionPanel);
    FlxTween.cancelTweensOf(descriptionText);

    FlxTween.tween(descriptionPanel, {
      y: out ? DESCRIPTION_PANEL_Y + DESCRIPTION_OFFSET : DESCRIPTION_PANEL_Y
    }, 0.4, {
      ease: FlxEase.expoOut
    });

    FlxTween.tween(descriptionText, {
      y: out ? DESCRIPTION_TEXT_Y + DESCRIPTION_OFFSET : DESCRIPTION_TEXT_Y
    }, 0.4, {
      ease: FlxEase.expoOut
    });
  }

  public function setupAnims()
  {
    paWipe = new PropertyAnimator(circleWipe);

    paWipe.addAnimationByName('wipe', 24, false);

    paWipe.addProperty('wipe', 'circleRadius', [
      3.1,
      3.8,
      4.3,
      4.6,
      4.8,
      10
    ]);

    paWipe.setDefaultProperties();

    paMiddle = new PropertyAnimator(selectedIcon);

    paMiddle.addAnimationByName('bump', 24, false);

    paMiddle.addProperty('bump', 'scale.x', [
      1.4,
      1.4,
      1.6,
      1.6,
      1.55,
      1.55,
      1.1,
      1.1,
      1.17,
      1.17,
      1.2
    ]);

    paMiddle.addProperty('bump', 'scale.y', [
      1.4,
      1.4,
      1.6,
      1.6,
      1.55,
      1.55,
      1.1,
      1.1,
      1.17,
      1.17,
      1.2
    ]);

    paMiddle.addProperty('bump', 'angle', [
      2,
      2,
      2.2,
      2.2,
      1.9,
      1.9,
      0.5,
      0.5,
      0.1,
      0.1,
      0
    ]);

    paMiddle.setDefaultProperties();
  }

  public function updateDescription(_text:String)
  {
    descriptionText.text = _text;
  }

  public function startTransition(data:QuickPanelButtonData)
  {
    selectedIcon.loadGraphic(Paths.image('ui/quick-panel/icons/${data.icon}'));
    selectedIcon.scale.set(1.4, 1.4);
    selectedIcon.antialiasing = true;
    selectedIcon.updateHitbox();
    selectedIcon.screenCenter();

    new FlxTimer().start(6 / 24, (_) ->
    {
      wipeSprite.visible = true;
      paWipe.playAnimation('wipe', true);
    });

    new FlxTimer().start(8 / 24, (_) ->
    {
      selectedIcon.visible = true;
      paMiddle.playAnimation('bump', true);

      selectedSplash.visible = true;
      selectedSplash.animation.play('splash');
    });

    new FlxTimer().start(22 / 24, (_) -> finish());
  }

  function finish()
  {
    FlxTween.tween(selectedIcon, {
      alpha: 0
    }, 8 / 24, {
      ease: FlxEase.expoOut
    });
    panel.currentButton.doCallback();
  }

  public override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.F)
    {
      repositionSide(!left);
    }
  }

  public override function destroy():Void
  {
    if (FlxG.sound.music != null)
    {
      FlxG.sound.music.volume = panel.rememberedVolume;
    }

    // cancel all tweens juuuust in case
    FlxTween.cancelTweensOf(bg);
    // FlxTween.cancelTweensOf(panel);

    super.destroy();
    // remove and destroy panel camera
    FlxG.cameras.remove(panelCam);
  }
}
