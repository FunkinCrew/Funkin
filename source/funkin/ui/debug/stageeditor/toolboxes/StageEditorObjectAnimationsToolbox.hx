package funkin.ui.debug.stageeditor.toolboxes;

import haxe.ui.components.Button;
import haxe.ui.components.CheckBox;
import haxe.ui.components.DropDown;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.ListView;
import haxe.ui.data.ArrayDataSource;
import flixel.graphics.frames.FlxFrame;
import haxe.ui.events.UIEvent;

@:access(funkin.ui.debug.stageeditor.StageEditorState)
@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/toolboxes/object-anims.xml"))
class StageEditorObjectAnimationsToolbox extends StageEditorBaseToolbox
{
  var objectAnimations:DropDown;
  var objectAnimationName:TextField;
  var objectFrameList:ListView;

  var objectAnimationPrefix:TextField;
  var objectAnimationIndices:TextField;
  var objectAnimationLoop:CheckBox;
  var objectAnimationFlipX:CheckBox;
  var objectAnimationFlipY:CheckBox;
  var objectPlayAnimation:CheckBox;
  var objectAnimationFramerate:NumberStepper;
  var objectAnimationOffsetX:NumberStepper;
  var objectAnimationOffsetY:NumberStepper;

  var objectAnimationSave:Button;
  var objectAnimationRemove:Button;

  var _initializing:Bool = true;

  public function new(stageEditorState2:StageEditorState)
  {
    super(stageEditorState2);

    // initialize();

    this.onDialogClosed = onClose;

    this._initializing = false;
  }

  function onClose(event:UIEvent)
  {
    stageEditorState.menubarItemWindowObjectAnimations.selected = false;
  }

  public override function refresh():Void
  {
    super.refresh();


  }
}
