package funkin.ui.stageBuildShit;

import flixel.group.FlxGroup;

class StagetoolBar extends FlxGroup
{
  var icons:Array<StageBuilderState.TOOLS> = [SELECT, MOVE, GRAB, BOYFRIEND];
  var iconSprs:Array<String> = ['cursorSelect', 'cursorGrab', 'cursorMove', 'toolbarBF'];

  public function new()
  {
    super();

    for (icon in icons)
    {
      // switch (icon)
      // {
      // case SELECT:
      // }
    }
  }
}
