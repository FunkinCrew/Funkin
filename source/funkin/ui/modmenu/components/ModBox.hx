package funkin.ui.modmenu.components;

import haxe.ui.containers.dialogs.Dialog;

@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/components/mod.xml"))
class ModBox extends Dialog
{
  public function new(name:String, desc:String)
  {
    super();

    this.dialogTitleLabel.value = name;
    this.modLabel.value = desc;
  }
}
