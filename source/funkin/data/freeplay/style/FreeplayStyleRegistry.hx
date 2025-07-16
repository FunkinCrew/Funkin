package funkin.data.freeplay.style;

import funkin.ui.freeplay.FreeplayStyle;
import funkin.data.freeplay.style.FreeplayStyleData;
import funkin.ui.freeplay.ScriptedFreeplayStyle;
import funkin.util.tools.ISingleton;
import funkin.data.DefaultRegistryImpl;

@:nullSafety
class FreeplayStyleRegistry extends BaseRegistry<FreeplayStyle, FreeplayStyleData> implements ISingleton implements DefaultRegistryImpl
{
  /**
   * The current version string for the style data format.
   * Handle breaking changes by incrementing this value
   * and adding migration to the `migrateStyleData()` function.
   */
  public static final FREEPLAYSTYLE_DATA_VERSION:thx.semver.Version = '1.0.0';

  public static final FREEPLAYSTYLE_DATA_VERSION_RULE:thx.semver.VersionRule = '1.0.x';

  public function new()
  {
    super('FREEPLAYSTYLE', 'ui/freeplay/styles', FREEPLAYSTYLE_DATA_VERSION_RULE);
  }
}
