package funkin.ui.debug.charting;

import funkin.play.character.CharacterData;
import funkin.util.Constants;
import funkin.util.SerializerUtil;
import funkin.play.song.SongData.SongChartData;
import funkin.play.song.SongData.SongMetadata;
import flixel.util.FlxTimer;
import funkin.util.SortUtil;
import funkin.input.Cursor;
import funkin.play.character.BaseCharacter;
import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.song.Song;
import funkin.play.song.SongMigrator;
import funkin.play.song.SongValidator;
import funkin.play.song.SongData.SongDataParser;
import funkin.play.song.SongData.SongPlayableChar;
import funkin.play.song.SongData.SongTimeChange;
import funkin.util.FileUtil;
import haxe.io.Path;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Label;
import haxe.ui.components.Link;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.properties.PropertyGrid;
import haxe.ui.containers.properties.PropertyGroup;
import haxe.ui.containers.VBox;
import haxe.ui.core.Component;
import haxe.ui.events.UIEvent;
import haxe.ui.notifications.NotificationManager;
import haxe.ui.notifications.NotificationType;

using Lambda;

/**
 * Handles dialogs for the new Chart Editor.
 */
@:nullSafety
class ChartEditorDialogHandler
{
  static final CHART_EDITOR_DIALOG_ABOUT_LAYOUT:String = Paths.ui('chart-editor/dialogs/about');
  static final CHART_EDITOR_DIALOG_WELCOME_LAYOUT:String = Paths.ui('chart-editor/dialogs/welcome');
  static final CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-inst');
  static final CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT:String = Paths.ui('chart-editor/dialogs/song-metadata');
  static final CHART_EDITOR_DIALOG_SONG_METADATA_CHARGROUP_LAYOUT:String = Paths.ui('chart-editor/dialogs/song-metadata-chargroup');
  static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-vocals');
  static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_ENTRY_LAYOUT:String = Paths.ui('chart-editor/dialogs/upload-vocals-entry');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart');
  static final CHART_EDITOR_DIALOG_OPEN_CHART_ENTRY_LAYOUT:String = Paths.ui('chart-editor/dialogs/open-chart-entry');
  static final CHART_EDITOR_DIALOG_IMPORT_CHART_LAYOUT:String = Paths.ui('chart-editor/dialogs/import-chart');
  static final CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT:String = Paths.ui('chart-editor/dialogs/user-guide');

  /**
   * Builds and opens a dialog giving brief credits for the chart editor.
   * @param state The current chart editor state.
   * @return The dialog that was opened.
   */
  public static inline function openAboutDialog(state:ChartEditorState):Null<Dialog>
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

