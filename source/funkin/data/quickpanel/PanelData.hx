package funkin.data.quickpanel;

typedef PanelData =
{
  @:default(funkin.data.quickpanel.PanelRegistry.PANEL_DATA_VERSION)
  var version:String;
  var text:String;
  var icon:String;
  @:default('') @:optional
  var description:String;
  @:default('none') @:optional
  var action:String;
  @:default('default') @:optional
  var panel:String;
  @:default(0) @:optional
  var order:Int;
  @:default(false) @:optional
  var disabled:Bool;
  @:default(true) @:optional
  var visible:Bool;
  @:default(true) @:optional
  var transitioning:Bool;
}
