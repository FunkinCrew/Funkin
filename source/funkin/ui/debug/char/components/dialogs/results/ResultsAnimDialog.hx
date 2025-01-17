package funkin.ui.debug.char.components.dialogs.results;

import haxe.ui.containers.VBox;
import haxe.ui.containers.HBox;
import haxe.ui.components.Button;
import haxe.ui.events.UIEvent;
import funkin.data.freeplay.player.PlayerData;
import funkin.data.freeplay.player.PlayerRegistry;
import funkin.play.scoring.Scoring.ScoringRank;
import funkin.graphics.adobeanimate.FlxAtlasSprite;
import funkin.ui.debug.char.animate.CharSelectAtlasSprite;
import funkin.graphics.FunkinSprite;
import funkin.ui.debug.char.pages.CharCreatorResultsPage;
import funkin.util.FileUtil;
import flixel.FlxSprite;
import haxe.io.Path;

@:build(haxe.ui.macros.ComponentMacros.build("assets/exclude/data/ui/char-creator/dialogs/results/results-anim-dialog.xml"))
@:access(funkin.ui.debug.char.pages.CharCreatorResultsPage)
class ResultsAnimDialog extends DefaultPageDialog
{
  public var currentRank(get, never):ScoringRank;

  public var rankAnimationDataMap:Map<ScoringRank, Array<PlayerResultsAnimationData>> = [];
  public var rankAnimationFiles:Map<ScoringRank, Array<Array<WizardFile>>> = [];
  public var previousRank:ScoringRank;

  var rankAnimationBox:AddRankAnimationDataBox;

  override public function new(daPage:CharCreatorResultsPage)
  {
    super(daPage);

    var charId = daPage.data.importedPlayerData ?? "";
    var currentChar = PlayerRegistry.instance.fetchEntry(charId);
    for (rank in CharCreatorResultsPage.ALL_RANKS)
    {
      var playerAnimations = currentChar?.getResultsAnimationDatas(rank) ?? [];
      rankAnimationDataMap.set(rank, playerAnimations);
      rankAnimationFiles.set(rank, [for (bs in playerAnimations) []]);
    }

    rankAnimationBox = new AddRankAnimationDataBox(this);
    rankAnimationView.addComponent(rankAnimationBox);

    rankDropdown.selectedIndex = 0;
    rankDropdown.onChange = function(_) {
      if (previousRank == currentRank) return;

      changeRankPreview();
      daPage.playAnimation();
    }

    rankAnimationBox.useAnimationData(rankAnimationDataMap[currentRank]);
    previousRank = currentRank;
  }

  public function changeRankPreview():Void
  {
    var resultsPage:CharCreatorResultsPage = cast page;
    resultsPage.generateSpritesByData(rankAnimationDataMap[currentRank]);

    rankAnimationBox.useAnimationData(rankAnimationDataMap[currentRank]);
    previousRank = currentRank;
  }

  function get_currentRank():ScoringRank
  {
    if (rankDropdown.safeSelectedItem == null) return PERFECT_GOLD;

    switch (rankDropdown.safeSelectedItem.text)
    {
      case "Perfect Gold":
        return PERFECT_GOLD;
      case "Perfect":
        return PERFECT;
      case "Excellent":
        return EXCELLENT;
      case "Great":
        return GREAT;
      case "Good":
        return GOOD;
      case "Shit":
        return SHIT;
    }

    return PERFECT_GOLD;
  }
}

private class AddRankAnimationDataBox extends HBox
{
  var addButton:Button;
  var removeButton:Button;

  var page:CharCreatorResultsPage;
  var dialog:ResultsAnimDialog;

  public function new(daDialog:ResultsAnimDialog)
  {
    super();
    page = cast(daDialog.page, CharCreatorResultsPage);
    dialog = daDialog;

    styleString = "border:1px solid $normal-border-color";
    percentWidth = 100;
    height = 25;
    verticalAlign = "center";

    addButton = new Button();
    addButton.text = "Add New Box";
    removeButton = new Button();
    removeButton.text = "Remove Last Box";

    addButton.percentWidth = removeButton.percentWidth = 50;
    addButton.percentHeight = removeButton.percentHeight = 100;

    addButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      var newBox = createNewBox();
      daDialog.rankAnimationDataMap[daDialog.previousRank].push(newBox.animData);
      daDialog.rankAnimationFiles[daDialog.previousRank].push([]);

      parentList.addComponentAt(newBox, parentList.childComponents.length - 1); // considering this box is last
      removeButton.disabled = false;
    }

