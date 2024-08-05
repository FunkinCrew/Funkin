package funkin.ui.debug.anim;

import flixel.addons.display.FlxGridOverlay;
import flixel.addons.ui.FlxInputText;
import flixel.addons.ui.FlxUIDropDownMenu;
import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.frames.FlxFrame;
import flixel.group.FlxGroup;
import flixel.math.FlxPoint;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import flixel.util.FlxTimer;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.SparrowCharacter;
import funkin.ui.mainmenu.MainMenuState;
import funkin.util.MouseUtil;
import funkin.util.SerializerUtil;
import funkin.util.SortUtil;
import haxe.ui.components.DropDown;
import haxe.ui.core.Component;
import haxe.ui.core.Screen;
import haxe.ui.events.ItemEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.RuntimeComponentBuilder;
import lime.utils.Assets as LimeAssets;
import openfl.Assets;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.geom.Rectangle;
import openfl.net.FileReference;
import openfl.net.URLLoader;
import openfl.net.URLRequest;
import openfl.utils.ByteArray;

using flixel.util.FlxSpriteUtil;

#if web
import js.html.FileList;
#end
#if sys
import sys.io.File;
#end

class DebugBoundingState extends FlxState
{
  /*
    TODAY'S TO-DO
    - Cleaner UI
   */
  var bg:FlxSprite;
  var fileInfo:FlxText;

  var txtGrp:FlxGroup;

  var hudCam:FlxCamera;

  var curView:ANIMDEBUGVIEW = SPRITESHEET;

  var spriteSheetView:FlxGroup;
  var offsetView:FlxGroup;
  var animDropDownMenu:FlxUIDropDownMenu;
  var dropDownSetup:Bool = false;

  var onionSkinChar:FlxSprite;
  var txtOffsetShit:FlxText;

  var uiStuff:Component;

  var haxeUIFocused(get, default):Bool = false;

  function get_haxeUIFocused():Bool
  {
    // get the screen position, according to the HUD camera, temp default to FlxG.camera juuust in case?
    var hudMousePos:FlxPoint = FlxG.mouse.getScreenPosition(hudCam ?? FlxG.camera);
    return Screen.instance.hasSolidComponentUnderPoint(hudMousePos.x, hudMousePos.y);
  }

  override function create()
  {
    Paths.setCurrentLevel('week1');

    // lv.
    // lv.onChange = function(e:UIEvent)
    // {
    // 	trace(e.type);
    // 	// trace(e.data.curView);
    // 	// var item:haxe.ui.core.ItemRenderer = cast e.target;
    // 	trace(e.target);
    // 	// if (e.type == "change")
    // 	// {
    // 	// 	curView = cast e.data;
    // 	// }
    // };

    hudCam = new FlxCamera();
    hudCam.bgColor.alpha = 0;

    bg = FlxGridOverlay.create(10, 10);
    // bg = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.GREEN);

    bg.scrollFactor.set();
    add(bg);

    // we are setting this as the default draw camera only temporarily, to trick haxeui
    FlxG.cameras.add(hudCam);

    var str = Paths.xml('ui/animation-editor/offset-editor-view');
    uiStuff = RuntimeComponentBuilder.fromAsset(str);

    // uiStuff.findComponent("btnViewSpriteSheet").onClick = _ -> curView = SPRITESHEET;
    var dropdown:DropDown = cast uiStuff.findComponent("swapper");
    dropdown.onChange = function(e:UIEvent) {
      trace(e.type);
      curView = cast e.data.curView;
      trace(e.data);
      // trace(e.data);
    };

    uiStuff.cameras = [hudCam];

    add(uiStuff);

    // sets the default camera back to FlxG.camera, since we set it to hudCamera for haxeui stuf
    FlxG.cameras.setDefaultDrawTarget(FlxG.camera, true);
    FlxG.cameras.setDefaultDrawTarget(hudCam, false);

    initSpritesheetView();
    initOffsetView();

    Cursor.show();

    super.create();
  }

  var bf:FlxSprite;
  var swagOutlines:FlxSprite;

