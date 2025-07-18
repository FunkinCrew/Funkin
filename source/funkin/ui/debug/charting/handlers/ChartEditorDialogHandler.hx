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
import funkin.play.character.BaseCharacter.CharacterType;
import funkin.ui.debug.charting.dialogs.ChartEditorAboutDialog;
import funkin.ui.debug.charting.dialogs.ChartEditorBaseDialog.DialogDropTarget;
import funkin.ui.debug.charting.dialogs.ChartEditorCharacterIconSelectorMenu;
import funkin.ui.debug.charting.dialogs.ChartEditorUploadChartDialog;
import funkin.ui.debug.charting.dialogs.ChartEditorWelcomeDialog;
import funkin.ui.debug.charting.dialogs.ChartEditorUploadVocalsDialog;
import funkin.ui.debug.charting.util.ChartEditorDropdowns;
import funkin.util.Constants;
import funkin.util.DateUtil;
import funkin.util.FileUtil;
import funkin.util.VersionUtil;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.Slider;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialog.DialogButton;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.Form;
import haxe.ui.containers.menus.Menu;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.RuntimeComponentBuilder;
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
  static final CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-inst');
  static final CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT:String = Paths.ui('chart-editor/dialogs/song-metadata');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart-parts');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart-parts-entry');
  static final CHART_EDITOR_DIALOG_IMPORT_CHART_LAYOUT:String = Paths.ui('chart-editor/dialogs/import-chart');
  static final CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT:String = Paths.ui('chart-editor/dialogs/user-guide');
  static final CHART_EDITOR_DIALOG_ADD_VARIATION_LAYOUT:String = Paths.ui('chart-editor/dialogs/add-variation');
  static final CHART_EDITOR_DIALOG_ADD_DIFFICULTY_LAYOUT:String = Paths.ui('chart-editor/dialogs/add-difficulty');
  static final CHART_EDITOR_DIALOG_BACKUP_AVAILABLE_LAYOUT:String = Paths.ui('chart-editor/dialogs/backup-available');

  /**
   * Builds and opens a dialog giving brief credits for the chart editor.
   * @param state The current chart editor state.
   * @return The dialog that was opened.
   */
  public static function openAboutDialog(state:ChartEditorState):Null<Dialog>
  {
    var dialog = ChartEditorAboutDialog.build(state);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openWelcomeDialog(state:ChartEditorState, closable:Bool = true):Null<Dialog>
  {
    var dialog = ChartEditorWelcomeDialog.build(state, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    state.fadeInWelcomeMusic();

    return dialog;
  }

  /**
   * Builds and opens a dialog letting the user browse for a chart file to open.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openBrowseFNFC(state:ChartEditorState, closable:Bool):Null<Dialog>
  {
    var dialog = ChartEditorUploadChartDialog.build(state, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

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
    var charData:SongCharacterData = state.currentSongMetadata.playData.characters;

    var hasClearedVocals:Bool = false;

    var charIdsForVocals:Array<String> = [charData.player, charData.opponent];

    var dialog = ChartEditorUploadVocalsDialog.build(state, charIdsForVocals, closable);

    dialog.zIndex = 1000;
    state.isHaxeUIDialogOpen = true;

    return dialog;
  }

  /**
   * Builds and opens the dialog for selecting a character.
   */
  public static function openCharacterDropdown(state:ChartEditorState, charType:CharacterType, lockPosition:Bool = false):Null<Menu>
  {
    var menu = ChartEditorCharacterIconSelectorMenu.build(state, charType, lockPosition);

    menu.zIndex = 1000;

    return menu;
  }

  /**
   * Builds and opens a dialog letting the user know a backup is available, and prompting them to load it.
   */
  public static function openBackupAvailableDialog(state:ChartEditorState, welcomeDialog:Null<Dialog>):Null<Dialog>
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_BACKUP_AVAILABLE_LAYOUT, true, true);
    if (dialog == null) throw 'Could not locate Backup Available dialog';
    dialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // User loaded the backup! Close the welcome dialog behind this.
        if (welcomeDialog != null) welcomeDialog.hideDialog(DialogButton.APPLY);
      }
      else
      {
        // User cancelled the dialog, don't close the welcome dialog so we aren't in a broken state.
      }
    };

    state.isHaxeUIDialogOpen = true;

    var backupTimeLabel:Null<Label> = dialog.findComponent('backupTimeLabel', Label);
    if (backupTimeLabel == null) throw 'Could not locate backupTimeLabel button in Backup Available dialog';

    var latestBackupDate:Null<Date> = ChartEditorImportExportHandler.getLatestBackupDate();
    if (latestBackupDate != null)
    {
      var latestBackupDateStr:String = DateUtil.generateCleanTimestamp(latestBackupDate);
      backupTimeLabel.text = latestBackupDateStr;
    }

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Backup Available dialog';
    buttonCancel.onClick = function(_) {
      // Don't hide the welcome dialog behind this.
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var buttonGoToFolder:Null<Button> = dialog.findComponent('buttonGoToFolder', Button);
    if (buttonGoToFolder == null) throw 'Could not locate buttonGoToFolder button in Backup Available dialog';
    buttonGoToFolder.onClick = function(_) {
      state.openBackupsFolder();
      // Don't hide the welcome dialog behind this.
      // Don't close this dialog.
    }

    var buttonOpenBackup:Null<Button> = dialog.findComponent('buttonOpenBackup', Button);
    if (buttonOpenBackup == null) throw 'Could not locate buttonOpenBackup button in Backup Available dialog';
    buttonOpenBackup.onClick = function(_) {
      var latestBackupPath:Null<String> = ChartEditorImportExportHandler.getLatestBackupPath();

      var result:Null<Array<String>> = (latestBackupPath != null) ? state.loadFromFNFCPath(latestBackupPath) : null;
      if (result != null)
      {
        if (result.length == 0)
        {
          // No warnings.
          state.success('Loaded Chart', 'Loaded chart (${latestBackupPath})');
        }
        else
        {
          // One or more warnings.
          state.warning('Loaded Chart', 'Loaded chart (${latestBackupPath})\n${result.join("\n")}');
        }

        // Close the welcome dialog behind this.
        dialog.hideDialog(DialogButton.APPLY);
      }
      else
      {
        state.error('Failed to Load Chart', 'Failed to load chart (${latestBackupPath})');

        // Song failed to load, don't close the Welcome dialog so we aren't in a broken state.
        dialog.hideDialog(DialogButton.CANCEL);
      }
    }

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
    openChartDialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // Step 2. Upload instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(event) {
          state.isHaxeUIDialogOpen = false;
          if (event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(event) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // Built from parts, so no .fnfc to save to.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard! Back to the welcome dialog.
            state.openWelcomeDialog(closable);
          }
        };
      }
      else
      {
        // User cancelled the wizard! Back to the welcome dialog.
        state.openWelcomeDialog(closable);
      }
    };
  }

  public static function openImportChartWizard(state:ChartEditorState, format:String, closable:Bool):Void
  {
    // Open the "Open Chart" wizard
    // Step 1. Open Chart
    var openChartDialog:Null<Dialog> = openImportChartDialog(state, format);
    if (openChartDialog == null) throw 'Could not locate Import Chart dialog';
    openChartDialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // Step 2. Upload instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(event) {
          state.isHaxeUIDialogOpen = false;
          if (event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard! Back to the welcome dialog.
            state.openWelcomeDialog(closable);
          }
        };
      }
      else
      {
        // User cancelled the wizard! Back to the welcome dialog.
        state.openWelcomeDialog(closable);
      }
    };
  }

  public static function openCreateSongWizardBasicOnly(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, false, Constants.DEFAULT_VARIATION, true);
    songMetadataDialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(event) {
          state.isHaxeUIDialogOpen = false;
          if (event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            state.openWelcomeDialog(closable);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        state.openWelcomeDialog(closable);
      }
    };
  }

  public static function openCreateSongWizardErectOnly(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, true, Constants.DEFAULT_VARIATION, true);
    songMetadataDialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(event) {
          state.isHaxeUIDialogOpen = false;
          if (event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_) {
              state.isHaxeUIDialogOpen = false;
              state.currentWorkingFilePath = null; // New file, so no path.
              state.switchToCurrentInstrumental();
              state.postLoadInstrumental();
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            state.openWelcomeDialog(closable);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        state.openWelcomeDialog(closable);
      }
    };
  }

  public static function openCreateSongWizardBasicErect(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Song Metadata
    var songMetadataDialog:Dialog = openSongMetadataDialog(state, false, Constants.DEFAULT_VARIATION, true);
    songMetadataDialog.onDialogClosed = function(event) {
      state.isHaxeUIDialogOpen = false;
      if (event.button == DialogButton.APPLY)
      {
        // Step 2. Upload Instrumental
        var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
        uploadInstDialog.onDialogClosed = function(event) {
          state.isHaxeUIDialogOpen = false;
          if (event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            var uploadVocalsDialog:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
            uploadVocalsDialog.onDialogClosed = function(_) {
              state.switchToCurrentInstrumental();
              // Step 4. Song Metadata (Erect)
              var songMetadataDialogErect:Dialog = openSongMetadataDialog(state, true, 'erect', false);
              songMetadataDialogErect.onDialogClosed = function(event) {
                state.isHaxeUIDialogOpen = false;
                if (event.button == DialogButton.APPLY)
                {
                  // Switch to the Erect variation so uploading the instrumental applies properly.
                  state.selectedVariation = 'erect';

                  // Step 5. Upload Instrumental (Erect)
                  var uploadInstDialogErect:Dialog = openUploadInstDialog(state, closable);
                  uploadInstDialogErect.onDialogClosed = function(event) {
                    state.isHaxeUIDialogOpen = false;
                    if (event.button == DialogButton.APPLY)
                    {
                      // Step 6. Upload Vocals (Erect)
                      // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
                      var uploadVocalsDialogErect:Dialog = openUploadVocalsDialog(state, closable); // var uploadVocalsDialog:Dialog
                      uploadVocalsDialogErect.onDialogClosed = function(_) {
                        state.isHaxeUIDialogOpen = false;
                        state.currentWorkingFilePath = null; // New file, so no path.
                        state.switchToCurrentInstrumental();
                        state.postLoadInstrumental();
                      }
                    }
                    else
                    {
                      // User cancelled the wizard at Step 5! Back to the welcome dialog.
                      state.openWelcomeDialog(closable);
                    }
                  };
                }
                else
                {
                  // User cancelled the wizard at Step 4! Back to the welcome dialog.
                  state.openWelcomeDialog(closable);
                }
              }
            }
          }
          else
          {
            // User cancelled the wizard at Step 2! Back to the welcome dialog.
            state.openWelcomeDialog(closable);
          }
        };
      }
      else
      {
        // User cancelled the wizard at Step 1! Back to the welcome dialog.
        state.openWelcomeDialog(closable);
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

    buttonCancel.onClick = function(_) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var instrumentalBox:Null<Box> = dialog.findComponent('instrumentalBox', Box);
    if (instrumentalBox == null) throw 'Could not locate instrumentalBox in Upload Instrumental dialog';

    instrumentalBox.onMouseOver = function(_) {
      instrumentalBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }

    instrumentalBox.onMouseOut = function(_) {
      instrumentalBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    var instId:String = state.currentInstrumentalId;

    var dropHandler:DialogDropTarget = {component: instrumentalBox, handler: null};

    instrumentalBox.onClick = function(_) {
      Dialogs.openBinaryFile('Open Instrumental', [
        {label: 'Audio File (.ogg)', extension: 'ogg'}], function(selectedFile:SelectedFileInfo) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            if (state.loadInstFromBytes(selectedFile.bytes, instId))
            {
              state.success('Loaded Instrumental', 'Loaded instrumental track (${selectedFile.name}) for variation (${state.selectedVariation})');

              state.switchToCurrentInstrumental();
              dialog.hideDialog(DialogButton.APPLY);
              state.removeDropHandler(dropHandler);
            }
            else
            {
              state.error('Failed to Load Instrumental', 'Failed to load instrumental track (${selectedFile.name}) for variation (${state.selectedVariation})');
            }
          }
      });
    }

    var onDropFile:String->Void = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped file (${path})');
      if (state.loadInstFromPath(path, instId))
      {
        // Tell the user the load was successful.
        state.success('Loaded Instrumental', 'Loaded instrumental track (${path.file}.${path.ext}) for variation (${state.selectedVariation})');

        state.switchToCurrentInstrumental();
        dialog.hideDialog(DialogButton.APPLY);
        state.removeDropHandler(dropHandler);
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
        state.error('Failed to Load Instrumental', message);
      }
    };

    dropHandler.handler = onDropFile;

    state.addDropHandler(dropHandler);

    return dialog;
  }

  /**
   * Opens the dialog in the wizard where the user can set song metadata like name and artist and BPM.
   * @param state The ChartEditorState instance.
   * @param erect Whether to create erect difficulties or normal ones.
   * @param targetVariation The variation to create difficulties for.
   * @param clearExistingMetadata Whether to clear existing metadata when confirming.
   * @return The dialog to open.
   */
  @:haxe.warning("-WVarInit")
  public static function openSongMetadataDialog(state:ChartEditorState, erect:Bool, targetVariation:String, clearExistingMetadata:Bool):Dialog
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
    buttonCancel.onClick = function(_) {
      state.isHaxeUIDialogOpen = false;
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var newSongMetadata:SongMetadata = new SongMetadata('', '', '', Constants.DEFAULT_VARIATION);

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
      if (event.data == null || event.data?.id == null) return;
      newSongMetadata.playData.stage = event.data.id;
    };
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(inputStage, newSongMetadata.playData.stage);
    inputStage.value = startingValueStage;

    var inputNoteStyle:Null<DropDown> = dialog.findComponent('inputNoteStyle', DropDown);
    if (inputNoteStyle == null) throw 'Could not locate inputNoteStyle DropDown in Song Metadata dialog';
    inputNoteStyle.onChange = function(event:UIEvent) {
      if (event.data?.id == null) return;
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
    dialogContinue.onClick = (_) -> {
      if (clearExistingMetadata)
      {
        state.songMetadata.clear();
        state.songChartData.clear();
      }

      state.songMetadata.set(targetVariation, newSongMetadata);

      Conductor.instance.instrumentalOffset = state.currentInstrumentalOffset; // Loads from the metadata.
      Conductor.instance.mapTimeChanges(state.currentSongMetadata.timeChanges);
      state.updateTimeSignature();

      state.selectedVariation = Constants.DEFAULT_VARIATION;
      state.selectedDifficulty = state.availableDifficulties[0];

      state.difficultySelectDirty = true;

      dialog.hideDialog(DialogButton.APPLY);
    }

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
    buttonCancel.onClick = function(_) {
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
    buttonContinue.onClick = function(_) {
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
      var songDefaultChartDataEntry:Component = RuntimeComponentBuilder.fromAsset(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
      var songDefaultChartDataEntryLabel:Null<Label> = songDefaultChartDataEntry.findComponent('chartEntryLabel', Label);
      if (songDefaultChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
      #if FILE_DROP_SUPPORTED
      songDefaultChartDataEntryLabel.text = 'Drag and drop <song>-chart.json file, or click to browse.';
      #else
      songDefaultChartDataEntryLabel.text = 'Click to browse for <song>-chart.json file.';
      #end

      songDefaultChartDataEntry.onClick = onClickChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel);
      state.addDropHandler(
        {
          component: songDefaultChartDataEntry,
          handler: onDropFileChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel)
        });
      chartContainerB.addComponent(songDefaultChartDataEntry);

      for (variation in variations)
      {
        // Build entries for -metadata-<variation>.json.
        var songVariationMetadataEntry:Component = RuntimeComponentBuilder.fromAsset(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
        var songVariationMetadataEntryLabel:Null<Label> = songVariationMetadataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationMetadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        #if FILE_DROP_SUPPORTED
        songVariationMetadataEntryLabel.text = 'Drag and drop <song>-metadata-${variation}.json file, or click to browse.';
        #else
        songVariationMetadataEntryLabel.text = 'Click to browse for <song>-metadata-${variation}.json file.';
        #end

        songVariationMetadataEntry.onMouseOver = function(_) {
          songVariationMetadataEntry.swapClass('upload-bg', 'upload-bg-hover');
          Cursor.cursorMode = Pointer;
        }
        songVariationMetadataEntry.onMouseOut = function(_) {
          songVariationMetadataEntry.swapClass('upload-bg-hover', 'upload-bg');
          Cursor.cursorMode = Default;
        }
        songVariationMetadataEntry.onClick = onClickMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel);
        #if FILE_DROP_SUPPORTED
        state.addDropHandler(
          {
            component: songVariationMetadataEntry,
            handler: onDropFileMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel)
          });
        #end
        chartContainerB.addComponent(songVariationMetadataEntry);

        // Build entries for -chart-<variation>.json.
        var songVariationChartDataEntry:Component = RuntimeComponentBuilder.fromAsset(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
        var songVariationChartDataEntryLabel:Null<Label> = songVariationChartDataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        #if FILE_DROP_SUPPORTED
        songVariationChartDataEntryLabel.text = 'Drag and drop <song>-chart-${variation}.json file, or click to browse.';
        #else
        songVariationChartDataEntryLabel.text = 'Click to browse for <song>-chart-${variation}.json file.';
        #end

        songVariationChartDataEntry.onMouseOver = function(_) {
          songVariationChartDataEntry.swapClass('upload-bg', 'upload-bg-hover');
          Cursor.cursorMode = Pointer;
        }
        songVariationChartDataEntry.onMouseOut = function(_) {
          songVariationChartDataEntry.swapClass('upload-bg-hover', 'upload-bg');
          Cursor.cursorMode = Default;
        }
        songVariationChartDataEntry.onClick = onClickChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel);
        #if FILE_DROP_SUPPORTED
        state.addDropHandler(
          {
            component: songVariationChartDataEntry,
            handler: onDropFileChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel)
          });
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
        state.error('Failure', 'Could not parse metadata file version (${path.file}.${path.ext})');
        return;
      }

      var songMetadataVariation:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(songMetadataTxt, path.toString(),
        songMetadataVersion);

      if (songMetadataVariation == null)
      {
        // Tell the user the load was not successful.
        state.error('Failure', 'Could not load metadata file (${path.file}.${path.ext})');
        return;
      }

      songMetadata.set(variation, songMetadataVariation);

      // Tell the user the load was successful.
      state.success('Loaded Metadata', 'Loaded metadata file (${path.file}.${path.ext})');

      #if FILE_DROP_SUPPORTED
      label.text = 'Metadata file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
      #else
      label.text = 'Metadata file (click to browse)\n${path.file}.${path.ext}';
      #end

      if (variation == Constants.DEFAULT_VARIATION) constructVariationEntries(songMetadataVariation.playData.songVariations);
    };

    onClickMetadataVariation = function(variation:String, label:Label, _:UIEvent) {
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
              state.error('Failure', 'Could not parse metadata file version (${selectedFile.name})');
              return;
            }

            var songMetadataVariation:Null<SongMetadata> = SongRegistry.instance.parseEntryMetadataRawWithMigration(songMetadataTxt, selectedFile.name,
              songMetadataVersion);

            if (songMetadataVariation != null)
            {
              songMetadata.set(variation, songMetadataVariation);

              // Tell the user the load was successful.
              state.success('Loaded Metadata', 'Loaded metadata file (${selectedFile.name})');

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
              state.error('Failure', 'Failed to load metadata file (${selectedFile.name})');
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
        state.error('Failure', 'Could not parse chart data file version (${path.file}.${path.ext})');
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
        state.success('Loaded Chart Data', 'Loaded chart data file (${path.file}.${path.ext})');

        #if FILE_DROP_SUPPORTED
        label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
        #else
        label.text = 'Chart data file (click to browse)\n${path.file}.${path.ext}';
        #end
      }
      else
      {
        // Tell the user the load was unsuccessful.
        state.error('Failure', 'Failed to load chart data file (${path.file}.${path.ext})');
      }
    };

    onClickChartDataVariation = function(variation:String, label:Label, _:UIEvent) {
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
              state.error('Failure', 'Could not parse chart data file version (${selectedFile.name})');
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
              state.success('Loaded Chart Data', 'Loaded chart data file (${selectedFile.name})');

              #if FILE_DROP_SUPPORTED
              label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
              #else
              label.text = 'Chart data file (click to browse)\n${selectedFile.name}';
              #end
            }
          }
      });
    }

    var metadataEntry:Component = RuntimeComponentBuilder.fromAsset(CHART_EDITOR_DIALOG_OPEN_CHART_PARTS_ENTRY_LAYOUT);
    var metadataEntryLabel:Null<Label> = metadataEntry.findComponent('chartEntryLabel', Label);
    if (metadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';

    #if FILE_DROP_SUPPORTED
    metadataEntryLabel.text = 'Drag and drop <song>-metadata.json file, or click to browse.';
    #else
    metadataEntryLabel.text = 'Click to browse for <song>-metadata.json file.';
    #end

    metadataEntry.onClick = onClickMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel);
    state.addDropHandler({component: metadataEntry, handler: onDropFileMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel)});
    metadataEntry.onMouseOver = function(_event) {
      metadataEntry.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }
    metadataEntry.onMouseOut = function(_) {
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
      case 'legacy':
        // TODO / BUG: File filtering not working on mac finder dialog, so we don't use it for now
        #if !mac
        [
          {label: 'JSON Data File (.json)', extension: 'json'}];
        #else
        [];
        #end
      default: null;
    }

    dialog.title = 'Import Chart - ${prettyFormat}';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Import Chart dialog';

    state.isHaxeUIDialogOpen = true;
    buttonCancel.onClick = function(_) {
      state.isHaxeUIDialogOpen = false;
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var importBox:Null<Box> = dialog.findComponent('importBox', Box);
    if (importBox == null) throw 'Could not locate importBox in Import Chart dialog';

    importBox.onMouseOver = function(_) {
      importBox.swapClass('upload-bg', 'upload-bg-hover');
      Cursor.cursorMode = Pointer;
    }
    importBox.onMouseOut = function(_) {
      importBox.swapClass('upload-bg-hover', 'upload-bg');
      Cursor.cursorMode = Default;
    }

    var onDropFile:String->Void;

    importBox.onClick = function(_) {
      Dialogs.openBinaryFile('Import Chart - ${prettyFormat}', fileFilter ?? [], function(selectedFile:SelectedFileInfo) {
        if (selectedFile != null && selectedFile.bytes != null)
        {
          trace('Selected file: ' + selectedFile.fullPath);
          var selectedFileTxt:String = selectedFile.bytes.toString();
          var fnfLegacyData:Null<FNFLegacyData> = FNFLegacyImporter.parseLegacyDataRaw(selectedFileTxt, selectedFile.fullPath);

          if (fnfLegacyData == null)
          {
            state.error('Failure', 'Failed to parse FNF chart file (${selectedFile.name})');
            return;
          }

          var songMetadata:SongMetadata = FNFLegacyImporter.migrateMetadata(fnfLegacyData);
          var songChartData:SongChartData = FNFLegacyImporter.migrateChartData(fnfLegacyData);

          state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

          dialog.hideDialog(DialogButton.APPLY);
          state.success('Success', 'Loaded chart file (${selectedFile.name})');
        }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      var selectedFileText:String = FileUtil.readStringFromPath(path.toString());
      var selectedFileData:Null<FNFLegacyData> = FNFLegacyImporter.parseLegacyDataRaw(selectedFileText, path.toString());

      if (selectedFileData == null)
      {
        state.error('Failure', 'Failed to parse FNF chart file (${path.file}.${path.ext})');
        return;
      }

      var songMetadata:SongMetadata = FNFLegacyImporter.migrateMetadata(selectedFileData);
      var songChartData:SongChartData = FNFLegacyImporter.migrateChartData(selectedFileData);

      state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

      dialog.hideDialog(DialogButton.APPLY);
      state.success('Success', 'Loaded chart file (${path.file}.${path.ext})');
    };

    state.addDropHandler({component: importBox, handler: onDropFile});

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
    buttonCancel.onClick = function(_) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var buttonAdd:Null<Button> = dialog.findComponent('dialogAdd', Button);
    if (buttonAdd == null) throw 'Could not locate dialogAdd button in Add Variation dialog';
    buttonAdd.onClick = function(_) {
      // This performs validation before the onSubmit callback is called.
      variationForm.submit();
    }

    var dialogSongName:Null<TextField> = dialog.findComponent('dialogSongName', TextField);
    if (dialogSongName == null) throw 'Could not locate dialogSongName TextField in Add Variation dialog';
    dialogSongName.value = state.currentSongMetadata.songName;

    var dialogSongArtist:Null<TextField> = dialog.findComponent('dialogSongArtist', TextField);
    if (dialogSongArtist == null) throw 'Could not locate dialogSongArtist TextField in Add Variation dialog';
    dialogSongArtist.value = state.currentSongMetadata.artist;

    var dialogSongCharter:Null<TextField> = dialog.findComponent('dialogSongCharter', TextField);
    if (dialogSongCharter == null) throw 'Could not locate dialogSongCharter TextField in Add Variation dialog';
    dialogSongCharter.value = state.currentSongMetadata.charter;

    var dialogStage:Null<DropDown> = dialog.findComponent('dialogStage', DropDown);
    if (dialogStage == null) throw 'Could not locate dialogStage DropDown in Add Variation dialog';
    var startingValueStage = ChartEditorDropdowns.populateDropdownWithStages(dialogStage, state.currentSongMetadata.playData.stage);
    dialogStage.value = startingValueStage;

    var dialogNoteStyle:Null<DropDown> = dialog.findComponent('dialogNoteStyle', DropDown);
    if (dialogNoteStyle == null) throw 'Could not locate dialogNoteStyle DropDown in Add Variation dialog';
    var startingValueNoteStyle = ChartEditorDropdowns.populateDropdownWithNoteStyles(dialogNoteStyle, state.currentSongMetadata.playData.noteStyle);
    dialogNoteStyle.value = startingValueNoteStyle;

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
    var currentStartingBPM:Float = state.currentSongMetadata.timeChanges[0].bpm;
    dialogBPM.value = currentStartingBPM;

    // If all validators succeeded, this callback is called.

    state.isHaxeUIDialogOpen = true;
    variationForm.onSubmit = function(_) {
      state.isHaxeUIDialogOpen = false;
      trace('Add Variation dialog submitted, validation succeeded!');

      var dialogVariationName:Null<TextField> = dialog.findComponent('dialogVariationName', TextField);
      if (dialogVariationName == null) throw 'Could not locate dialogVariationName TextField in Add Variation dialog';

      var pendingVariation:SongMetadata = new SongMetadata(dialogSongName.text, dialogSongArtist.text, dialogSongCharter.text,
        dialogVariationName.text.toLowerCase());

      pendingVariation.playData.stage = dialogStage.value.id;
      pendingVariation.playData.noteStyle = dialogNoteStyle.value.id;
      pendingVariation.timeChanges[0].bpm = dialogBPM.value;

      state.songMetadata.set(pendingVariation.variation, pendingVariation);
      state.difficultySelectDirty = true; // Force the Difficulty toolbox to update.

      // Don't update conductor since we haven't switched to the new variation yet.

      state.success('Add Variation', 'Added new variation "${pendingVariation.variation}"');

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
    buttonCancel.onClick = function(_) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var buttonAdd:Null<Button> = dialog.findComponent('dialogAdd', Button);
    if (buttonAdd == null) throw 'Could not locate dialogAdd button in Add Difficulty dialog';
    buttonAdd.onClick = function(_) {
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

    difficultyForm.onSubmit = function(_) {
      trace('Add Difficulty dialog submitted, validation succeeded!');

      var dialogDifficultyName:Null<TextField> = dialog.findComponent('dialogDifficultyName', TextField);
      if (dialogDifficultyName == null) throw 'Could not locate dialogDifficultyName TextField in Add Difficulty dialog';

      state.createDifficulty(dialogVariation.value.id, dialogDifficultyName.text.toLowerCase(), inputScrollSpeed.value ?? 1.0);

      state.success('Add Difficulty', 'Added new difficulty "${dialogDifficultyName.text.toLowerCase()}"');

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
    var dialog:Null<Dialog> = cast RuntimeComponentBuilder.fromAsset(key);
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

  // ===============
  //  DROP HANDLERS
  // ===============
  static var dropHandlers:Array<DialogDropTarget> = [];

  /**
   * Add a callback for when a file is dropped on a component.
   *
   * On OS X you can’t drop on the application window, but rather only the app icon
   * (either in the dock while running or the icon on the hard drive) so this must be disabled
   * and UI updated appropriately.
   */
  public static function addDropHandler(state:ChartEditorState, dropTarget:DialogDropTarget):Void
  {
    #if desktop
    if (!FlxG.stage.window.onDropFile.has(onDropFile)) FlxG.stage.window.onDropFile.add(onDropFile);

    dropHandlers.push(dropTarget);
    #else
    trace('addDropHandler not implemented for this platform');
    #end
  }

  /**
   * Remove a callback for when a file is dropped on a component.
   */
  public static function removeDropHandler(state:ChartEditorState, dropTarget:DialogDropTarget):Void
  {
    #if desktop
    dropHandlers.remove(dropTarget);
    #end
  }

  /**
   * Clear ALL drop handlers, including the core handler.
   * Call this only when leaving the chart editor entirely.
   */
  public static function clearDropHandlers(state:ChartEditorState):Void
  {
    #if desktop
    dropHandlers = [];
    FlxG.stage.window.onDropFile.remove(onDropFile);
    #end
  }

  static final EPSILON:Float = 0.01;

  static function onDropFile(path:String):Void
  {
    // a VERY short timer to wait for the mouse position to update
    new FlxTimer().start(EPSILON, function(_) {
      for (handler in dropHandlers)
      {
        if (handler.component.hitTest(FlxG.mouse.viewX, FlxG.mouse.viewY))
        {
          handler.handler(path);
          return;
        }
      }
    });
  }
}
