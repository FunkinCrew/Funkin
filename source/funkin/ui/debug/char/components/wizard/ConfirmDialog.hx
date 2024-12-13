package funkin.ui.debug.char.components.wizard;

import haxe.ui.components.Label;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/confirm-wizard.xml"))
class ConfirmDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(CONFIRM);
  }

  override public function showDialog(modal:Bool = true)
  {
    super.showDialog(modal);

    while (viewAllAssets.childComponents.length > 0)
      viewAllAssets.removeComponent(viewAllAssets.childComponents[0]);

    var labelFiles = new Label();
    labelFiles.text = "Files:";
    viewAllAssets.addComponent(labelFiles);

    var allFiles = [];
    if (params.files.length > 0) allFiles = allFiles.concat(params.files);
    if (params.charSelectFile != null) allFiles.push(params.charSelectFile);
    if (params.freeplayFile != null) allFiles.push(params.freeplayFile);

    if (allFiles.length == 0) labelFiles.text += " None";

    for (file in allFiles)
    {
      var fname = new Label();
      fname.text = "- " + file.name;
      fname.percentWidth = 100;
      viewAllAssets.addComponent(fname);
    }

    var labelImports = new Label();
    labelImports.text = "Imports:" + (params.importedCharacter == null && params.importedPlayerData == null ? " None" : "");
    viewAllAssets.addComponent(labelImports);

    if (params.importedCharacter != null)
    {
      var charImport = new Label();
      charImport.text = "- Character: " + params.importedCharacter;
      charImport.percentWidth = 100;
      viewAllAssets.addComponent(charImport);
    }

    if (params.importedPlayerData != null)
    {
      var playerImport = new Label();
      playerImport.text = "- Player Data: " + params.importedPlayerData;
      playerImport.percentWidth = 100;
      viewAllAssets.addComponent(playerImport);
    }
  }

  override public function isNextStepAvailable()
  {
    CharCreatorUtil.info("Character Generating Wizard", "Generated Character from the Files.");
    return true;
  }
}
