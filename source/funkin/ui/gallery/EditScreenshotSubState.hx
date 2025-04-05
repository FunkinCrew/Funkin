package funkin.ui.gallery;

import funkin.audio.FunkinSound;
import funkin.graphics.FunkinCamera;
import funkin.input.Cursor;
import funkin.ui.transition.StickerSubState.StickerShit;
import funkin.util.FileUtil;
import flixel.FlxSprite;
import flixel.addons.display.shapes.FlxShapeCircle;
import flixel.group.FlxSpriteGroup;
import flixel.input.keyboard.FlxKey;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import openfl.display.BitmapData;
import openfl.events.KeyboardEvent;

using flixel.util.FlxSpriteUtil;
using StringTools;

class EditScreenshotSubState extends MusicBeatSubState
{
  public static final ALL_MODES:Array<ScreenshotEditMode> = [SELECT, DRAW, STICKERS, TEXT, DELETE];

  var shotCopy:FlxSprite;
  var shotName:String = "Unnamed";
  var curMode:ScreenshotEditMode = SELECT;

  var selectorSprite:FlxSprite;
  var evilSelectorSprite:FlxSprite;

  var drawSprite:FlxShapeCircle;
  var invisDrawLayer:FlxSprite;
  var drawLayerBitmap:BitmapData;

  var objectLayer:FlxSpriteGroup;
  var bottomBar:EditScreenshotBox;

  var isCursorOverHaxeUI(get, never):Bool;
  var finishCam:FunkinCamera;

  public static var stickerSprites:Map<String, FlxSprite> = [];
  public static var stickerStuff:Map<String, Array<String>> = [];
  public static var selectedSticker:String = "";

  var stickerSounds:Array<String> = [];

  override public function new(daShot:FlxSprite, name:String = "Unnamed")
  {
    super(FlxColor.fromRGBFloat(0, 0, 0, 0.45));

    shotCopy = new FlxSprite().loadGraphicFromSprite(daShot);
    shotName = name;

    selectorSprite = new FlxSprite().makeGraphic(25, 25, FlxColor.fromRGBFloat(1, 1, 1, 0.45));
    selectorSprite.drawRect(0, 0, selectorSprite.width, selectorSprite.height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.WHITE});

    evilSelectorSprite = new FlxSprite().loadGraphicFromSprite(selectorSprite);
    evilSelectorSprite.color = FlxColor.RED;

    drawSprite = new FlxShapeCircle(0, 0, 25, {thickness: 0, color: FlxColor.TRANSPARENT}, FlxColor.WHITE);
    invisDrawLayer = new FlxSprite().makeGraphic(Math.floor(shotCopy.width), Math.floor(shotCopy.height), FlxColor.TRANSPARENT);
    drawLayerBitmap = invisDrawLayer.pixels.clone();

    objectLayer = new FlxSpriteGroup();

    bottomBar = new EditScreenshotBox(this);

    finishCam = new FunkinCamera("exportCamera");

    stickerSprites = [];
    stickerStuff = [];
    selectedSticker = "";

    var path:String = Paths.file('images/transitionSwag/stickers-set-1/stickers.json'); // will replace with actual entries at some point once poof's stickerregistry gets merged!
    var json:StickerShit = cast haxe.Json.parse(Assets.getText(path));

    for (key in Reflect.fields(json.stickers))
    {
      var stuff = Reflect.field(json.stickers, key);
      stickerStuff.set(key, stuff);

      for (thingy in stuff)
      {
        if (selectedSticker == "") selectedSticker = thingy;

        var stickerSprite:FlxSprite = new FlxSprite().loadGraphic(Paths.image("transitionSwag/stickers-set-1/" + thingy));
        stickerSprite.active = false;
        stickerSprite.visible = false;
        stickerSprites.set(thingy, stickerSprite);
      }
    }

    // doing some neat stuff for placing stickers
    var allSounds:Array<String> = Assets.list(SOUND);
    var filterFunc = function(a:String) {
      return a.startsWith('assets/shared/sounds/stickersounds/');
    };

    stickerSounds = allSounds.filter(filterFunc);

    for (i in 0...stickerSounds.length)
    {
      stickerSounds[i] = stickerSounds[i].replace('assets/shared/sounds/', '');
      stickerSounds[i] = stickerSounds[i].substring(0, stickerSounds[i].lastIndexOf('.'));
    }

