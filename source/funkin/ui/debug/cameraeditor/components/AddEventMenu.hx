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
import haxe.ui.Toolkit;

/**
 * The dialog that appears when clicking the timeline, prompting the user to add an event.
 */
@:access(haxe.ui.core.Component)
class AddEventMenu
{
  static final MENU_WIDTH:Float = 150;
  static final ICON_SIZE:Float = 16;
  static final ICON_PATH:String = 'shared:assets/shared/images/ui/camera-editor/event-icons/';
  static final EVENT_ITEMS:Array<
    {kind:String, label:String, icon:String, submenu:String}> = [
    {
      kind: 'FocusCamera',
      label: 'Focus Camera',
      icon: 'focus_event.png',
      submenu: 'Camera'
    },
    {
      kind: 'ZoomCamera',
      label: 'Zoom Camera',
      icon: 'zoom_event.png',
      submenu: 'Camera'
    },
    {
      kind: 'PlayAnimation',
      label: 'Play Animation',
      icon: 'playanim_event.png',
      submenu: 'Character'
    },
  ];

  var menu:Null<Menu> = null;
  var onEventSelected:Null<SongEventDataRaw->Void>;

  public function new(onEventSelected:SongEventDataRaw->Void)
  {
    this.onEventSelected = onEventSelected;
  }

  /**
   * Show the dialog at the current mouse position.
   */
  public function show():Void
  {
    close();

    var screenX:Float = MouseHelper.currentWorldX;
    var screenY:Float = MouseHelper.currentWorldY;

    var header = new MenuItem();
    header.text = 'Add Event';
    header.shortcutText = 'Shift+A';
    header.disabled = true;

    var submenus:Map<String, Menu> = new Map();
    var submenuOrder:Array<String> = [];

    for (info in EVENT_ITEMS)
    {
      var submenu:Null<Menu> = submenus.get(info.submenu);
      if (submenu == null)
      {
        submenu = new Menu();
        submenu.text = info.submenu;
        submenu.width = MENU_WIDTH;
        submenus.set(info.submenu, submenu);
        submenuOrder.push(info.submenu);
      }

      var item = new MenuItem();
      item.text = info.label;
      item.id = info.kind;

      var icon = new Image();
      icon.id = 'menuitem-icon';
      icon.addClass('menuitem-icon');
      icon.resource = ICON_PATH + info.icon;
      icon.width = ICON_SIZE;
      icon.height = ICON_SIZE;
      item.addComponentAt(icon, 0);

      submenu.addComponent(item);
    }

    menu = new Menu();
    menu.width = MENU_WIDTH;
    menu.addComponent(header);
    menu.addComponent(new MenuSeparator());
    for (submenuName in submenuOrder)
    {
      menu.addComponent(submenus.get(submenuName));
    }

    menu.registerEvent(MenuEvent.MENU_SELECTED, onMenuSelected);
    menu.registerEvent(UIEvent.CLOSE, function(_) { menu = null; });

    // Hide before adding so we can measure without a visual flash
    menu.handleVisibility(false);
    menu.left = screenX;
    menu.top = screenY;
    Screen.instance.addComponent(menu);
    menu.validateNow();

    // Edge detection
    var menuW:Float = menu.actualComponentWidth;
    var menuH:Float = menu.actualComponentHeight;
    var scrW:Float = Screen.instance.width;
    var scrH:Float = Screen.instance.height;

    var left:Float = screenX;
    var top:Float = screenY;

    // Right edge: flip to left side of cursor
    if (left + menuW > scrW)
    {
      left = screenX - menuW;
    }

    // Bottom edge: clamp so menu bottom aligns with window bottom
    if (top + menuH > scrH)
    {
      top = scrH - menuH;
    }

    // Safety clamp to 0 if negative (e.g., menu larger than screen)
    if (left < 0) left = 0;
    if (top < 0) top = 0;

    menu.left = left;
    menu.top = top;

    // Reveal on next frame (matches showSubMenu pattern)
    var menuRef = menu;
    Toolkit.callLater(() ->
    {
      if (menuRef != null)
      {
        menuRef.handleVisibility(true);
      }
    });
  }

  /**
   * Close the dialog.
   */
  public function close():Void
  {
    if (menu != null)
    {
      Screen.instance.removeComponent(menu);
      menu = null;
    }
  }

  /**
   * @return Whether the dialog is currently open.
   */
  public function isOpen():Bool
  {
    return menu != null;
  }

  function onMenuSelected(e:MenuEvent):Void
  {
    if (e.menuItem == null) return;

    var eventKind:String = e.menuItem.id;
    if (eventKind == null || eventKind == '') return;

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
    {
      return new SongEventDataRaw(time, eventKind, {});
    }

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
