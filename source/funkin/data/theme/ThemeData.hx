package funkin.data.theme;

typedef ThemeData =
{
  /**
   * Semantic version of the theme data.
   */
  public var version:String;

  /**
   * Readable name of the theme.
   */
  public var name:String;

  @:optional
  public var chart:ChartThemeData;

  @:optional
  public var stage:StageThemeData;
}

typedef ChartThemeData =
{
  var background:String;

  var gridColors:Array<String>;

  @:optional
  @:default("0xFF111111")
  var gridStrumlineDivider:String;

  @:optional
  @:default("0xFF111111")
  var gridMeasureDivider:String;

  @:optional
  @:default("0xFFC1C1C1")
  var gridBeatDivider:String;

  @:optional
  @:default("0xFF339933")
  var selectionSquareBorder:String;

  @:optional
  @:default("0x4033FF33")
  var selectionSquareFill:String;

  @:optional
  @:default("0xFFF8A657")
  var notePreviewViewportBorder:String;

  @:optional
  @:default("0x80F8A657")
  var notePreviewViewportFill:String;
}

typedef StageThemeData =
{
  var backgroundColors:Array<String>;
}
