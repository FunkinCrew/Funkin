package funkin.ui.charSelect.icons;

import flixel.FlxObject;
import flixel.math.FlxRect;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.FunkinSprite;
import funkin.group.FunkinGroup;
import funkin.input.Controls;
import funkin.ui.charSelect.CharacterSelectState;
import funkin.ui.freeplay.charselect.PlayableCharacter;
import funkin.util.FramesJSFLParser;
import funkin.util.MathUtil;
import openfl.display.BlendMode;
import openfl.filters.BitmapFilter;
import openfl.filters.DropShadowFilter;

/**
 * A `FunkinGroup` that holds all of the icons for the Character Select screen.
 */
@:nullSafety
class IconGroup extends FunkinGroup<FunkinSprite>
{
  /**
   * The filters applied to the currently selected icon.
   */
  public static final SELECTED_FILTERS:Array<BitmapFilter> = [
    new DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
    new DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
  ];

  /**
   * The path to the icon animation info file.
   */
  public static final ICON_ANIMATION_INFO_PATH:String = 'ui/character-select/interface/icon-bop/info.txt';

  /**
   * The distance between icons in the X axis.
   * @default 107
   */
  public var iconSpreadX:Float = 107;

  /**
   * The distance between icons in the Y axis.
   * @default 127
   */
  public var iconSpreadY:Float = 127;

  var controls(get, never):Controls;

  function get_controls():Controls
  {
    @:privateAccess
    return CharacterSelectState.instance.controls;
  }

  var introTween:Null<FlxTween> = null;
  var exitTween:Null<FlxTween> = null;
  var _iconAnimationInfo:Null<Null<FramesJSFLInfo>>;

  public function new(x:Float = 0, y:Float = 0)
  {
    super(x, y);

    _iconAnimationInfo = FramesJSFLParser.parse(Paths.file(ICON_ANIMATION_INFO_PATH));
    if (_iconAnimationInfo == null)
    {
      throw 'Failed to icon animation data at path ${ICON_ANIMATION_INFO_PATH}, is the path provided correct?';
    }

    this.scrollFactor.set();
  }

  @:privateAccess
  public function loadCharacters():Void
  {
    if (CharacterSelectState.instance == null) return;

    for (i in 0...CharacterSelectState.instance.totalSlots)
    {
      if (CharacterSelectState.instance.availableChars.exists(i)
        && PlayerRegistry.instance.isCharacterSeen(CharacterSelectState.instance.availableChars.get(i) ?? Constants.DEFAULT_CHARACTER))
      {
        var path:Null<String> = CharacterSelectState.instance.availableChars.get(i) ?? Constants.DEFAULT_CHARACTER;
        var temp:PixelatedIcon = new PixelatedIcon(0, 0);
        temp.setCharacter(path);
        temp.setGraphicSize(128, 128);
        temp.updateHitbox();
        temp.ID = 0;

        this.add(temp);
      }
      else
      {
        var playableCharacterId:Null<String> = CharacterSelectState.instance.availableChars.get(i) ?? Constants.DEFAULT_CHARACTER;
        var player:Null<PlayableCharacter> = PlayerRegistry.instance.fetchEntry(playableCharacterId);
        var isPlayerUnlocked:Bool = player?.isUnlocked() ?? false;
        if (CharacterSelectState.instance.availableChars.exists(i) && isPlayerUnlocked) CharacterSelectState.instance.nonLocks.push(i);

        var temp:Lock = new Lock(0, 0, i);

        temp.ID = 1;

        this.add(temp);
      }

      if (i >= CharacterSelectState.SLOTS_PER_PAGE) continue;

      var hitTemp:FlxObject = new FlxObject(this.children[i].x, this.children[i].y, 86, 86);
      hitTemp.active = false;
      hitTemp.scrollFactor.set();

      @:privateAccess
      CharacterSelectState.instance.grpHitboxes.add(hitTemp);
    }

    updateIconPositions();
  }

  public function doIntroTween():Void
  {
    if (introTween != null) introTween.cancel();

    this.y += 300;
    introTween = FlxTween.tween(this, {y: this.y - 300}, 1, {ease: FlxEase.expoOut});
    introTween.start();
  }

  public function doExitTween():Void
  {
    if (exitTween != null) exitTween.cancel();

    exitTween = FlxTween.tween(this, {y: this.y + 300}, 0.8, {ease: FlxEase.backIn});
    exitTween.start();
  }

  public function updateIconPositions():Void
  {
    for (index => member in this.children)
    {
      var posX:Float = (index % CharacterSelectState.SLOTS_PER_ROW);
      var posY:Float = Math.floor(index / CharacterSelectState.SLOTS_PER_ROW);

      member.localX = posX * iconSpreadX;
      member.localY = posY * iconSpreadY;

      member.localX += CharacterSelectState.CUTOUT_SIZE + 450;
      member.localY += 120;
    }
  }

