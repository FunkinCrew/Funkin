package funkin.ui.debug.char.components.wizard;

import haxe.ui.containers.dialogs.Dialog;
import funkin.ui.debug.char.handlers.CharCreatorStartupWizard;

// some super basic wizard dialog functions
class DefaultWizardDialog extends Dialog
{
  public static inline final PREVIOUS_STEP_BUTTON:String = "{{Previous Step}}";
  public static inline final NEXT_STEP_BUTTON:String = "{{Next Step}}";

  public var step:WizardStep;

  public var params:WizardGenerateParams = CharCreatorStartupWizard.params; // modify em directly from wizard dialog
  public var dialogArray:Array<DefaultWizardDialog> = CharCreatorStartupWizard.dialogArray;

  public var onComplete:WizardGenerateParams->Void = CharCreatorStartupWizard.onComplete;
  public var onQuit:Void->Void = CharCreatorStartupWizard.onQuit;

  override function new(step:WizardStep, isFirstStep:Bool = false)
  {
    super();

    this.step = step;
    destroyOnClose = false;

    buttons = (isFirstStep ? (DialogButton.CANCEL | NEXT_STEP_BUTTON) : (DialogButton.CANCEL | PREVIOUS_STEP_BUTTON | NEXT_STEP_BUTTON));

    onDialogClosed = function(_) {
      var id:Int = step;
      if (_.button == DialogButton.CANCEL)
      {
        CharCreatorStartupWizard.wizardProcessRunning = false;
        if (onQuit != null) onQuit();
      }
      else if (_.button == PREVIOUS_STEP_BUTTON)
      {
        id--;
        if (id < 0) return;
        dialogArray[id].showDialog();
      }
      else if (_.button == NEXT_STEP_BUTTON)
      {
        id++;
        if (id >= dialogArray.length)
        {
          CharCreatorStartupWizard.wizardProcessRunning = false;
          if (onComplete != null) onComplete(params);
          return;
        }

        dialogArray[id].showDialog();
      }
    }
  }

  override public function showDialog(modal:Bool = true)
  {
    super.showDialog();
    screenCenter();
  }

  public override function validateDialog(button:DialogButton, fn:Bool->Void)
  {
    if (button == NEXT_STEP_BUTTON)
    {
      if (!isNextStepAvailable())
      {
        fn(false);
        return;
      }

      fn(true);
      return;
    }

    fn(true);
  }

  public function isNextStepAvailable() // override for functionality
    return false;
}
