package;

#if DISCORD_ALLOWED
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.3.2'; // This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	final optionShit:Array<String> = ['story_mode', 'freeplay', 'credits', 'options'];
	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;

	override function create():Void
	{
		#if DISCORD_ALLOWED
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		MASKstate.saveDataSetup();

		persistentUpdate = persistentDraw = true;

		final yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		var bg:FlxSprite = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		bg.scrollFactor.set(0, yScroll);
		bg.screenCenter();
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);

		camFollow = new FlxObject(0, 0, 1, 1);
		add(camFollow);

		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollowPos);

		magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var star:Array<FlxSprite> = [];

		for (i in 0...3)
		{
			var gfx = 'endstar';
			if (!FlxG.save.data.ending[i])
				gfx += '_e';

			star[i] = new FlxSprite().loadGraphic(Paths.image(gfx));
			star[i].scrollFactor.set();
			star[i].screenCenter(X);
			star[i].y = 0;
			star[i].x += (i - 1) * 90;
			star[i].scale.x = 0.75;
			star[i].scale.y = 0.75;
			star[i].antialiasing = ClientPrefs.globalAntialiasing;
			add(star[i]);
		}

		for (i in 0...optionShit.length)
		{
			final offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;

			var menuItem:FlxSprite = new FlxSprite(0, (i * 140) + offset);
			menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItem.screenCenter(X);
			menuItems.add(menuItem);

			var scr:Float = (optionShit.length - 4) * 0.135;
			if (optionShit.length < 6)
				scr = 0;

			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(Paths.font('vcr.ttf'), 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		changeItem();

		#if mobile
		addVPad(UP_DOWN, A_B);

		vPad.y -= 44;
		#end

		super.create();
	}

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		#if debug
		if (FlxG.keys.pressed.SHIFT)
		{
			if (FlxG.keys.justPressed.ONE)
				FlxG.save.data.p_maskGot[0] = true;
			if (FlxG.keys.justPressed.TWO)
				FlxG.save.data.p_maskGot[1] = true;
			if (FlxG.keys.justPressed.THREE)
				FlxG.save.data.p_maskGot[2] = true;
			if (FlxG.keys.justPressed.FOUR)
				FlxG.save.data.p_maskGot[3] = true;
			if (FlxG.keys.justPressed.FIVE)
				FlxG.save.data.ending[0] = true;
			if (FlxG.keys.justPressed.SIX)
				FlxG.save.data.ending[1] = true;
			if (FlxG.keys.justPressed.SEVEN)
				FlxG.save.data.ending[2] = true;
			if (FlxG.keys.justPressed.ANY)
				FlxG.sound.play(Paths.sound('confirmMenu'));
		}
		#end

		if (FlxG.sound.music.volume < 0.8)
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 5.6, 0, 1);

		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				FlxG.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;

					FlxG.sound.play(Paths.sound('confirmMenu'));

					if (ClientPrefs.flashing)
						FlxFlicker.flicker(magenta, 1.1, 0.15, false);

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
							FlxFlicker.flicker(spr, 1, 0.06, false, false, function(flick:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'story_mode':
										FlxG.switchState(new StoryMenuState());
									case 'freeplay':
										FlxG.switchState(new FreeplayState());
									case 'credits':
										FlxG.switchState(new CreditsState());
									case 'options':
										FlxG.switchState(new OptionsState());
								}
							});
						}
					});
				}
			}
		}

		super.update(elapsed);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.screenCenter(X);
		});
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.offset.y = 0;
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');

				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y);

				spr.offset.x = 0.15 * (spr.frameWidth / 2 + 180);
				spr.offset.y = 0.15 * spr.frameHeight;
			}
		});
	}
}
