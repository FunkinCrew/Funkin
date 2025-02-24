package funkin.ui.debug.mods.components;

import funkin.util.WindowUtil;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.components.Spacer;
import haxe.ui.containers.windows.Window;
import polymod.Polymod.ModMetadata;

@:xml('
  <?xml version="1.0" encoding="utf-8"?>
  <window title="Contributors" width="275" height="275">
    <scrollview width="100%" height="100%" contentWidth="100%">
      <vbox id="modViewContributorList" />
    </scrollview>
  </window>
')
class ModContributorWindow extends Window
{
  override public function new(mod:ModMetadata)
  {
    super();

    // this assumes contributors list isnt null
    for (info in mod.contributors)
    {
      var nameLabel = new Label();
      nameLabel.text = info.name;
      nameLabel.styleString = "font-size: 18px; font-bold: true; font-underline: true;";

      modViewContributorList.addComponent(nameLabel);

      if (info.role != null)
      {
        var roleLabel = new Label();
        roleLabel.text = info.role;
        modViewContributorList.addComponent(roleLabel);
      }

      if (info.email != null)
      {
        var emailLabel = new Label();
        emailLabel.text = info.email;
        modViewContributorList.addComponent(emailLabel);
      }

      #if CAN_OPEN_LINKS
      if (info.url != null)
      {
        var urlLink = new Link();
        urlLink.text = "Visit URL";
        urlLink.onClick = function(_) WindowUtil.openURL(info.url);
        modViewContributorList.addComponent(urlLink);
      }
      #end

      var spacer = new Spacer();
      spacer.height = 25;
      modViewContributorList.addComponent(spacer);
    }
  }
}
