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
  @:optional
  var buttonAnim:PanelButtonAnim;
}

typedef PanelButtonAnim =
{
  var animType:ButtonAnimType;
  var idleName:String;
  var idlePrefix:String;
  var acceptName:String;
  var acceptPrefix:String;
}

enum abstract ButtonAnimType(String) from String to String
{
  var ANIMATE_ATLAS:String = 'animate';
  var SPARROW_ATLAS:String = 'sparrow';
  var NONE:String = 'none';
}
