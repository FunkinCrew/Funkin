package funkin.ui.debug.char.components.wizard;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/start-dialog.xml"))
class StartWizardDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(STARTUP, true);

    startupCheckChar.onChange = function(_) params.generateCharacter = startupCheckChar.selected;
    startupCheckData.onChange = function(_) params.generatePlayerData = startupCheckData.selected;
    startupFieldID.onChange = function(_) params.characterID = startupFieldID.text;
  }

  override public function isNextStepAvailable()
  {
    if ((!params.generateCharacter && !params.generatePlayerData))
    {
      CharCreatorUtil.error("Start", "Please choose to Generate at least one thing.");
      return false;
    }

    if (params.characterID == "")
    {
      CharCreatorUtil.error("Start", "Missing the Character ID.");
      return false;
    }

    return true;
  }

  override public function showDialog(modal:Bool = true)
  {
    super.showDialog(modal);

    startupCheckChar.selected = params.generateCharacter;
    startupCheckData.selected = params.generatePlayerData;
  }
}
