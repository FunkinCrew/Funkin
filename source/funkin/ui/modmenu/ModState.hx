package funkin.ui.modmenu;

import funkin.ui.modmenu.components.ModBox;
import funkin.graphics.FunkinCamera;
import funkin.graphics.FunkinSprite;
import funkin.audio.FunkinSound;
import funkin.input.Cursor;
import haxe.ui.backend.flixel.UIState;
import haxe.ui.containers.VBox;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.FlxG;
import flixel.FlxSprite;

/**
 * A state for enabling and reordering mods.
 */
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-menu/main-view.xml"))
class ModState extends UIState // UIState derives from MusicBeatState
{
  var uiCamera:FunkinCamera;
  var mods:Array<ModBox>;

  var disabledModsBox:VBox;
  var enabledModsBox:VBox;

  public function new()
  {
    super();

    mods = [];

    addMod("Cool Mod", "Cool Mod Description");
  }

  override function create():Void
  {
    super.create();

    Cursor.show();

    uiCamera = new FunkinCamera('modMenuUI');
    FlxG.cameras.reset(uiCamera);

    // this.root.zIndex = 100;

    // var bg:FlxSprite = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
    // add(bg);
    // bg.setGraphicSize(Std.int(bg.width * 1.1));
    // bg.updateHitbox();
    // bg.screenCenter();
    // bg.scrollFactor.set(0, 0);
    // bg.zIndex = -100;

    // this.refresh();
  }

  override function update(elapsed:Float):Void
  {
    super.update(elapsed);

    handleCursor();
  }

  function addMod(name:String, desc:String):Void
  {
    var mod:ModBox = new ModBox(name, desc);

    // mod.onDragStart = function(_) {
    //   disabledModsBox.removeComponent(mod);
    //   this.root.addComponent(mod);
    // };

    // mod.onDragEnd = function(_) {
    //   this.root.removeComponent(mod);
    //   disabledModsBox.addComponent(mod);
    // };

    mods.push(mod);
    disabledModsBox.addComponent(mod);
  }

  function handleCursor():Void
  {
    if (FlxG.mouse.justPressed) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickDown"));
    if (FlxG.mouse.justReleased) FunkinSound.playOnce(Paths.sound("chartingSounds/ClickUp"));
  }
}
