package funkin.ui.debug.stage;

import flixel.FlxSprite;
import flixel.input.mouse.FlxMouseEvent;
import flixel.math.FlxPoint;
import funkin.play.PlayState;
import funkin.data.stage.StageData;
import funkin.play.stage.StageProp;
import funkin.graphics.shaders.StrokeShader;
import funkin.ui.haxeui.HaxeUISubState;
import funkin.ui.debug.stage.StageEditorCommand.MovePropCommand;
import funkin.ui.debug.stage.StageEditorCommand.SelectPropCommand;
import funkin.data.stage.StageRegistry;
import funkin.util.MouseUtil;
import haxe.ui.containers.ListView;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import openfl.events.Event;
import openfl.events.IOErrorEvent;
import openfl.net.FileReference;

/**
 * A substate dedicated to allowing the user to create and edit stages/props
 * Built with HaxeUI for use by both developers and modders.
 *
 * All functionality is kept within this file to ruin my own sanity.
 *
 * @author ninjamuffin99
 */
// Give other classes access to private instance fields
@:allow(funkin.ui.debug.stage.StageEditorCommand)
class StageOffsetSubState extends HaxeUISubState
{
  var uiStuff:Component;

  var outlineShader:StrokeShader;

  static final STAGE_EDITOR_LAYOUT = Paths.ui('stage-editor/stage-editor-view');

  public function new()
  {
    super(STAGE_EDITOR_LAYOUT);
  }

  override function create()
  {
    super.create();

    var playState = PlayState.instance;

    FlxG.mouse.visible = true;
    playState.pauseMusic();
    playState.cancelAllCameraTweens();
    FlxG.camera.target = null;

    setupUIListeners();

    // var str = Paths.xml('ui/stage-editor-view');
    // uiStuff = RuntimeComponentBuilder.fromAsset(str);

    // uiStuff.findComponent("lol").onClick = saveCharacterCompile;
    // uiStuff.findComponent('saveAs').onClick = saveStageFileRef;

    // add(uiStuff);

    playState.persistentUpdate = true;
    component.cameras = [playState.camHUD];
    // uiStuff.cameras = [PlayState.instance.camHUD];
    // btn.cameras = [PlayState.instance.camHUD];

    outlineShader = new StrokeShader(0xFFFFFFFF, 4, 4);

    var layerList:ListView = findComponent("prop-layers");

    for (thing in playState.currentStage)
    {
      var prop:StageProp = cast thing;
      if (prop != null && prop.name != null)
      {
        layerList.dataSource.add(
          {
            item: prop.name,
            complete: true,
            id: 'swag'
          });
      }

      FlxMouseEvent.add(thing, spr -> {
        // onMouseClick

        trace(spr);

        var dyn:StageProp = cast spr;
        if (dyn != null && dyn.name != null)
        {
          if (FlxG.keys.pressed.CONTROL && char != dyn) selectProp(dyn.name);
        }
      }, null, spr -> {
        // onMouseHover
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
        // onOut
        // this if statement is for when u move ur mouse too fast... figure out how to proper lock it to mouse!
        if (char != spr)
        {
          spr.ID = 0;
          spr.alpha = 1;
        }
      });
    }
  }

  function selectProp(propName:String)
  {
    if (char != null && char.shader == outlineShader) char.shader = null;

    var proptemp:FlxSprite = cast PlayState.instance.currentStage.getNamedProp(propName);

    if (proptemp == null) return;

    performCommand(new SelectPropCommand(proptemp));

    char.shader = outlineShader;

    // trace(thing);
    // trace(spr);
    trace("JUST PRESSED!");
    sprOld.x = char.x;
    sprOld.y = char.y;

    mosPosOld.x = FlxG.mouse.x;
    mosPosOld.y = FlxG.mouse.y;

    setUIValue('propXPos', char.x);
    setUIValue('propYPos', char.y);
  }

