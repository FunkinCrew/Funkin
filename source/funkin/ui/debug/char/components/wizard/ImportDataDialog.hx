package funkin.ui.debug.char.components.wizard;

import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.data.freeplay.player.PlayerRegistry;
import haxe.ui.components.OptionBox;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/import-data.xml"))
class ImportDataDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(IMPORT_DATA);

    importCharCheck.onChange = function(_) importCharList.disabled = !importCharCheck.selected;
    importPlayerCheck.onChange = function(_) importPlayerList.disabled = !importPlayerCheck.selected;

    for (id in CharacterRegistry.listCharacterIds())
    {
      var check = new OptionBox();
      check.text = id;
      check.componentGroup = "characterData";
      check.selected = (id == selectedData);
      check.onChange = _ -> {
        selectedData = id;
      }
      importCharList.addComponent(check);
    }

    for (id in PlayerRegistry.instance.listEntryIds())
    {
      var check = new OptionBox();
      check.text = id;
      check.componentGroup = "playerData";
      check.selected = (id == selectedPlayer);
      check.onChange = _ -> {
        selectedPlayer = id;
      }
      importPlayerList.addComponent(check);
    }
  }

  var selectedData:String = Constants.DEFAULT_CHARACTER;
  var selectedPlayer:String = "bf"; // eh

  override public function showDialog(modal:Bool = true)
  {
    super.showDialog(modal);

    // we dont want to import any data if we don't even generate the character to begin with
    importCharData.disabled = !params.generateCharacter;
    importPlayer.disabled = !params.generatePlayerData;
  }

  override public function isNextStepAvailable()
  {
    if (params.generateCharacter && importCharCheck.selected) params.importedCharacter = selectedData;
    else
      params.importedCharacter = null;

    if (params.importedCharacter != null) params.renderType = CharacterRegistry.parseCharacterData(params.importedCharacter)?.renderType ?? Sparrow;

    if (params.generatePlayerData && importPlayerCheck.selected) params.importedPlayerData = selectedPlayer;
    else
      params.importedPlayerData = null;

    return true;
  }
}
