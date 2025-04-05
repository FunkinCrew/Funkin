package funkin.ui.debug.stageeditor.components;

import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.components.TextField;
import haxe.ui.components.CheckBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/stage-editor/dialogs/find-object.xml"))
class FindObjDialog extends Dialog
{
  var stageEditorState:StageEditorState;

  var assets:Array<StageEditorObject> = [];
  var curSelected:Int = 0;
  var field:TextField;

  var checkWord:CheckBox;
  var checkCaps:CheckBox;

  override public function new(state:StageEditorState, searchFor:String = "")
  {
    super();

    stageEditorState = state;
    nameField.text = searchFor;

    this.field = nameField;
    this.checkWord = wordCheck;
    this.checkCaps = capsCheck;

    field.onChange = function(_) updateIndicator();
    indicator.hide();

    top = 20;
    left = FlxG.width - width - 20;

    buttons = DialogButton.CANCEL | "{{Find Next}}";
    defaultButton = "{{Find Next}}";
  }

  public function updateIndicator()
  {
    var prevObjCheck = assets[curSelected];

    assets = [];

    for (ass in stageEditorState.spriteArray)
    {
      var name = ass.name;
      var checkFor = field.text;

      if (!checkCaps.selected)
      {
        name = name.toLowerCase();
        checkFor = checkFor.toLowerCase();
      }

      if (((name.contains(checkFor) && !checkWord.selected) || (name == checkFor && checkWord.selected)) && ass.visible) assets.push(ass);
    }

    if (assets.length > 0 && prevObjCheck == null)
    {
      stageEditorState.selectedSprite = assets[0];
    }

    if (assets.length > 0)
    {
      indicator.text = "Selected: " + (assets.indexOf(stageEditorState.selectedSprite) + 1) + " / " + assets.length;
    }
    else
    {
      indicator.text = "No Matches Found";
    }

    if (field.text != "" && field.text != null) indicator.show();
    else
      indicator.hide();
  }

  public override function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    var done = true;

    if (button == "{{Find Next}}")
    {
      done = false;

      if (assets.length > 0)
      {
        curSelected = assets.indexOf(stageEditorState.selectedSprite);
        curSelected++;

        if (curSelected >= assets.length) curSelected = 0;

        stageEditorState.selectedSprite = assets[curSelected];
        indicator.text = "Selected: " + (assets.indexOf(stageEditorState.selectedSprite) + 1) + " / " + assets.length;

        stageEditorState.camFollow.x = assets[curSelected].getMidpoint().x;
        stageEditorState.camFollow.y = assets[curSelected].getMidpoint().y;
      }
    }
    fn(done);
  }
}
