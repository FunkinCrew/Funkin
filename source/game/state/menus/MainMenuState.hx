package game.state.menus;

import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.math.FlxMath;
import lime.app.Application;
import game.state.*;
import game.state.menus.*;
import game.state.subState.*;
import game.state.menus.options.OptionsState;
import game.state.menus.options.PreferencesMenu;
import game.ui.AtlasMenuList;
import game.ui.MenuList;
import game.ui.*;
import game.ui.menu.*;
import game.data.backend.Conductor;
import game.data.backend.SwagCamera;

using StringTools;

#if discord_rpc
import game.data.backend.Discord.DiscordClient;
#end

class MainMenuState extends MusicBeatState
{
	// var menuItems:MainMenuList;
	var menuItems:FlxTypedGroup<FlxSprite>;
	var menuOptions:Array<String> = ['story mode', 'freeplay', 'options'];

	var curSelected:Int = 0;
	var selected:Bool = false;

	var magenta:FlxSprite;
	var logo:FlxSprite;

	override function create()
	{
		#if discord_rpc
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		if (!FlxG.sound.music.playing)
		{
			FlxG.sound.playMusic(Paths.music('freakyMenu'));
		}

		persistentUpdate = persistentDraw = true;

		var bg:FlxSprite = new FlxSprite(Paths.image('menuBG'));
		bg.scrollFactor.x = 0;
		bg.scrollFactor.y = 0.17;
		bg.setGraphicSize(Std.int(bg.width * 1.2));
		bg.updateHitbox();
		bg.screenCenter();
		bg.antialiasing = true;
		add(bg);

		magenta = new FlxSprite(Paths.image('menuDesat'));
		magenta.scrollFactor.x = bg.scrollFactor.x;
		magenta.scrollFactor.y = bg.scrollFactor.y;
		magenta.setGraphicSize(Std.int(bg.width));
		magenta.updateHitbox();
		magenta.x = bg.x;
		magenta.y = bg.y;
		magenta.visible = false;
		magenta.antialiasing = true;
		magenta.color = 0xFFfd719b;
		if (PreferencesMenu.preferences.get('flashing-menu'))
			add(magenta);

		// FUCK YOU FNF LOGO
		// Actually Kill Yourself
		logo = new FlxSprite(0, -130).loadGraphic(Paths.image('logo'));
		logo.screenCenter(X);
		add(logo);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		// This took forever to get the x value right
		// the menu options kept having hard sex in front of the fnf logo every time
		var menItemTex = Paths.getSparrowAtlas('main_menu');
		for (i in 0...menuOptions.length)
		{
			var menuItem:FlxSprite = new FlxSprite(10 + (i * 500), FlxG.height / 2 + 100);
			menuItem.frames = menItemTex;
			menuItem.animation.addByPrefix('idle', menuOptions[i] + ' idle', 24);
			menuItem.animation.addByPrefix('selected', menuOptions[i] + ' selected', 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			// menuItem.screenCenter(Y);
			menuItems.add(menuItem);
			menuItem.scale.set(0.7, 0.7);
			menuItem.updateHitbox();

			if (i == 1)
				menuItem.y += 130;
			if (i == 2)
				menuItem.x -= 100;
		}

		changeOption();

		var versionShit:FlxText = new FlxText(5, FlxG.height - 32, 0, "FNF v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat("VCR OSD Mono", 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		versionShit.text += '\nZyflixel Engine (HEAVY WIP)';

		super.create();
	}

	public function openPrompt(prompt:Prompt, onClose:Void->Void)
	{
		// menuItems.enabled = false;
		prompt.closeCallback = function()
		{
			// menuItems.enabled = true;
			if (onClose != null)
				onClose();
		}

		openSubState(prompt);
	}

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		FlxG.camera.zoom = FlxMath.lerp(1, FlxG.camera.zoom, CoolUtil.boundTo(1 - (elapsed * 4), 0, 1));

		logo.scale.x = FlxMath.lerp(0.6, logo.scale.x, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));
		logo.scale.y = FlxMath.lerp(0.6, logo.scale.y, CoolUtil.boundTo(1 - (elapsed * 9), 0, 1));

		if (!selected)
		{
			if (controls.UI_LEFT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeOption(-1);
			}
			else if (controls.UI_RIGHT_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeOption(1);
			}
		}

		if (controls.BACK)
		{
			FlxG.sound.play(Paths.sound('cancelMenu'));
			FlxG.switchState(new TitleState());
		}

		if (controls.ACCEPT && !selected)
		{
			selected = true;
			FlxG.sound.play(Paths.sound('confirmMenu'));
			FlxFlicker.flicker(magenta, 1.1, 0.15, false, true);

			menuItems.forEach(function(spr:FlxSprite)
			{
				if (curSelected != spr.ID)
				{
					FlxTween.tween(spr, {alpha: 0}, 0.4, {
						ease: FlxEase.quadOut,
						onComplete: function(twn:FlxTween)
						{
							spr.kill();
						}
					});
				}
				else
				{
					FlxFlicker.flicker(spr, 1, 0.06, true, false, function(flicker:FlxFlicker)
					{
						var options:String = menuOptions[curSelected];

						switch (options)
						{
							case 'story mode':
								FlxG.switchState(new StoryMenuState());
							case 'freeplay':
								FlxG.switchState(new FreeplayState());
							case 'options':
								FlxG.switchState(new OptionsState());
						}
					});
				}
			});
		}

		super.update(elapsed);
	}

	override function beatHit()
	{
		if (curBeat % 2 == 0)
		{
			FlxG.camera.zoom += 0.015;
			logo.scale.set(0.7, 0.7);
		}
		super.beatHit();
	}

	function changeOption(num:Int = 0)
	{
		curSelected += num;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;
		else if (curSelected >= menuItems.length)
			curSelected = 0;

		menuItems.forEach(function(item:FlxSprite)
		{
			item.offset.x = 0;
			item.animation.play('idle');
			item.updateHitbox();

			if (item.ID == curSelected)
			{
				item.animation.play('selected');
				switch (item.ID)
				{
					case 0:
						item.offset.x = 100;
					case 1:
						item.offset.x = 130;
					case 2:
						item.offset.x = 130;
				}
			}
		});
	}
}
/*private class MainMenuList extends MenuTypedList<MainMenuItem>
	{
	public var atlas:FlxAtlasFrames;

	public function new()
	{
		atlas = Paths.getSparrowAtlas('main_menu');
		super(Vertical);
	}

	public function createItem(x = 0.0, y = 0.0, name:String, callback, fireInstantly = false)
	{
		var item = new MainMenuItem(x, y, name, atlas, callback);
		item.fireInstantly = fireInstantly;
		item.ID = length;

		return addItem(name, item);
	}

	override function destroy()
	{
		super.destroy();
		atlas = null;
	}
	}

	private class MainMenuItem extends AtlasMenuItem
	{
	public function new(x = 0.0, y = 0.0, name, atlas, callback)
	{
		super(x, y, name, atlas, callback);
		scrollFactor.set();
	}

	override function changeAnim(anim:String)
	{
		super.changeAnim(anim);
		// position by center
		centerOrigin();
		offset.copyFrom(origin);
	}
}*/
