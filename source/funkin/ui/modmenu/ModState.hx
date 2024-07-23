package funkin.ui.modmenu;

import haxe.ui.backend.flixel.UIState;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.input.Cursor;
import flixel.FlxSprite;

/**
 * A state for enabling and reordering mods.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/main-view.xml"))
class ModState extends UIState // UIState derives from MusicBeatState
{
  var uiCamera:FunkinCamera;

  public function new()
  {
    super();

    addComponent(new funkin.ui.modmenu.components.ModBox("Cool Mod", "Cool Mod Description"));
  }

  override function create():Void
  {
    super.create();

    Cursor.show();

    uiCamera = new FunkinCamera('modMenuUI');
    FlxG.cameras.reset(uiCamera);

    this.root.zIndex = 100;

    var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    add(bg);
    bg.setGraphicSize(Std.int(bg.width * 1.1));
    bg.updateHitbox();
    bg.screenCenter();
    bg.scrollFactor.set(0, 0);
    bg.zIndex = -100;

    this.refresh();
  }
}
