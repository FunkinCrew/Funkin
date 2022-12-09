package funkin.ui.debug.charting;

import funkin.play.character.CharacterData.CharacterDataParser;
import funkin.play.character.BaseCharacter;
import haxe.ui.components.Label;
import haxe.ui.events.MouseEvent;
import funkin.play.song.SongData.SongPlayableChar;
import flixel.FlxSprite;
import flixel.util.FlxTimer;
import funkin.input.Cursor;
import funkin.play.song.SongData.SongTimeChange;
import haxe.ui.components.Button;
import haxe.ui.components.DropDown;
import haxe.ui.components.Image;
import haxe.ui.components.Link;
import haxe.ui.components.NumberStepper;
import haxe.ui.components.TextField;
import haxe.ui.containers.Box;
import haxe.ui.containers.dialogs.Dialog;
import haxe.ui.containers.dialogs.Dialogs;
import haxe.ui.containers.properties.Property;
import haxe.ui.containers.properties.PropertyGrid;
import haxe.ui.containers.properties.PropertyGroup;
import haxe.ui.containers.VBox;
import haxe.ui.events.UIEvent;

using Lambda;

class ChartEditorDialogHandler
{
	static final CHART_EDITOR_DIALOG_ABOUT_LAYOUT = Paths.ui('chart-editor/dialogs/about');
	static final CHART_EDITOR_DIALOG_WELCOME_LAYOUT = Paths.ui('chart-editor/dialogs/welcome');
	static final CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT = Paths.ui('chart-editor/dialogs/upload-inst');
	static final CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT = Paths.ui('chart-editor/dialogs/song-metadata');
	static final CHART_EDITOR_DIALOG_SONG_METADATA_CHARGROUP_LAYOUT = Paths.ui('chart-editor/dialogs/song-metadata-chargroup');
	static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_LAYOUT = Paths.ui('chart-editor/dialogs/upload-vocals');
	static final CHART_EDITOR_DIALOG_UPLOAD_VOCALS_ENTRY_LAYOUT = Paths.ui('chart-editor/dialogs/upload-vocals-entry');
	static final CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT = Paths.ui('chart-editor/dialogs/user-guide');

	/**
	 * 
	 */
	public static inline function openAboutDialog(state:ChartEditorState):Dialog
	{
		return openDialog(state, CHART_EDITOR_DIALOG_ABOUT_LAYOUT, true, true);
	}

	/**
	 * Builds and opens a dialog letting the user create a new chart, open a recent chart, or load from a template.
	 */
	public static function openWelcomeDialog(state:ChartEditorState, closable:Bool = true):Dialog
	{
		var dialog:Dialog = openDialog(state, CHART_EDITOR_DIALOG_WELCOME_LAYOUT, true, closable);

		// TODO: Add callbacks to the dialog buttons

		// Switch the graphic for frames.
		var bfSpritePlaceholder:Image = dialog.findComponent('bfSprite', Image);

		// TODO: Replace this bullshit with a custom HaxeUI component that loads the sprite from the game's assets.

		if (bfSpritePlaceholder != null)
		{
			var bfSprite:FlxSprite = new FlxSprite(0, 0);

			bfSprite.visible = false;

			var frames = Paths.getSparrowAtlas(bfSpritePlaceholder.resource);
			bfSprite.frames = frames;

			bfSprite.animation.addByPrefix('idle', 'Boyfriend DJ0', 24, true);
			bfSprite.animation.play('idle');

			bfSpritePlaceholder.rootComponent.add(bfSprite);
			bfSpritePlaceholder.visible = false;

			new FlxTimer().start(0.10, (_timer:FlxTimer) ->
			{
				bfSprite.x = bfSpritePlaceholder.screenLeft;
				bfSprite.y = bfSpritePlaceholder.screenTop;
				bfSprite.setGraphicSize(Std.int(bfSpritePlaceholder.width), Std.int(bfSpritePlaceholder.height));
				bfSprite.visible = true;
			});
		}

		// Add handlers to the "Create From Song" section.
		var linkCreateBasic:Link = dialog.findComponent('splashCreateFromSongBasic', Link);
		linkCreateBasic.onClick = (_event) ->
		{
			dialog.hideDialog(DialogButton.CANCEL);

			// Create song wizard
			var uploadInstDialog = openUploadInstDialog(state, false);
			uploadInstDialog.onDialogClosed = (_event) ->
			{
				state.isHaxeUIDialogOpen = false;
				if (_event.button == DialogButton.APPLY)
				{
					var songMetadataDialog = openSongMetadataDialog(state);
					songMetadataDialog.onDialogClosed = (_event) ->
					{
						state.isHaxeUIDialogOpen = false;
						if (_event.button == DialogButton.APPLY)
						{
							var uploadVocalsDialog = openUploadVocalsDialog(state);
						}
					};
				}
			};
		}

		// TODO: Get the list of songs and insert them as links into the "Create From Song" section.
		var linkTemplateDadBattle:Link = dialog.findComponent('splashTemplateDadBattle', Link);
		linkTemplateDadBattle.onClick = (_event) ->
		{
			dialog.hideDialog(DialogButton.CANCEL);

			// Load song from template
			state.loadSongAsTemplate('dadbattle');
		}
		var linkTemplateBopeebo:Link = dialog.findComponent('splashTemplateBopeebo', Link);
		linkTemplateBopeebo.onClick = (_event) ->
		{
			dialog.hideDialog(DialogButton.CANCEL);

			// Load song from template
			state.loadSongAsTemplate('bopeebo');
		}

		var splashTemplateContainer:VBox = dialog.findComponent('splashTemplateContainer', VBox);

		return dialog;
	}

