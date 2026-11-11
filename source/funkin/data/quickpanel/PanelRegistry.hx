package funkin.data.quickpanel;

import funkin.assets.Assets.AssetType;
import funkin.assets.Paths.AssetPath;
import funkin.data.DefaultRegistryImpl;
import funkin.ui.quickpanel.PanelEntry;
import funkin.ui.quickpanel.QuickPanelTypes.QuickPanelButtonData;
import funkin.util.SortUtil;
import funkin.util.tools.ISingleton;

@:nullSafety
class PanelRegistry extends BaseRegistry<PanelEntry, PanelData, PanelEntryParams> implements ISingleton implements DefaultRegistryImpl
{
  public static final PANEL_DATA_VERSION:thx.semver.Version = '1.0.0';
  public static final PANEL_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super({
      registryId: 'QUICKPANEL',
      dataFilePath: 'ui/quick-panel/buttons/',
      nestedEntries: false,
      versionRule: PANEL_DATA_VERSION_RULE
    });
  }

  public function listBaseGameEntryIds():Array<String>
  {
    return [
      'exit-mod',
      'mods',
      'freeplay',
      'online',
      'options'
    ];
  }

  public function listPanelEntries(panel:String):Array<PanelEntry>
  {
    var result:Array<PanelEntry> = [];

    for (id in listEntryIds())
    {
      var entry:Null<PanelEntry> = fetchEntry(id);
      if (entry == null || !entry.isVisible() || entry.getPanel() != panel) continue;
      result.push(entry);
    }

    var baseIds:Array<String> = listBaseGameEntryIds();
    result.sort((a, b) ->
    {
      if (a.getOrder() != b.getOrder()) return a.getOrder() - b.getOrder();
      return SortUtil.defaultsThenAlphabetically(baseIds, a.id, b.id);
    });

    return result;
  }

  public function listButtonData(panel:String):Array<QuickPanelButtonData>
  {
    return listPanelEntries(panel).map(entry -> entry.toButtonData());
  }

  /**
   * TODO
   */
  public function queryPanelAssets(type:AssetType, panel:String):Array<AssetPath>
  {
    var results:Array<AssetPath> = [];
    for (entry in listPanelEntries(panel)) results.append(PanelEntry.queryAssets(type, entry.id));
    return results;
  }
}

typedef PanelEntryParams =
{
}
