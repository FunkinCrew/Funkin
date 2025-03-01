package funkin.ui.debug.char.components.wizard;

import haxe.io.Path;
import haxe.ui.containers.HBox;
import haxe.ui.containers.dialogs.Dialogs.FileDialogExtensionInfo;
import haxe.ui.components.Button;
import haxe.ui.components.TextField;
import funkin.ui.debug.char.handlers.CharCreatorStartupWizard;
import funkin.util.FileUtil;
import flxanimate.data.AnimationData.AnimAtlas;
import flxanimate.data.SpriteMapData.AnimateAtlas;
import funkin.data.character.CharacterData.CharacterRenderType;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.FlxSprite;
import openfl.display.BitmapData;
import openfl.net.FileFilter;

using StringTools;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/wizard/add-assets.xml"))
class AddCharFilesDialog extends DefaultWizardDialog
{
  override public function new()
  {
    super(UPLOAD_ASSETS);
  }

  var stupidFuckingRenderCheck:String = "";

  override public function showDialog(modal:Bool = true):Void
  {
    super.showDialog(modal);

    addAssetsBox.disabled = (!params.generateCharacter || params.importedCharacter != null);
    if (stupidFuckingRenderCheck == params.renderType) return;

    while (addAssetsBox.childComponents.length > 0)
      addAssetsBox.removeComponent(addAssetsBox.childComponents[0]);

    switch (params.renderType)
    {
      case CharacterRenderType.Sparrow:
        addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Spritesheet Image here.", FileUtil.FILE_EXTENSION_INFO_PNG));

      case CharacterRenderType.MultiSparrow:
        addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Spritesheet Image here.", FileUtil.FILE_EXTENSION_INFO_PNG));
        addAssetsBox.addComponent(new AddAssetBox());

      case CharacterRenderType.Packer:
        addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Spritesheet Image here.", FileUtil.FILE_EXTENSION_INFO_PNG));

      case CharacterRenderType.AnimateAtlas:
        addAssetsBox.addComponent(new UploadAssetsBox("Put the path to the Atlas .zip Data Here", FileUtil.FILE_EXTENSION_INFO_ZIP));

      default:
        // this should never happen, right?
    }

    stupidFuckingRenderCheck = params.renderType;
  }

  override public function isNextStepAvailable():Bool
  {
    params.files = [];

    // we skippin if we aint even doin these
    if (addAssetsBox.disabled) return true;

    var uploadBoxes:Array<UploadAssetsBox> = [];
    for (unsafeBox in addAssetsBox.childComponents)
    {
      if (!Std.isOfType(unsafeBox, UploadAssetsBox))
      {
        continue;
      }
      var box:UploadAssetsBox = cast unsafeBox;
      if (box.daField.text == null || box.daField.text.length == 0)
      {
        continue;
      }
      uploadBoxes.push(box);
    }

    if (uploadBoxes.length == 0)
    {
      CharCreatorUtil.error("Add Files", "Please fill out at least one field.");
      return false;
    }

    // check if the files even exist
    for (thingy in uploadBoxes)
    {
      if (!FileUtil.doesFileExist(thingy.daField.text) && !openfl.Assets.exists(thingy.daField.text))
      {
        CharCreatorUtil.error("Add Files", "Path: " + thingy.daField.text + " doesn't exist. Is the spelling correct?");
        return false;
      }
    }

    // we do a little trollin
    return typeCheck(uploadBoxes);
  }

