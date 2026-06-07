package funkin.ui.debug.stageeditor.toolboxes;

#if FEATURE_STAGE_EDITOR
import animate.FlxAnimateFrames;
import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.ListView;
import haxe.ui.data.ArrayDataSource;
import flixel.graphics.frames.FlxFrame;
import haxe.ui.events.UIEvent;

using StringTools;

@:access(funkin.ui.debug.stageeditor.StageEditorState) @:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-anims.xml"))
class StageEditorObjectAnimsToolbox extends StageEditorDefaultToolbox
{
  var linkedObj:StageEditorObject = null;
  var objAnims:DropDown;
  var objAnimName:TextField;
  var objFrameList:ListView;
  var objAnimPrefix:TextField;
  var objAnimIndices:TextField;
  var objAnimLooped:CheckBox;
  var objAnimFlipX:CheckBox;
  var objAnimFlipY:CheckBox;
  var objAnimStart:CheckBox;
  var objAnimFramerate:NumberStepper;
  var objAnimOffsetX:NumberStepper;
  var objAnimOffsetY:NumberStepper;
  var objAnimSave:Button;
  var objAnimDelete:Button;

  override public function new(state:StageEditorState)
  {
    super(state);

    objFrameList.onChange = function(_)
    {
      if (objFrameList.selectedIndex == -1) return;
      objAnimPrefix.text = objFrameList.selectedItem.name;

      // Remove the indicators from the prefix text if the selected item is from an atlas sprite.
      if (objFrameList.selectedItem.isLabel != null)
      {
        var isLabel:Bool = objFrameList.selectedItem.isLabel ?? false;
        objAnimPrefix.text = objAnimPrefix.text.replace(' ${isLabel ? "(Label)" : "(Symbol)"}', '');
      }
    }

    objAnims.onChange = function(_)
    {
      var animData = linkedObj?.animationDatas[
        objAnims.selectedItem?.text ?? ""
      ];

      if (linkedObj == null || objAnims.selectedIndex == -1 || animData == null)
      {
        // Reset everything.
        objAnimName.text = objAnimPrefix.text = objAnimIndices.text = "";
        objAnimLooped.selected = objAnimFlipX.selected = objAnimFlipY.selected = objAnimStart.selected = false;
        objAnimFramerate.pos = 24;
        objAnimOffsetX.pos = objAnimOffsetY.pos = 0;
        return;
      }

      // Update the displays.
      objAnimName.text = objAnims.selectedItem.text;
      objAnimPrefix.text = animData.prefix ?? "";
      objAnimIndices.text = (animData.frameIndices?.join(", ") ?? "");

      objAnimLooped.selected = animData.looped ?? false;
      objAnimFlipX.selected = animData.flipX ?? false;
      objAnimFlipY.selected = animData.flipY ?? false;
      objAnimFramerate.pos = animData.frameRate ?? 24;
      objAnimStart.selected = objAnimName.text == linkedObj.startingAnimation;

      objAnimOffsetX.pos = (animData.offsets[0] ?? 0);
      objAnimOffsetY.pos = (animData.offsets[1] ?? 0);
    }

    objAnimSave.onClick = function(_)
    {
      if (linkedObj == null) return;

      if ((objAnimName.text ?? "") == "")
      {
        state.notifyChange("Animation Saving Error", "The Animation Name is missing.", true);
        return;
      }

      if ((objAnimPrefix.text ?? "") == "")
      {
        state.notifyChange("Animation Saving Error", "The Animation Prefix is missing.", true);
        return;
      }

      addAnimation();
    }

    objAnimDelete.onClick = function(_)
    {
      if (linkedObj == null || linkedObj.animation.getNameList().length <= 0 || objAnims.selectedIndex < 0) return;

      linkedObj.animation.pause();
      linkedObj.animation.stop();
      linkedObj.animation.curAnim = null;

      var daAnim:String = linkedObj.animation.getNameList()[objAnims.selectedIndex];
      if (linkedObj.startingAnimation == daAnim) linkedObj.startingAnimation = "";

      linkedObj.animation.remove(daAnim);
      linkedObj.animationDatas.remove(daAnim);

      state.notifyChange("Animation Deletion Done", "Animation "
        + objAnims.selectedItem.text
        + " has been removed from the Object "
        + linkedObj.name
        + ".");

      updateAnimList();

      objAnims.selectedIndex = objAnims.dataSource.size - 1;
    }

    this.onDialogClosed = onClose;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowObjectAnims.selected = false;
  }

