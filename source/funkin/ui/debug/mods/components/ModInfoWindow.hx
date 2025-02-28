package funkin.ui.debug.mods.components;

import funkin.modding.PolymodHandler;
import funkin.util.WindowUtil;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.Image;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.components.Spacer;
import haxe.ui.containers.TreeViewNode;
import haxe.ui.containers.VBox;
import haxe.ui.containers.windows.WindowManager;
import polymod.Polymod.ModMetadata;
import thx.semver.VersionRule;
#if sys
import sys.FileSystem;
#end

@:access(funkin.ui.debug.mods.ModsSelectState)
@:build(haxe.ui.ComponentBuilder.build("assets/exclude/data/ui/mod-select/components/mod-info.xml"))
class ModInfoWindow extends VBox
{
  public var parentState:ModsSelectState;
  public var linkedMod:ModMetadata;

  public var modWindowIcon:Image;
  public var modWindowName:Label;
  public var modWindowVersion:Label;
  public var modWindowDependency:Label;
  public var modWindowOptional:Label;
  public var modWindowHomepage:Button;
  public var modWindowDesc:Label;
  public var modWindowDependencies:VBox;
  public var modWindowContributors:VBox;
  public var modWindowFiles:VBox;
  public var modWindowLicense:Label;

  override public function new(parentState:ModsSelectState, data:ModMetadata)
  {
    super();
    this.parentState = parentState;
    linkedMod = data;

    var img = openfl.display.BitmapData.fromBytes(data.icon);
    if (img != null) modWindowIcon.resource = new flixel.FlxSprite().loadGraphic(img).frames.frames[0]; // such a hacky thing I hate it

    modWindowName.text = data.title;
    modWindowDesc.text = data.description;
    modWindowVersion.text = "Mod Version: " + data.modVersion;
    modWindowLicense.text = "License: " + data.license;

    #if CAN_OPEN_LINKS
    modWindowHomepage.disabled = (data.homepage == "" || data.homepage == null);
    modWindowHomepage.onClick = function(_) WindowUtil.openURL(data.homepage);
    #else
    modWindowHomepage.disabled = true;
    #end

    // Dependencies.
    if (data.dependencies.keys().array().length > 0)
    {
      var nameLabel = new Label();
      nameLabel.text = "Required:";
      modWindowDependencies.addComponent(nameLabel);

      for (mod => version in data.dependencies)
      {
        var depLink = new Link();
        depLink.text = mod + " (" + version + ")";
        depLink.onClick = function(_) openDifferentMod(mod, version);
        modWindowDependencies.addComponent(depLink);
      }
    }

    if (data.optionalDependencies.keys().array().length > 0)
    {
      var nameLabel = new Label();
      nameLabel.text = "Optional:";
      modWindowDependencies.addComponent(nameLabel);

      for (mod => version in data.optionalDependencies)
      {
        var depLink = new Link();
        depLink.text = mod + " (" + version + ")";
        depLink.onClick = function(_) openDifferentMod(mod, version);
        modWindowDependencies.addComponent(depLink);
      }
    }

    // Contributors.
    for (info in data.contributors)
    {
      var nameLabel = new Label();
      nameLabel.text = info.name;
      nameLabel.styleString = "font-size: 18px; font-bold: true; font-underline: true;";
      modWindowContributors.addComponent(nameLabel);

      if (info.role != null)
      {
        var roleLabel = new Label();
        roleLabel.text = info.role;
        modWindowContributors.addComponent(roleLabel);
      }

      if (info.email != null)
      {
        var emailLabel = new Label();
        emailLabel.text = info.email;
        modWindowContributors.addComponent(emailLabel);
      }

      #if CAN_OPEN_LINKS
      if (info.url != null)
      {
        var urlLink = new Link();
        urlLink.text = "Visit URL";
        urlLink.onClick = function(_) WindowUtil.openURL(info.url);
        modWindowContributors.addComponent(urlLink);
      }
      #end

      var spacer = new Spacer();
      spacer.height = 25;
      modWindowContributors.addComponent(spacer);
    }

    // Files.
    var modPath:String = PolymodHandler.MOD_FOLDER + "/" + data.id;
    var pathObj:Path = new Path(modPath);
    var rootFileNode:TreeViewNode = modWindowFileTree.addNode({text: pathObj.file, icon: "haxeui-core/styles/shared/folder-light.png"});
    fillUpTreeView(rootFileNode, modPath);

    // Dependencies.
    var dependableChildren:Array<String> = [];
    var optionalChildren:Array<String> = [];

    for (childMod in parentState.listAllModsOrdered())
    {
      if (childMod.id == data.id) continue;
      for (dep => ver in childMod.dependencies)
      {
        if (dep == data.id
          && ver.isSatisfiedBy(data.modVersion)
          && !dependableChildren.contains(childMod.id)) dependableChildren.push(childMod.id);
      }
      for (dep => ver in childMod.optionalDependencies)
      {
        if (dep == data.id && ver.isSatisfiedBy(data.modVersion) && !optionalChildren.contains(childMod.id)) optionalChildren.push(childMod.id);
      }
    }

    if (dependableChildren.length != 0) modWindowDependency.text = "This Mod is a Dependency of: " + dependableChildren.join(", ");
    if (optionalChildren.length != 0) modWindowOptional.text = "This Mod is an Optional Dependency of: " + optionalChildren.join(", ");

    parentState.colorButtonLabels(data.dependencies.keys().array(), data.optionalDependencies.keys().array());
  }

  function openDifferentMod(mod:String, version:VersionRule)
  {
    parentState.cleanupBeforeSwitch();

    for (button in parentState.modListUnloadedBox.childComponents.concat(parentState.modListLoadedBox.childComponents))
    {
      if (Std.isOfType(button, ModButton))
      {
        var realButton:ModButton = cast button;
        if (realButton.linkedMod.id == mod && version.isSatisfiedBy(realButton.linkedMod.modVersion))
        {
          realButton.styleNames = "modBoxSelected";

          var infoWindow = new ModInfoWindow(parentState, realButton.linkedMod);
          parentState.windowContainer.addComponent(infoWindow);
          break;
        }
      }
    }
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
      else
      {
        newNode.onDblClick = function(_) {
          switch (pathObj.ext)
          {
            case "txt" | "json" | "xml" | "hx" | "hxc" | "hscript" | "hxs":
              WindowManager.instance.addWindow(new ModTxtFileViewer(sys.io.File.getContent(fullPath)));

            case "png" | "jpg" | "jpeg":
              var bitmap = openfl.display.BitmapData.fromFile(fullPath);
              var graphic = flixel.graphics.FlxGraphic.fromBitmapData(bitmap, false, fullPath);

              WindowManager.instance.addWindow(new ModImageFileViewer(graphic.imageFrame.frame));
          }
        }
      }
    }
    #end
  }
}