  function initSpritesheetView():Void
  {
    spriteSheetView = new FlxGroup();
    add(spriteSheetView);

    var tex = Paths.getSparrowAtlas('characters/BOYFRIEND');
    // tex.frames[0].uv

    bf = new FlxSprite();
    bf.loadGraphic(tex.parent);
    spriteSheetView.add(bf);

    swagOutlines = new FlxSprite().makeGraphic(tex.parent.width, tex.parent.height, FlxColor.TRANSPARENT);

    generateOutlines(tex.frames);

    txtGrp = new FlxGroup();
    txtGrp.cameras = [hudCam];
    spriteSheetView.add(txtGrp);

    addInfo('boyfriend.xml', "");
    addInfo('Width', bf.width);
    addInfo('Height', bf.height);

    spriteSheetView.add(swagOutlines);

    FlxG.stage.window.onDropFile.add(function(path:String) {
      // WACKY ASS TESTING SHIT FOR WEB FILE LOADING??
      #if web
      var swagList:FileList = cast path;

      var objShit = js.html.URL.createObjectURL(swagList.item(0));
      trace(objShit);

      var funnysound = new FunkinSound().loadStream('https://cdn.discordapp.com/attachments/767500676166451231/817821618251759666/Flutter.mp3', false, false,
        null, function() {
          trace('LOADED SHIT??');
      });

      funnysound.volume = 1;
      funnysound.play();

      var urlShit = new URLLoader(new URLRequest(objShit));

      new FlxTimer().start(3, function(tmr:FlxTimer) {
        // music lol!
        if (urlShit.dataFormat == BINARY)
        {
          // var daSwagBytes:ByteArray = urlShit.data;

          // FlxG.sound.playMusic();

          // trace('is binary!!');
        }
        trace(urlShit.dataFormat);
      });

      // remove(bf);
      // FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
      // Assets.cache.clear();

      // bf.loadGraphic(objShit);
      // add(bf);

      // trace(swagList.item(0).name);
      // var urlShit = js.html.URL.createObjectURL(path);
      #end

      #if sys
      trace("DROPPED FILE FROM: " + Std.string(path));
      var newPath = "./" + Paths.image('characters/temp');
      File.copy(path, newPath);

      var swag = Paths.image('characters/temp');

      if (bf != null) remove(bf);
      FlxG.bitmap.removeByKey(Paths.image('characters/temp'));
      Assets.cache.clear();

      bf.loadGraphic(Paths.image('characters/temp'));
      add(bf);
      #end
    });
  }

  function generateOutlines(frameShit:Array<FlxFrame>):Void
  {
    // swagOutlines.width = frameShit[0].parent.width;
    // swagOutlines.height = frameShit[0].parent.height;
    swagOutlines.pixels.fillRect(new Rectangle(0, 0, swagOutlines.width, swagOutlines.height), 0x00000000);

    for (i in frameShit)
    {
      var lineStyle:LineStyle = {color: FlxColor.RED, thickness: 2};

      var uvW:Float = (i.uv.width * i.parent.width) - (i.uv.x * i.parent.width);
      var uvH:Float = (i.uv.height * i.parent.height) - (i.uv.y * i.parent.height);

      // trace(Std.int(i.uv.width * i.parent.width));
      swagOutlines.drawRect(i.uv.x * i.parent.width, i.uv.y * i.parent.height, uvW, uvH, FlxColor.TRANSPARENT, lineStyle);
      // swagGraphic.setPosition(, );
      // trace(uvH);
    }
  }