	public static function openUploadInstDialog(state:ChartEditorState, ?closable:Bool = true):Dialog
	{
		var dialog:Dialog = openDialog(state, CHART_EDITOR_DIALOG_UPLOAD_INST_LAYOUT, true, closable);

		var instrumentalBox:Box = dialog.findComponent('instrumentalBox', Box);

		instrumentalBox.onMouseOver = (_event) ->
		{
			instrumentalBox.swapClass('upload-bg', 'upload-bg-hover');
			Cursor.cursorMode = Pointer;
		}

		instrumentalBox.onMouseOut = (_event) ->
		{
			instrumentalBox.swapClass('upload-bg-hover', 'upload-bg');
			Cursor.cursorMode = Default;
		}

		var onDropFile:String->Void;

		instrumentalBox.onClick = (_event) ->
		{
			Dialogs.openBinaryFile("Open Instrumental", [{label: "Audio File (.ogg)", extension: "ogg"}], function(selectedFile)
			{
				if (selectedFile != null)
				{
					trace('Selected file: ' + selectedFile);
					state.loadInstrumentalFromBytes(selectedFile.bytes);
					dialog.hideDialog(DialogButton.APPLY);
					removeDropHandler(onDropFile);
				}
			});
		}

		onDropFile = (path:String) ->
		{
			trace('Dropped file: ' + path);
			state.loadInstrumentalFromPath(path);
			dialog.hideDialog(DialogButton.APPLY);
			removeDropHandler(onDropFile);
		};

		addDropHandler(onDropFile);

		return dialog;
	}

	static function addDropHandler(handler:String->Void)
	{
		#if desktop
		FlxG.stage.window.onDropFile.add(handler);
		#else
		trace('addDropHandler not implemented for this platform');
		#end
	}

	static function removeDropHandler(handler:String->Void)
	{
		#if desktop
		FlxG.stage.window.onDropFile.remove(handler);
		#end
	}