  function setupUIListeners()
  {
    addUIClickListener('lol', saveCharacterCompile);
    addUIClickListener('saveAs', saveStageFileRef);

    // addUIChangeListener('complete', (event:UIEvent) -> {
    //   trace(event.value);
    //   trace(event.type);
    //   trace(event.target);
    //   trace(event.data);
    // });

    addUIChangeListener('propXPos', (event:UIEvent) -> {
      if (char != null)
      {
        char.x = event.value;
        // var xDiff = event.value - char.x;
        // performCommand(new MovePropCommand(xDiff, 0));
      }
    });

    addUIChangeListener('propYPos', (event:UIEvent) -> {
      if (char != null)
      {
        char.y = event.value;
        // var yDiff = event.value - char.y;
        // performCommand(new MovePropCommand(0, yDiff));
      }
    });

    addUIChangeListener('prop-layers', (event:UIEvent) -> {
      trace(event.value);
      trace(event.type);
      trace(event.target);
      trace(event.data);
      trace(event.relatedEvent);
    });

    setUICheckboxSelected('complete', false);
  }

  var mosPosOld:FlxPoint = new FlxPoint();
  var sprOld:FlxPoint = new FlxPoint();

  private var char:FlxSprite = null;
  var overlappingChar:Bool = false;

  override function update(elapsed:Float)
  {
    super.update(elapsed);

    if (FlxG.keys.justPressed.O)
    {
      trace("COMMANDS!!!");
      trace("-/-/-/-/-/-");
      for (ind => cmd in commandStack)
      {
        var output:String = cmd.toString();
        if (curOperation == ind) output += " <---";

        trace(output);
      }
      trace("-/-/-/-/-/-");
    }

    if (char != null)
    {
      setUIValue('propXPos', char.x);
      setUIValue('propYPos', char.y);
    }

    if (char != null && char.ID == 1)
    {
      if (FlxG.mouse.pressed)
      {
        char.x = sprOld.x - (mosPosOld.x - FlxG.mouse.x);
        char.y = sprOld.y - (mosPosOld.y - FlxG.mouse.y);
      }

      if (FlxG.mouse.justReleased)
      {
        trace("LOL");
        var xDiff = (mosPosOld.x - FlxG.mouse.x);
        var yDiff = (mosPosOld.y - FlxG.mouse.y);
        performCommand(new MovePropCommand(-xDiff, -yDiff, false));
      }
    }

    if (char != null)
    {
      var zoomShitLol:Float = 2 / FlxG.camera.zoom;

      if (FlxG.keys.justPressed.LEFT) performCommand(new MovePropCommand(-zoomShitLol, 0));
      if (FlxG.keys.justPressed.RIGHT) performCommand(new MovePropCommand(zoomShitLol, 0));
      if (FlxG.keys.justPressed.UP) performCommand(new MovePropCommand(0, -zoomShitLol));
      if (FlxG.keys.justPressed.DOWN) performCommand(new MovePropCommand(0, zoomShitLol));
    }

    FlxG.mouse.visible = true;

    MouseUtil.mouseCamDrag();

    if (FlxG.keys.pressed.CONTROL) MouseUtil.mouseWheelZoom();

    if (FlxG.keys.pressed.CONTROL && FlxG.keys.justPressed.Z) undoLastCommand();

    if (FlxG.keys.justPressed.Y)
    {
      for (thing in PlayState.instance.currentStage)
      {
        FlxMouseEvent.remove(thing);
        thing.alpha = 1;
      }

      // if (uiStuff != null) remove(uiStuff);

      // uiStuff = null;
      PlayState.instance.disableKeys = false;
      PlayState.instance.resetCamera();
      FlxG.mouse.visible = false;
      close();
    }
  }

  var commandStack:Array<StageEditorCommand> = [];
  var curOperation:Int = -1; // -1 at default, arrays start at 0

  function performCommand(command:StageEditorCommand):Void
  {
    command.execute(this);
    commandStack.push(command);
    curOperation++;
    if (curOperation < commandStack.length - 1) commandStack = commandStack.slice(0, curOperation + 1);
  }

  function undoCommand(command:StageEditorCommand):Void
  {
    command.undo(this);
    curOperation--;
  }

  function undoLastCommand():Void
  {
    trace(curOperation);
    trace(commandStack.length);
    // trace(commandStack[commandStack.length]);
    if (curOperation == -1 || commandStack.length == 0)
    {
      trace('no actions to undo');
      return;
    }

    var command = commandStack[curOperation];
    undoCommand(command);
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
    var stageLol:StageData = StageRegistry.instance.fetchEntry(PlayState.instance.currentStageId)?._data;

    if (stageLol == null)
    {
      FlxG.log.error("Stage not found in registry!");
      return "";
    }

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

    return stageLol.serialize();
  }
}