  function initOffsetView():Void
  {
    offsetView = new FlxGroup();
    add(offsetView);

    onionSkinChar = new FlxSprite().makeGraphic(FlxG.width * 2, FlxG.height * 2, FlxColor.TRANSPARENT);
    onionSkinChar.visible = false;
    offsetView.add(onionSkinChar);

    txtOffsetShit = new FlxText(20, 20, 0, "", 20);
    txtOffsetShit.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    txtOffsetShit.cameras = [hudCam];
    offsetView.add(txtOffsetShit);

    animDropDownMenu = new FlxUIDropDownMenu(0, 0, FlxUIDropDownMenu.makeStrIdLabelArray(['weed'], true));
    animDropDownMenu.cameras = [hudCam];
    // Move to bottom right corner
    animDropDownMenu.x = FlxG.width - animDropDownMenu.width - 20;
    animDropDownMenu.y = FlxG.height - animDropDownMenu.height - 20;
    offsetView.add(animDropDownMenu);

    var characters:Array<String> = CharacterDataParser.listCharacterIds();
    characters = characters.filter(function(charId:String) {
      var char = CharacterDataParser.fetchCharacterData(charId);
      return char.renderType != AnimateAtlas;
    });
    characters.sort(SortUtil.alphabetically);

    var charDropdown:DropDown = cast uiStuff.findComponent('characterDropdown');
    for (char in characters)
    {
      charDropdown.dataSource.add({text: char});
    }

    charDropdown.onChange = function(e:UIEvent) {
      loadAnimShit(e.data.text);
    };
  }

  public var mouseOffset:FlxPoint = FlxPoint.get(0, 0);
  public var oldPos:FlxPoint = FlxPoint.get(0, 0);

  function mouseOffsetMovement()
  {
    if (swagChar != null)
    {
      if (FlxG.mouse.justPressed)
      {
        mouseOffset.set(FlxG.mouse.x - -swagChar.animOffsets[0], FlxG.mouse.y - -swagChar.animOffsets[1]);
      }

      if (FlxG.mouse.pressed)
      {
        swagChar.animOffsets = [(FlxG.mouse.x - mouseOffset.x) * -1, (FlxG.mouse.y - mouseOffset.y) * -1];

        swagChar.animationOffsets.set(animDropDownMenu.selectedLabel, swagChar.animOffsets);

        txtOffsetShit.text = 'Offset: ' + swagChar.animOffsets;
      }
    }
  }

  function addInfo(str:String, value:Dynamic)
  {
    var swagText:FlxText = new FlxText(10, 10 + (28 * txtGrp.length));
    swagText.setFormat(Paths.font("vcr.ttf"), 26, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    swagText.scrollFactor.set();
    txtGrp.add(swagText);

    swagText.text = str + ": " + Std.string(value);
  }

  function clearInfo()
  {
    txtGrp.clear();
  }

  function checkLibrary(library:String)
  {
    trace(Assets.hasLibrary(library));
    if (Assets.getLibrary(library) == null)
    {
      @:privateAccess
      if (!LimeAssets.libraryPaths.exists(library)) throw "Missing library: " + library;

      // var callback = callbacks.add("library:" + library);
      Assets.loadLibrary(library).onComplete(function(_) {
        trace('LOADED... awesomeness...');
        // callback();
      });
    }
  }

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.ONE)
    {
      var lv:DropDown = cast uiStuff.findComponent("swapper");
      lv.selectedIndex = 0;
      curView = SPRITESHEET;
    }

    if (FlxG.keys.justReleased.TWO)
    {
      var lv:DropDown = cast uiStuff.findComponent("swapper");
      lv.selectedIndex = 1;
      curView = ANIMATIONS;
      if (swagChar != null)
      {
        FlxG.camera.focusOn(swagChar.getMidpoint());
        FlxG.camera.zoom = 0.95;
      }
    }

    switch (curView)
    {
      case SPRITESHEET:
        spriteSheetView.visible = true;
        offsetView.visible = false;
        offsetView.active = false;
      case ANIMATIONS:
        spriteSheetView.visible = false;
        offsetView.visible = true;
        offsetView.active = true;
        offsetControls();
        if (!haxeUIFocused) mouseOffsetMovement();
    }

    if (FlxG.keys.justPressed.H) hudCam.visible = !hudCam.visible;

    if (FlxG.keys.justPressed.F4) FlxG.switchState(() -> new MainMenuState());

    MouseUtil.mouseCamDrag();
    if (!haxeUIFocused) MouseUtil.mouseWheelZoom();

    // bg.scale.x = FlxG.camera.zoom;
    // bg.scale.y = FlxG.camera.zoom;

    bg.setGraphicSize(Std.int(bg.width / FlxG.camera.zoom));

