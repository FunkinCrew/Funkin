package funkin.ui.debug.mods.components;

import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.windows.Window;
#if sys
import sys.FileSystem;
#end

@:xml('
  <?xml version="1.0" encoding="utf-8"?>
  <window title="Files" width="275" height="275">
    <scrollview width="100%" height="100%" contentWidth="100%">
      <vbox width="100%">
        <tree-view id="modWindowFileTree" width="100%"/>
      </vbox>
    </scrollview>
  </window>
')
class ModDefaultFileViewer extends Window
{
  var rootNode:TreeViewNode;

  override public function new(path:String)
  {
    super();

    var pathObj = new haxe.io.Path(path);
    rootNode = modWindowFileTree.addNode({text: pathObj.file, icon: "haxeui-core/styles/shared/folder-light.png"});
    fillUpTreeView(rootNode, path);
  }

  function fillUpTreeView(parent:TreeViewNode, path:String)
  {
    #if sys
    for (item in FileSystem.readDirectory(path))
    {
      var fullPath = path + "/" + item;
      var pathObj = new haxe.io.Path(fullPath);
      var isFolder = FileSystem.isDirectory(fullPath);

      var newNode = parent.addNode(
        {
          text: pathObj.file + (isFolder ? "" : " (." + pathObj.ext + ")"),
          icon: isFolder ? "haxeui-core/styles/shared/folder-light.png" : null
        });

      if (isFolder)
      {
        fillUpTreeView(newNode, fullPath);
      }
    }
    #end
  }
}