    removeButton.disabled = true;
    removeButton.onClick = function(_) {
      var parentList = this.parentComponent;
      if (parentList == null) return;

      parentList.removeComponentAt(parentList.childComponents.length - 2);

      var daData = page.currentAnims.pop();
      var daDataSprite = cast(daData.sprite, FlxSprite);

      daDataSprite.kill();
      page.remove(daDataSprite, true);
      daDataSprite.destroy();

      daDialog.rankAnimationDataMap[daDialog.previousRank].pop();
      daDialog.rankAnimationFiles[daDialog.previousRank].pop();

      if (parentList.childComponents.length < 2) removeButton.disabled = true;
    }

    addComponent(addButton);
    addComponent(removeButton);
  }

  public function useAnimationData(playerAnimations:Array<PlayerResultsAnimationData>):Void
  {
    var parentList = this.parentComponent;
    if (parentList == null) return;

    clearAnimationData();

    for (animData in playerAnimations)
    {
      parentList.addComponentAt(createNewBox(animData), parentList.childComponents.length - 1);
    }

    removeButton.disabled = parentList.childComponents.length < 2;
  }

  function clearAnimationData():Void
  {
    var parentList = this.parentComponent;
    if (parentList == null) return;

    while (parentList.childComponents.length > 1)
      parentList.removeComponentAt(parentList.childComponents.length - 2);
  }

  function createNewBox(?data:PlayerResultsAnimationData)
  {
    var newBox = new RankAnimationData(data);

    var parentList = this.parentComponent;
    if (parentList == null) return newBox;

    newBox.ID = parentList.childComponents.length - 1;
    if (page.currentAnims.length <= newBox.ID)
    {
      page.currentAnims.push(
        {
          sprite: null,
          delay: newBox.animData.delay
        });
    }

    newBox.pauseEvent(UIEvent.CHANGE, true);

    newBox.onOffsetsChange = function() {
      var obj = page.currentAnims[newBox.ID];
      if (obj?.sprite == null) return;
      cast(obj.sprite, FlxSprite).setPosition(newBox.animOffsetX.pos, newBox.animOffsetY.pos);
      copyData(data, newBox.animData);
    }

    newBox.animZIndex.onChange = function(_) {
      var obj = page.currentAnims[newBox.ID];
      if (obj?.sprite == null) return;

      cast(obj.sprite, FlxSprite).zIndex = Std.int(newBox.animZIndex.pos);
      page.refresh();
      copyData(data, newBox.animData);
    }

    newBox.animScale.onChange = function(_) {
      var obj = page.currentAnims[newBox.ID];
      if (obj?.sprite == null) return;
      cast(obj.sprite, FlxSprite).scale.set(newBox.animScale.pos, newBox.animScale.pos);
      copyData(data, newBox.animData);
    }

    newBox.onAssetChange = function() reloadSpriteFromBox(newBox);

    newBox.onLoopDataChange = function() {
      var obj = page.currentAnims[newBox.ID];
      if (obj?.sprite == null) return;

      var atlas = (Std.isOfType(obj.sprite, CharSelectAtlasSprite) ? cast(obj.sprite, CharSelectAtlasSprite) : null);
      var sparrow = (Std.isOfType(obj.sprite, FunkinSprite) ? cast(obj.sprite, FunkinSprite) : null);

      if (sparrow != null)
      {
        sparrow.animation.finishCallback = (_name:String) -> {
          if (animation != null)
          {
            sparrow.animation.play('idle', true, false, newBox.animData.loopFrame ?? 0);
          }
        }
      }
      else if (atlas != null)
      {
        atlas.onAnimationFrame.removeAll();
        atlas.onAnimationComplete.removeAll();

        if (!(newBox.animData.looped ?? true))
        {
          atlas.onAnimationComplete.add((_name:String) -> {
            if (atlas != null) atlas.anim.pause();
          });
        }
        else if (newBox.animData.loopFrameLabel != null)
        {
          atlas.onAnimationComplete.add((_name:String) -> {
            if (atlas != null) atlas.playAnimation(newBox.animData.loopFrameLabel ?? '', true, false, true); // unpauses this anim, since it's on PlayOnce!
          });
        }
        else if (newBox.animData.loopFrame != null)
        {
          atlas.onAnimationComplete.add((_name:String) -> {
            if (atlas != null)
            {
              atlas.anim.curFrame = newBox.animData.loopFrame ?? 0;
              atlas.anim.play(); // unpauses this anim, since it's on PlayOnce!
            }
          });
        }
      }

      copyData(data, newBox.animData);
    }

    newBox.resumeEvent(UIEvent.CHANGE, true, true);

    return newBox;
  }

  function reloadSpriteFromBox(box:RankAnimationData)
  {
    var obj = page.currentAnims[box.ID];
    if (obj?.sprite == null) return;

    page.setStatusOfEverything(false);

    var animPath:String = Paths.stripLibrary(box.animData.assetPath);
    var animLibrary:String = Paths.getLibrary(box.animData.assetPath);

    var isAbsolute:Bool = Path.isAbsolute(box.animData.assetPath);
    var newObj:Dynamic = null;
    var wizFiles:Array<WizardFile> = [];

    if (box.animData.renderType == "animateatlas")
    {
      newObj = new CharSelectAtlasSprite(0, 0, null, null);

      if (isAbsolute)
      {
        if (Path.extension(box.animData.assetPath) != "zip") return;

        wizFiles.push({name: box.animData.assetPath, bytes: FileUtil.readBytesFromPath(box.animData.assetPath)});
        newObj.loadFromZip(wizFiles[0].bytes);
      }
      else
      {
        newObj.loadAtlas(Paths.animateAtlas(animPath, animLibrary));
      }

      if (newObj.anim == null || newObj.frames == null) return;

      newObj.initSymbols();
    }
    else
    {
      newObj = new FunkinSprite(0, 0);

      if (isAbsolute)
      {
        if (Path.extension(box.animData.assetPath) != "png") return;

        var bitBytes = FileUtil.readBytesFromPath(box.animData.assetPath);
        var datBytes = FileUtil.readBytesFromPath(box.animData.assetPath.replace(".png", ".xml"));

        var bitmap = openfl.display.BitmapData.fromBytes(bitBytes);
        newObj.frames = flixel.graphics.frames.FlxAtlasFrames.fromSparrow(bitmap, datBytes.toString());

        wizFiles = [
          {name: box.animData.assetPath, bytes: bitBytes},
          {name: box.animData.assetPath.replace(".png", ".xml"), bytes: datBytes}
        ];
      }
      else
      {
        newObj.loadSparrow(animPath);
      }

      if (newObj.frames == null) return;
      newObj.animation.addByPrefix('idle', '', 24, false, false, false);
    }

    var spr:FlxSprite = cast obj.sprite;
    spr.kill();
    page.remove(spr);
    spr.destroy();

    obj.sprite = newObj;
    box.onOffsetsChange();
    box.onLoopDataChange();
    newObj.zIndex = box.animData.zIndex;
    newObj.scale.set(box.animData.scale, box.animData.scale);

    page.add(newObj);
    page.makeMarkers();
    page.refresh();

    dialog.rankAnimationFiles[dialog.currentRank][box.ID] = wizFiles;
    copyData(dialog.rankAnimationDataMap[dialog.currentRank][box.ID], box.animData);
  }

  function copyData(?oldData:PlayerResultsAnimationData, newData:PlayerResultsAnimationData) // this is how we update data
  {
    if (oldData != null)
    {
      oldData.renderType = newData.renderType;
      oldData.assetPath = newData.assetPath;
      oldData.offsets = newData.offsets.copy();
      oldData.zIndex = newData.zIndex;
      oldData.delay = newData.delay;
      oldData.scale = newData.scale;
      oldData.looped = newData.looped;
      oldData.loopFrame = newData.loopFrame;
      oldData.loopFrameLabel = newData.loopFrameLabel;
    }
    else if (oldData == null) oldData = newData;
  }
}

