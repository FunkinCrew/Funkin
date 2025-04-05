package funkin.ui.debug.stage;

import flixel.FlxCamera;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.group.FlxGroup;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;
import funkin.ui.MusicBeatState;
import flixel.text.FlxText;
import flixel.ui.FlxButton;
import flixel.util.FlxColor;
import flixel.util.FlxSort;
import funkin.util.MouseUtil;
import flixel.util.FlxTimer;

class StageBuilderState extends MusicBeatState
{
  var hudGrp:FlxGroup;
  var textInfo:FlxText;

  var sprGrp:FlxTypedGroup<SprStage>;

  // var snd:Sound;
  // var sndChannel:SoundChannel;
  var hudCam:FlxCamera;

  override function create()
  {
    hudCam = new FlxCamera();
    hudCam.bgColor.alpha = 0;

    FlxG.cameras.add(hudCam, false);

    super.create();

    FlxG.mouse.visible = true;

    // snd = new Sound();

    // var swagBytes:ByteArray = new ByteArray(8192);

    // for (shit in 0...8192)
    // {
    // swagBytes.writeFloat(Math.sin((shit) / Math.PI) * 0.25);
    // swagBytes.writeFloat(Math.sin((shit) / Math.PI) * 0.25);
    // trace('wweseosme???');
    // }

    // snd.__buffer = AudioBuffer.fromBytes(swagBytes);
    // snd.dispatchEvent(new Event(Event.COMPLETE));

    // swagBytes.writeFloat(Math.sin((shit + event.position) / Math.PI) * 0.25);
    // swagBytes.writeFloat(Math.sin((shit + event.position) / Math.PI) * 0.25);

    // function sineShit(event:SampleDataEvent):Void
    // {
    // 	for (shit in 0...8192)
    // 	{
    // 		event.data.writeFloat(Math.sin((shit + event.position) / Math.PI) * 0.25);
    // 		event.data.writeFloat(Math.sin((shit + event.position) / Math.PI) * 0.25);
    // 		trace('wweseosme???');
    // 	}
    // }

    // snd.addEventListener(SampleDataEvent.SAMPLE_DATA, sineShit);
    // snd.__buffer.
    // snd = Assets.getSound(Paths.music('freakyMenu/freakyMenu'));
    // for (thing in snd.load)
    // thing = Std.int(thing / 2);
    // snd.play();
    // trace(snd.__buffer.data.toBytes().getData().bytes);

    var bg:FlxSprite = FlxGridOverlay.create(10, 10);
    add(bg);

    sprGrp = new FlxTypedGroup<SprStage>();
    add(sprGrp);

    hudGrp = new FlxGroup();
    hudGrp.cameras = [hudCam];
    add(hudGrp);

    textInfo = new FlxText(10, 80, 0, "", 24);
    textInfo.setFormat(Paths.font("vcr.ttf"), 20, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
    textInfo.scrollFactor.set();
    hudGrp.add(textInfo);

    var imgBtn:FlxButton = new FlxButton(20, 20, "Load Image", loadImage);
    hudGrp.add(imgBtn);

    var saveSceneBtn:FlxButton = new FlxButton(20, 50, "Save Scene", saveScene);
    hudGrp.add(saveSceneBtn);

    #if desktop
    FlxG.stage.window.onDropFile.add(function(path:String) {
      trace("DROPPED FILE FROM: " + Std.string(path));

      var fileName:String = path.split('\\').pop();
      var fileNameNoExt:String = fileName.split('.')[0];

      var newPath = './' + Paths.image('stageBuild/' + fileNameNoExt);
      // sys.io.File.copy(path, newPath);
      // trace(sys.io.File.getBytes(Std.string(path)).toString());

      // FlxG.bitmap.add('assets/preload/images/stageBuild/eltonJohn.png');

      sys.io.File.copy(path, './' + Paths.image('stageBuild/stageTempImg'));

      var fo = sys.io.File.write(newPath);

      fo.write(sys.io.File.getBytes(path));

      new FlxTimer().start(0.2, function(tmr) {
        var awesomeImg:SprStage = new SprStage(FlxG.mouse.x, FlxG.mouse.y, sprDragShitFunc);
        awesomeImg.loadGraphic(Paths.image('stageBuild/stageTempImg'), false, 0, 0, true);

        awesomeImg.layer = sprGrp.members.length;
        awesomeImg.imgName = fileName;

        sprGrp.add(awesomeImg);

        curFocus = MOVEMENTS;
      });

      // Load the image shit by
      // 1. reading the image file names
      // 2. copy to stage temp like normal?

      // var awesomeImg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('stageBuild/swag'));
      // sprGrp.add(awesomeImg);
      // var swag = Paths.image('characters/temp');

      // if (bf != null)
      // remove(bf);
      // FlxG.bitmap.removeByKey(Paths.image('characters/temp'));

      // bf.loadGraphic(Paths.image('characters/temp'));
      // add(bf);
    });
    #end
  }

  public static var curSelectedSpr:SprStage;

  function loadImage():Void
  {
    // var img:FlxSprite = new FlxSprite().loadGraphic(Paths.image('newgrounds_logo'));
    // img.scrollFactor.set(0.5, 2);
    // sprGrp.add(img);
  }

  function saveScene():Void
  {
    // trace();
  }

  public static var curTool:TOOLS = SELECT;

  var tempTool:TOOLS = SELECT;

  override function update(elapsed:Float)
  {
    if (FlxG.keys.justPressed.H) hudGrp.visible = !hudGrp.visible;

    if (FlxG.keys.justPressed.ESCAPE)
    {
      if (curFocus == ATTRIBUTES) curFocus = MOVEMENTS;
      else
        curFocus = ATTRIBUTES;
    }

    switch (curFocus)
    {
      case MOVEMENTS:
        movementControls();
      case ATTRIBUTES:
        attributeControls();
      default:
    }

    if (FlxG.keys.justPressed.DELETE)
    {
      if (curSelectedSpr != null) sprGrp.remove(curSelectedSpr, true);
    }

    MouseUtil.mouseCamDrag();

    if (FlxG.keys.pressed.CONTROL) MouseUtil.mouseWheelZoom();

    if (isShaking)
    {
      FlxG.stage.window.x = Std.int(shakePos.x + (FlxG.random.float(-1, 1) * shakeIntensity));
      FlxG.stage.window.y = Std.int(shakePos.y + (FlxG.random.float(-1, 1) * shakeIntensity));

      shakeIntensity -= 30 * elapsed;

      if (shakeIntensity <= 0)
      {
        isShaking = false;
        shakeIntensity = 60;
        FlxG.stage.window.x = Std.int(shakePos.x);
        FlxG.stage.window.y = Std.int(shakePos.y);
      }
    }

    if (curTool == GRABBING && FlxG.mouse.justReleased)
    {
      moveSprPos([
        curSelectedSpr.x - curSelectedSpr.oldPos.x,
        curSelectedSpr.y - curSelectedSpr.oldPos.y
      ]);
    }

    if (FlxG.keys.justPressed.Z && actionQueue.length > 0)
    {
      // trace('UNDO - QUEUE LENGTH: ' + actionQueue.length);
      isUndoRedo = true;

      var daFunc = actionQueue.pop();
      var daValue = posQueue.pop();

      daFunc(daValue);
    }

    super.update(elapsed);
  }

  function attributeControls():Void
  {
    textInfo.alpha = 1;

    if (FlxG.keys.justPressed.LEFT || FlxG.keys.justPressed.RIGHT)
    {
      if (FlxG.keys.justPressed.LEFT)
      {
        curSelectedSpr.scrollFactor.x -= 0.1;
        curSelectedSpr.scrollFactor.y -= 0.1;
      }

      if (FlxG.keys.justPressed.RIGHT)
      {
        curSelectedSpr.scrollFactor.x += 0.1;
        curSelectedSpr.scrollFactor.y += 0.1;
      }

      updateTextInfo();
    }
  }

  function movementControls():Void
  {
    textInfo.alpha = 0.5;

    if (FlxG.keys.justPressed.CONTROL)
    {
      tempTool = curTool;

      changeTool(SELECT);
    }
    if (FlxG.keys.justReleased.CONTROL)
    {
      changeTool(tempTool);
    }

    if (FlxG.keys.justPressed.V)
    {
      changeTool(SELECT);
    }

    if (FlxG.keys.justPressed.R)
    {
      shakingScreen();

      FlxG.stage.window.title = "YOU WILL DIE";

      // FlxG.stage.window.x -= Std.int(10);
      // FlxG.stage.window.y -= Std.int(10);
      // FlxG.stage.window.width += Std.int(40);
      // FlxG.stage.window.height += Std.int(20);
    }

    if (FlxG.keys.justPressed.RIGHT) moveSprPos([1, 0, true]);
    if (FlxG.keys.justPressed.LEFT) moveSprPos([-1, 0, true]);
    if (FlxG.keys.justPressed.UP) moveSprPos([0, -1, true]);
    if (FlxG.keys.justPressed.DOWN) moveSprPos([0, 1, true]);

    if (FlxG.keys.justPressed.LBRACKET)
    {
      if (curSelectedSpr != null) moveLayer(1);
    }

    if (FlxG.keys.justPressed.RBRACKET)
    {
      if (curSelectedSpr != null) moveLayer(-1);
    }
  }

  var curFocus:FOCUS = MOVEMENTS;

  static public function changeTool(newTool:TOOLS)
  {
    curTool = newTool;

    switch (curTool)
    {
      // redo this later so it doesn't create brand new FlxSprites into memory or someshit??? this was lazy 3AM way
      case SELECT:
        FlxG.mouse.load(new FlxSprite().loadGraphic(Paths.image('stageBuild/cursorSelect')).pixels);
      case GRABBING:
        FlxG.mouse.load(new FlxSprite().loadGraphic(Paths.image('stageBuild/cursorGrabbing')).pixels);
      case GRAB:
        FlxG.mouse.load(new FlxSprite().loadGraphic(Paths.image('stageBuild/cursorGrab')).pixels);
      default:
        trace('swag');
    }
  }

  function changeCurSelected(spr:SprStage)
  {
    undoRedoCheck(changeCurSelected, curSelectedSpr);
    curSelectedSpr = spr;

    updateTextInfo();
  }

  function updateTextInfo()
  {
    textInfo.text = curSelectedSpr.imgName;
    textInfo.text += ' - parallax: ' + curSelectedSpr.scrollFactor;
  }

  // base check to see if its in a state of undo or redo
  function undoRedoCheck(daFunc:Dynamic->Void, daValue:Dynamic)
  {
    if (!isUndoRedo)
    {
      actionQueue.push(daFunc);
      posQueue.push(daValue);
    }
    else
      isUndoRedo = false;
  }

  function sprDragShitFunc(spr:SprStage)
  {
    if (curTool == SELECT) changeCurSelected(spr);

    spr.mousePressing = true;

    if (spr.isSelected()) changeTool(GRABBING);
    spr.mouseOffset.set(FlxG.mouse.x - spr.x, FlxG.mouse.y - spr.y);
    spr.oldPos.set(spr.x, spr.y);
  }

  // make function for changing cur selection
  function moveSprPos(dumbArray:Array<Dynamic>)
  {
    var xDiff:Float = dumbArray[0];
    var yDiff:Float = dumbArray[1];
    var forceMove:Bool = dumbArray[2];

    // trace(xDiff);
    // trace(yDiff);

    // usually set to false for the MOUSE DRAG, merely to track movements from the mouse
    if (forceMove)
    {
      curSelectedSpr.x += xDiff;
      curSelectedSpr.y += yDiff;
    }

    undoRedoCheck(moveSprPos, [-xDiff, -yDiff, true]);
  }

  var isUndoRedo:Bool = false;
  var actionQueue:Array<Dynamic->Void> = [];
  var posQueue:Array<Dynamic> = [];

  function moveLayer(layerMovement:Int = 0):Void
  {
    if (curSelectedSpr.layer == 0 && layerMovement > 0) return;

    curSelectedSpr.layer -= layerMovement;
    sprGrp.members[curSelectedSpr.layer].layer += layerMovement;
    // NOTE: fix to account if only one layer is in?

    sortSprGrp();
    undoRedoCheck(moveLayer, layerMovement * -1);
  }

  var isShaking:Bool = false;
  var shakeIntensity:Float = 60;
  var shakePos:FlxPoint = new FlxPoint();

  function shakingScreen()
  {
    if (!isShaking)
    {
      isShaking = true;
      shakePos.set(FlxG.stage.window.x, FlxG.stage.window.y);
    }
  }

  function sortSprGrp()
  {
    sprGrp.sort(daLayerSorting, FlxSort.ASCENDING);

    FlxMouseEvent.reorder();
  }

  function daLayerSorting(order:Int = FlxSort.ASCENDING, layer1:SprStage, layer2:SprStage):Int
  {
    return FlxSort.byValues(FlxSort.ASCENDING, layer1.layer, layer2.layer);
  }
}

enum FOCUS
{
  ATTRIBUTES;
  MOVEMENTS;
  TOOLBAR;
}

enum TOOLS
{
  SELECT;
  MOVE;
  GRAB;
  GRABBING;
  BOYFRIEND;
}