    // Add handlers to the "Create From Song" section.
    var linkCreateBasic:Null<Link> = dialog.findComponent('splashCreateFromSongBasic', Link);
    if (linkCreateBasic == null) throw 'Could not locate splashCreateFromSongBasic link in Welcome dialog';
    linkCreateBasic.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);

      //
      // Create Song Wizard
      //
      openCreateSongWizard(state, false);
    }

    var linkImportChartLegacy:Null<Link> = dialog.findComponent('splashImportChartLegacy', Link);
    if (linkImportChartLegacy == null) throw 'Could not locate splashImportChartLegacy link in Welcome dialog';
    linkImportChartLegacy.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);

      // Open the "Import Chart" dialog
      openImportChartWizard(state, 'legacy', false);
    };

    var buttonBrowse:Null<Button> = dialog.findComponent('splashBrowse', Button);
    if (buttonBrowse == null) throw 'Could not locate splashBrowse button in Welcome dialog';
    buttonBrowse.onClick = function(_event) {
      // Hide the welcome dialog
      dialog.hideDialog(DialogButton.CANCEL);

      // Open the "Open Chart" dialog
      openBrowseWizard(state, false);
    }

    var splashTemplateContainer:Null<VBox> = dialog.findComponent('splashTemplateContainer', VBox);
    if (splashTemplateContainer == null) throw 'Could not locate splashTemplateContainer in Welcome dialog';

    var songList:Array<String> = SongDataParser.listSongIds();
    songList.sort(SortUtil.alphabetically);

    for (targetSongId in songList)
    {
      var songData:Null<Song> = SongDataParser.fetchSong(targetSongId);

      if (songData == null) continue;

      var diffNormal:Null<SongDifficulty> = songData.getDifficulty('normal');
      var songName:Null<String> = diffNormal?.songName;
      if (songName == null)
      {
        var diffDefault:Null<SongDifficulty> = songData.getDifficulty();
        songName = diffDefault?.songName;
      }
      if (songName == null)
      {
        trace('[WARN] Could not fetch song name for ${targetSongId}');
        continue;
      }

      var linkTemplateSong:Link = new Link();
      linkTemplateSong.text = songName;
      linkTemplateSong.onClick = function(_event) {
        dialog.hideDialog(DialogButton.CANCEL);

        // Load song from template
        state.loadSongAsTemplate(targetSongId);
      }

      splashTemplateContainer.addComponent(linkTemplateSong);
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

  public static function openCreateSongWizard(state:ChartEditorState, closable:Bool):Void
  {
    // Step 1. Upload Instrumental
    var uploadInstDialog:Dialog = openUploadInstDialog(state, closable);
    uploadInstDialog.onDialogClosed = function(_event) {
      state.isHaxeUIDialogOpen = false;
      if (_event.button == DialogButton.APPLY)
      {
        // Step 2. Song Metadata
        var songMetadataDialog:Dialog = openSongMetadataDialog(state);
        songMetadataDialog.onDialogClosed = function(_event) {
          state.isHaxeUIDialogOpen = false;
          if (_event.button == DialogButton.APPLY)
          {
            // Step 3. Upload Vocals
            // NOTE: Uploading vocals is optional, so we don't need to check if the user cancelled the wizard.
            openUploadVocalsDialog(state, false); // var uploadVocalsDialog:Dialog
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

    var onDropFile:String->Void;

    instrumentalBox.onClick = function(_event) {
      Dialogs.openBinaryFile('Open Instrumental', [
        {label: 'Audio File (.ogg)', extension: 'ogg'}], function(selectedFile:SelectedFileInfo) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            if (state.loadInstrumentalFromBytes(selectedFile.bytes))
            {
              trace('Selected file: ' + selectedFile.fullPath);
              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Success',
                  body: 'Loaded instrumental track (${selectedFile.name})',
                  type: NotificationType.Success,
                  expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
                });
              #end

              dialog.hideDialog(DialogButton.APPLY);
              removeDropHandler(onDropFile);
            }
            else
            {
              trace('Failed to load instrumental (${selectedFile.fullPath})');

              #if !mac
              NotificationManager.instance.addNotification(
                {
                  title: 'Failure',
                  body: 'Failed to load instrumental track (${selectedFile.name})',
                  type: NotificationType.Error,
                  expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
                });
              #end
            }
          }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped file (${path})');
      if (state.loadInstrumentalFromPath(path))
      {
        // Tell the user the load was successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Success',
            body: 'Loaded instrumental track (${path.file}.${path.ext})',
            type: NotificationType.Success,
            expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
          });
        #end

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
          'Failed to load instrumental track (${path.file}.${path.ext})';
        }

        // Tell the user the load was successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: message,
            type: NotificationType.Error,
            expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
          });
        #end
      }
    };

    addDropHandler(instrumentalBox, onDropFile);

    return dialog;
  }

  static var dropHandlers:Array<
    {
      component:Component,
      handler:(String->Void)
    }> = [];

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

  /**
   * Opens the dialog in the wizard where the user can set song metadata like name and artist and BPM.
   * @param state The ChartEditorState instance.
   * @return The dialog to open.
   */
  @:haxe.warning("-WVarInit")
  public static function openSongMetadataDialog(state:ChartEditorState):Dialog
  {
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT, true, false);
    if (dialog == null) throw 'Could not locate Song Metadata dialog';

    var buttonCancel:Null<Button> = dialog.findComponent('dialogCancel', Button);
    if (buttonCancel == null) throw 'Could not locate dialogCancel button in Song Metadata dialog';
    buttonCancel.onClick = function(_event) {
      dialog.hideDialog(DialogButton.CANCEL);
    }

    var dialogSongName:Null<TextField> = dialog.findComponent('dialogSongName', TextField);
    if (dialogSongName == null) throw 'Could not locate dialogSongName TextField in Song Metadata dialog';
    dialogSongName.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        dialogSongName.removeClass('invalid-value');
        state.currentSongMetadata.songName = event.target.text;
      }
      else
      {
        state.currentSongMetadata.songName = "";
      }
    };
    state.currentSongMetadata.songName = "";

    var dialogSongArtist:Null<TextField> = dialog.findComponent('dialogSongArtist', TextField);
    if (dialogSongArtist == null) throw 'Could not locate dialogSongArtist TextField in Song Metadata dialog';
    dialogSongArtist.onChange = function(event:UIEvent) {
      var valid:Bool = event.target.text != null && event.target.text != '';

      if (valid)
      {
        dialogSongArtist.removeClass('invalid-value');
        state.currentSongMetadata.artist = event.target.text;
      }
      else
      {
        state.currentSongMetadata.artist = "";
      }
    };
    state.currentSongMetadata.artist = "";

    var dialogStage:Null<DropDown> = dialog.findComponent('dialogStage', DropDown);
    if (dialogStage == null) throw 'Could not locate dialogStage DropDown in Song Metadata dialog';
    dialogStage.onChange = function(event:UIEvent) {
      if (event.data == null && event.data.id == null) return;
      state.currentSongMetadata.playData.stage = event.data.id;
    };
    state.currentSongMetadata.playData.stage = 'mainStage';

    var dialogNoteSkin:Null<DropDown> = dialog.findComponent('dialogNoteSkin', DropDown);
    if (dialogNoteSkin == null) throw 'Could not locate dialogNoteSkin DropDown in Song Metadata dialog';
    dialogNoteSkin.onChange = function(event:UIEvent) {
      if (event.data.id == null) return;
      state.currentSongMetadata.playData.noteSkin = event.data.id;
    };
    state.currentSongMetadata.playData.noteSkin = 'funkin';

    var dialogBPM:Null<NumberStepper> = dialog.findComponent('dialogBPM', NumberStepper);
    if (dialogBPM == null) throw 'Could not locate dialogBPM NumberStepper in Song Metadata dialog';
    dialogBPM.onChange = function(event:UIEvent) {
      if (event.value == null || event.value <= 0) return;

      var timeChanges:Array<SongTimeChange> = state.currentSongMetadata.timeChanges;
      if (timeChanges == null || timeChanges.length == 0)
      {
        timeChanges = [new SongTimeChange(-1, 0, event.value, 4, 4, [4, 4, 4, 4])];
      }
      else
      {
        timeChanges[0].bpm = event.value;
      }

      Conductor.forceBPM(event.value);

      state.currentSongMetadata.timeChanges = timeChanges;
    };

    var dialogCharGrid:Null<PropertyGrid> = dialog.findComponent('dialogCharGrid', PropertyGrid);
    if (dialogCharGrid == null) throw 'Could not locate dialogCharGrid PropertyGrid in Song Metadata dialog';
    var dialogCharAdd:Null<Button> = dialog.findComponent('dialogCharAdd', Button);
    if (dialogCharAdd == null) throw 'Could not locate dialogCharAdd Button in Song Metadata dialog';
    dialogCharAdd.onClick = function(event:UIEvent) {
      var charGroup:PropertyGroup;
      charGroup = buildCharGroup(state, null, () -> dialogCharGrid.removeComponent(charGroup));
      dialogCharGrid.addComponent(charGroup);
    };

    // Empty the character list.
    state.currentSongMetadata.playData.playableChars = {};
    // Add at least one character group with no Remove button.
    dialogCharGrid.addComponent(buildCharGroup(state, 'bf'));

    var dialogContinue:Null<Button> = dialog.findComponent('dialogContinue', Button);
    if (dialogContinue == null) throw 'Could not locate dialogContinue button in Song Metadata dialog';
    dialogContinue.onClick = (_event) -> dialog.hideDialog(DialogButton.APPLY);

    return dialog;
  }

  static function buildCharGroup(state:ChartEditorState, key:String = '', removeFunc:Void->Void = null):PropertyGroup
  {
    var groupKey:String = key;

    var getCharData:Void->SongPlayableChar = function() {
      if (groupKey == null) groupKey = 'newChar${state.currentSongMetadata.playData.playableChars.keys().count()}';

      var result = state.currentSongMetadata.playData.playableChars.get(groupKey);
      if (result == null)
      {
        result = new SongPlayableChar('', 'dad');
        state.currentSongMetadata.playData.playableChars.set(groupKey, result);
      }
      return result;
    }

    var moveCharGroup:String->Void = function(target:String) {
      var charData = getCharData();
      state.currentSongMetadata.playData.playableChars.remove(groupKey);
      state.currentSongMetadata.playData.playableChars.set(target, charData);
      groupKey = target;
    }

    var removeGroup:Void->Void = function() {
      state.currentSongMetadata.playData.playableChars.remove(groupKey);
      if (removeFunc != null) removeFunc();
    }

    var charData:SongPlayableChar = getCharData();

    var charGroup:PropertyGroup = cast state.buildComponent(CHART_EDITOR_DIALOG_SONG_METADATA_CHARGROUP_LAYOUT);

    var charGroupPlayer:Null<DropDown> = charGroup.findComponent('charGroupPlayer', DropDown);
    if (charGroupPlayer == null) throw 'Could not locate charGroupPlayer DropDown in Song Metadata dialog';
    charGroupPlayer.onChange = function(event:UIEvent) {
      charGroup.text = event.data.text;
      moveCharGroup(event.data.id);
    };

    var charGroupOpponent:Null<DropDown> = charGroup.findComponent('charGroupOpponent', DropDown);
    if (charGroupOpponent == null) throw 'Could not locate charGroupOpponent DropDown in Song Metadata dialog';
    charGroupOpponent.onChange = function(event:UIEvent) {
      charData.opponent = event.data.id;
    };
    charGroupOpponent.value = getCharData().opponent;

    var charGroupGirlfriend:Null<DropDown> = charGroup.findComponent('charGroupGirlfriend', DropDown);
    if (charGroupGirlfriend == null) throw 'Could not locate charGroupGirlfriend DropDown in Song Metadata dialog';
    charGroupGirlfriend.onChange = function(event:UIEvent) {
      charData.girlfriend = event.data.id;
    };
    charGroupGirlfriend.value = getCharData().girlfriend;

    var charGroupRemove:Null<Button> = charGroup.findComponent('charGroupRemove', Button);
    if (charGroupRemove == null) throw 'Could not locate charGroupRemove Button in Song Metadata dialog';
    charGroupRemove.onClick = function(event:UIEvent) {
      removeGroup();
    };

    if (removeFunc == null) charGroupRemove.hidden = true;

    return charGroup;
  }

  /**
   * Builds and opens a dialog where the user uploads vocals for the current song.
   * @param state The current chart editor state.
   * @param closable Whether the dialog can be closed by the user.
   * @return The dialog that was opened.
   */
  public static function openUploadVocalsDialog(state:ChartEditorState, closable:Bool = true):Dialog
  {
    var charIdsForVocals:Array<String> = [];

    for (charKey in state.currentSongMetadata.playData.playableChars.keys())
    {
      var charData:SongPlayableChar = state.currentSongMetadata.playData.playableChars.get(charKey);
      charIdsForVocals.push(charKey);
      if (charData.opponent != null) charIdsForVocals.push(charData.opponent);
    }

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
      vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';

      var onDropFile:String->Void = function(pathStr:String) {
        trace('Selected file: $pathStr');
        var path:Path = new Path(pathStr);

        if (state.loadVocalsFromPath(path, charKey))
        {
          // Tell the user the load was successful.
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: 'Loaded vocal track for $charName (${path.file}.${path.ext})',
              type: NotificationType.Success,
              expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
            });
          #end
          vocalsEntryLabel.text = 'Vocals for $charName (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
          dialogNoVocals.hidden = true;
          removeDropHandler(onDropFile);
        }
        else
        {
          var message:String = if (!ChartEditorState.SUPPORTED_MUSIC_FORMATS.contains(path.ext ?? ''))
          {
            'File format (${path.ext}) not supported for vocal track (${path.file}.${path.ext})';
          }
          else
          {
            'Failed to load vocal track (${path.file}.${path.ext})';
          }

          // Vocals failed to load.
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Failure',
              body: message,
              type: NotificationType.Error,
              expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
            });
          #end

          vocalsEntryLabel.text = 'Drag and drop vocals for $charName here, or click to browse.';
        }
      };

      vocalsEntry.onClick = function(_event) {
        Dialogs.openBinaryFile('Open $charName Vocals', [
          {label: 'Audio File (.ogg)', extension: 'ogg'}], function(selectedFile) {
            if (selectedFile != null && selectedFile.bytes != null)
            {
              trace('Selected file: ' + selectedFile.name);
              vocalsEntryLabel.text = 'Vocals for $charName (click to browse)\n${selectedFile.name}';
              state.loadVocalsFromBytes(selectedFile.bytes, charKey);
              dialogNoVocals.hidden = true;
              removeDropHandler(onDropFile);
            }
        });
      }

      // onDropFile
      addDropHandler(vocalsEntry, onDropFile);
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
    var dialog:Null<Dialog> = openDialog(state, CHART_EDITOR_DIALOG_OPEN_CHART_LAYOUT, true, closable);
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
      var songDefaultChartDataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_ENTRY_LAYOUT);
      var songDefaultChartDataEntryLabel:Null<Label> = songDefaultChartDataEntry.findComponent('chartEntryLabel', Label);
      if (songDefaultChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
      songDefaultChartDataEntryLabel.text = 'Drag and drop <song>-chart.json file, or click to browse.';

      songDefaultChartDataEntry.onClick = onClickChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel);
      addDropHandler(songDefaultChartDataEntry, onDropFileChartDataVariation.bind(Constants.DEFAULT_VARIATION).bind(songDefaultChartDataEntryLabel));
      chartContainerB.addComponent(songDefaultChartDataEntry);

      for (variation in variations)
      {
        // Build entries for -metadata-<variation>.json.
        var songVariationMetadataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_ENTRY_LAYOUT);
        var songVariationMetadataEntryLabel:Null<Label> = songVariationMetadataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationMetadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        songVariationMetadataEntryLabel.text = 'Drag and drop <song>-metadata-${variation}.json file, or click to browse.';

        songVariationMetadataEntry.onClick = onClickMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel);
        addDropHandler(songVariationMetadataEntry, onDropFileMetadataVariation.bind(variation).bind(songVariationMetadataEntryLabel));
        chartContainerB.addComponent(songVariationMetadataEntry);

        // Build entries for -chart-<variation>.json.
        var songVariationChartDataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_ENTRY_LAYOUT);
        var songVariationChartDataEntryLabel:Null<Label> = songVariationChartDataEntry.findComponent('chartEntryLabel', Label);
        if (songVariationChartDataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
        songVariationChartDataEntryLabel.text = 'Drag and drop <song>-chart-${variation}.json file, or click to browse.';

        songVariationChartDataEntry.onClick = onClickChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel);
        addDropHandler(songVariationChartDataEntry, onDropFileChartDataVariation.bind(variation).bind(songVariationChartDataEntryLabel));
        chartContainerB.addComponent(songVariationChartDataEntry);
      }
    }

    onDropFileMetadataVariation = function(variation:String, label:Label, pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped JSON file (${path})');

      var songMetadataJson:Dynamic = FileUtil.readJSONFromPath(path.toString());
      var songMetadataVariation:SongMetadata = SongMigrator.migrateSongMetadata(songMetadataJson, 'import');
      songMetadataVariation = SongValidator.validateSongMetadata(songMetadataVariation, 'import');

      if (songMetadataVariation == null)
      {
        // Tell the user the load was not successful.
        #if !mac
        NotificationManager.instance.addNotification(
          {
            title: 'Failure',
            body: 'Could not load metadata file (${path.file}.${path.ext})',
            type: NotificationType.Error,
            expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
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
          expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
        });
      #end

      label.text = 'Metadata file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';

      if (variation == Constants.DEFAULT_VARIATION) constructVariationEntries(songMetadataVariation.playData.songVariations);
    };

    onClickMetadataVariation = function(variation:String, label:Label, _event:UIEvent) {
      Dialogs.openBinaryFile('Open Chart ($variation) Metadata', [
        {label: 'JSON File (.json)', extension: 'json'}], function(selectedFile) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            trace('Selected file: ' + selectedFile.name);

            var songMetadataJson:Dynamic = SerializerUtil.fromJSONBytes(selectedFile.bytes);
            var songMetadataVariation:SongMetadata = SongMigrator.migrateSongMetadata(songMetadataJson, 'import');
            songMetadataVariation = SongValidator.validateSongMetadata(songMetadataVariation, 'import');
            songMetadataVariation.variation = variation;

            songMetadata.set(variation, songMetadataVariation);

            // Tell the user the load was successful.
            #if !mac
            NotificationManager.instance.addNotification(
              {
                title: 'Success',
                body: 'Loaded metadata file (${selectedFile.name})',
                type: NotificationType.Success,
                expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
              });
            #end

            label.text = 'Metadata file (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';

            if (variation == Constants.DEFAULT_VARIATION) constructVariationEntries(songMetadataVariation.playData.songVariations);
          }
      });
    }

    onDropFileChartDataVariation = function(variation:String, label:Label, pathStr:String) {
      var path:Path = new Path(pathStr);
      trace('Dropped JSON file (${path})');

      var songChartDataJson:Dynamic = FileUtil.readJSONFromPath(path.toString());
      var songChartDataVariation:SongChartData = SongMigrator.migrateSongChartData(songChartDataJson, 'import');
      songChartDataVariation = SongValidator.validateSongChartData(songChartDataVariation, 'import');

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
          expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
        });
      #end

      label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${path.file}.${path.ext}';
    };

    onClickChartDataVariation = function(variation:String, label:Label, _event:UIEvent) {
      Dialogs.openBinaryFile('Open Chart ($variation) Metadata', [
        {label: 'JSON File (.json)', extension: 'json'}], function(selectedFile) {
          if (selectedFile != null && selectedFile.bytes != null)
          {
            trace('Selected file: ' + selectedFile.name);

            var songChartDataJson:Dynamic = SerializerUtil.fromJSONBytes(selectedFile.bytes);
            var songChartDataVariation:SongChartData = SongMigrator.migrateSongChartData(songChartDataJson, 'import');
            songChartDataVariation = SongValidator.validateSongChartData(songChartDataVariation, 'import');

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
                expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
              });
            #end

            label.text = 'Chart data file (drag and drop, or click to browse)\nSelected file: ${selectedFile.name}';
          }
      });
    }

    var metadataEntry:Component = state.buildComponent(CHART_EDITOR_DIALOG_OPEN_CHART_ENTRY_LAYOUT);
    var metadataEntryLabel:Null<Label> = metadataEntry.findComponent('chartEntryLabel', Label);
    if (metadataEntryLabel == null) throw 'Could not locate chartEntryLabel in Open Chart dialog';
    metadataEntryLabel.text = 'Drag and drop <song>-metadata.json file, or click to browse.';

    metadataEntry.onClick = onClickMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel);
    addDropHandler(metadataEntry, onDropFileMetadataVariation.bind(Constants.DEFAULT_VARIATION).bind(metadataEntryLabel));

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

    buttonCancel.onClick = function(_event) {
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
          var selectedFileJson:Dynamic = SerializerUtil.fromJSONBytes(selectedFile.bytes);
          var songMetadata:SongMetadata = SongMigrator.migrateSongMetadataFromLegacy(selectedFileJson);
          var songChartData:SongChartData = SongMigrator.migrateSongChartDataFromLegacy(selectedFileJson);

          state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

          dialog.hideDialog(DialogButton.APPLY);
          #if !mac
          NotificationManager.instance.addNotification(
            {
              title: 'Success',
              body: 'Loaded chart file (${selectedFile.name})',
              type: NotificationType.Success,
              expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
            });
          #end
        }
      });
    }

    onDropFile = function(pathStr:String) {
      var path:Path = new Path(pathStr);
      var selectedFileJson:Dynamic = FileUtil.readJSONFromPath(path.toString());
      var songMetadata:SongMetadata = SongMigrator.migrateSongMetadataFromLegacy(selectedFileJson);
      var songChartData:SongChartData = SongMigrator.migrateSongChartDataFromLegacy(selectedFileJson);

      state.loadSong([Constants.DEFAULT_VARIATION => songMetadata], [Constants.DEFAULT_VARIATION => songChartData]);

      dialog.hideDialog(DialogButton.APPLY);
      #if !mac
      NotificationManager.instance.addNotification(
        {
          title: 'Success',
          body: 'Loaded chart file (${path.file}.${path.ext})',
          type: NotificationType.Success,
          expiryMs: ChartEditorState.NOTIFICATION_DISMISS_TIME
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
  public static inline function openUserGuideDialog(state:ChartEditorState):Null<Dialog>
  {
    return openDialog(state, CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT, true, true);
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
}
