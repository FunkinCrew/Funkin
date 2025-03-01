package funkin.ui.debug.char.components.dialogs.select;

import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.VerticalScroll;
import haxe.ui.data.ArrayDataSource;
import funkin.data.character.CharacterRegistry;
import funkin.util.SortUtil;
import funkin.data.freeplay.player.PlayerRegistry;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/select/playable-character-settings-dialog.xml"))
class PlayableCharacterSettingsDialog extends DefaultPageDialog
{
  public var ownedCharacters(get, never):Array<String>;

  function get_ownedCharacters():Array<String>
  {
    return ownedCharBox.listOwnedCharacters();
  }

  var ownedCharBox:AddOwnedCharBox;

  override public function new(daPage:CharCreatorSelectPage)
  {
    super(daPage);

    ownedCharBox = new AddOwnedCharBox(daPage);
    ownedCharsView.addComponent(ownedCharBox);
    ownedCharBox.addPlayerDropdowns();

    var playuh = PlayerRegistry.instance.fetchEntry(daPage.data.importedPlayerData ?? "");
    if (playuh != null)
    {
      playerDataName.text = playuh.getName();
      playerDataShowUnowned.selected = playuh.shouldShowUnownedChars();
      playerDataUnlocked.selected = playuh.isUnlocked();
    }
  }
}

private class AddOwnedCharBox extends HBox
{
  var dropDowns:Array<DropDown> = [];
  var daPage:CharCreatorSelectPage;

  var addButton:Button = new Button();
  var removeButton:Button = new Button();

  override public function new(page:CharCreatorSelectPage)
  {
    super();
    daPage = page;

    styleString = "border:1px solid $normal-border-color";
    percentWidth = 100;
    height = 25;
    verticalAlign = "center";

    addButton.text = "Add New Box";
    removeButton.text = "Remove Last Box";

    addButton.percentWidth = removeButton.percentWidth = 50;
    addButton.percentHeight = removeButton.percentHeight = 100;

    addButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      var newDropDown = createDropdown();
      dropDowns.push(newDropDown);

      parentList.addComponentAt(newDropDown, parentList.childComponents.length - 1); // considering this box is last
      removeButton.disabled = false;
    }

    removeButton.disabled = true;
    removeButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      dropDowns.pop();

      parentList.removeComponentAt(parentList.childComponents.length - 2);
      if (parentList.childComponents.length <= 2) removeButton.disabled = true;
    }

    addComponent(addButton);
    addComponent(removeButton);
  }

  public function addPlayerDropdowns()
  {
    var playuh = PlayerRegistry.instance.fetchEntry(daPage.data.importedPlayerData ?? "");
    if (playuh != null && this.parentComponent != null)
    {
      for (thing in playuh.getOwnedCharacterIds())
      {
        var newDropDown = createDropdown(thing);
        dropDowns.push(newDropDown);

        this.parentComponent.addComponentAt(newDropDown, this.parentComponent.childComponents.length - 1); // considering this box is last
      }
    }
  }

  function createDropdown(?selectSumth:String = "")
  {
    var newDropDown = new DropDown();
    newDropDown.dataSource = new ArrayDataSource();
    newDropDown.height = 25;
    newDropDown.dropdownHeight = 100;
    newDropDown.percentWidth = 100;
    newDropDown.verticalAlign = "center";
    newDropDown.searchable = true;

    var ids = CharacterRegistry.listCharacterIds();
    if (daPage.data.generateCharacter && !ids.contains(daPage.data.characterID)) ids.push(daPage.data.characterID);
    ids.sort(SortUtil.alphabetically);

    for (id in ids)
    {
      newDropDown.dataSource.add({text: id, id: id});
    }

    if (selectSumth != null && ids.contains(selectSumth)) newDropDown.selectedIndex = ids.indexOf(selectSumth);

    return newDropDown;
  }

  public function listOwnedCharacters():Array<String>
  {
    return [
      for (dropDown in dropDowns)
        dropDown.safeSelectedItem.id
    ];
  }
}
