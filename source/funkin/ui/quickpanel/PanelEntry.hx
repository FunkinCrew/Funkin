package funkin.ui.quickpanel;

import funkin.assets.Assets.AssetType;
import funkin.assets.Paths;
import funkin.assets.Paths.AssetPath;
import funkin.data.IRegistryEntry;
import funkin.data.quickpanel.PanelData;
import funkin.data.quickpanel.PanelData.PanelButtonAnim;
import funkin.data.quickpanel.PanelRegistry;
import funkin.data.quickpanel.PanelRegistry.PanelEntryParams;
import funkin.ui.quickpanel.QuickPanelTypes.QuickPanelButtonData;

@:nullSafety
class PanelEntry implements IRegistryEntry<PanelData>
{
  public static final DEFAULT_ANIM_DATA:PanelButtonAnim = {
    animType: NONE,
    idleName: '',
    idlePrefix: '',
    acceptName: '',
    acceptPrefix: ''
  };

  public function new(id:String, ?params:Dynamic)
  {
    this.id = id;
    _data = _fetchData(id);

    if (_data == null)
    {
      throw 'Could not parse quick panel button data for id: $id';
    }
  }

  public static function queryAssets(type:AssetType, entryId:String, ?params:PanelEntryParams):Array<AssetPath>
  {
    final entry:Null<PanelEntry> = PanelRegistry.instance.fetchEntry(entryId);
    if (entry == null) return [];

    switch (type)
    {
      case IMAGE:
        return [Paths.image('ui/quick-panel/icons/${entry.getIcon()}')];
      default:
        return [];
    }
  }

  public function getText():String
  {
    return _data?.text ?? 'NO TEXT';
  }

  public function getIcon():String
  {
    return _data?.icon ?? '';
  }

  public function getDescription():String
  {
    return _data?.description ?? '';
  }

  public function getAction():String
  {
    return _data?.action ?? 'none';
  }

  public function getPanel():String
  {
    return _data?.panel ?? QuickPanelState.DEFAULT_PANEL_ID;
  }

  public function getOrder():Int
  {
    return _data?.order ?? 0;
  }

  public function isDisabled():Bool
  {
    return (_data?.disabled ?? false) || !PanelActions.exists(getAction());
  }

  public function isVisible():Bool
  {
    return _data?.visible ?? true;
  }

  public function isTransitioning():Bool
  {
    return _data?.transitioning ?? true;
  }

  public function getPanelAnim():PanelButtonAnim
  {
    return _data?.buttonAnim ?? DEFAULT_ANIM_DATA;
  }

  public function onAccept():Void
  {
    PanelActions.run(getAction());
  }

  public function onSelect():Void
  {
  }

  public function onUnSelect():Void
  {
  }

  /**
   * TODO: Probably just use panelData instead
   */
  public function toButtonData():QuickPanelButtonData
  {
    return {
      id: id,
      text: getText(),
      icon: getIcon(),
      description: getDescription(),
      disabled: isDisabled(),
      callback: onAccept,
      callbackSelect: onSelect,
      callbackUnselect: onUnSelect,
      transitioning: isTransitioning(),
      buttonAnim: getPanelAnim()
    };
  }
}
