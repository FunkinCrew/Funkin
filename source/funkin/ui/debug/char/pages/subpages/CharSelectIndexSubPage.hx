package funkin.ui.debug.char.pages.subpages;

import funkin.audio.FunkinSound;
import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.graphics.FunkinSprite;
import flixel.group.FlxSpriteGroup.FlxTypedSpriteGroup;
import flixel.group.FlxSpriteGroup;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import openfl.display.BlendMode;
import openfl.filters.ShaderFilter;
import funkin.ui.charSelect.Lock;
import funkin.util.MathUtil;
import flixel.math.FlxPoint;
import flixel.math.FlxMath;
import flixel.FlxG;

class CharSelectIndexSubPage extends FlxSpriteGroup
{
  var parentPage:CharCreatorSelectPage;

  var cursor:FlxSprite;
  var cursorBlue:FlxSprite;
  var cursorDarkBlue:FlxSprite;
  var grpCursors:FlxTypedSpriteGroup<FlxSprite>; // using flxtypedgroup raises an error
  var cursorConfirmed:FlxSprite;
  var cursorDenied:FlxSprite;

  var cursorIndex:Int = 0;

  var isSelecting:Bool = false;

  public function new(parentPage:CharCreatorSelectPage)
  {
    super();

    this.visible = false;
    this.active = false;

    this.parentPage = parentPage;

    var bg = new FunkinSprite().makeSolidColor(FlxG.width, FlxG.height, 0xFF000000);
    bg.alpha = 0.6;
    add(bg);

    initCursors();
    initSounds();

    initLocks();

    FlxTween.color(cursor, 0.2, 0xFFFFFF00, 0xFFFFCC00, {type: PINGPONG});
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    if (!isSelecting)
    {
      changeSelectedIcon();
      updateIconAnims();
      handleMousePress();

      if (PlayerSettings.player1.controls.BACK)
      {
        close();
      }
    }

    handleCursorPosition(elapsed);
  }

  public function open():Void
  {
    this.visible = true;
    this.active = true;

    cursorConfirmed.visible = false;
    cursorDenied.visible = false;

    parentPage.handleInput = false;
  }

  public function close():Void
  {
    this.visible = false;
    this.active = false;

    parentPage.handleInput = true;
  }

  function initCursors():Void
  {
    grpCursors = new FlxTypedSpriteGroup<FlxSprite>();
    add(grpCursors);

    cursor = new FlxSprite(0, 0);
    cursor.loadGraphic(Paths.image('charSelect/charSelector'));
    cursor.color = 0xFFFFFF00;

    // FFCC00

    cursorBlue = new FlxSprite(0, 0);
    cursorBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorBlue.color = 0xFF3EBBFF;

    cursorDarkBlue = new FlxSprite(0, 0);
    cursorDarkBlue.loadGraphic(Paths.image('charSelect/charSelector'));
    cursorDarkBlue.color = 0xFF3C74F7;

    cursorBlue.blend = BlendMode.SCREEN;
    cursorDarkBlue.blend = BlendMode.SCREEN;

    cursorConfirmed = new FlxSprite(0, 0);
    cursorConfirmed.frames = Paths.getSparrowAtlas("charSelect/charSelectorConfirm");
    cursorConfirmed.animation.addByPrefix("idle", "cursor ACCEPTED instance 1", 24, true);
    cursorConfirmed.offset.set(3, 3);
    cursorConfirmed.visible = false;
    add(cursorConfirmed);

    cursorDenied = new FlxSprite(0, 0);
    cursorDenied.frames = Paths.getSparrowAtlas("charSelect/charSelectorDenied");
    cursorDenied.animation.addByPrefix("idle", "cursor DENIED instance 1", 24, false);
    cursorDenied.offset.set(3, 3);
    cursorDenied.visible = false;
    add(cursorDenied);

    grpCursors.add(cursorDarkBlue);
    grpCursors.add(cursorBlue);
    grpCursors.add(cursor);
  }

  var selectSound:FunkinSound;
  var lockedSound:FunkinSound;
  var staticSound:FunkinSound;

  function initSounds():Void
  {
    selectSound = new FunkinSound();
    selectSound.loadEmbedded(Paths.sound('CS_select'));
    selectSound.pitch = 1;
    selectSound.volume = 0.7;

    FlxG.sound.defaultSoundGroup.add(selectSound);
    FlxG.sound.list.add(selectSound);

    lockedSound = new FunkinSound();
    lockedSound.loadEmbedded(Paths.sound('CS_locked'));
    lockedSound.pitch = 1;
    lockedSound.volume = 1.0;

    FlxG.sound.defaultSoundGroup.add(lockedSound);
    FlxG.sound.list.add(lockedSound);

    staticSound = new FunkinSound();
    staticSound.loadEmbedded(Paths.sound('static loop'));
    staticSound.pitch = 1;
    staticSound.looped = true;
    staticSound.volume = 0.6;

    FlxG.sound.defaultSoundGroup.add(staticSound);
    FlxG.sound.list.add(staticSound);
  }