    super.update(elapsed);
  }

  function offsetControls():Void
  {
    if (FlxG.keys.justPressed.RBRACKET || FlxG.keys.justPressed.E)
    {
      if (Std.parseInt(animDropDownMenu.selectedId) + 1 <= animDropDownMenu.length)
        animDropDownMenu.selectedId = Std.string(Std.parseInt(animDropDownMenu.selectedId)
        + 1);
      else
        animDropDownMenu.selectedId = Std.string(0);
      playCharacterAnimation(animDropDownMenu.selectedId, true);
    }
    if (FlxG.keys.justPressed.LBRACKET || FlxG.keys.justPressed.Q)
    {
      if (Std.parseInt(animDropDownMenu.selectedId) - 1 >= 0) animDropDownMenu.selectedId = Std.string(Std.parseInt(animDropDownMenu.selectedId) - 1);
      else
        animDropDownMenu.selectedId = Std.string(animDropDownMenu.length - 1);
      playCharacterAnimation(animDropDownMenu.selectedId, true);
    }

    // Keyboards controls for general WASD "movement"
    // modifies the animDropDownMenu so that it's properly updated and shit
    // and then it's just played and updated from the animDropDownMenu callback, which is set in the loadAnimShit() function probabbly
    if (FlxG.keys.justPressed.W || FlxG.keys.justPressed.S || FlxG.keys.justPressed.D || FlxG.keys.justPressed.A)
    {
      var suffix:String = '';
      var targetLabel:String = '';

      if (FlxG.keys.pressed.SHIFT) suffix = 'miss';

      if (FlxG.keys.justPressed.W) targetLabel = 'singUP$suffix';
      if (FlxG.keys.justPressed.S) targetLabel = 'singDOWN$suffix';
      if (FlxG.keys.justPressed.A) targetLabel = 'singLEFT$suffix';
      if (FlxG.keys.justPressed.D) targetLabel = 'singRIGHT$suffix';

      if (targetLabel != animDropDownMenu.selectedLabel)
      {
        // Play the new animation if the IDs are the different.
        // Override the onion skin.
        animDropDownMenu.selectedLabel = targetLabel;
        playCharacterAnimation(animDropDownMenu.selectedId, true);
      }
      else
      {
        // Replay the current animation if the IDs are the same.
        // Don't override the onion skin.
        playCharacterAnimation(animDropDownMenu.selectedId, false);
      }
    }

    if (FlxG.keys.justPressed.F)
    {
      onionSkinChar.visible = !onionSkinChar.visible;
    }

    // Plays the idle animation
    if (FlxG.keys.justPressed.SPACE)
    {
      animDropDownMenu.selectedLabel = 'idle';
      playCharacterAnimation(animDropDownMenu.selectedId, true);
    }

    // Playback the animation
    if (FlxG.keys.justPressed.ENTER) playCharacterAnimation(animDropDownMenu.selectedId, false);

    if (FlxG.keys.justPressed.RIGHT || FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.UP || FlxG.keys.justPressed.DOWN)
    {
      var animName = animDropDownMenu.selectedLabel;
      var coolValues:Array<Float> = swagChar.animationOffsets.get(animName).copy();

      var multiplier:Int = 5;

      if (FlxG.keys.pressed.CONTROL) multiplier = 1;

      if (FlxG.keys.pressed.SHIFT) multiplier = 10;

      if (FlxG.keys.justPressed.RIGHT) coolValues[0] -= 1 * multiplier;
      else if (FlxG.keys.justPressed.LEFT) coolValues[0] += 1 * multiplier;
      else if (FlxG.keys.justPressed.UP) coolValues[1] += 1 * multiplier;
      else if (FlxG.keys.justPressed.DOWN) coolValues[1] -= 1 * multiplier;

      swagChar.animationOffsets.set(animDropDownMenu.selectedLabel, coolValues);
      swagChar.playAnimation(animName);

      txtOffsetShit.text = 'Offset: ' + coolValues;

      trace(animName);
    }

    if (FlxG.keys.justPressed.ESCAPE)
    {
      var outputString = FlxG.keys.pressed.CONTROL ? buildOutputStringOld() : buildOutputStringNew();
      saveOffsets(outputString, FlxG.keys.pressed.CONTROL ? swagChar.characterId + "Offsets.txt" : swagChar.characterId + ".json");
    }
  }

  function buildOutputStringOld():String
  {
    var outputString:String = "";

    for (i in swagChar.animationOffsets.keys())
    {
      outputString += i + " " + swagChar.animationOffsets.get(i)[0] + " " + swagChar.animationOffsets.get(i)[1] + "\n";
    }

    outputString.trim();

    return outputString;
  }

  function buildOutputStringNew():String
  {
    var charData:CharacterData = Reflect.copy(swagChar._data);

    for (charDataAnim in charData.animations)
    {
      var animName:String = charDataAnim.name;
      charDataAnim.offsets = swagChar.animationOffsets.get(animName);
    }

    return SerializerUtil.toJSON(charData, true);
  }

  var swagChar:BaseCharacter;

  /*
    Called when animation dropdown is changed!
   */
  function loadAnimShit(char:String)
  {
    if (swagChar != null)
    {
      offsetView.remove(swagChar);
      swagChar.destroy();
    }

    swagChar = CharacterDataParser.fetchCharacter(char);
    swagChar.x = 100;
    swagChar.y = 100;
    // swagChar.debugMode = true;
    offsetView.add(swagChar);

    if (swagChar == null || swagChar.frames == null)
    {
      trace('ERROR: Failed to load character ${char}!');
    }

    generateOutlines(swagChar.frames.frames);
    bf.pixels = swagChar.pixels;

    clearInfo();
    addInfo(swagChar._data.assetPath, "");
    addInfo('Width', bf.width);
    addInfo('Height', bf.height);

    characterAnimNames = [];

    for (i in swagChar.animationOffsets.keys())
    {
      characterAnimNames.push(i);
      trace(i);
      trace(swagChar.animationOffsets[i]);
    }

    animDropDownMenu.setData(FlxUIDropDownMenu.makeStrIdLabelArray(characterAnimNames, true));
    animDropDownMenu.callback = function(str:String) {
      playCharacterAnimation(str, true);
    };
    txtOffsetShit.text = 'Offset: ' + swagChar.animOffsets;
    dropDownSetup = true;
  }

  private var characterAnimNames:Array<String>;

  function playCharacterAnimation(str:String, setOnionSkin:Bool = true)
  {
    if (setOnionSkin)
    {
      // clears the canvas
      onionSkinChar.pixels.fillRect(new Rectangle(0, 0, FlxG.width * 2, FlxG.height * 2), 0x00000000);

      onionSkinChar.stamp(swagChar, Std.int(swagChar.x), Std.int(swagChar.y));
      onionSkinChar.alpha = 0.6;
    }

    var animName = characterAnimNames[Std.parseInt(str)];
    swagChar.playAnimation(animName, true); // trace();
    trace(swagChar.animationOffsets.get(animName));

    txtOffsetShit.text = 'Offset: ' + swagChar.animOffsets;
  }

  var _file:FileReference;

  function saveOffsets(saveString:String, fileName:String)
  {
    if ((saveString != null) && (saveString.length > 0))
    {
      _file = new FileReference();
      _file.addEventListener(Event.COMPLETE, onSaveComplete);
      _file.addEventListener(Event.CANCEL, onSaveCancel);
      _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
      _file.save(saveString, fileName);
    }
  }

  function onSaveComplete(_):Void
  {
    _file.removeEventListener(Event.COMPLETE, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
    FlxG.log.notice("Successfully saved LEVEL DATA.");
  }

  /**
   * Called when the save file dialog is cancelled.
   */
  function onSaveCancel(_):Void
  {
    _file.removeEventListener(Event.COMPLETE, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
  }

  /**
   * Called if there is an error while saving the gameplay recording.
   */
  function onSaveError(_):Void
  {
    _file.removeEventListener(Event.COMPLETE, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
    FlxG.log.error("Problem saving Level data");
  }
}

enum abstract ANIMDEBUGVIEW(String)
{
  var SPRITESHEET;
  var ANIMATIONS;
}