@:xml('
<?xml version="1.0" encoding="utf-8"?>
<vbox width="100%" style="border:1px solid $normal-border-color; padding: 5px">
  <dropdown id="animRenderType" width="100%" height="25" dropdownHeight="50">
    <data>
      <item text="Animate Atlas" value="animateatlas"/>
      <item text="Sparrow" value="sparrow"/>
    </data>
  </dropdown>
  <hbox width="100%">
    <textfield id="animAssetPath" placeholder="Asset Path" width="80%"/>
    <button id="animLoadAsset" text="Load" width="20%"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <label text="Offsets" verticalAlign="center"/>
    <number-stepper id="animOffsetX" step="1" pos="0" verticalAlign="center"/>
    <number-stepper id="animOffsetY" step="1" pos="0" verticalAlign="center"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <label text="Z Index" verticalAlign="center"/>
    <number-stepper id="animZIndex" min="0" step="1" pos="500" verticalAlign="center"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <label text="Delay" verticalAlign="center"/>
    <number-stepper id="animDelay" min="0" step="0.01" verticalAlign="center"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <label text="Scale" verticalAlign="center"/>
    <number-stepper id="animScale" min="0" step="0.01" pos="1" verticalAlign="center"/>
  </hbox>
  <checkbox id="animLooped" text="Looped" selected="true"/>
  <hbox width="100%" verticalAlign="center">
    <checkbox id="animStartFrameLabelCheck" text="Start Frame Label" verticalAlign="center"/>
    <textfield id="animStartFrameLabel" placeholder="Frame Label" disabled="true" verticalAlign="center"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <checkbox id="animLoopFrameCheck" text="Loop Frame" verticalAlign="center"/>
    <number-stepper id="animLoopFrame" min="0" step="1" disabled="true" verticalAlign="center"/>
  </hbox>
  <hbox width="100%" verticalAlign="center">
    <checkbox id="animLoopFrameLabelCheck" text="Loop Frame Label" verticalAlign="center"/>
    <textfield id="animLoopFrameLabel" placeholder="Loop Frame Label" disabled="true" verticalAlign="center"/>
  </hbox>
</vbox>
')
private class RankAnimationData extends VBox
{
  public var animData(get, never):PlayerResultsAnimationData;

  function get_animData():PlayerResultsAnimationData
  {
    return {
      renderType: animRenderType.safeSelectedItem.value,
      assetPath: animAssetPath.text,
      offsets: [animOffsetX.value, animOffsetY.value],
      zIndex: animZIndex.value,
      delay: animDelay.value,
      scale: animScale.value,
      startFrameLabel: animStartFrameLabelCheck.selected ? animStartFrameLabel.text : null,
      looped: animLooped.selected,
      loopFrame: animLoopFrameCheck.selected ? animLoopFrame.value : null,
      loopFrameLabel: animLoopFrameLabelCheck.selected ? animLoopFrameLabel.text : null,
    };
  }

  public function new(?data:PlayerResultsAnimationData)
  {
    super();

    animStartFrameLabelCheck.onClick = function(_) {
      animStartFrameLabel.disabled = !animStartFrameLabelCheck.selected;
    }

    animLoopFrameCheck.onClick = function(_) {
      animLoopFrame.disabled = !animLoopFrameCheck.selected;
    }

    animLoopFrameLabelCheck.onClick = function(_) {
      animLoopFrameLabel.disabled = !animLoopFrameLabelCheck.selected;
    }

    if (data != null)
    {
      animRenderType.selectedIndex = data.renderType == "sparrow" ? 1 : 0;
      animAssetPath.value = data.assetPath;

      if (data.offsets != null)
      {
        animOffsetX.value = data.offsets[0];
        animOffsetY.value = data.offsets[1];
      }

      if (data.zIndex != null) animZIndex.value = data.zIndex;

      if (data.delay != null) animDelay.value = data.delay;

      if (data.scale != null) animScale.value = data.scale;

      if (data.looped != null) animLooped.selected = data.looped;

      if (data.startFrameLabel != null && data.startFrameLabel != "")
      {
        animStartFrameLabelCheck.selected = true;
        animStartFrameLabel.disabled = false;
        animStartFrameLabel.text = data.startFrameLabel;
      }

      if (data.loopFrame != null)
      {
        animLoopFrameCheck.selected = true;
        animLoopFrame.disabled = false;
        animLoopFrame.value = data.loopFrame;
      }

      if (data.loopFrameLabel != null)
      {
        animLoopFrameLabelCheck.selected = true;
        animLoopFrameLabel.disabled = false;
        animLoopFrameLabel.text = data.loopFrameLabel;
      }
    }

    animLoadAsset.onClick = function(_) {
      var isAtlas:Bool = (animRenderType.safeSelectedItem.value == "animateatlas");

      FileUtil.browseForBinaryFile("Load Animation File", [isAtlas ? FileUtil.FILE_EXTENSION_INFO_ZIP : FileUtil.FILE_EXTENSION_INFO_PNG], function(_) {
        if (_?.fullPath == null) return;
        animAssetPath.text = _.fullPath;
      });
    }

    animOffsetX.onChange = animOffsetY.onChange = _ -> onOffsetsChange();
    animLooped.onChange = animLoopFrame.onChange = animLoopFrameLabel.onChange = _ -> onLoopDataChange();
    animRenderType.onChange = animAssetPath.onChange = _ -> onAssetChange();
  }

  public dynamic function onOffsetsChange() {}

  public dynamic function onLoopDataChange() {}

  public dynamic function onAssetChange() {}
}