  var grpIcons:FlxSpriteGroup;
  final grpXSpread:Float = 107;
  final grpYSpread:Float = 127;
  var iconTint:PixelatedIcon;

  function initLocks():Void
  {
    grpIcons = new FlxSpriteGroup();
    add(grpIcons);

    // only the unused slots should be selectable
    // i dont know if i like using the lock sprite
    // maybe there is a different placeholder we could use
    // also, we should probably make the used slots
    // less visible or something like that
    for (i in 0...9)
    {
      var temp:PixelatedIcon = new PixelatedIcon(0, 0);
      temp.setCharacter("bf");
      temp.shader = new funkin.graphics.shaders.Grayscale();
      temp.ID = 1;

      if (parentPage.availableChars.exists(i))
      {
        temp.setCharacter(parentPage.availableChars.get(i));
        temp.shader = null;

        if (parentPage.data.importedPlayerData != parentPage.availableChars[i]) temp.ID = 0;
      }

      temp.setGraphicSize(128, 128);
      temp.updateHitbox();

      grpIcons.add(temp);
    }

    updateIconPositions();

    var selectedIcon = grpIcons.members[parentPage.selectedIndexData];

    iconTint = new PixelatedIcon(selectedIcon.x, selectedIcon.y);
    iconTint.setCharacter("bf");
    iconTint.setGraphicSize(128, 128);
    iconTint.updateHitbox();
    var yellowShader = new funkin.graphics.shaders.PureColor(0xFFFFFF00);
    yellowShader.colorSet = true;
    iconTint.shader = yellowShader;
    iconTint.blend = BlendMode.MULTIPLY;
    add(iconTint);
  }

  function updateIconPositions():Void
  {
    grpIcons.x = 450;
    grpIcons.y = 120;
    for (index => member in grpIcons.members)
    {
      var posX:Float = (index % 3);
      var posY:Float = Math.floor(index / 3);

      member.x = posX * grpXSpread;
      member.y = posY * grpYSpread;

      member.x += grpIcons.x;
      member.y += grpIcons.y;
    }
  }

  function changeSelectedIcon():Void
  {
    var mouseX:Float = FlxG.mouse.viewX - grpIcons.x;
    var mouseY:Float = FlxG.mouse.viewY - grpIcons.y;

    var cursorX:Int = Math.floor(mouseX / grpXSpread);
    var cursorY:Int = Math.floor(mouseY / grpYSpread);

    if (cursorX < 0 || cursorX >= 3 || cursorY < 0 || cursorY >= 3)
    {
      return;
    }

    var newIndex:Int = cursorY * 3 + cursorX;

    if (newIndex == cursorIndex)
    {
      return;
    }

    selectSound.play(true);

    cursorIndex = newIndex;
  }

  function handleMousePress():Void
  {
    if (!FlxG.mouse.justPressed)
    {
      return;
    }

    cursor.visible = false;
    cursorBlue.visible = false;
    cursorDarkBlue.visible = false;

    isSelecting = true;

    var selectedIcon = grpIcons.members[cursorIndex];

    // skip if the selected icon is already used
    if (selectedIcon.ID == 0)
    {
      lockedSound.play(true);
      cursorDenied.visible = true;
      cursorDenied.animation.play("idle", true);
      new FlxTimer().start(0.5, _ -> {
        cursorDenied.visible = false;
        cursor.visible = true;
        cursorBlue.visible = true;
        cursorDarkBlue.visible = true;
        isSelecting = false;
      });
      return;
    }

    iconTint.x = selectedIcon.x;
    iconTint.y = selectedIcon.y;
    iconTint.scale.set(selectedIcon.scale.x, selectedIcon.scale.y);

    var ogIcon = grpIcons.members[parentPage.selectedIndexData];
    parentPage.selectedIndexData = cursorIndex;
    FlxG.sound.play(Paths.sound('CS_confirm'));

    cursorConfirmed.visible = true;
    cursorConfirmed.animation.play("idle", true);
    new FlxTimer().start(0.5, _ -> {
      cursorConfirmed.visible = false;
      cursor.visible = true;
      cursorBlue.visible = true;
      cursorDarkBlue.visible = true;
      isSelecting = false;
    });

    if (Std.isOfType(ogIcon, PixelatedIcon))
    {
      var icon:PixelatedIcon = cast ogIcon;
      icon.shader = new funkin.graphics.shaders.Grayscale();

      icon.setCharacter("bf");
      icon.setGraphicSize(128, 128);
      icon.updateHitbox();
      icon.scale.set(2, 2);
    }

    if (Std.isOfType(selectedIcon, PixelatedIcon))
    {
      var icon:PixelatedIcon = cast selectedIcon;
      icon.shader = null;

      // also do we even need icontint anymore?
      if (parentPage.pixelIconFiles.length > 0) // custom icons should have the priority over preset ones i think
      {
        resetIconTexture();
      }
      else if (parentPage.data.importedPlayerData != null)
      {
        icon.setCharacter(parentPage.data.importedPlayerData);
        iconTint.setCharacter(parentPage.data.importedPlayerData);
      }

      icon.setGraphicSize(128, 128);
      iconTint.setGraphicSize(128, 128);
      icon.updateHitbox();
      iconTint.updateHitbox();
    }

    updateIconPositions();
  }

