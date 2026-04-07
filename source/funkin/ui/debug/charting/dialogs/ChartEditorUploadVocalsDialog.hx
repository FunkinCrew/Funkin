package funkin.ui.debug.charting.dialogs;

#if FEATURE_CHART_EDITOR
import funkin.input.Cursor;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogParams;
import funkin.util.FileUtil;
import funkin.data.character.CharacterData;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.Label;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialog.DialogEvent;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.core.Component;

// @:nullSafety // TODO: Fix null safety when used with HaxeUI build macros.

@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/chart-editor/dialogs/upload-vocals.xml')) @:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorUploadVocalsDialog extends ChartEditorBaseDialog
{
  var dropHandlers:Array<DialogDropTarget> = [];
  var vocalContainer:Component;
  var dialogCancel:Button;
  var dialogNoVocals:Button;
  var dialogContinue:Button;
  var playerCharId:String;
  var opponentCharId:String;
  var instId:String;
  var hasClearedVocals:Bool = false;

  public function new(state2:ChartEditorState, playerCharId:String, opponentCharId:String, params2:DialogParams)
  {
    super(state2, params2);

    this.playerCharId = playerCharId;
    this.opponentCharId = opponentCharId;
    this.instId = chartEditorState.currentInstrumentalId;

    dialogCancel.onClick = function(_)
    {
      hideDialog(DialogButton.CANCEL);
    }

    dialogNoVocals.onClick = function(_)
    {
      // Dismiss
      chartEditorState.wipeVocalData();
      hideDialog(DialogButton.APPLY);
    };

    dialogContinue.onClick = function(_)
    {
      // Dismiss
      hideDialog(DialogButton.APPLY);
    };

    buildDropHandlers();
  }

  function buildDropHandlers():Void
  {
    var charIds:Array<String> = [playerCharId, opponentCharId];
    for (charKey in charIds)
    {
      var isPlayer:Bool = charKey == playerCharId;

      trace('Adding vocal upload for character ${charKey}');

      var charMetadata:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charKey);
      var charName:String = charMetadata?.name ?? charKey;

      var vocalsEntry = new ChartEditorUploadVocalsEntry(charName);

      var dropHandler:DialogDropTarget = {component: vocalsEntry, handler: null};

      var onDropFile:String->Void = function(pathStr:String)
      {
        trace('Selected file: $pathStr');
        var path:Path = new Path(pathStr);

        if (chartEditorState.loadVocalsFromPath(path, charKey, this.instId, !this.hasClearedVocals))
        {
          if (isPlayer)
          {
            chartEditorState.currentSongMetadata.playData.characters.playerVocals = [playerCharId];
          }
          else
          {
            chartEditorState.currentSongMetadata.playData.characters.opponentVocals = [opponentCharId];
          }

          this.hasClearedVocals = true;
          // Tell the user the load was successful.
          chartEditorState.success('Loaded Vocals', 'Loaded vocals for $charName (${path.file}.${path.ext}), variation ${chartEditorState.selectedVariation}');
          #if FEATURE_FILE_DROP
          vocalsEntry.vocalsEntryLabel.text = 'Voices for $charName (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
          #else
          vocalsEntry.vocalsEntryLabel.text = 'Voices for $charName (click to browse)\n${path.file}.${path.ext}';
          #end

          dialogNoVocals.hidden = true;
          chartEditorState.removeDropHandler(dropHandler);
        }
        else
        {
          trace('Failed to load vocal track (${path.file}.${path.ext})');

          chartEditorState.error('Failed to Load Vocals',
            'Failed to load vocal track (${path.file}.${path.ext}) for variation (${chartEditorState.selectedVariation})');

          #if FEATURE_FILE_DROP
          vocalsEntry.vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
          #else
          vocalsEntry.vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
          #end
        }
      };

      vocalsEntry.onClick = function(_event)
      {
        FileUtil.browseForFile('Open $charName Vocals', [FileUtil.FILE_FILTER_OGG], function(selectedFile)
        {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            trace('Selected file: ' + selectedFile.name);

            if (chartEditorState.loadVocalsFromBytes(selectedFile.bytes, charKey, this.instId, !this.hasClearedVocals))
            {
              hasClearedVocals = true;
              // Tell the user the load was successful.
              chartEditorState.success('Loaded Vocals', 'Loaded vocals for $charName (${selectedFile.name}), variation ${chartEditorState.selectedVariation}');

              #if FEATURE_FILE_DROP
              vocalsEntry.vocalsEntryLabel.text = 'Voices for $charName (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
              #else
              vocalsEntry.vocalsEntryLabel.text = 'Voices for $charName (click to browse)\n${selectedFile.name}';
              #end

              dialogNoVocals.hidden = true;
            }
            else
            {
              trace('Failed to load vocal track (${selectedFile.fullPath})');

              chartEditorState.error('Failed to Load Vocals',
                'Failed to load vocal track (${selectedFile.name}) for variation (${chartEditorState.selectedVariation})');

              #if FEATURE_FILE_DROP
              vocalsEntry.vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
              #else
              vocalsEntry.vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
              #end
            }
          }
        });
      }

      dropHandler.handler = onDropFile;

      // onDropFile
      #if FEATURE_FILE_DROP
      dropHandlers.push(dropHandler);
      #end

      vocalContainer.addComponent(vocalsEntry);
    }
  }

  public static function build(state:ChartEditorState, playerCharId:String, opponentCharId:String, ?closable:Bool, ?modal:Bool):ChartEditorUploadVocalsDialog
  {
    var dialog = new ChartEditorUploadVocalsDialog(state, playerCharId, opponentCharId, {
      closable: closable ?? false,
      modal: modal ?? true
    });

    for (dropTarget in dialog.dropHandlers)
    {
      state.addDropHandler(dropTarget);
    }

    dialog.showDialog(modal ?? true);

    return dialog;
  }

  override public function onClose(event:DialogEvent):Void
  {
    super.onClose(event);

    if (event.button != DialogButton.APPLY && !this.closable)
    {
      // User cancelled the wizard! Back to the welcome dialog.
      chartEditorState.openWelcomeDialog(this.closable);
    }

    for (dropTarget in dropHandlers)
    {
      chartEditorState.removeDropHandler(dropTarget);
    }
  }

  override public function lock():Void
  {
    super.lock();
    this.dialogCancel.disabled = true;
  }

  override public function unlock():Void
  {
    super.unlock();
    this.dialogCancel.disabled = false;
  }

  function onCancelBrowse():Void
  {
    this.unlock();
  }
}

@:build(haxe.ui.ComponentBuilder.build('assets/exclude/data/ui/chart-editor/dialogs/upload-vocals-entry.xml'))
class ChartEditorUploadVocalsEntry extends Box
{
  public var vocalsEntryLabel:Label;

  var charName:String;

  public function new(charName:String)
  {
    super();

    this.charName = charName;

    #if FEATURE_FILE_DROP
    vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
    #else
    vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
    #end

    this.onMouseOver = function(_event)
    {
      // if (this.locked) return;
      this.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    this.onMouseOut = function(_event)
    {
      this.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }
  }
}
#end