	public static function openSongMetadataDialog(state:ChartEditorState):Dialog
	{
		var dialog:Dialog = openDialog(state, CHART_EDITOR_DIALOG_SONG_METADATA_LAYOUT, true, false);

		var dialogSongName:TextField = dialog.findComponent('dialogSongName', TextField);
		dialogSongName.onChange = (event:UIEvent) ->
		{
			var valid = event.target.text != null && event.target.text != "";

			if (valid)
			{
				dialogSongName.removeClass('invalid-value');
				state.currentSongMetadata.songName = event.target.text;
			}
			else
			{
				state.currentSongMetadata.songName = null;
			}
		};
		state.currentSongMetadata.songName = null;

		var dialogSongArtist:TextField = dialog.findComponent('dialogSongArtist', TextField);
		dialogSongArtist.onChange = (event:UIEvent) ->
		{
			var valid = event.target.text != null && event.target.text != "";

			if (valid)
			{
				dialogSongArtist.removeClass('invalid-value');
				state.currentSongMetadata.artist = event.target.text;
			}
			else
			{
				state.currentSongMetadata.artist = null;
			}
		};
		state.currentSongMetadata.artist = null;

		var dialogStage:DropDown = dialog.findComponent('dialogStage', DropDown);
		dialogStage.onChange = (event:UIEvent) ->
		{
			var valid = event.data != null && event.data.id != null;

			if (event.data.id == null)
				return;
			state.currentSongMetadata.playData.stage = event.data.id;
		};
		state.currentSongMetadata.playData.stage = null;

		var dialogNoteSkin:DropDown = dialog.findComponent('dialogNoteSkin', DropDown);
		dialogNoteSkin.onChange = (event:UIEvent) ->
		{
			if (event.data.id == null)
				return;
			state.currentSongMetadata.playData.noteSkin = event.data.id;
		};
		state.currentSongMetadata.playData.noteSkin = null;

		var dialogBPM:NumberStepper = dialog.findComponent('dialogBPM', NumberStepper);
		dialogBPM.onChange = (event:UIEvent) ->
		{
			if (event.value == null || event.value <= 0)
				return;

			var timeChanges = state.currentSongMetadata.timeChanges;
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

		var dialogCharGrid:PropertyGrid = dialog.findComponent('dialogCharGrid', PropertyGrid);
		var dialogCharAdd:Button = dialog.findComponent('dialogCharAdd', Button);
		dialogCharAdd.onClick = (_event) ->
		{
			var charGroup:PropertyGroup;
			charGroup = buildCharGroup(state, null, () ->
			{
				dialogCharGrid.removeComponent(charGroup);
			});
			dialogCharGrid.addComponent(charGroup);
		};

		// Empty the character list.
		state.currentSongMetadata.playData.playableChars = {};
		// Add at least one character group with no Remove button.
		dialogCharGrid.addComponent(buildCharGroup(state, 'bf', null));

		var dialogContinue:Button = dialog.findComponent('dialogContinue', Button);
		dialogContinue.onClick = (_event) ->
		{
			dialog.hideDialog(DialogButton.APPLY);
		};

		return dialog;
	}

	static function buildCharGroup(state:ChartEditorState, ?key:String = null, removeFunc:Void->Void):PropertyGroup
	{
		var groupKey = key;

		var getCharData = () ->
		{
			if (groupKey == null)
				groupKey = 'newChar${state.currentSongMetadata.playData.playableChars.keys().count()}';

			var result = state.currentSongMetadata.playData.playableChars.get(groupKey);
			if (result == null)
			{
				result = new SongPlayableChar('', 'dad');
				state.currentSongMetadata.playData.playableChars.set(groupKey, result);
			}
			return result;
		}

		var moveCharGroup = (target:String) ->
		{
			var charData = getCharData();
			state.currentSongMetadata.playData.playableChars.remove(groupKey);
			state.currentSongMetadata.playData.playableChars.set(target, charData);
			groupKey = target;
		}

		var removeGroup = () ->
		{
			state.currentSongMetadata.playData.playableChars.remove(groupKey);
			removeFunc();
		}

		var charData = getCharData();

		var charGroup:PropertyGroup = cast state.buildComponent(CHART_EDITOR_DIALOG_SONG_METADATA_CHARGROUP_LAYOUT);

		var charGroupPlayer:DropDown = charGroup.findComponent('charGroupPlayer', DropDown);
		charGroupPlayer.onChange = (event:UIEvent) ->
		{
			charGroup.text = event.data.text;
			moveCharGroup(event.data.id);
		};

		if (key == null)
		{
			// Find the next available player character.
			trace(charGroupPlayer.dataSource.data);
		}

		var charGroupOpponent:DropDown = charGroup.findComponent('charGroupOpponent', DropDown);
		charGroupOpponent.onChange = (event:UIEvent) ->
		{
			charData.opponent = event.data.id;
		};
		charGroupOpponent.value = getCharData().opponent;

		var charGroupGirlfriend:DropDown = charGroup.findComponent('charGroupGirlfriend', DropDown);
		charGroupGirlfriend.onChange = (event:UIEvent) ->
		{
			charData.girlfriend = event.data.id;
		};
		charGroupGirlfriend.value = getCharData().girlfriend;

		var charGroupRemove:Button = charGroup.findComponent('charGroupRemove', Button);
		charGroupRemove.onClick = (_event:MouseEvent) ->
		{
			removeGroup();
		};

		if (removeFunc == null)
			charGroupRemove.hidden = true;

		return charGroup;
	}

	public static function openUploadVocalsDialog(state:ChartEditorState, ?closable:Bool = true):Dialog
	{
		var charIdsForVocals = [];

		for (charKey in state.currentSongMetadata.playData.playableChars.keys())
		{
			var charData = state.currentSongMetadata.playData.playableChars.get(charKey);
			charIdsForVocals.push(charKey);
			if (charData.opponent != null)
				charIdsForVocals.push(charData.opponent);
		}

		var dialog:Dialog = openDialog(state, CHART_EDITOR_DIALOG_UPLOAD_VOCALS_LAYOUT, true, closable);

		var dialogContainer = dialog.findComponent('vocalContainer');

		var onDropFile:String->Void;

		for (charKey in charIdsForVocals)
		{
			trace('Adding vocal upload for character ${charKey}');
			var charMetadata:BaseCharacter = CharacterDataParser.fetchCharacter(charKey);
			var charName:String = charMetadata.characterName;

			var vocalsEntry = state.buildComponent(CHART_EDITOR_DIALOG_UPLOAD_VOCALS_ENTRY_LAYOUT);

			var vocalsEntryLabel:Label = vocalsEntry.findComponent('vocalsEntryLabel', Label);
			vocalsEntryLabel.text = 'Click to browse for a vocal track for $charName.';

			vocalsEntry.onClick = (_event) ->
			{
				Dialogs.openBinaryFile('Open $charName Vocals', [{label: "Audio File (.ogg)", extension: "ogg"}], function(selectedFile)
				{
					if (selectedFile != null)
					{
						trace('Selected file: ' + selectedFile.name + "~" + selectedFile.fullPath);
						vocalsEntryLabel.text = 'Vocals for $charName (click to browse)\n${selectedFile.name}';
						state.loadVocalsFromBytes(selectedFile.bytes);
						removeDropHandler(onDropFile);
					}
				});
			}

			dialogContainer.addComponent(vocalsEntry);
		}

		var dialogContinue:Button = dialog.findComponent('dialogContinue', Button);
		dialogContinue.onClick = (_event) ->
		{
			dialog.hideDialog(DialogButton.APPLY);
		};

		// TODO: Redo the logic for file drop handler to be more robust.
		// We need to distinguish which component the mouse is over when the file is dropped.

		onDropFile = (path:String) ->
		{
			trace('Dropped file: ' + path);
		};
		addDropHandler(onDropFile);

		return dialog;
	}

	/**
	 * Builds and opens a dialog displaying the user guide, providing guidance and help on how to use the chart editor.
	 */
	public static inline function openUserGuideDialog(state:ChartEditorState):Dialog
	{
		return openDialog(state, CHART_EDITOR_DIALOG_USER_GUIDE_LAYOUT, true, true);
	}

	/**
	 * Builds and opens a dialog from a given layout path.
	 * @param modal Makes the background uninteractable while the dialog is open.
	 * @param closable Hides the close button on the dialog, preventing it from being closed unless the user interacts with the dialog.
	 */
	static function openDialog(state:ChartEditorState, key:String, modal:Bool = true, closable:Bool = true):Dialog
	{
		var dialog:Dialog = cast state.buildComponent(key);
		dialog.destroyOnClose = true;
		dialog.closable = closable;
		dialog.showDialog(modal);

		state.isHaxeUIDialogOpen = true;
		dialog.onDialogClosed = (_event) ->
		{
			state.isHaxeUIDialogOpen = false;
		};

		return dialog;
	}
}
