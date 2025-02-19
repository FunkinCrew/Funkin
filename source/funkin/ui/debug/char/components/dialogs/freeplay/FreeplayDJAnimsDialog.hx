package funkin.ui.debug.char.components.dialogs.freeplay;

import funkin.data.animation.AnimationData;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/freeplay/dj-anims-dialog.xml"))
@:access(funkin.ui.debug.char.pages.CharCreatorFreeplayPage)
class FreeplayDJAnimsDialog extends DefaultPageDialog
{
  override public function new(daPage:CharCreatorFreeplayPage)
  {
    super(daPage);

    djAnimList.onChange = function(_) {
      daPage.changeDJAnimation(djAnimList.selectedIndex - daPage.currentDJAnimation);
    }

    djAnimSave.onClick = function(_) {
      if (!daPage.dj.hasAnimation(djAnimPrefix.text))
      {
        return;
      }

      if ((djAnimList.safeSelectedItem?.text ?? "") == djAnimName.text) // update instead of add
      {
        var animData = daPage.djAnims[daPage.currentDJAnimation];

        animData.prefix = djAnimPrefix.text;
        animData.looped = djAnimLooped.selected;
        animData.offsets = [djAnimOffsetX.pos, djAnimOffsetY.pos];

        daPage.changeDJAnimation();
      }
      else
      {
        daPage.djAnims.push(
          {
            name: djAnimName.text,
            prefix: djAnimPrefix.text,
            looped: djAnimLooped.selected,
            offsets: [djAnimOffsetX.pos, djAnimOffsetY.pos]
          });

        djAnimList.dataSource.add({text: djAnimName.text});
        djAnimList.selectedIndex = daPage.djAnims.length - 1;
        daPage.changeDJAnimation(djAnimList.selectedIndex - daPage.currentDJAnimation);
      }
    }
  }
}
