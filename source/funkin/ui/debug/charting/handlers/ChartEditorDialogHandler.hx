package funkin.ui.debug.charting.handlers;

import flixel.util.FlxTimer;
import funkin.data.song.importer.FNFLegacyData;
import funkin.data.song.importer.FNFLegacyImporter;
import funkin.data.song.SongData.SongCharacterData;
import funkin.data.song.SongData.SongChartData;
import funkin.data.song.SongData.SongMetadata;
import funkin.data.song.SongData.SongTimeChange;
import funkin.data.song.SongRegistry;
import funkin.input.Cursor;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.song.Song;
import funkin.play.stage.StageData;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.util.Constants;
import funkin.util.FileUtil;
import funkin.util.SerializerUtil;
import funkin.util.SortUtil;
import funkin.util.VersionUtil;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.Form;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;
import thx.semver.Version;

using Lambda;

/**
 * Handles dialogs for the new Chart Editor.
 */
@:nullSafety
@:access(funkin.ui.debug.charting.ChartEditorState)
class ChartEditorDialogHandler
{
  // Paths to HaxeUI layout files for each dialog.
  static final CHART_EDITOR_DIALOG_ABOUT_LAYOUT:String = Paths.ui('chart-editor/dialogs/about');
  static final CHART_EDITOR_DIALOG_WELCOME_LAYOUT:String = Paths.ui('chart-editor/dialogs/welcome');
  static final CHART_EDITOR_DIALOG_UPLOAD_CHART_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-chart');
  static final CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-inst');
  static final CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT:String = Paths.ui('chart-editor/dialogs/song-metadata');
  static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-vocals');
  static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_ENTRY_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-vocals-entry');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart-parts');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart-parts-entry');
  static final CHART_EDITOR_DIALOG_IMPORT_CHART_LAYOUT:String = Paths.ui('chart-editor/dialogs/import-chart');
  static final CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT:String = Paths.ui('chart-editor/dialogs/user-guide');
  static final CHART_EDITOR_DIALOG_ADD_VARIATION_LAYOUT:String = Paths.ui('chart-editor/dialogs/add-variation');
  static final CHART_EDITOR_DIALOG_ADD_DIFFICULTY_LAYOUT:String = Paths.ui('chart-editor/dialogs/add-difficulty');

  /**
   * Builds and opens a dialog giving brief credits for the chart editor.
   * @param state The current chart editor state.
   * @return The dialog that was opened.
   */
  public static function openAboutDialog(state:ChartEditorState):Null<Dialog>
  {
    return openDialog(state, CHART_EDITOR_DIALOG_ABOUT_LAYOUT, true, true);
  }

  /**
   * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openWelcomeDialog(state:ChartEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_WELCOME_LAYOUT, true, closable);
    if (dialog == null) throw 'Could not locate Welcome dialog';

    state.isHaxeUIDialogOpen = true;
    dialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      // Called when the Welcome dialog is closed while it is closable.
      state.stopWelcomeMusic();
    }

    #if sys
    var splashRecentContainer:Null<VBox> = dialog.findComponent('splashRecentContainer', VBox);
    if (splashRecentContainer == null) throw 'Could not locate splashRecentContainer in Welcome dialog';

    for (chartPath in state.previousWorkingFilePaths)
    {
      if (chartPath == null) continue;

      var linkRecentChart:Link = new Link();
      // regex to only use the filename, not the full path
      // "dadbattle.fnc" insted of "c:/user/docs/funkin/dadbattle.fnc"
      // hovering tooltip shows full path
      var fileNamePattern:EReg = new EReg("([^/\\\\]+)$", "");
      var fileName:String = fileNamePattern.match(chartPath) ? fileNamePattern.matched(1) : chartPath;
      linkRecentChart.text = fileName;
      linkRecentChart.tooltip = chartPath;
      linkRecentChart.onClick = function(_event) {
        dialog.hideDialog(DialogButton.CANCEL);
        state.stopWelcomeMusic();

        // Load chart from file
        var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(state, chartPath);
        if (result != null)
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: result.length == 0 ? 'Loaded chart (${chartPath.toString()})' : 'Loaded chart (${chartPath.toString()})\n${result.join("\n")}',
              type: result.length == 0 ? NotificationType.Success : NotificationType.Warning,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
        else
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Failure',
              body: 'Failed to load chart (${chartPath.toString()})',
              type: NotificationType.Error,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
      }

      if (!FileUtil.doesFileExist(chartPath))
      {
        trace('Previously loaded chart file (${chartPath}) does not exist, disabling link...');
        linkRecentChart.disabled = true;
      }

      splashRecentContainer.addComponent(linkRecentChart);
    }
    #else
    var splashRecentContainer:Null<VBox> = dialog.findComponent('splashRecentContainer', VBox);
    if (splashRecentContainer == null) throw 'Could not locate splashRecentContainer in Welcome dialog';

    var webLoadLabel:Label = new Label();
    webLoadLabel.text = 'Click the button below to load a chart file (.fnfc) from your computer.';

    splashRecentContainer.add(webLoadLabel);
    #end

    // Create New Song "Easy/Normal/Hard"
    var linkCreateBasic:Null<Link> = dialog.findComponent('splashCreateFromSongBasicOnly', Link);
    if (linkCreateBasic == null) throw 'Could not locate splashCreateFromSongBasicOnly link in Welcome dialog';
    linkCreateBasic.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);
      state.stopWelcomeMusic();

      //
      // Create Song Wizard
      //
      openCreateSongWizardBasicOnly(state, false);
    }

    // Create New Song "Erect/Nightmare"
    var linkCreateErect:Null<Link> = dialog.findComponent('splashCreateFromSongErectOnly', Link);
    if (linkCreateErect == null) throw 'Could not locate splashCreateFromSongErectOnly link in Welcome dialog';
    linkCreateErect.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);

      //
      // Create Song Wizard
      //
      openCreateSongWizardErectOnly(state, false);
    }

    // Create New Song "Easy/Normal/Hard/Erect/Nightmare"
    var linkCreateErect:Null<Link> = dialog.findComponent('splashCreateFromSongBasicErect', Link);
    if (linkCreateErect == null) throw 'Could not locate splashCreateFromSongBasicErect link in Welcome dialog';
    linkCreateErect.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);

      //
      // Create Song Wizard
      //
      openCreateSongWizardBasicErect(state, false);
    }

    var linkImportChartLegacy:Null<Link> = dialog.findComponent('splashImportChartLegacy', Link);
    if (linkImportChartLegacy == null) throw 'Could not locate splashImportChartLegacy link in Welcome dialog';
    linkImportChartLegacy.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);
      state.stopWelcomeMusic();

      // Open the "Import Chart" dialog
      openImportChartWizard(state, 'legacy', false);
    };

    var buttonBrowse:Null<Button> = dialog.findComponent('splashBrowse', Button);
    if (buttonBrowse == null) throw 'Could not locate splashBrowse button in Welcome dialog';
    buttonBrowse.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);
      state.stopWelcomeMusic();

      // Open the "Open Chart" dialog
      openBrowseFNFC(state, false);
    }

    var splashTemplateContainer:Null<VBox> = dialog.findComponent('splashTemplateContainer', VBox);
    if (splashTemplateContainer == null) throw 'Could not locate splashTemplateContainer in Welcome dialog';

    var songList:Array<String> = SongRegistry.instance.listEntryIds();
    songList.sort(SortUtil.alphabetically);

    for (targetSongId in songList)
    {
      var songData:Null<Song> = SongRegistry.instance.fetchEntry(targetSongId);
      if (songData == null) continue;

      var songName:Null<String> = songData.getDifficulty('normal')?.songName;
      if (songName == null) songName = songData.getDifficulty()?.songName;
      if (songName == null) // Still null?
      {
        trace('[WARN] Could not fetch song name for ${targetSongId}');
        continue;
      }

      var linkTemplateSong:Link = new Link();
      linkTemplateSong.text = songName;
      linkTemplateSong.onClick = function(_event) {
        dialog.hideDialog(DialogButton.CANCEL);
        state.stopWelcomeMusic();

        // Load song from template
        state.loadSongAsTemplate(targetSongId);
      }

      splashTemplateContainer.addComponent(linkTemplateSong);
    }

    state.fadeInWelcomeMusic();
    return dialog;
  }

  public static function openBrowseFNFC(state:ChartEditorState, closable:Bool):Null<Dialog>
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_UPLOAD_CHART_LAYOUT, true, closable);
    if (dialog == null) throw 'Could not locate Upload Chart dialog';

    dialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Simply let the dialog close.
      }
      else
      {
        // User cancelled the wizard! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Upload Chart dialog';

    state.isHaxeUIDialogOpen = true;
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var chartBox:Null<Box> = dialog.findComponent('chartBox', Box);
    if (chartBox == null) throw 'Could not locate chartBox in Upload Chart dialog';

    chartBox.onMouseOver = function(_event) {
      chartBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    chartBox.onMouseOut = function(_event) {
      chartBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    var onDropFile:String->Void;

    chartBox.onClick = function(_event) {
      Dialogs.openBinaryFile('Open Chart', [
        {label: 'Friday Night Funkin\' Chart (.fnfc)', extension: 'fnfc'}], function(selectedFile:SelectedFileInfo) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            try
            {
              var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFC(state, selectedFile.bytes);
              if (result != null)
              {
                #if !mac
                NotificationManager.instance.addNotification(
                  {
                    title: 'Success',
                    body: 'Loaded chart (${selectedFile.name})',
                    type: NotificationType.Success,
                    expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                  });
                #end

                if (selectedFile.fullPath != null) state.currentWorkingFilePath = selectedFile.fullPath;
                dialog.hideDialog(DialogButton.APPLY);
                removeDropHandler(onDropFile);
              }
            }
            catch (err)
            {
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Failed to load chart (${selectedFile.name}): ${err}',
                  type: NotificationType.Error,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end
            }
          }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped file (${path})');

      try
      {
        var result:Null<Array<String>> = ChartEditorImportExportHandler.loadFromFNFCPath(state, path.toString());
        if (result != null)
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: result.length == 0 ? 'Loaded chart (${path.toString()})' : 'Loaded chart (${path.toString()})\n${result.join("\n")}',
              type: result.length == 0 ? NotificationType.Success : NotificationType.Warning,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
          dialog.hideDialog(DialogButton.APPLY);
          removeDropHandler(onDropFile);
        }
        else
        {
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Failure',
              body: 'Failed to load chart (${path.toString()})',
              type: NotificationType.Error,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
      }
      catch (err)
      {
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Failed to load chart (${path.toString()}): ${err}',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
      }
    };

    addDropHandler(chartBox, onDropFile);

    return dialog;
  }

  /**
   * Open the wizard for opening an existing chart from individual files.
   * @param state
   * @param closable
   */
  public static function openBrowseWizard(state:ChartEditorState, closable:Bool):Void
  {
    // Open the "Open Chart" wizard
    // Step 1. Open Chart
    var openChartDialog:Dialog = openChartDialog(state);
    openChartDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Upload instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_event) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // Built from parts, so no .fnfc to save to.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard! Back to the welcome dialog.
            openWelcomeDialog(state);
          }
        };
      }
      else
      {
        // User cancelled the wizard! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };
  }

  public static function openImportChartWizard(state:ChartEditorState, format:String, closable:Bool):Void
  {
    // Open the "Open Chart" wizard
    // Step 1. Open Chart
    var openChartDialog:Null<Dialog> = openImportChartDialog(state, format);
    if (openChartDialog == null) throw 'Could not locate Import Chart dialog';
    openChartDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Upload instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_event) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard! Back to the welcome dialog.
            openWelcomeDialog(state);
          }
        };
      }
      else
      {
        // User cancelled the wizard! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };
  }

  public static function openCreateSongWizardBasicOnly(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, false, Constants.DEFAULT_VARIATION);
    songMetadataDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_event) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            openWelcomeDialog(state);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };
  }

  public static function openCreateSongWizardErectOnly(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, true, Constants.DEFAULT_VARIATION);
    songMetadataDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_event) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            openWelcomeDialog(state);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };
  }

  public static function openCreateSongWizardBasicErect(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, false, Constants.DEFAULT_VARIATION);
    songMetadataDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_event) {
              state.switchToCurrentInstrumental();
              // Step 4. Song Metadata (Erect)
              var songMetadataDialogErect:Dialog = openSongMetadataDialog(state, true, 'erect');
              songMetadataDialogErect.onDialogClosed = function(_event) {
                state.isHaxeUIDialogOpen = false;
                if (_event.button == DialogButton.APPLY)
                {
                  // Switch to the Erect variation so uploading the instrumental applies properly.
                  state.selectedVariation = 'erect';

                  // Step 5. Upload Instrumental (Erect)
                  var uploadInstDialogErect:Dialog = openUploadInstDialog(state, closable);
                  uploadInstDialogErect.onDialogClosed = function(_event) {
                    state.isHaxeUIDialogOpen = false;
                    if (_event.button == DialogButton.APPLY)
                    {
                      // Step 6. Upload Vocals (Erect)
                      // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
                      var uploadVocalsDialogErect:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
                      uploadVocalsDialogErect.onDialogClosed = function(_event) {
                        state.isHaxeUIDialogOpen = false;
                        state.currentWorkingFilePath = null; // New file, so no path.
                        state.switchToCurrentInstrumental();
                        state.postLoadInstrumental();
                      }
                    }
                    else
                    {
                      // User cancelled the wizard at Step 5! Back to the welcome dialog.
                      openWelcomeDialog(state);
                    }
                  };
                }
                else
                {
                  // User cancelled the wizard at Step 4! Back to the welcome dialog.
                  openWelcomeDialog(state);
                }
              }
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            openWelcomeDialog(state);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        openWelcomeDialog(state);
      }
    };
  }

  /**
   * Builds and opens a dialog where the user uploads an instrumental for the current song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  @:haxe.warning("-WVarInit") // Hide the warning about the onDropFile handler.
  public static function openUploadInstDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT, true, closable);
    if (dialog == null) throw 'Could not locate Upload Instrumental dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Upload Instrumental dialog';

    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var instrumentalBox:Null<Box> = dialog.findComponent('instrumentalBox', Box);
    if (instrumentalBox == null) throw 'Could not locate instrumentalBox in Upload Instrumental dialog';

    instrumentalBox.onMouseOver = function(_event) {
      instrumentalBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    instrumentalBox.onMouseOut = function(_event) {
      instrumentalBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    var instId:String = state.currentInstrumentalId;

    var onDropFile:String->Void;

    instrumentalBox.onClick = function(_event) {
      Dialogs.openBinaryFile('Open Instrumental', [
        {label: 'Audio File (.ogg)', extension: 'ogg'}], function(selectedFile:SelectedFileInfo) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            if (state.loadInstFromBytes(selectedFile.bytes, instId))
            {
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Success',
                  body: 'Loaded instrumental track (${selectedFile.name}) for variation (${state.selectedVariation})',
                  type: NotificationType.Success,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end

              state.switchToCurrentInstrumental();
              dialog.hideDialog(DialogButton.APPLY);
              removeDropHandler(onDropFile);
            }
            else
            {
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Failed to load instrumental track (${selectedFile.name}) for variation (${state.selectedVariation})',
                  type: NotificationType.Error,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end
            }
          }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped file (${path})');
      if (state.loadInstFromPath(path, instId))
      {
        // Tell the user the load was successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Success',
            body: 'Loaded instrumental track (${path.file}.${path.ext}) for variation (${state.selectedVariation})',
            type: NotificationType.Success,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end

        state.switchToCurrentInstrumental();
        dialog.hideDialog(DialogButton.APPLY);
        removeDropHandler(onDropFile);
      }
      else
      {
        var message:String = if (!ChartEditorState.SUPPORTED_MUSIC_FORMATS.contains(path.ext ?? ''))
        {
          'File format (${path.ext}) not supported for instrumental track (${path.file}.${path.ext})';
        }
        else
        {
          'Failed to load instrumental track (${path.file}.${path.ext}) for variation (${state.selectedVariation})';
        }

        // Tell the user the load was successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: message,
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
      }
    };

    addDropHandler(instrumentalBox, onDropFile);

    return dialog;
  }

  /**
   * Opens the dialog in the wizard where the user can set song metadata like name and artist and BPM.
   * @param state The ChartEditorState instance.
   * @return The dialog to open.
   */
  @:haxe.warning("-WVarInit")
  public static function openSongMetadataDialog(state:ChartEditorState, erect:Bool, targetVariation:String):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT, true, false);
    if (dialog == null) throw 'Could not locate Song Metadata dialog';

    if (targetVariation != Constants.DEFAULT_VARIATION)
    {
      dialog.title = 'New Chart - Provide Song Metadata (${targetVariation.toTitleCase()})';
    }

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Song Metadata dialog';
    state.isHaxeUIDialogOpen = true;
    buttonCancel.onClick = function(_event) {
      state.isHaxeUIDialogOpen = false;
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var newSongMetadata:SongMetadata = new SongMetadata('', '', Constants.DEFAULT_VARIATION);

    newSongMetadata.variation = targetVariation;
    newSongMetadata.playData.difficulties = (erect) ? ['erect', 'nightmare'] : ['easy', 'normal', 'hard'];

    var inputSongName:Null<TextField> = dialog.findComponent('inputSongName', TextField);
    if (inputSongName == null) throw 'Could not locate inputSongName TextField in Song Metadata dialog';
    inputSongName.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongName.removeClass('invalid-value');
        newSongMetadata.songName = event.target.text;
      }
      else
      {
        newSongMetadata.songName = "";
      }
    };
    inputSongName.text = "";

    var inputSongArtist:Null<TextField> = dialog.findComponent('inputSongArtist', TextField);
    if (inputSongArtist == null) throw 'Could not locate inputSongArtist TextField in Song Metadata dialog';
    inputSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        inputSongArtist.removeClass('invalid-value');
        newSongMetadata.artist = event.target.text;
      }
      else
      {
        newSongMetadata.artist = "";
      }
    };
    inputSongArtist.text = "";

    var inputStage:Null<DropDown> = dialog.findComponent('inputStage', DropDown);
    if (inputStage == null) throw 'Could not locate inputStage DropDown in Song Metadata dialog';
    inputStage.onChange = function(event:UIEvent) {
      if (event.data == null && event.data.id == null) return;
      newSongMetadata.playData.stage = event.data.id;
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, newSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    var inputNoteStyle:Null<DropDown> = dialog.findComponent('inputNoteStyle', DropDown);
    if (inputNoteStyle == null) throw 'Could not locate inputNoteStyle DropDown in Song Metadata dialog';
    inputNoteStyle.onChange = function(event:UIEvent) {
      if (event.data.id == null) return;
      newSongMetadata.playData.noteStyle = event.data.id;
    };
    var startingValueNoteStyle = ChartEditorDropdowns.populateDropdownWithNoteStyles(inputNoteStyle, newSongMetadata.playData.noteStyle);
    inputNoteStyle.value = startingValueNoteStyle;

    var inputCharacterPlayer:Null<DropDown> = dialog.findComponent('inputCharacterPlayer', DropDown);
    if (inputCharacterPlayer == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterPlayer component.';
    inputCharacterPlayer.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      newSongMetadata.playData.characters.player = event.data.id;
    };
    var startingValuePlayer = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterPlayer, CharacterType.BF,
      newSongMetadata.playData.characters.player);
    inputCharacterPlayer.value = startingValuePlayer;

    var inputCharacterOpponent:Null<DropDown> = dialog.findComponent('inputCharacterOpponent', DropDown);
    if (inputCharacterOpponent == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterOpponent component.';
    inputCharacterOpponent.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      newSongMetadata.playData.characters.opponent = event.data.id;
    };
    var startingValueOpponent = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterOpponent, CharacterType.DAD,
      newSongMetadata.playData.characters.opponent);
    inputCharacterOpponent.value = startingValueOpponent;

    var inputCharacterGirlfriend:Null<DropDown> = dialog.findComponent('inputCharacterGirlfriend', DropDown);
    if (inputCharacterGirlfriend == null) throw 'ChartEditorToolboxHandler.buildToolboxMetadataLayout() - Could not find inputCharacterGirlfriend component.';
    inputCharacterGirlfriend.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
      newSongMetadata.playData.characters.girlfriend = event.data.id == "none" ? "" : event.data.id;
    };
    var startingValueGirlfriend = ChartEditorDropdowns.populateDropdownWithCharacters(inputCharacterGirlfriend, CharacterType.GF,
      newSongMetadata.playData.characters.girlfriend);
    inputCharacterGirlfriend.value = startingValueGirlfriend;

    var dialogBPM:Null<NumberStepper> = dialog.findComponent('dialogBPM', NumberStepper);
    if (dialogBPM == null) throw 'Could not locate dialogBPM NumberStepper in Song Metadata dialog';
    dialogBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      var timeChanges:Array<SongTimeChange> = newSongMetadata.timeChanges;
      if (timeChanges == null || timeChanges.length == 0)
      {
        timeChanges = [new SongTimeChange(0, event.value)];
      }
      else
      {
        timeChanges[0].bpm = event.value;
      }

      newSongMetadata.timeChanges = timeChanges;
    };

    var dialogContinue:Null<Button> = dialog.findComponent('dialogContinue', Button);
    if (dialogContinue == null) throw 'Could not locate dialogContinue button in Song Metadata dialog';
    dialogContinue.onClick = (_event) -> {
      if (targetVariation == Constants.DEFAULT_VARIATION) state.songMetadata.clear();

      state.songMetadata.set(targetVariation, newSongMetadata);

      Conductor.mapTimeChanges(state.currentSongMetadata.timeChanges);

      state.difficultySelectDirty = true;

      dialog.hideDialog(DialogButton.APPLY);
    }

    return dialog;
  }

  /**
   * Builds and opens a dialog where the user uploads vocals for the current song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openUploadVocalsDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var instId:String = state.currentInstrumentalId;
    var charIdsForVocals:Array<String> = [];

    var charData:SongCharacterData = state.currentSongMetadata.playData.characters;

    var hasClearedVocals:Bool = false;

    charIdsForVocals.push(charData.player);
    charIdsForVocals.push(charData.opponent);

    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_UPLOAD_VOCALS_LAYOUT, true, closable);
    if (dialog == null) throw 'Could not locate Upload Vocals dialog';

    var dialogContainer:Null<Component> = dialog.findComponent('vocalContainer');
    if (dialogContainer == null) throw 'Could not locate vocalContainer in Upload Vocals dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Upload Vocals dialog';
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var dialogNoVocals:Null<Button> = dialog.findComponent('dialogNoVocals', Button);
    if (dialogNoVocals == null) throw 'Could not locate dialogNoVocals button in Upload Vocals dialog';
    dialogNoVocals.onClick = function(_event) {
      // Dismiss
      state.wipeVocalData();
      dialog.hideDialog(DialogButton.APPLY);
    };

    for (charKey in charIdsForVocals)
    {
      trace('Adding vocal upload for character ${charKey}');
      var charMetadata:Null<CharacterData> = CharacterDataParser.fetchCharacterData(charKey);
      var charName:String = charMetadata != null ? charMetadata.name : charKey;

      var vocalsEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_UPLOAD_VOCALS_ENTRY_LAYOUT);

      var vocalsEntryLabel:Null<Label> = vocalsEntry.findComponent('vocalsEntryLabel', Label);
      if (vocalsEntryLabel == null) throw 'Could not locate vocalsEntryLabel in Upload Vocals dialog';
      #if FILE_DROP_SUPPORTED
      vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
      #else
      vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
      #end

      var onDropFile:String->Void = function(pathStr:String) {
        trace('Selected file: $pathStr');
        var path:Path = new Path(pathStr);

        if (!hasClearedVocals)
        {
          hasClearedVocals = true;
          state.stopExistingVocals();
        }

        if (state.loadVocalsFromPath(path, charKey, instId))
        {
          // Tell the user the load was successful.
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: 'Loaded vocals for $charName (${path.file}.${path.ext}), variation ${state.selectedVariation}',
              type: NotificationType.Success,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
          #if FILE_DROP_SUPPORTED
          vocalsEntryLabel.text = 'Voices for $charName (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
          #else
          vocalsEntryLabel.text = 'Voices for $charName (click to browse)\n${path.file}.${path.ext}';
          #end

          dialogNoVocals.hidden = true;
          removeDropHandler(onDropFile);
        }
        else
        {
          trace('Failed to load vocal track (${path.file}.${path.ext})');

          // Vocals failed to load.
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Failure',
              body: 'Failed to load vocal track (${path.file}.${path.ext}) for variation (${state.selectedVariation})',
              type: NotificationType.Error,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end

          #if FILE_DROP_SUPPORTED
          vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
          #else
          vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
          #end
        }
      };

      vocalsEntry.onClick = function(_event) {
        Dialogs.openBinaryFile('Open $charName Vocals', [
          {label: 'Audio File (.ogg)', extension: 'ogg'}], function(selectedFile) {
            if (selectedFile != null && selectedFile.bytes != null)
            {
              trace('Selected file: ' + selectedFile.name);
              if (!hasClearedVocals)
              {
                hasClearedVocals = true;
                state.stopExistingVocals();
              }
              if (state.loadVocalsFromBytes(selectedFile.bytes, charKey, instId))
              {
                // Tell the user the load was successful.
                #if !mac
                NotificationManager.instance.addNotification(
                  {
                    title: 'Success',
                    body: 'Loaded vocals for $charName (${selectedFile.name}), variation ${state.selectedVariation}',
                    type: NotificationType.Success,
                    expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                  });
                #end
                #if FILE_DROP_SUPPORTED
                vocalsEntryLabel.text = 'Voices for $charName (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
                #else
                vocalsEntryLabel.text = 'Voices for $charName (click to browse)\n${selectedFile.name}';
                #end

                dialogNoVocals.hidden = true;
              }
              else
              {
                trace('Failed to load vocal track (${selectedFile.fullPath})');

                #if !mac
                NotificationManager.instance.addNotification(
                  {
                    title: 'Failure',
                    body: 'Failed to load vocal track (${selectedFile.name}) for variation (${state.selectedVariation})',
                    type: NotificationType.Error,
                    expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                  });
                #end

                #if FILE_DROP_SUPPORTED
                vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
                #else
                vocalsEntryLabel.text = 'Click to browse for vocals for $charName.';
                #end
              }
            }
        });
      }

      // onDropFile
      #if FILE_DROP_SUPPORTED
      addDropHandler(vocalsEntry, onDropFile);
      #end
      dialogContainer.addComponent(vocalsEntry);
    }

    var dialogContinue:Null<Button> = dialog.findComponent('dialogContinue', Button);
    if (dialogContinue == null) throw 'Could not locate dialogContinue button in Upload Vocals dialog';
    dialogContinue.onClick = function(_event) {
      // Dismiss
      dialog.hideDialog(DialogButton.APPLY);
    };

    return dialog;
  }

  /**
   * Builds and opens a dialog where the user upload the JSON files for a song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  @:haxe.warning('-WVarInit')
  public static function openChartDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_LAYOUT, true, closable);
    if (dialog == null) throw 'Could not locate Open Chart dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Open Chart dialog';
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var chartContainerA:Null<Component> = dialog.findComponent('chartContainerA');
    if (chartContainerA == null) throw 'Could not locate chartContainerA in Open Chart dialog';
    var chartContainerB:Null<Component> = dialog.findComponent('chartContainerB');
    if (chartContainerB == null) throw 'Could not locate chartContainerB in Open Chart dialog';

    var songMetadata:Map<String, SongMetadata> = [];
    var songChartData:Map<String, SongChartData> = [];

    var buttonContinue:Null<Button> = dialog.findComponent('dialogContinue', Button);
    if (buttonContinue == null) throw 'Could not locate dialogContinue button in Open Chart dialog';
    buttonContinue.onClick = function(_event) {
      state.loadSong(songMetadata, songChartData);

      dialog.hideDialog(DialogButton.APPLY);
    }

    var onDropFileMetadataVariation:String->Label->String->Void;
    var onClickMetadataVariation:String->Label->UIEvent->Void;
    var onDropFileChartDataVariation:String->Label->String->Void;
    var onClickChartDataVariation:String->Label->UIEvent->Void;

    var constructVariationEntries:Array<String>->Void = function(variations:Array<String>) {
      // Clear the chart container.
      while (chartContainerB.getComponentAt(0) != null)
      {
        chartContainerB.removeComponent(chartContainerB.getComponentAt(0));
      }

      // Build an entry for -chart.json.
      var songDefaultChartDataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
      var songDefaultChartDataEntryLabel:Null<Label> = songDefaultChartDataEntry.findComponent('chartEntryLabel', Label);
      if (songDefaultChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
      #if FILE_DROP_SUPPORTED
      songDefaultChartDataEntryLabel.text = 'Drag and drop <song>-chart.json file, or click to browse.';
      #else
      songDefaultChartDataEntryLabel.text = 'Click to browse for <song>-chart.json file.';
      #end

      songDefaultChartDataEntry.onClick = onClickChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel);
      addDropHandler(songDefaultChartDataEntry, onDropFileChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel));
      chartContainerB.addComponent(songDefaultChartDataEntry);

      for (variation in variations)
      {
        // Build entries for -metadata-<variation>.json.
        var songVariationMetadataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
        var songVariationMetadataEntryLabel:Null<Label> = songVariationMetadataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationMetadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        #if FILE_DROP_SUPPORTED
        songVariationMetadataEntryLabel.text = 'Drag and drop <song>-metadata-${variation}.json file, or click to browse.';
        #else
        songVariationMetadataEntryLabel.text = 'Click to browse for <song>-metadata-${variation}.json file.';
        #end

        songVariationMetadataEntry.onMouseOver = function(_event) {
          songVariationMetadataEntry.swapClass('upload-bg', 'upload-bg-hover');
          Cursor.cursorMode = Pointer;
        }
        songVariationMetadataEntry.onMouseOut = function(_event) {
          songVariationMetadataEntry.swapClass('upload-bg-hover', 'upload-bg');
          Cursor.cursorMode = Default;
        }
        songVariationMetadataEntry.onClick = onClickMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel);
        #if FILE_DROP_SUPPORTED
        addDropHandler(songVariationMetadataEntry, onDropFileMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel));
        #end
        chartContainerB.addComponent(songVariationMetadataEntry);

        // Build entries for -chart-<variation>.json.
        var songVariationChartDataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
        var songVariationChartDataEntryLabel:Null<Label> = songVariationChartDataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        #if FILE_DROP_SUPPORTED
        songVariationChartDataEntryLabel.text = 'Drag and drop <song>-chart-${variation}.json file, or click to browse.';
        #else
        songVariationChartDataEntryLabel.text = 'Click to browse for <song>-chart-${variation}.json file.';
        #end

        songVariationChartDataEntry.onMouseOver = function(_event) {
          songVariationChartDataEntry.swapClass('upload-bg', 'upload-bg-hover');
          Cursor.cursorMode = Pointer;
        }
        songVariationChartDataEntry.onMouseOut = function(_event) {
          songVariationChartDataEntry.swapClass('upload-bg-hover', 'upload-bg');
          Cursor.cursorMode = Default;
        }
        songVariationChartDataEntry.onClick = onClickChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel);
        #if FILE_DROP_SUPPORTED
        addDropHandler(songVariationChartDataEntry, onDropFileChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel));
        #end
        chartContainerB.addComponent(songVariationChartDataEntry);
      }
    }

    onDropFileMetadataVariation = function(variation:String, label:Label, pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped JSON file (${path})');

      var songMetadataTxt:String = FileUtil.readStringFromPath(path.toString());

      var songMetadataVersion:Null<Version> = VersionUtil.getVersionFromJSON(songMetadataTxt);
      if (songMetadataVersion == null)
      {
        // Tell the user the load was not successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Could not parse metadata file version (${path.file}.${path.ext})',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
        return;
      }

      var songMetadataVariation:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(songMetadataTxt, path.toString(),
        songMetadataVersion);

      if (songMetadataVariation == null)
      {
        // Tell the user the load was not successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Could not load metadata file (${path.file}.${path.ext})',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
        return;
      }

      songMetadata.set(variation, songMetadataVariation);

      // Tell the user the load was successful.
      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: 'Success',
          body: 'Loaded metadata file (${path.file}.${path.ext})',
          type: NotificationType.Success,
          expiryMs: Constants.NOTIFICATION_DISMISS_TIME
        });
      #end

      #if FILE_DROP_SUPPORTED
      label.text = 'Metadata file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
      #else
      label.text = 'Metadata file (click to browse)\n${path.file}.${path.ext}';
      #end

      if (variation == Constants.DEFAULT_VARIATION) constructVariationEntries(songMetadataVariation.playData.songVariations);
    };

    onClickMetadataVariation = function(variation:String, label:Label, _event:UIEvent) {
      Dialogs.openBinaryFile('Open Chart ($variation) Metadata', [
        {label: 'JSON File (.json)', extension: 'json'}], function(selectedFile) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            trace('Selected file: ' + selectedFile.name);

            var songMetadataTxt:String = selectedFile.bytes.toString();

            var songMetadataVersion:Null<Version> = VersionUtil.getVersionFromJSON(songMetadataTxt);
            if (songMetadataVersion == null)
            {
              // Tell the user the load was not successful.
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Could not parse metadata file version (${selectedFile.name})',
                  type: NotificationType.Error,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end
              return;
            }

            var songMetadataVariation:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(songMetadataTxt, selectedFile.name,
              songMetadataVersion);

            if (songMetadataVariation != null)
            {
              songMetadata.set(variation, songMetadataVariation);

              // Tell the user the load was successful.
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Success',
                  body: 'Loaded metadata file (${selectedFile.name})',
                  type: NotificationType.Success,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end

              #if FILE_DROP_SUPPORTED
              label.text = 'Metadata file (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
              #else
              label.text = 'Metadata file (click to browse)\n${selectedFile.name}';
              #end

              if (variation == Constants.DEFAULT_VARIATION) constructVariationEntries(songMetadataVariation.playData.songVariations);
            }
            else
            {
              // Tell the user the load was unsuccessful.
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Failed to load metadata file (${selectedFile.name})',
                  type: NotificationType.Error,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end
            }
          }
      });
    }

    onDropFileChartDataVariation = function(variation:String, label:Label, pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped JSON file (${path})');

      var songChartDataTxt:String = FileUtil.readStringFromPath(path.toString());

      var songChartDataVersion:Null<Version> = VersionUtil.getVersionFromJSON(songChartDataTxt);
      if (songChartDataVersion == null)
      {
        // Tell the user the load was not successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Could not parse chart data file version (${path.file}.${path.ext})',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
        return;
      }

      var songChartDataVariation:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataRawWithMigration(songChartDataTxt, path.toString(),
        songChartDataVersion);

      if (songChartDataVariation != null)
      {
        songChartData.set(variation, songChartDataVariation);
        state.notePreviewDirty = true;
        state.notePreviewViewportBoundsDirty = true;
        state.noteDisplayDirty = true;

        // Tell the user the load was successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Success',
            body: 'Loaded chart data file (${path.file}.${path.ext})',
            type: NotificationType.Success,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end

        #if FILE_DROP_SUPPORTED
        label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
        #else
        label.text = 'Chart data file (click to browse)\n${path.file}.${path.ext}';
        #end
      }
      else
      {
        // Tell the user the load was unsuccessful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Failed to load chart data file (${path.file}.${path.ext})',
            type: NotificationType.Error,
            expiryMs: Constants.NOTIFICATION_DISMISS_TIME
          });
        #end
      }
    };

    onClickChartDataVariation = function(variation:String, label:Label, _event:UIEvent) {
      Dialogs.openBinaryFile('Open Chart ($variation) Metadata', [
        {label: 'JSON File (.json)', extension: 'json'}], function(selectedFile) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            trace('Selected file: ' + selectedFile.name);

            var songChartDataTxt:String = selectedFile.bytes.toString();

            var songChartDataVersion:Null<Version> = VersionUtil.getVersionFromJSON(songChartDataTxt);
            if (songChartDataVersion == null)
            {
              // Tell the user the load was not successful.
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Could not parse chart data file version (${selectedFile.name})',
                  type: NotificationType.Error,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end
              return;
            }

            var songChartDataVariation:Null<SongChartData> = SongRegistry.instance.parseEntryChartDataRawWithMigration(songChartDataTxt, selectedFile.name,
              songChartDataVersion);

            if (songChartDataVariation != null)
            {
              songChartData.set(variation, songChartDataVariation);
              state.notePreviewDirty = true;
              state.notePreviewViewportBoundsDirty = true;
              state.noteDisplayDirty = true;

              // Tell the user the load was successful.
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Success',
                  body: 'Loaded chart data file (${selectedFile.name})',
                  type: NotificationType.Success,
                  expiryMs: Constants.NOTIFICATION_DISMISS_TIME
                });
              #end

              #if FILE_DROP_SUPPORTED
              label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
              #else
              label.text = 'Chart data file (click to browse)\n${selectedFile.name}';
              #end
            }
          }
      });
    }

    var metadataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
    var metadataEntryLabel:Null<Label> = metadataEntry.findComponent('chartEntryLabel', Label);
    if (metadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';

    #if FILE_DROP_SUPPORTED
    metadataEntryLabel.text = 'Drag and drop <song>-metadata.json file, or click to browse.';
    #else
    metadataEntryLabel.text = 'Click to browse for <song>-metadata.json file.';
    #end

    metadataEntry.onClick = onClickMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel);
    addDropHandler(metadataEntry, onDropFileMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel));
    metadataEntry.onMouseOver = function(_event) {
      metadataEntry.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }
    metadataEntry.onMouseOut = function(_event) {
      metadataEntry.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    chartContainerA.addComponent(metadataEntry);

    return dialog;
  }

  /**
   * Builds and opens a dialog where the user can import a chart from an existing file format.
   * @param state The current chart editor state.
   * @param format The format to import from.
   * @param closable
   * @return Dialog
   */
  public static function openImportChartDialog(state:ChartEditorState, format:String, closable:Bool = true):Null<Dialog>
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_IMPORT_CHART_LAYOUT, true, closable);
    if (dialog == null) return null;

    var prettyFormat:String = switch (format)
    {
      case 'legacy': 'FNF Legacy';
      default: 'Unknown';
    }

    var fileFilter = switch (format)
    {
      case 'legacy': {label: 'JSON Data File (.json)', extension: 'json'};
      default: null;
    }

    dialog.title = 'Import Chart - ${prettyFormat}';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Import Chart dialog';

    state.isHaxeUIDialogOpen = true;
    buttonCancel.onClick = function(_event) {
      state.isHaxeUIDialogOpen = false;
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var importBox:Null<Box> = dialog.findComponent('importBox', Box);
    if (importBox == null) throw 'Could not locate importBox in Import Chart dialog';

    importBox.onMouseOver = function(_event) {
      importBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }
    importBox.onMouseOut = function(_event) {
      importBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    var onDropFile:String->Void;

    importBox.onClick = function(_event) {
      Dialogs.openBinaryFile('Import Chart - ${prettyFormat}', fileFilter != null ? [fileFilter] : [], function(selectedFile:SelectedFileInfo) {
        if (selectedFile != null && selectedFile.bytes != null)
        {
          trace('Selected file: ' + selectedFile.fullPath);
          var selectedFileTxt:String = selectedFile.bytes.toString();
          var fnfLegacyData:Null<FNFLegacyData> = FNFLegacyImporter.parseLegacyDataRaw(selectedFileTxt, selectedFile.fullPath);

          if (fnfLegacyData == null)
          {
            #if !mac
            NotificationManager.instance.addNotification(
              {
                title: 'Failure',
                body: 'Failed to parse FNF chart file (${selectedFile.name})',
                type: NotificationType.Error,
                expiryMs: Constants.NOTIFICATION_DISMISS_TIME
              });
            #end
            return;
          }

          var songMetadata:SongMetadata = FNFLegacyImporter.migrateMetadata(fnfLegacyData);
          var songChartData:SongChartData = FNFLegacyImporter.migrateChartData(fnfLegacyData);

          state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

          dialog.hideDialog(DialogButton.APPLY);
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: 'Loaded chart file (${selectedFile.name})',
              type: NotificationType.Success,
              expiryMs: Constants.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      var selectedFileText:String = FileUtil.readStringFromPath(path.toString());
      var selectedFileData:FNFLegacyData = FNFLegacyImporter.parseLegacyDataRaw(selectedFileText, path.toString());
      var songMetadata:SongMetadata = FNFLegacyImporter.migrateMetadata(selectedFileData);
      var songChartData:SongChartData = FNFLegacyImporter.migrateChartData(selectedFileData);

      state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

      dialog.hideDialog(DialogButton.APPLY);
      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: 'Success',
          body: 'Loaded chart file (${path.file}.${path.ext})',
          type: NotificationType.Success,
          expiryMs: Constants.NOTIFICATION_DISMISS_TIME
        });
      #end
    };

    addDropHandler(importBox, onDropFile);

    return dialog;
  }

  /**
   * Builds and opens a dialog displaying the user guide, providing guidance and help on how to use the chart editor.
   *
   * @param state The current chart editor state.
   * @return The dialog that was opened.
   */
  public static function openUserGuideDialog(state:ChartEditorState):Null<Dialog>
  {
    return openDialog(state, CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT, true, true);
  }

  /**
   * Builds and opens a dialog where the user can add a new variation for a song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openAddVariationDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_ADD_VARIATION_LAYOUT, true, false);
    if (dialog == null) throw 'Could not locate Add Variation dialog';

    var variationForm:Null<Form> = dialog.findComponent('variationForm', Form);
    if (variationForm == null) throw 'Could not locate variationForm Form in Add Variation dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Add Variation dialog';
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var buttonAdd:Null<Button> = dialog.findComponent('dialogAdd', Button);
    if (buttonAdd == null) throw 'Could not locate dialogAdd button in Add Variation dialog';
    buttonAdd.onClick = function(_event) {
      // This performs validation before the onSubmit callback is called.
      variationForm.submit();
    }

    var dialogSongName:Null<TextField> = dialog.findComponent('dialogSongName', TextField);
    if (dialogSongName == null) throw 'Could not locate dialogSongName TextField in Add Variation dialog';
    dialogSongName.value = state.currentSongMetadata.songName;

    var dialogSongArtist:Null<TextField> = dialog.findComponent('dialogSongArtist', TextField);
    if (dialogSongArtist == null) throw 'Could not locate dialogSongArtist TextField in Add Variation dialog';
    dialogSongArtist.value = state.currentSongMetadata.artist;

    var dialogStage:Null<DropDown> = dialog.findComponent('dialogStage', DropDown);
    if (dialogStage == null) throw 'Could not locate dialogStage DropDown in Add Variation dialog';
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(dialogStage, state.currentSongMetadata.playData.stage);
    dialogStage.value = startingValueStage;

    var dialogNoteStyle:Null<DropDown> = dialog.findComponent('dialogNoteStyle', DropDown);
    if (dialogNoteStyle == null) throw 'Could not locate dialogNoteStyle DropDown in Add Variation dialog';
    dialogNoteStyle.value = state.currentSongMetadata.playData.noteStyle;

    var dialogCharacterPlayer:Null<DropDown> = dialog.findComponent('dialogCharacterPlayer', DropDown);
    if (dialogCharacterPlayer == null) throw 'Could not locate dialogCharacterPlayer DropDown in Add Variation dialog';
    dialogCharacterPlayer.value = ChartEditorDropdowns.populateDropdownWithCharacters(dialogCharacterPlayer, CharacterType.BF,
      state.currentSongMetadata.playData.characters.player);

    var dialogCharacterOpponent:Null<DropDown> = dialog.findComponent('dialogCharacterOpponent', DropDown);
    if (dialogCharacterOpponent == null) throw 'Could not locate dialogCharacterOpponent DropDown in Add Variation dialog';
    dialogCharacterOpponent.value = ChartEditorDropdowns.populateDropdownWithCharacters(dialogCharacterOpponent, CharacterType.DAD,
      state.currentSongMetadata.playData.characters.opponent);

    var dialogCharacterGirlfriend:Null<DropDown> = dialog.findComponent('dialogCharacterGirlfriend', DropDown);
    if (dialogCharacterGirlfriend == null) throw 'Could not locate dialogCharacterGirlfriend DropDown in Add Variation dialog';
    dialogCharacterGirlfriend.value = ChartEditorDropdowns.populateDropdownWithCharacters(dialogCharacterGirlfriend, CharacterType.GF,
      state.currentSongMetadata.playData.characters.girlfriend);

    var dialogBPM:Null<NumberStepper> = dialog.findComponent('dialogBPM', NumberStepper);
    if (dialogBPM == null) throw 'Could not locate dialogBPM NumberStepper in Add Variation dialog';
    dialogBPM.value = state.currentSongMetadata.timeChanges[0].bpm;

    // If all validators succeeded, this callback is called.

    state.isHaxeUIDialogOpen = true;
    variationForm.onSubmit = function(_event) {
      state.isHaxeUIDialogOpen = false;
      trace('Add Variation dialog submitted, validation succeeded!');

      var dialogVariationName:Null<TextField> = dialog.findComponent('dialogVariationName', TextField);
      if (dialogVariationName == null) throw 'Could not locate dialogVariationName TextField in Add Variation dialog';

      var pendingVariation:SongMetadata = new SongMetadata(dialogSongName.text, dialogSongArtist.text, dialogVariationName.text.toLowerCase());

      pendingVariation.playData.stage = dialogStage.value.id;
      pendingVariation.playData.noteStyle = dialogNoteStyle.value;
      pendingVariation.timeChanges[0].bpm = dialogBPM.value;

      state.songMetadata.set(pendingVariation.variation, pendingVariation);
      state.difficultySelectDirty = true; // Force the Difficulty toolbox to update.
      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: "Add Variation",
          body: 'Added new variation "${pendingVariation.variation}"',
          type: NotificationType.Success
        });
      #end
      dialog.hideDialog(DialogButton.APPLY);
    }

    return dialog;
  }

  /**
   * Builds and opens a dialog where the user can add a new difficulty for a song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openAddDifficultyDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_ADD_DIFFICULTY_LAYOUT, true, false);
    if (dialog == null) throw 'Could not locate Add Difficulty dialog';

    var difficultyForm:Null<Form> = dialog.findComponent('difficultyForm', Form);
    if (difficultyForm == null) throw 'Could not locate difficultyForm Form in Add Difficulty dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Add Difficulty dialog';
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var buttonAdd:Null<Button> = dialog.findComponent('dialogAdd', Button);
    if (buttonAdd == null) throw 'Could not locate dialogAdd button in Add Difficulty dialog';
    buttonAdd.onClick = function(_event) {
      // This performs validation before the onSubmit callback is called.
      difficultyForm.submit();
    }

    var dialogVariation:Null<DropDown> = dialog.findComponent('dialogVariation', DropDown);
    if (dialogVariation == null) throw 'Could not locate dialogVariation DropDown in Add Variation dialog';
    dialogVariation.value = ChartEditorDropdowns.populateDropdownWithVariations(dialogVariation, state, true);

    var labelScrollSpeed:Null<Label> = dialog.findComponent('labelScrollSpeed', Label);
    if (labelScrollSpeed == null) throw 'Could not find labelScrollSpeed component.';

    var inputScrollSpeed:Null<Slider> = dialog.findComponent('inputScrollSpeed', Slider);
    if (inputScrollSpeed == null) throw 'Could not find inputScrollSpeed component.';
    inputScrollSpeed.onChange = function(event:UIEvent) {
      labelScrollSpeed.text = 'Scroll Speed: ${inputScrollSpeed.value}x';
    };
    inputScrollSpeed.value = state.currentSongChartScrollSpeed;
    labelScrollSpeed.text = 'Scroll Speed: ${inputScrollSpeed.value}x';

    difficultyForm.onSubmit = function(_event) {
      trace('Add Difficulty dialog submitted, validation succeeded!');

      var dialogDifficultyName:Null<TextField> = dialog.findComponent('dialogDifficultyName', TextField);
      if (dialogDifficultyName == null) throw 'Could not locate dialogDifficultyName TextField in Add Difficulty dialog';

      state.createDifficulty(dialogVariation.value.id, dialogDifficultyName.text.toLowerCase(), inputScrollSpeed.value ?? 1.0);

      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: "Add Difficulty",
          body: 'Added new difficulty "${dialogDifficultyName.text.toLowerCase()}"',
          type: NotificationType.Success
        });
      #end
      dialog.hideDialog(DialogButton.APPLY);
    }

    return dialog;
  }

  /**
   * Builds and opens a dialog from a given layout path.
   * @param modal Makes the background uninteractable while the dialog is open.
   * @param closable Hides the close button on the dialog, preventing it from being closed unless the user interacts with the dialog.
   */
  static function openDialog(state:ChartEditorState, key:String, modal:Bool = true, closable:Bool = true):Null<Dialog>
  {
    var dialog:Null<Dialog> = cast state.buildComponent(key);
    if (dialog == null) return null;

    dialog.destroyOnClose = true;
    dialog.closable = closable;
    dialog.showDialog(modal);

    state.isHaxeUIDialogOpen = true;
    dialog.onDialogClosed = function(event:UIEvent) {
      state.isHaxeUIDialogOpen = false;
    };

    dialog.zIndex = 1000;

    return dialog;
  }

  // ==========
  // DROP HANDLERS
  // ==========
  static var dropHandlers:Array<
    {
      component:Component,
      handler:(String->Void)
    }> = [];

  /**
   * Add a callback for when a file is dropped on a component.
   *
   * On OS X you can’t drop on the application window, but rather only the app icon
   * (either in the dock while running or the icon on the hard drive) so this must be disabled
   * and UI updated appropriately.
   * @param component
   * @param handler
   */
  static function addDropHandler(component:Component, handler:String->Void):Void
  {
    #if desktop
    if (!FlxG.stage.window.onDropFile.has(onDropFile)) FlxG.stage.window.onDropFile.add(onDropFile);

    dropHandlers.push(
      {
        component: component,
        handler: handler
      });
    #else
    trace('addDropHandler not implemented for this platform');
    #end
  }

  static function removeDropHandler(handler:String->Void):Void
  {
    #if desktop
    FlxG.stage.window.onDropFile.remove(handler);
    #end
  }

  static function clearDropHandlers():Void
  {
    #if desktop
    dropHandlers = [];
    FlxG.stage.window.onDropFile.remove(onDropFile);
    #end
  }

  static function onDropFile(path:String):Void
  {
    // a VERY short timer to wait for the mouse position to update
    new FlxTimer().start(0.01, function(_) {
      for (handler in dropHandlers)
      {
        if (handler.component.hitTest(FlxG.mouse.screenX, FlxG.mouse.screenY))
        {
          handler.handler(path);
          return;
        }
      }
    });
  }
}