  public function typeCheck(uploadBoxes:Array<UploadAssetsBox>):Bool
  {
    switch (params.renderType)
    {
      case CharacterRenderType.Sparrow | CharacterRenderType.MultiSparrow:
        var files = [];
        for (uploadBox in uploadBoxes)
        {
          var imgPath = uploadBox.daField.text;
          var xmlPath = uploadBox.daField.text.replace(".png", ".xml");

          // checking if we even have the correct file types in the correct places
          if (Path.extension(imgPath) != "png" || Path.extension(xmlPath) != "xml")
          {
            CharCreatorUtil.error("Add Files", "The provided Path doesn't end with the supported format, (.png).");
            return false;
          }

          // testing if we could actually use these
          var imgBytes = CharCreatorUtil.gimmeTheBytes(imgPath);
          var xmlBytes = CharCreatorUtil.gimmeTheBytes(xmlPath);
          if (imgBytes == null || xmlBytes == null)
          {
            CharCreatorUtil.error("Add Files", "Error retrieving Bytes from the given Path.");
            return false;
          }

          var tempSprite = new FlxSprite();
          try
          {
            var bitmap = BitmapData.fromBytes(imgBytes);
            tempSprite.frames = FlxAtlasFrames.fromSparrow(bitmap, xmlBytes.toString());

            if (tempSprite.frames == null) throw "";
          }
          catch (e)
          {
            CharCreatorUtil.error("Add Files", "The provided Bytes cannot be used to make Character Frames.");
            tempSprite.destroy();
            return false;
          }

          tempSprite.destroy(); // fuck this guy i hate him
          files = files.concat([
            {
              name: imgPath,
              bytes: imgBytes
            },
            {
              name: xmlPath,
              bytes: xmlBytes
            }
          ]);
        }
        params.files = files;

        return true;

      case CharacterRenderType.Packer: // essentially just sparrow...but different!
        var imgPath = uploadBoxes[0].daField.text;
        var txtPath = uploadBoxes[0].daField.text.replace(".png", ".txt");

        // checking if we even have the correct file types in the correct places
        if (Path.extension(imgPath) != "png" || Path.extension(txtPath) != "txt")
        {
          CharCreatorUtil.error("Add Files", "The provided Path doesn't end with the supported format, (.png).");
          return false;
        }

        // testing if we could actually use these
        var imgBytes = CharCreatorUtil.gimmeTheBytes(imgPath);
        var txtBytes = CharCreatorUtil.gimmeTheBytes(txtPath);
        if (imgBytes == null || txtBytes == null)
        {
          CharCreatorUtil.error("Add Files", "Error retrieving Bytes from the given Path.");
          return false;
        }

        var tempSprite = new FlxSprite();
        try
        {
          var bitmap = BitmapData.fromBytes(imgBytes);
          tempSprite.frames = FlxAtlasFrames.fromSpriteSheetPacker(bitmap, txtBytes.toString());

          if (tempSprite.frames == null) throw "";
        }
        catch (e)
        {
          CharCreatorUtil.error("Add Files", "The provided Bytes cannot be used to make Character Frames.");
          tempSprite.destroy();
          return false;
        }
        tempSprite.destroy();

        params.files = [
          {name: imgPath, bytes: imgBytes}, {name: txtPath, bytes: txtBytes}];

        return true;

      case CharacterRenderType.AnimateAtlas:
        var zipPath = uploadBoxes[0].daField.text;

        // checking if we even have the correct file types in the correct places
        if (Path.extension(zipPath) != "zip")
        {
          CharCreatorUtil.error("Add Files", "The provided Path doesn't end with the supported format, (.zip).");
          return false;
        }

        var zipBytes = CharCreatorUtil.gimmeTheBytes(zipPath);
        if (zipBytes == null)
        {
          CharCreatorUtil.error("Add Files", "Error retrieving Bytes from the given Path.");
          return false;
        }

        var zipFiles = FileUtil.readZIPFromBytes(zipBytes);
        if (zipFiles.length == 0)
        {
          CharCreatorUtil.error("Add Files", "The provided .zip file has no content.");
          return false;
        }

        params.files = [];
        var hasAnimData:Bool = false;
        var hasSpritemapData:Bool = false;
        var hasImageData:Bool = false;

        for (entry in zipFiles)
        {
          if (entry.fileName.indexOf("/") != -1) entry.fileName = Path.withoutDirectory(entry.fileName);

          if (entry.fileName.endsWith("Animation.json"))
          {
            var fileData = entry.data.toString();
            var animData:AnimAtlas = haxe.Json.parse(CharCreatorUtil.normalizeJSONText(fileData));
            if (animData == null)
            {
              CharCreatorUtil.error("Add Files", "Error parsing the Animation.json File.");
              return false;
            }

            hasAnimData = true;
          }

          if (entry.fileName.startsWith("spritemap") && entry.fileName.endsWith(".json"))
          {
            var fileData = entry.data.toString();
            var spritemapData:AnimateAtlas = haxe.Json.parse(CharCreatorUtil.normalizeJSONText(fileData));
            if (spritemapData == null)
            {
              CharCreatorUtil.error("Add Files", "Error parsing the Spritemap.json File.");
              return false;
            }

            hasSpritemapData = true;
          }

          if (entry.fileName.startsWith("spritemap") && entry.fileName.endsWith(".png"))
          {
            if (BitmapData.fromBytes(entry.data) == null)
            {
              CharCreatorUtil.error("Add Files", "Error parsing the Spritemap.png File.");
              return false;
            }
            hasImageData = true;
          }
        }

        if (hasAnimData && hasSpritemapData && hasImageData) params.files.push({name: zipPath, bytes: zipBytes});

        if (!(hasAnimData && hasSpritemapData && hasImageData))
        {
          CharCreatorUtil.error("Add Files", "Insufficient amount of Files in the .zip File.");
          return false;
        }

        return true;
      default:
        return false;
    }

    return false;
  }
}

class AddAssetBox extends HBox
{
  override public function new()
  {
    super();

    styleString = "border:1px solid $normal-border-color";
    percentWidth = 100;
    height = 25;
    verticalAlign = "center";

    var addButton = new Button();
    addButton.text = "Add New Box";
    var removeButton = new Button();
    removeButton.text = "Remove Last Box";

    addButton.percentWidth = removeButton.percentWidth = 50;
    addButton.percentHeight = removeButton.percentHeight = 100;

    addButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      var first = parentList.childComponents[0];
      if (!Std.isOfType(first, UploadAssetsBox)) return;

      var firstBox:UploadAssetsBox = cast first;

      var newBox = new UploadAssetsBox(firstBox.daField.placeholder, firstBox.lookFor);
      parentList.addComponentAt(newBox, parentList.childComponents.length - 1); // considering this box is last
      removeButton.disabled = false;
    }

    removeButton.disabled = true;
    removeButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      parentList.removeComponentAt(parentList.childComponents.length - 2);
      if (parentList.childComponents.length <= 2) removeButton.disabled = true;
    }

    addComponent(addButton);
    addComponent(removeButton);
  }
}

class UploadAssetsBox extends HBox
{
  public var daField:TextField;
  public var lookFor:FileDialogExtensionInfo = null;

  override public function new(title:String = "", lookFor:FileDialogExtensionInfo = null)
  {
    super();
    this.lookFor = lookFor;

    styleString = "border:1px solid $normal-border-color";
    percentWidth = 100;
    height = 25;
    verticalAlign = "center";

    daField = new TextField();
    daField.placeholder = title;
    daField.height = this.height;
    daField.percentWidth = 75;
    addComponent(daField);

    var daButton = new Button();
    daButton.text = "Load File";
    daButton.height = this.height;
    daButton.percentWidth = 100 - daField.percentWidth;
    addComponent(daButton);

    daButton.onClick = function(_) {
      FileUtil.browseForBinaryFile("Load File", [lookFor], function(_) {
        if (_?.fullPath != null) daField.text = _.fullPath;
      });
    }
  }
}