    trace(stickerSounds);
  }

  override public function create()
  {
    super.create();

    shotCopy.screenCenter();
    invisDrawLayer.setPosition(shotCopy.x, shotCopy.y);

    add(shotCopy);

    add(objectLayer);
    add(invisDrawLayer);

    for (n => sticker in stickerSprites)
    {
      add(sticker);
    }

    add(drawSprite);
    add(selectorSprite);
    add(evilSelectorSprite);
    add(bottomBar);

    camera.zoom = 0.75;

    shotCopy.cameras = [this.camera, finishCam];
    objectLayer.cameras = [this.camera, finishCam];
  }

  override public function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));

    drawSprite.visible = (curMode == DRAW && !isCursorOverHaxeUI);
    drawSprite.x = FlxG.mouse.getWorldPosition(camera).x - drawSprite.width / 2;
    drawSprite.y = FlxG.mouse.getWorldPosition(camera).y - drawSprite.height / 2;

    stickerSprites[selectedSticker].visible = (curMode == STICKERS && !isCursorOverHaxeUI);
    stickerSprites[selectedSticker].x = FlxG.mouse.getWorldPosition(camera).x - stickerSprites[selectedSticker].width / 2;
    stickerSprites[selectedSticker].y = FlxG.mouse.getWorldPosition(camera).y - stickerSprites[selectedSticker].height / 2;

    switch (curMode)
    {
      case SELECT:
        selectLogic();
      case DRAW:
        drawLogic();
      case STICKERS:
        stickerLogic();
      case TEXT:
        textLogic();
      case DELETE:
        deleteLogic();
    }

    if (curMode != SELECT) selectorSprite.visible = false;
    if (curMode != DELETE) evilSelectorSprite.visible = false;

    if (placedText != null && curMode != TEXT) placeText();

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.S && placedText == null)
    {
      var finishedBitmap:BitmapData = finishCam.grabScreen(true, true);
      FileUtil.saveFile(finishedBitmap.image.encode(PNG), [FileUtil.FILE_FILTER_PNG], null, null, shotName);
    }

    if (controls.BACK && placedText == null) close();
  }

  var selectedThing:FlxSprite = null;
  var moveOffset:Array<Float> = [];

  function selectLogic()
  {
    Cursor.show();

    if (FlxG.mouse.justReleased && moveOffset.length > 0) moveOffset = [];

    var prevSelectedThing = selectedThing;
    if (FlxG.mouse.justPressed && !isCursorOverHaxeUI) selectedThing = getObjectBelowMouse();

    if (prevSelectedThing != selectedThing)
    {
      // update bottom bar
      bottomBar.selectScale.pos = selectedThing?.scale.x ?? 1;
      bottomBar.selectAngle.pos = selectedThing?.angle ?? 0;
      bottomBar.selectFlipX.selected = selectedThing?.flipX ?? false;
      bottomBar.selectFlipY.selected = selectedThing?.flipY ?? false;
    }

    if (selectedThing != null)
    {
      selectorSprite.visible = true;
      selectorSprite.setGraphicSize(selectedThing.width, selectedThing.height);
      selectorSprite.updateHitbox();
      selectorSprite.setPosition(selectedThing.x, selectedThing.y);

      selectedThing.scale.x = selectedThing.scale.y = bottomBar.selectScale.pos;
      selectedThing.updateHitbox();
      selectedThing.angle = bottomBar.selectAngle.pos;
      selectedThing.flipX = bottomBar.selectFlipX.selected;
      selectedThing.flipY = bottomBar.selectFlipY.selected;

      if (FlxG.mouse.pressed && FlxG.mouse.overlaps(selectedThing, camera) && !isCursorOverHaxeUI)
      {
        if (moveOffset.length == 0)
        {
          moveOffset = [
            FlxG.mouse.getWorldPosition(camera).x - selectedThing.x,
            FlxG.mouse.getWorldPosition(camera).y - selectedThing.y
          ];
        }

        selectedThing.x = FlxG.mouse.getWorldPosition(camera).x - moveOffset[0];
        selectedThing.y = FlxG.mouse.getWorldPosition(camera).y - moveOffset[1];
      }

      if (FlxG.keys.justPressed.DELETE)
      {
        FunkinSound.playOnce(Paths.sound("chartingSounds/noteErase"));

        selectedThing.kill();
        objectLayer.remove(selectedThing, true);
        selectedThing.destroy();
        selectedThing = null;
      }
    }
    else
    {
      selectorSprite.visible = false;
    }
  }

  var drawMinX:Int = FlxMath.MAX_VALUE_INT;
  var drawMinY:Int = FlxMath.MAX_VALUE_INT;
  var drawMaxX:Int = 0;
  var drawMaxY:Int = 0;

  function drawLogic()
  {
    if (!isCursorOverHaxeUI) Cursor.hide();
    else
      Cursor.show();

    drawSprite.radius = bottomBar.drawSize.pos;
    drawSprite.color = cast(bottomBar.drawColor.selectedItem ?? 0xFFFFFFFF, Int);

    var flooredMousePos:Array<Int> = [
      Math.floor(drawSprite.x - invisDrawLayer.x),
      Math.floor(drawSprite.y - invisDrawLayer.y)
    ];

    if (FlxG.mouse.pressed)
    {
      for (px in 0...drawSprite.pixels.width)
      {
        for (py in 0...drawSprite.pixels.height)
        {
          if (flooredMousePos[0] + px < 0) continue;
          if (flooredMousePos[0] + px >= invisDrawLayer.width) continue;

          if (flooredMousePos[1] + py < 0) continue;
          if (flooredMousePos[1] + py >= invisDrawLayer.height) continue;

          if ((drawSprite.pixels.getPixel32(px, py) : FlxColor) == FlxColor.TRANSPARENT) continue;
          if (invisDrawLayer.pixels.getPixel32(flooredMousePos[0] + px, flooredMousePos[1] + py) == drawSprite.pixels.getPixel32(px, py)) continue;

          var col:FlxColor = FlxColor.fromRGBFloat(drawSprite.color.redFloat, drawSprite.color.greenFloat, drawSprite.color.blueFloat, drawSprite.alpha);
          var fillPixelX:Int = flooredMousePos[0] + px;
          var fillPixelY:Int = flooredMousePos[1] + py;

          invisDrawLayer.pixels.setPixel32(fillPixelX, fillPixelY, col);

          // This part is used to make an object and add it to the objects list.
          if (fillPixelX < drawMinX) drawMinX = fillPixelX;
          if (fillPixelX > drawMaxX) drawMaxX = fillPixelX;
          if (fillPixelY < drawMinY) drawMinY = fillPixelY;
          if (fillPixelY > drawMaxY) drawMaxY = fillPixelY;
        }
      }
    }

    if (FlxG.mouse.justReleased && drawMinX != FlxMath.MAX_VALUE_INT && drawMinY != FlxMath.MAX_VALUE_INT)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/noteLay"));

      // Create a new object from all the drawn pixels.
      var newObj:FlxSprite = new FlxSprite(invisDrawLayer.x + drawMinX, invisDrawLayer.y + drawMinY);
      newObj.pixels = new BitmapData(drawMaxX - drawMinX, drawMaxY - drawMinY, true, 0x00000000);
      newObj.active = false; // stop any updates for performance!

      for (px in drawMinX...(drawMaxX + 1))
      {
        for (py in drawMinY...(drawMaxY + 1))
        {
          var col:Int = invisDrawLayer.pixels.getPixel32(px, py);
          if (col != 0x00000000) newObj.pixels.setPixel32(px - drawMinX, py - drawMinY, col);
        }
      }

      objectLayer.add(newObj);

      // Reset the graphic of invisDrawLayer.
      invisDrawLayer.pixels = drawLayerBitmap.clone();

      drawMinX = FlxMath.MAX_VALUE_INT;
      drawMinY = FlxMath.MAX_VALUE_INT;
      drawMaxX = 0;
      drawMaxY = 0;
    }
  }

  function stickerLogic()
  {
    Cursor.show();

    var stickerToSelect:String = bottomBar.stickerDropdown.text;

    if (stickerToSelect != selectedSticker && stickerSprites.exists(stickerToSelect))
    {
      stickerSprites[selectedSticker].visible = false;
      selectedSticker = stickerToSelect;
    }

    if (FlxG.mouse.justPressed && !isCursorOverHaxeUI)
    {
      FunkinSound.playOnce(Paths.sound(FlxG.random.getObject(stickerSounds)));

      var newObj:FlxSprite = new FlxSprite(stickerSprites[selectedSticker].x, stickerSprites[selectedSticker].y);
      newObj.loadGraphicFromSprite(stickerSprites[selectedSticker]);
      newObj.active = false; // stop any updates for performance!

      objectLayer.add(newObj);
    }
  }

  var placedText:FlxText = null;

  function textLogic()
  {
    Cursor.show();

    if (placedText == null)
    {
      if (FlxG.mouse.justPressed && !isCursorOverHaxeUI)
      {
        placedText = new FlxText(FlxG.mouse.getWorldPosition(camera).x, FlxG.mouse.getWorldPosition(camera).y, 0, "", 16);
        add(placedText);

        FlxG.stage.addEventListener(KeyboardEvent.KEY_DOWN, updateText);
      }
    }
    else
    {
      placedText.size = Std.int(bottomBar.textSize.pos);
      placedText.font = bottomBar.allFonts[bottomBar.textFont.selectedIndex] ?? "Arial";
      placedText.color = cast(bottomBar.textColor.selectedItem ?? 0xFFFFFFFF, Int);
      placedText.bold = bottomBar.textBold.selected;
      placedText.italic = bottomBar.textItalic.selected;
      placedText.underline = bottomBar.textUnderline.selected;

      if (FlxG.mouse.justPressed && !isCursorOverHaxeUI && !FlxG.mouse.overlaps(placedText, camera)) placeText();
    }
  }

  function deleteLogic() // what if selectlogic was evil
  {
    Cursor.show();

    var objToDelete:FlxSprite = getObjectBelowMouse();

    if (objToDelete != null)
    {
      evilSelectorSprite.visible = true;
      evilSelectorSprite.setGraphicSize(objToDelete.width, objToDelete.height);
      evilSelectorSprite.updateHitbox();
      evilSelectorSprite.setPosition(objToDelete.x, objToDelete.y);

      if (FlxG.mouse.justPressed)
      {
        FunkinSound.playOnce(Paths.sound("chartingSounds/noteErase"));

        objToDelete.kill();
        objectLayer.remove(objToDelete, true);
        objToDelete.destroy();
        objToDelete = null;
      }
    }
    else
    {
      evilSelectorSprite.visible = false;
    }
  }

  function getObjectBelowMouse()
  {
    // return the latest added object below mouse
    var objArray = objectLayer.members.copy();
    objArray.reverse();

    for (obj in objArray)
    {
      if (FlxG.mouse.overlaps(obj, camera) && !isCursorOverHaxeUI) return obj;
    }

    return null;
  }

  function placeText()
  {
    FlxG.stage.removeEventListener(KeyboardEvent.KEY_DOWN, updateText);

    if (placedText.text.length > 0)
    {
      FunkinSound.playOnce(Paths.sound("chartingSounds/noteLay"));

      var newObj:FlxSprite = new FlxSprite(placedText.x, placedText.y).loadGraphic(placedText.pixels.clone());
      newObj.active = false;
      objectLayer.add(newObj);
    }

    placedText.kill();
    remove(placedText, true);
    placedText.destroy();
    placedText = null;
  }

  var isTabDown:Bool = false;

  function updateText(event:KeyboardEvent) // mostly nabbed from FlxInputText! except this has mutliline!
  {
    var daCode:FlxKey = event.keyCode;

    if (placedText == null) return;

    switch (daCode)
    {
      case SHIFT | CONTROL | BACKSLASH | ESCAPE | LEFT | RIGHT | END | HOME | DELETE | UP | DOWN: // todo: add caret shit
        return;

      case TAB:
        isTabDown = !isTabDown;

      case BACKSPACE:
        if (placedText.text.length > 0) placedText.text = placedText.text.substring(0, placedText.text.length - 1);

        FunkinSound.playOnce(Paths.sound("chartingSounds/hitNotePlayer"));

      case ENTER:
        placedText.text += "\n";

      case V if (event.ctrlKey):
        // Reapply focus  when tabbing back into the window and selecting the field
        #if (js && html5)
        FlxG.stage.window.textInputEnabled = true;
        #else
        placedText.text += lime.system.Clipboard.text ?? "";
        #end
      default:
        if (event.charCode == 0) return; // non-printable characters crash String.fromCharCode

        var daString:String = String.fromCharCode(event.charCode);
        if (event.shiftKey && !isTabDown) daString = daString.toUpperCase();
        else if (!event.shiftKey && isTabDown) daString = daString.toUpperCase();

        placedText.text += daString;

        FunkinSound.playOnce(Paths.sound("chartingSounds/hitNotePlayer"));
    }
  }

  function get_isCursorOverHaxeUI():Bool
  {
    return haxe.ui.core.Screen.instance.hasComponentUnderPoint(FlxG.mouse.viewX, FlxG.mouse.viewY);
  }
}

enum abstract ScreenshotEditMode(String) from String to String
{
  var SELECT = "select";
  var DRAW = "draw";
  var STICKERS = "stickers";
  var TEXT = "text";
  var DELETE = "delete";
}
