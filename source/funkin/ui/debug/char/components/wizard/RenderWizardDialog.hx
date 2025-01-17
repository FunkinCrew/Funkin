package funkin.ui.debug.char.components.wizard;

import funkin.data.character.CharacterData.CharacterRenderType;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/sprite-support.xml"))
class RenderWizardDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(SELECT_CHAR_TYPE);

    renderOptionSparrow.onChange = function(_) params.renderType = CharacterRenderType.Sparrow;
    renderOptionPacker.onChange = function(_) params.renderType = CharacterRenderType.Packer;
    renderOptionAtlas.onChange = function(_) params.renderType = CharacterRenderType.AnimateAtlas;
    renderOptionMulti.onChange = function(_) params.renderType = CharacterRenderType.MultiSparrow;
  }

  override public function showDialog(modal:Bool = true)
  {
    super.showDialog(modal);
    renderOptionSparrow.disabled = renderOptionPacker.disabled = renderOptionAtlas.disabled = renderOptionMulti.disabled = (!params.generateCharacter
      || params.importedCharacter != null);

    renderOptionSparrow.selected = params.renderType == CharacterRenderType.Sparrow;
    renderOptionPacker.selected = params.renderType == CharacterRenderType.Packer;
    renderOptionAtlas.selected = params.renderType == CharacterRenderType.AnimateAtlas;
    renderOptionMulti.selected = params.renderType == CharacterRenderType.MultiSparrow;
  }

  override public function isNextStepAvailable()
    return true;
}