  var bopTimer:Float = 0;
  var delay:Float = 1 / 24;
  var bopFr:Int = 0;
  var bopPlay:Bool = false;
  var bopRefX:Float = 0;
  var bopRefY:Float = 0;

  function doBop(icon:PixelatedIcon, elapsed:Float):Void
  {
    if (_iconAnimationInfo == null) return;
    if (bopFr >= _iconAnimationInfo.frames.length)
    {
      bopRefX = 0;
      bopRefY = 0;
      bopPlay = false;
      bopFr = 0;
      return;
    }
    bopTimer += elapsed;

    if (bopTimer >= delay)
    {
      bopTimer -= bopTimer;

      var refFrame = _iconAnimationInfo.frames[
        _iconAnimationInfo.frames.length - 1
      ];
      var curFrame = _iconAnimationInfo.frames[bopFr];
      if (bopFr >= 13) icon.filters = SELECTED_FILTERS;

      var scaleXDiff:Float = curFrame.scaleX - refFrame.scaleX;
      var scaleYDiff:Float = curFrame.scaleY - refFrame.scaleY;

      icon.scale.set(2.6, 2.6);
      icon.scale.add(scaleXDiff, scaleYDiff);

      bopFr++;
    }
  }

  function updateIconAnimations():Void
  {
    if (CharacterSelectState.instance == null) return;

    for (index => member in this.children)
    {
      switch (member.ID)
      {
        case 1:
          var lock:Lock = cast member;
          if (index == CharacterSelectState.instance.currentSelection)
          {
            switch (lock.getCurrentAnimation())
            {
              case 'idle':
                lock.animation.play('selected');
              case 'selected' | 'clicked':
                @:privateAccess
                if (controls.ACCEPT_P || CharacterSelectState.instance.mobileAccept) lock.animation.play('clicked', true);
            }
          }
          else
          {
            lock.animation.play('idle');
          }
        case 0:
          var memb:PixelatedIcon = cast member;

          if (index == CharacterSelectState.instance.currentSelection)
          {
            if (bopPlay)
            {
              if (bopRefX == 0)
              {
                bopRefX = memb.x;
                bopRefY = memb.y;
              }
              doBop(memb, FlxG.elapsed);
            }
            else
            {
              memb.filters = SELECTED_FILTERS;
              memb.scale.set(2.6, 2.6);
            }
            if (CharacterSelectState.instance.pressedSelect && memb.animation.curAnim?.name == 'idle') memb.animation.play('confirm');
            if (CharacterSelectState.instance.autoFollow
              && !CharacterSelectState.instance.pressedSelect
              && memb.animation.curAnim?.name != 'idle')
            {
              memb.animation.play('confirm', false, true);

              var onFinish:String->Void;
              onFinish = (_) ->
              {
                member.animation.play('idle');
                member.animation.onFinish.remove(onFinish);
              };

              member.animation.onFinish.add(onFinish);
            }
          }
          else
          {
            memb.filters = null;
            memb.scale.set(2, 2);
          }
      }
    }
  }

  var previousPage:Int = 0;

  override public function update(elapsed:Float):Void
  {
    super.update(elapsed);

    updateIconAnimations();

    if (CharacterSelectState.instance == null) return;

    var currentPage:Int = Math.floor(CharacterSelectState.instance.currentSelection / CharacterSelectState.SLOTS_PER_PAGE);

    if (introTween != null && introTween.active)
    {
      if (previousPage != currentPage)
      {
        @:privateAccess
        introTween.finish();
      }
    }
    else
    {
      this.y = MathUtil.smoothLerpPrecision(this.y, (120 - currentPage * iconSpreadY * 3) - 120, elapsed, CharacterSelectState.SLOT_LERP_VALUE);
    }

    // Update icon visibility based on the current page.
    for (index => member in this.children)
    {
      var memberPage:Int = Math.floor(index / CharacterSelectState.SLOTS_PER_PAGE);
      var isFirst3:Bool = (index % CharacterSelectState.SLOTS_PER_PAGE) < 3;
      var targetAlpha:Float = (memberPage == currentPage) ? 1 : (isFirst3 ? 0.5 : 0);

      member.localAlpha = MathUtil.smoothLerpPrecision(member.localAlpha, targetAlpha, elapsed, CharacterSelectState.SLOT_LERP_VALUE);

      if (isFirst3 && memberPage != currentPage)
      {
        member.blend = BlendMode.MULTIPLY;

        if (member.clipRect == null)
        {
          member.clipRect = FlxRect.get(0, 0, member.frameWidth, member.frameHeight / 2);
        }
      }
      else
      {
        member.blend = BlendMode.NORMAL;

        if (member.clipRect != null)
        {
          @:nullSafety(Off)
          member.clipRect = null;
        }
      }
    }

    previousPage = currentPage;
  }
}
