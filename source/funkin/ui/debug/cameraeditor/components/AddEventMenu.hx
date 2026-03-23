package funkin.ui.debug.cameraeditor.components;

#if FEATURE_CAMERA_EDITOR
import funkin.data.event.SongEventRegistry;
import funkin.data.song.SongData.SongEventDataRaw;
import haxe.ui.components.Image;
import haxe.ui.containers.menus.Menu;
import haxe.ui.containers.menus.MenuItem;
import haxe.ui.containers.menus.MenuSeparator;
import haxe.ui.core.Screen;
import haxe.ui.events.MenuEvent;
import haxe.ui.backend.flixel.MouseHelper;
import haxe.ui.events.UIEvent;

class AddEventMenu
{
  static final MENU_WIDTH:Float = 150;
  static final ICON_SIZE:Float = 16;
  static final ICON_PATH:String = "shared:assets/shared/images/ui/camera-editor/event-icons/";

  static final EVENT_ITEMS:Array<{kind:String, label:String, icon:String}> = [
    {kind: "FocusCamera", label: "Focus Camera", icon: "focus_event.png"},
    {kind: "ZoomCamera", label: "Zoom Camera", icon: "zoom_event.png"},
  ];

  var menu:Null<Menu> = null;
  var onEventSelected:Null<SongEventDataRaw->Void>;

  public function new(onEventSelected:SongEventDataRaw->Void)
  {
    this.onEventSelected = onEventSelected;
  }

  public function show():Void
  {
    close();

    var screenX:Float = MouseHelper.currentWorldX;
    var screenY:Float = MouseHelper.currentWorldY;

    var header = new MenuItem();
    header.text = "Add Event";
    header.shortcutText = "Shift+A";
    header.disabled = true;

    var cameraSubmenu = new Menu();
    cameraSubmenu.text = "Camera";
    cameraSubmenu.width = MENU_WIDTH;

    for (info in EVENT_ITEMS)
    {
      var item = new MenuItem();
      item.text = info.label;
      item.id = info.kind;

      var icon = new Image();
      icon.id = "menuitem-icon";
      icon.addClass("menuitem-icon");
      icon.resource = ICON_PATH + info.icon;
      icon.width = ICON_SIZE;
      icon.height = ICON_SIZE;
      item.addComponentAt(icon, 0);

      cameraSubmenu.addComponent(item);
    }

    menu = new Menu();
    menu.width = MENU_WIDTH;
    menu.addComponent(header);
    menu.addComponent(new MenuSeparator());
    menu.addComponent(cameraSubmenu);

    menu.registerEvent(MenuEvent.MENU_SELECTED, onMenuSelected);
    menu.registerEvent(UIEvent.CLOSE, function(_) { menu = null; });

    menu.left = screenX;
    menu.top = screenY;
    Screen.instance.addComponent(menu);
  }

  public function close():Void
  {
    if (menu != null)
    {
      Screen.instance.removeComponent(menu);
      menu = null;
    }
  }

  public function isOpen():Bool
  {
    return menu != null;
  }

  function onMenuSelected(e:MenuEvent):Void
  {
    if (e.menuItem == null) return;

    var eventKind:String = e.menuItem.id;
    if (eventKind == null || eventKind == "") return;

    var eventData = createDefaultEvent(eventKind);
    if (onEventSelected != null)
      onEventSelected(eventData);

    menu = null;
  }

  static function createDefaultEvent(eventKind:String):SongEventDataRaw
  {
    var time:Float = Conductor.instance.songPosition;
    var schema = SongEventRegistry.getEventSchema(eventKind);

    if (schema == null)
      return new SongEventDataRaw(time, eventKind, {});

    var value:haxe.DynamicAccess<Dynamic> = {};
    for (fieldName in schema.listAllFieldNames())
    {
      var defaultVal = schema.getDefaultFieldValue(fieldName);
      if (defaultVal != null) value.set(fieldName, defaultVal);
    }

    return new SongEventDataRaw(time, eventKind, value);
  }
}
#end