  function handleCursorPosition(elapsed:Float):Void
  {
    var selectedIcon = grpIcons.members[cursorIndex];

    var cursorLocIntended:FlxPoint = FlxPoint.get(selectedIcon.x + grpXSpread / 2 - cursor.width / 2, selectedIcon.y + grpYSpread / 2 - cursor.height / 2);

    cursor.x = MathUtil.smoothLerp(cursor.x, cursorLocIntended.x, elapsed, 0.1);
    cursor.y = MathUtil.smoothLerp(cursor.y, cursorLocIntended.y, elapsed, 0.1);

    cursorBlue.x = MathUtil.coolLerp(cursorBlue.x, cursor.x, 0.95 * 0.4);
    cursorBlue.y = MathUtil.coolLerp(cursorBlue.y, cursor.y, 0.95 * 0.4);

    cursorDarkBlue.x = MathUtil.coolLerp(cursorDarkBlue.x, cursorLocIntended.x, 0.95 * 0.2);
    cursorDarkBlue.y = MathUtil.coolLerp(cursorDarkBlue.y, cursorLocIntended.y, 0.95 * 0.2);

    cursorConfirmed.x = cursor.x;
    cursorConfirmed.y = cursor.y;

    cursorDenied.x = cursor.x;
    cursorDenied.y = cursor.y;

    cursorLocIntended.put();
  }

  var selectedBizz:Array<openfl.filters.BitmapFilter> = [
    new openfl.filters.DropShadowFilter(0, 0, 0xFFFFFF, 1, 2, 2, 19, 1, false, false, false),
    new openfl.filters.DropShadowFilter(5, 45, 0x000000, 1, 2, 2, 1, 1, false, false, false)
  ];

  function updateIconAnims():Void
  {
    for (index => member in grpIcons.group.members)
    {
      if (Std.isOfType(member, PixelatedIcon))
      {
        var memb:PixelatedIcon = cast member;

        if (index == cursorIndex)
        {
          memb.filters = selectedBizz;
          memb.scale.set(2.6, 2.6);
        }
        else
        {
          memb.filters = null;
          memb.scale.set(2, 2);
        }
      }
    }

    var selectedIcon = grpIcons.members[parentPage.selectedIndexData];

    iconTint.scale.set(selectedIcon.scale.x, selectedIcon.scale.y);
  }

  public function resetIconTexture():Void
  {
    var icon:PixelatedIcon = cast grpIcons.members[parentPage.selectedIndexData];

    var pngBytes = parentPage.pixelIconFiles[0].bytes;
    var xmlBytes = parentPage.pixelIconFiles[1]?.bytes ?? null;
    var graphic = openfl.display.BitmapData.fromBytes(pngBytes);
    if (xmlBytes == null)
    {
      icon.loadGraphic(graphic);
      iconTint.loadGraphic(graphic);
    }
    else
    {
      icon.frames = iconTint.frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(graphic, xmlBytes.toString());
      icon.animation.addByPrefix('idle', 'idle0', 10, true);
      icon.animation.addByPrefix('confirm', 'confirm0', 10, false);
      icon.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);
      iconTint.animation.addByPrefix('idle', 'idle0', 10, true);
      iconTint.animation.addByPrefix('confirm', 'confirm0', 10, false);
      iconTint.animation.addByPrefix('confirm-hold', 'confirm-hold0', 10, true);
      icon.animation.finishCallback = function(name:String):Void {
        if (name == 'confirm') icon.animation.play('confirm-hold');
      };
      iconTint.animation.finishCallback = function(name:String):Void {
        if (name == 'confirm') icon.animation.play('confirm-hold');
      };
      icon.animation.play('idle');
      iconTint.animation.play('idle');
    }
  }
}
