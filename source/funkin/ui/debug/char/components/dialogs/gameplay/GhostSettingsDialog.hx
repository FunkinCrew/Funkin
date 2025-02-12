package funkin.ui.debug.char.components.dialogs.gameplay;

import haxe.ui.core.Screen;
import haxe.ui.containers.Grid;
import haxe.ui.containers.menus.Menu;
import funkin.data.character.CharacterData;
import funkin.data.character.CharacterRegistry;
import funkin.util.SortUtil;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/gameplay/ghost-dialog.xml"))
class GhostSettingsDialog extends DefaultPageDialog
{
  public var attachedMenu:GhostCharacterMenu;
  public var charId:String = Constants.DEFAULT_CHARACTER;

  override public function new(daPage:CharCreatorGameplayPage)
  {
    super(daPage);

    var regularChar = daPage.currentCharacter;
    var ghostChar = daPage.ghostCharacter;
    var charData = CharacterRegistry.fetchCharacterData(Constants.DEFAULT_CHARACTER);

    ghostTypeButton.icon = (charData == null ? null : CharacterRegistry.getCharPixelIconAsset(Constants.DEFAULT_CHARACTER));
    ghostTypeButton.text = (charData == null ? "None" : charData.name.length > 6 ? '${charData.name.substr(0, 6)}.' : '${charData.name}');

    // callbacks
    ghostEnable.onChange = function(_) {
      ghostDataBox.disabled = !ghostEnable.selected;
      ghostChar.visible = ghostEnable.selected;

      if (ghostChar.visible) // i love saving on data
      {
        daPage.ghostId = (ghostCustomChar.selected ? charId : "");
      }
    }

    ghostCurChar.onChange = function(_) {
      ghostTypeButton.disabled = ghostCurChar.selected;
      if (ghostCurChar.selected) Screen.instance.removeComponent(attachedMenu);

      if (ghostChar.visible && ghostCurChar.selected) daPage.ghostId = "";
    }

    ghostCustomChar.onChange = function(_) {
      ghostTypeButton.disabled = !ghostCustomChar.selected;
      if (!ghostCustomChar.selected) Screen.instance.removeComponent(attachedMenu);

      if (ghostChar.visible && ghostCustomChar.selected) daPage.ghostId = charId;
    }

    ghostTypeButton.onClick = function(_) {
      attachedMenu = new GhostCharacterMenu(daPage, this);
      Screen.instance.addComponent(attachedMenu);
    }

    ghostAnimDropdown.onChange = function(_) {
      if (ghostAnimDropdown.selectedIndex == -1) return;
      ghostChar.playAnimation(ghostAnimDropdown.selectedItem.text);
    }
  }
}

/**
 * Maybe it would be nice to move the character menus to it's own group at some point - this is the third state to use it.
 */
@:xml('
<menu id="iconSelector" width="410" height="185" padding="8">
  <vbox width="100%" height="100%">
    <scrollview id="ghostSelectScroll" width="390" height="150" contentWidth="100%" />
    <label id="ghostIconName" text="(choose a character)" />
  </vbox>
</menu>
')
class GhostCharacterMenu extends Menu
{
  override public function new(page:CharCreatorDefaultPage, parent:GhostSettingsDialog)
  {
    super();

    this.x = Screen.instance.currentMouseX;
    this.y = Screen.instance.currentMouseY;

    var charGrid = new Grid();
    charGrid.columns = 5;
    charGrid.width = this.width;
    ghostSelectScroll.addComponent(charGrid);

    var charIds = CharacterRegistry.listCharacterIds();
    charIds.sort(SortUtil.alphabetically);

    var defaultText:String = '(choose a character)';

    for (charIndex => charId in charIds)
    {
      var charData:CharacterData = CharacterRegistry.fetchCharacterData(charId);

      var charButton = new haxe.ui.components.Button();
      charButton.width = 70;
      charButton.height = 70;
      charButton.padding = 8;
      charButton.iconPosition = "top";

      if (charId == parent.charId)
      {
        // Scroll to the character if it is already selected.
        ghostSelectScroll.hscrollPos = Math.floor(charIndex / 5) * 80;
        charButton.selected = true;

        defaultText = '${charData.name} [${charId}]';
      }

      var LIMIT = 6;
      charButton.icon = CharacterRegistry.getCharPixelIconAsset(charId);
      charButton.text = charData.name.length > LIMIT ? '${charData.name.substr(0, LIMIT)}.' : '${charData.name}';

      charButton.onClick = _ -> {
        parent.charId = charId;

        var gameplayPage = cast(page, CharCreatorGameplayPage);
        if (gameplayPage.ghostCharacter.visible) gameplayPage.ghostId = charId;

        parent.ghostTypeButton.text = charButton.text;
        parent.ghostTypeButton.icon = charButton.icon;
      };

      charButton.onMouseOver = _ -> {
        ghostIconName.text = '${charData.name} [${charId}]';
      };
      charButton.onMouseOut = _ -> {
        ghostIconName.text = defaultText;
      };
      charGrid.addComponent(charButton);
    }

    ghostIconName.text = defaultText;

    this.alpha = 0;
    this.y -= 10;
    FlxTween.tween(this, {alpha: 1, y: this.y + 10}, 0.2, {ease: FlxEase.quartOut});
  }
}
