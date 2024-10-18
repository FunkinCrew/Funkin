package funkin.save.migrator;

// Internal enums used to ensure old save data can be parsed by the default Haxe unserializer.
// In the future, only primitive types and abstract enums should be used in save data!

@:native("funkin.ui.debug.stageeditor.StageEditorTheme")
enum StageEditorTheme
{
  Light;
  Dark;
}

@:native("funkin.ui.debug.charting.ChartEditorTheme")
enum ChartEditorTheme
{
  Light;
  Dark;
}

@:native("funkin.ui.debug.charting.ChartEditorLiveInputStyle")
enum ChartEditorLiveInputStyle
{
  None;
  NumberKeys;
  WASDKeys;
}