  var previousFrames:Array<String> = [];
  var previousAnims:Array<String> = [];

  override public function refresh()
  {
    linkedObj = stageEditorState.selectedSprite;

    // If the selected object is null, reset the displays.
    if (linkedObj == null)
    {
      updateFrameList();
      updateAnimList();
      objAnims.selectedIndex = -1;
      return;
    }

    // Otherwise, update them accordingly.
    if (previousFrames != getObjectFrameList()) updateFrameList();
    if (previousAnims != linkedObj.animation.getNameList().copy()) updateAnimList();
  }

  /**
   * Get a formatted list of frames for the object.
   */
  function getObjectFrameList():Array<String>
  {
    if (linkedObj == null) return [];

    if (linkedObj.frames is FlxAnimateFrames)
    {
      var frames:FlxAnimateFrames = cast linkedObj.frames;

      @:privateAccess
      return linkedObj.getFrameLabelList().concat(frames.dictionary.keys().array());
    }

    return[
      for (f in linkedObj.frames.frames) f.name
    ];
  }

  function updateFrameList()
  {
    previousFrames = [];
    objFrameList.dataSource = new ArrayDataSource();

    if (linkedObj == null) return;

    if (linkedObj.frames is FlxAnimateFrames)
    {
      for (fname in linkedObj.getFrameLabelList())
      {
        objFrameList.dataSource.add({name: '$fname (Label)', isLabel: true});
        previousFrames.push(fname);
      }

      var frames:FlxAnimateFrames = cast linkedObj.frames;

      @:privateAccess
      for (fname in frames.dictionary.keys())
      {
        objFrameList.dataSource.add({name: '$fname (Symbol)', isLabel: false});
        previousFrames.push(fname);
      }
    }
    else
    {
      for (fname in linkedObj.frames.frames)
      {
        if (fname != null) objFrameList.dataSource.add({name: fname.name});
        previousFrames.push(fname.name);
      }
    }
  }

  function updateAnimList()
  {
    objAnims.dataSource.clear();
    previousAnims = [];

    if (linkedObj == null) return;

    for (aname in linkedObj.animation.getNameList())
    {
      objAnims.dataSource.add({text: aname});
      previousAnims.push(aname);
    }

    if (previousAnims.contains(linkedObj.startingAnimation)) objAnims.selectedIndex = previousAnims.indexOf(linkedObj.startingAnimation);
  }

  function addAnimation()
  {
    if (linkedObj.animation.getNameList().contains(objAnimName.text))
    {
      linkedObj.animation.remove(objAnimName.text);
    }

    var indices:Array<Null<Int>> = [];

    if ((objAnimIndices.text ?? "") != "")
    {
      var splitter = objAnimIndices.text.replace(" ", "").split(",");

      for (num in splitter) indices.push(Std.parseInt(num));
    }

    var shouldDoIndices:Bool = (indices.length > 0 && !indices.contains(null));
    var isSymbol:Bool = false;

    if (linkedObj.frames is FlxAnimateFrames)
    {
      isSymbol = cast(linkedObj.frames, FlxAnimateFrames).existsSymbol(objAnimPrefix.text);
    }

    linkedObj.addAnimation({
      name: objAnimName.text,
      prefix: objAnimPrefix.text,
      offsets: [objAnimOffsetX.pos, objAnimOffsetY.pos],
      looped: objAnimLooped.selected,
      frameIndices: (shouldDoIndices ? indices : []),
      frameRate: Std.int(objAnimFramerate.pos),
      flipX: objAnimFlipX.selected,
      flipY: objAnimFlipY.selected,
      animType: isSymbol ? 'symbol' : 'framelabel'
    });

    if (linkedObj.animation.getByName(objAnimName.text) == null)
    {
      stageEditorState.notifyChange("Animation Saving Error", "Could not build Animation by the provided Frames.", true);
      return;
    }

    if (objAnimStart.selected) linkedObj.startingAnimation = objAnimName.text;
    linkedObj.playAnimation(objAnimName.text);

    stageEditorState.notifyChange("Animation Saving Done", "Animation " + objAnimName.text + " has been saved to the Object " + linkedObj.name + ".");
    updateAnimList();

    // Stop the animation after a certain time.
    flixel.util.FlxTimer.wait(StageEditorState.TIME_BEFORE_ANIM_STOP, function()
    {
      if (linkedObj?.animation?.curAnim != null) linkedObj.animation.stop();
    });
  }
}
#end
