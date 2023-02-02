package funkin.ui.stageBuildShit;

import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;
import funkin.play.PlayState;
import funkin.play.stage.StageData;
import funkin.ui.haxeui.HaxeUISubState;
import haxe.ui.RuntimeComponentBuilder;
import haxe.ui.core.Component;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

class StageOffsetSubstate extends HaxeUISubState
{
  var uiStuff:Component;

  static final STAGE_EDITOR_LAYOUT = Paths.ui('stage-editor/stage-editor-view');

  public function new()
  {
    super(STAGE_EDITOR_LAYOUT);
  }

  override function create()
  {
    super.create();

    FlxG.mouse.visible = true;
    PlayState.instance.pauseMusic();
    FlxG.camera.target = null;

    setupUIListeners();

    // var str = Paths.xml('ui/stage-editor-view');
    // uiStuff = RuntimeComponentBuilder.fromAsset(str);

    // uiStuff.findComponent("lol").onClick = saveCharacterCompile;
    // uiStuff.findComponent('saveAs').onClick = saveStageFileRef;

    // add(uiStuff);

    PlayState.instance.persistentUpdate = true;
    component.cameras = [PlayState.instance.camHUD];
    // uiStuff.cameras = [PlayState.instance.camHUD];
    // btn.cameras = [PlayState.instance.camHUD];

    for (thing in PlayState.instance.currentStage)
    {
      FlxMouseEvent.add(thing, spr -> {
        char = cast thing;
        trace("JUST PRESSED!");
        sprOld.x = thing.x;
        sprOld.y = thing.y;

        mosPosOld.x = FlxG.mouse.x;
        mosPosOld.y = FlxG.mouse.y;
      }, null, spr -> {
        // ID tag is to see if currently overlapping hold basically!, a bit more reliable than checking transparency!
        // used for bug where you can click, and if you click on NO sprite, it snaps the thing to position! unintended!

        if (FlxG.keys.pressed.CONTROL)
        {
          spr.ID = 1;
          spr.alpha = 0.5;
        }
        else
        {
          spr.ID = 0;
          spr.alpha = 1;
        }
      }, spr -> {
        spr.ID = 0;
        spr.alpha = 1;
      });
    }
  }

  function setupUIListeners()
  {
    addUIClickListener('lol', saveCharacterCompile);
    addUIClickListener('saveAs', saveStageFileRef);
  }

  var mosPosOld:FlxPoint = new FlxPoint();
  var sprOld:FlxPoint = new FlxPoint();

  var char:FlxSprite = null;
  var overlappingChar:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (char != null && char.ID == 1 && FlxG.mouse.pressed)
    {
      char.x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
      char.y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
    }

    if (char != null)
    {
      var zoomShitLol:Float = 2 / FlxG.camera.zoom;

      if (FlxG.keys.justPressed.LEFT) char.x -= zoomShitLol;
      if (FlxG.keys.justPressed.RIGHT) char.x += zoomShitLol;
      if (FlxG.keys.justPressed.UP) char.y -= zoomShitLol;
      if (FlxG.keys.justPressed.DOWN) char.y += zoomShitLol;
    }

    FlxG.mouse.visible = true;

    CoolUtil.mouseCamDrag();

    if (FlxG.keys.pressed.CONTROL) CoolUtil.mouseWheelZoom();

    if (FlxG.mouse.wheel != 0)
    {
      FlxG.camera.zoom += FlxG.mouse.wheel * 0.1;
    }

    if (FlxG.keys.justPressed.Y)
    {
      for (thing in PlayState.instance.currentStage)
      {
        FlxMouseEvent.remove(thing);
        thing.alpha = 1;
      }

      // if (uiStuff != null) remove(uiStuff);

      // uiStuff = null;
      PlayState.disableKeys = false;
      PlayState.instance.resetCamera();
      FlxG.mouse.visible = false;
      close();
    }
  }

  var _file:FileReference;

  function saveStageFileRef(_):Void
  {
    var jsonStr = prepStageStuff();

    _file = new FileReference();
    _file.addEventListener(Event.COMPLETE, onSaveComplete);
    _file.addEventListener(Event.CANCEL, onSaveCancel);
    _file.addEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file.save(jsonStr, PlayState.instance.currentStageId + ".json");
  }

  function onSaveComplete(_)
  {
    fileRemoveListens();
    FlxG.log.notice("Successfully saved!");
  }

  function onSaveCancel(_)
  {
    fileRemoveListens();
  }

  function onSaveError(_)
  {
    fileRemoveListens();
    FlxG.log.error("Problem saving Stage file!");
  }

  function fileRemoveListens()
  {
    _file.removeEventListener(Event.COMPLETE, onSaveComplete);
    _file.removeEventListener(Event.CANCEL, onSaveCancel);
    _file.removeEventListener(IOErrorEvent.IO_ERROR, onSaveError);
    _file = null;
  }

  function saveCharacterCompile(_):Void
  {
    var outputJson:String = prepStageStuff();

    #if sys
    // save "local" to the current export.
    sys.io.File.saveContent('./assets/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);

    // save to the dev version
    sys.io.File.saveContent('../../../../assets/preload/data/stages/' + PlayState.instance.currentStageId + '.json', outputJson);
    #end
  }

  function prepStageStuff():String
  {
    var stageLol:StageData = StageDataParser.parseStageData(PlayState.instance.currentStageId);

    for (prop in stageLol.props)
    {
      @:privateAccess
      var posStuff = PlayState.instance.currentStage.namedProps.get(prop.name);

      prop.position[0] = posStuff.x;
      prop.position[1] = posStuff.y;
    }

    var bfPos = PlayState.instance.currentStage.getBoyfriend().feetPosition;
    stageLol.characters.bf.position[0] = Std.int(bfPos.x);
    stageLol.characters.bf.position[1] = Std.int(bfPos.y);

    var dadPos = PlayState.instance.currentStage.getDad().feetPosition;

    stageLol.characters.dad.position[0] = Std.int(dadPos.x);
    stageLol.characters.dad.position[1] = Std.int(dadPos.y);

    var GF_FEET_SNIIIIIIIIIIIIIFFFF = PlayState.instance.currentStage.getGirlfriend().feetPosition;
    stageLol.characters.gf.position[0] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.x);
    stageLol.characters.gf.position[1] = Std.int(GF_FEET_SNIIIIIIIIIIIIIFFFF.y);

    return CoolUtil.jsonStringify(stageLol);
  }
}
