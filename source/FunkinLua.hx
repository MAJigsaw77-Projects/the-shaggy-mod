package;

#if LUA_ALLOWED
import hxlua.Lua;
import hxlua.LuaL;
import hxlua.Types;
#end
import flixel.FlxG;
import flixel.tweens.FlxTween;
import flixel.tweens.FlxEase;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxPoint;
import flixel.util.FlxTimer;
import flixel.FlxSprite;
import flixel.FlxCamera;
import haxe.ds.ObjectMap;
import haxe.ds.StringMap;
import haxe.Constraints;
import haxe.DynamicAccess;
import haxe.Exception;
#if sys
import sys.FileSystem;
import sys.io.File;
#end
import openfl.Lib;

using StringTools;

class FunkinLua
{
	public static var Function_Stop:Int = 1;
	public static var Function_Continue:Int = 0;

	private static var callbacks:Map<String, Function> = [];

	#if LUA_ALLOWED
	private var lua:cpp.RawPointer<Lua_State> = null;
	#end

	var lePlayState:PlayState = null;

	public var tweens:Map<String, FlxTween> = [];
	public var sprites:Map<String, LuaSprite> = [];
	public var accessedProps:Map<String, Dynamic> = [];
	public var timers:Map<String, FlxTimer> = [];

	public function new(script:String):Void
	{
		#if LUA_ALLOWED
		LuaL.openlibs(lua);

		Lua.register(lua, "print", cpp.Function.fromStaticFunction(print));

		lePlayState = cast(FlxG.state, PlayState);

		// Lua shit
		set('Function_Stop', Function_Stop);
		set('Function_Continue', Function_Continue);
		set('luaDebugMode', false);
		set('luaDeprecatedWarnings', true);

		// Song/Week shit
		set('curBpm', Conductor.bpm);
		set('bpm', PlayState.SONG.bpm);
		set('scrollSpeed', PlayState.SONG.speed);
		set('crochet', Conductor.crochet);
		set('stepCrochet', Conductor.stepCrochet);
		set('songLength', FlxG.sound.music.length);
		set('songName', PlayState.SONG.song);
		set('startedCountdown', false);

		set('isStoryMode', PlayState.isStoryMode);
		set('difficulty', PlayState.storyDifficulty);
		set('weekRaw', PlayState.storyWeek);
		set('week', WeekData.getCurrentWeekNumber());
		set('seenCutscene', PlayState.seenCutscene);

		// Camera poo
		set('cameraX', 0);
		set('cameraY', 0);

		// Screen stuff
		set('screenWidth', FlxG.width);
		set('screenHeight', FlxG.height);

		// PlayState cringe ass nae nae bullcrap
		set('curBeat', 0);
		set('curStep', 0);

		set('score', 0);
		set('misses', 0);
		set('hits', 0);

		set('rating', 0);
		set('ratingName', '');

		set('mustHitSection', false);
		set('botPlay', PlayState.cpuControlled);

		for (i in 0...4)
		{
			set('defaultPlayerStrumX' + i, 0);
			set('defaultPlayerStrumY' + i, 0);
			set('defaultOpponentStrumX' + i, 0);
			set('defaultOpponentStrumY' + i, 0);
		}

		// Some settings, no jokes
		set('downscroll', ClientPrefs.downScroll);
		set('middlescroll', ClientPrefs.middleScroll);
		set('framerate', ClientPrefs.framerate);
		set('ghostTapping', ClientPrefs.ghostTapping);
		set('hideHud', ClientPrefs.hideHud);
		set('hideTime', ClientPrefs.hideTime);
		set('cameraZoomOnBeat', ClientPrefs.camZooms);
		set('flashingLights', ClientPrefs.flashing);
		set('noteOffset', ClientPrefs.noteOffset);
		set('lowQuality', ClientPrefs.lowQuality);

		// stuff 4 noobz like you B)
		addCallback("getProperty", function(variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(lePlayState, killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(lePlayState, variable);
		});
		addCallback("setProperty", function(variable:String, value:Dynamic)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(lePlayState, killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(lePlayState, variable, value);
		});
		addCallback("getPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(lePlayState, obj), FlxTypedGroup))
			{
				return Reflect.getProperty(Reflect.getProperty(lePlayState, obj).members[index], variable);
			}

			var leArray:Dynamic = Reflect.getProperty(lePlayState, obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == TInt)
				{
					return leArray[variable];
				}
				return Reflect.getProperty(leArray, variable);
			}
			return null;
		});
		addCallback("setPropertyFromGroup", function(obj:String, index:Int, variable:Dynamic, value:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(lePlayState, obj), FlxTypedGroup))
			{
				return Reflect.setProperty(Reflect.getProperty(lePlayState, obj).members[index], variable, value);
			}

			var leArray:Dynamic = Reflect.getProperty(lePlayState, obj)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == TInt)
				{
					return leArray[variable] = value;
				}
				return Reflect.setProperty(leArray, variable, value);
			}
		});
		addCallback("removeFromGroup", function(obj:String, index:Int, dontKill:Bool = false, dontDestroy:Bool = false)
		{
			if (Std.isOfType(Reflect.getProperty(lePlayState, obj), FlxTypedGroup))
			{
				var sex = Reflect.getProperty(lePlayState, obj).members[index];
				if (!dontKill)
					sex.kill();
				Reflect.getProperty(lePlayState, obj).remove(sex, true);
				if (!dontDestroy)
					sex.destroy();
				return;
			}
			Reflect.getProperty(lePlayState, obj).remove(Reflect.getProperty(lePlayState, obj)[index]);
		});

		addCallback("getPropertyFromClass", function(classVar:String, variable:String)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
			}
			return Reflect.getProperty(Type.resolveClass(classVar), variable);
		});
		addCallback("setPropertyFromClass", function(classVar:String, variable:String, value:Dynamic)
		{
			var killMe:Array<String> = variable.split('.');
			if (killMe.length > 1)
			{
				var coverMeInPiss:Dynamic = Reflect.getProperty(Type.resolveClass(classVar), killMe[0]);
				for (i in 1...killMe.length - 1)
				{
					coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
				}
				return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
			}
			return Reflect.setProperty(Type.resolveClass(classVar), variable, value);
		});

		// shitass stuff for epic coders like me B)  *image of obama giving himself a medal*
		addCallback("accessPropertyFirst", function(tag:String, classVar:String, variable:String)
		{
			accessedProps.set(tag, Reflect.getProperty(classVar != null ? Type.resolveClass(classVar) : lePlayState, variable));
		});
		addCallback("accessPropertyFromGroupFirst", function(tag:String, classVar:String, obj:String, index:Int, variable:Dynamic)
		{
			if (Std.isOfType(Reflect.getProperty(classVar != null ? Type.resolveClass(classVar) : lePlayState, variable), FlxTypedGroup))
			{
				accessedProps.set(tag,
					Reflect.getProperty(Reflect.getProperty(classVar != null ? Type.resolveClass(classVar) : lePlayState, obj).members[index], variable));
			}

			var leArray:Dynamic = Reflect.getProperty(classVar != null ? Type.resolveClass(classVar) : lePlayState, variable)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == TInt)
				{
					accessedProps.set(tag, leArray[variable]);
				}
				accessedProps.set(tag, Reflect.getProperty(leArray, variable));
			}
		});
		addCallback("accessProperty", function(tag:String, variable:String)
		{
			if (accessedProps.exists(tag))
			{
				accessedProps.set(tag, Reflect.getProperty(accessedProps.get(tag), variable));
			}
		});
		addCallback("accessPropertyFromGroup", function(tag:String, index:Int, variable:Dynamic)
		{
			if (!accessedProps.exists(tag))
			{
				return;
			}

			if (Std.isOfType(accessedProps.get(tag), FlxTypedGroup))
			{
				accessedProps.set(tag, Reflect.getProperty(accessedProps.get(tag).members[index], variable));
			}

			var leArray:Dynamic = accessedProps.get(tag)[index];
			if (leArray != null)
			{
				if (Type.typeof(variable) == TInt)
				{
					accessedProps.set(tag, leArray[variable]);
				}
				accessedProps.set(tag, Reflect.getProperty(leArray, variable));
			}
		});
		addCallback("getAccessedPropertyValue", function(tag:String, variable:String)
		{
			if (accessedProps.exists(tag))
			{
				return Reflect.getProperty(accessedProps.get(tag), variable);
			}
			return null;
		});
		addCallback("setAccessedPropertyValue", function(tag:String, variable:String, value:Dynamic)
		{
			if (accessedProps.exists(tag))
			{
				return Reflect.setProperty(accessedProps.get(tag), variable, value);
			}
		});
		addCallback("getAccessedPropertyValueFromGroup", function(tag:String, index:Int, variable:Dynamic)
		{
			if (accessedProps.exists(tag))
			{
				if (Std.isOfType(accessedProps.get(tag), FlxTypedGroup))
				{
					return Reflect.getProperty(accessedProps.get(tag).members[index], variable);
				}

				var leArray:Dynamic = accessedProps.get(tag)[index];
				if (leArray != null)
				{
					if (Type.typeof(variable) == TInt)
					{
						return leArray[variable];
					}
					return Reflect.getProperty(leArray, variable);
				}
			}
			return null;
		});
		addCallback("setAccessedPropertyValueFromGroup", function(tag:String, index:Int, variable:Dynamic, value:Dynamic)
		{
			if (accessedProps.exists(tag))
			{
				if (Std.isOfType(accessedProps.get(tag), FlxTypedGroup))
				{
					return Reflect.setProperty(accessedProps.get(tag).members[index], variable, value);
				}

				var leArray:Dynamic = accessedProps.get(tag)[index];
				if (leArray != null)
				{
					if (Type.typeof(variable) == TInt)
					{
						return leArray[variable] = value;
					}
					return Reflect.setProperty(leArray, variable, value);
				}
			}
		});

		// gay ass tweens
		addCallback("doTweenX", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String, delay:Float = 0)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				tweens.set(tag, FlxTween.tween(penisExam, {x: value}, duration, {
					ease: getFlxEaseByString(ease),
					startDelay: delay,
					onComplete: function(twn:FlxTween)
					{
						call('onTweenCompleted', [tag]);
						tweens.remove(tag);
					}
				}));
			}
		});
		addCallback("doTweenY", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String, delay:Float = 0)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				tweens.set(tag, FlxTween.tween(penisExam, {y: value}, duration, {
					ease: getFlxEaseByString(ease),
					startDelay: delay,
					onComplete: function(twn:FlxTween)
					{
						call('onTweenCompleted', [tag]);
						tweens.remove(tag);
					}
				}));
			}
		});
		addCallback("doTweenAlpha", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String, delay:Float = 0)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				tweens.set(tag, FlxTween.tween(penisExam, {alpha: value}, duration, {
					ease: getFlxEaseByString(ease),
					startDelay: delay,
					onComplete: function(twn:FlxTween)
					{
						call('onTweenCompleted', [tag]);
						tweens.remove(tag);
					}
				}));
			}
		});
		addCallback("doTweenZoom", function(tag:String, vars:String, value:Dynamic, duration:Float, ease:String, delay:Float = 0)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				tweens.set(tag, FlxTween.tween(penisExam, {zoom: value}, duration, {
					ease: getFlxEaseByString(ease),
					startDelay: delay,
					onComplete: function(twn:FlxTween)
					{
						call('onTweenCompleted', [tag]);
						tweens.remove(tag);
					}
				}));
			}
		});
		addCallback("doTweenColor", function(tag:String, vars:String, targetColor:String, duration:Float, ease:String, delay:Float = 0)
		{
			var penisExam:Dynamic = tweenShit(tag, vars);
			if (penisExam != null)
			{
				var color:Int = Std.parseInt(targetColor);
				if (!targetColor.startsWith('0x'))
					color = Std.parseInt('0xff' + targetColor);

				tweens.set(tag, FlxTween.color(penisExam, duration, penisExam.color, color, {
					ease: getFlxEaseByString(ease),
					startDelay: delay,
					onComplete: function(twn:FlxTween)
					{
						tweens.remove(tag);
						call('onTweenCompleted', [tag]);
					}
				}));
			}
		});
		addCallback("cancelTween", function(tag:String)
		{
			cancelTween(tag);
		});

		addCallback("runTimer", function(tag:String, time:Float = 1, loops:Int = 1)
		{
			cancelTimer(tag);
			timers.set(tag, new FlxTimer().start(time, function(tmr:FlxTimer)
			{
				if (tmr.finished)
				{
					timers.remove(tag);
				}
				call('onTimerCompleted', [tag, tmr.loops, tmr.loopsLeft]);
			}, loops));
		});
		addCallback("cancelTimer", function(tag:String)
		{
			cancelTimer(tag);
		});

		/*addCallback("getPropertyAdvanced", function(varsStr:String) {
				var variables:Array<String> = varsStr.replace(' ', '').split(',');
				var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
				if(variables.length > 2) {
					var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
					if(variables.length > 3) {
						for (i in 2...variables.length-1) {
							curProp = Reflect.getProperty(curProp, variables[i]);
						}
					}
					return Reflect.getProperty(curProp, variables[variables.length-1]);
				} else if(variables.length == 2) {
					return Reflect.getProperty(leClass, variables[variables.length-1]);
				}
				return null;
			});
			addCallback("setPropertyAdvanced", function(varsStr:String, value:Dynamic) {
				var variables:Array<String> = varsStr.replace(' ', '').split(',');
				var leClass:Class<Dynamic> = Type.resolveClass(variables[0]);
				if(variables.length > 2) {
					var curProp:Dynamic = Reflect.getProperty(leClass, variables[1]);
					if(variables.length > 3) {
						for (i in 2...variables.length-1) {
							curProp = Reflect.getProperty(curProp, variables[i]);
						}
					}
					return Reflect.setProperty(curProp, variables[variables.length-1], value);
				} else if(variables.length == 2) {
					return Reflect.setProperty(leClass, variables[variables.length-1], value);
				}
		});*/

		// stupid bietch ass functions
		addCallback("addScore", function(value:Int = 0)
		{
			lePlayState.songScore += value;
			lePlayState.RecalculateRating();
		});
		addCallback("addMisses", function(value:Int = 0)
		{
			lePlayState.songMisses += value;
			lePlayState.RecalculateRating();
		});
		addCallback("addHits", function(value:Int = 0)
		{
			lePlayState.songHits += value;
			lePlayState.RecalculateRating();
		});
		addCallback("setScore", function(value:Int = 0)
		{
			lePlayState.songScore = value;
			lePlayState.RecalculateRating();
		});
		addCallback("setMisses", function(value:Int = 0)
		{
			lePlayState.songMisses = value;
			lePlayState.RecalculateRating();
		});
		addCallback("setHits", function(value:Int = 0)
		{
			lePlayState.songHits = value;
			lePlayState.RecalculateRating();
		});

		addCallback("getColorFromHex", function(color:String)
		{
			if (!color.startsWith('0x'))
				color = '0xff' + color;
			return Std.parseInt(color);
		});
		addCallback("keyJustPressed", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = lePlayState.getControl('NOTE_LEFT_P');
				case 'down':
					key = lePlayState.getControl('NOTE_DOWN_P');
				case 'up':
					key = lePlayState.getControl('NOTE_UP_P');
				case 'right':
					key = lePlayState.getControl('NOTE_RIGHT_P');
				case 'accept':
					key = lePlayState.getControl('ACCEPT');
				case 'back':
					key = lePlayState.getControl('BACK');
				case 'pause':
					key = lePlayState.getControl('PAUSE');
				case 'reset':
					key = lePlayState.getControl('RESET');
			}
			return key;
		});
		addCallback("keyPressed", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = lePlayState.getControl('NOTE_LEFT');
				case 'down':
					key = lePlayState.getControl('NOTE_DOWN');
				case 'up':
					key = lePlayState.getControl('NOTE_UP');
				case 'right':
					key = lePlayState.getControl('NOTE_RIGHT');
			}
			return key;
		});
		addCallback("keyReleased", function(name:String)
		{
			var key:Bool = false;
			switch (name)
			{
				case 'left':
					key = lePlayState.getControl('NOTE_LEFT_R');
				case 'down':
					key = lePlayState.getControl('NOTE_DOWN_R');
				case 'up':
					key = lePlayState.getControl('NOTE_UP_R');
				case 'right':
					key = lePlayState.getControl('NOTE_RIGHT_R');
			}
			return key;
		});
		addCallback("addCharacterToList", function(name:String, type:String)
		{
			var charType:Int = 0;
			switch (type.toLowerCase())
			{
				case 'dad':
					charType = 1;
				case 'gf' | 'girlfriend':
					charType = 2;
			}
			lePlayState.addCharacterToList(name, charType);
		});
		addCallback("triggerEvent", function(name:String, arg1:Dynamic, arg2:Dynamic)
		{
			var value1:String = arg1;
			var value2:String = arg2;
			lePlayState.triggerEventNote(name, value1, value2, true);
			// trace('Triggered event: ' + name + ', ' + value1 + ', ' + value2);
		});
		addCallback("playSound", function(sound:String, volume:Float = 1)
		{
			FlxG.sound.play(Paths.sound(sound), volume);
		});

		addCallback("startCountdown", function(variable:String)
		{
			lePlayState.startCountdown();
		});
		addCallback("getSongPosition", function()
		{
			return Conductor.songPosition;
		});

		addCallback("getCharacterX", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad':
					return lePlayState.DAD_X;
				case 'gf' | 'girlfriend':
					return lePlayState.GF_X;
				default:
					return lePlayState.BF_X;
			}
		});
		addCallback("setCharacterX", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad':
					lePlayState.DAD_X = value;
					lePlayState.dadGroup.forEachAlive(function(char:Character)
					{
						char.x = lePlayState.DAD_X + char.positionArray[0];
					});
				case 'gf' | 'girlfriend':
					lePlayState.BF_X = value;
					lePlayState.boyfriendGroup.forEachAlive(function(char:Boyfriend)
					{
						char.x = lePlayState.BF_X + char.positionArray[0];
					});
				default:
					lePlayState.GF_X = value;
					lePlayState.gfGroup.forEachAlive(function(char:Character)
					{
						char.x = lePlayState.GF_X + char.positionArray[0];
					});
			}
		});
		addCallback("getCharacterY", function(type:String)
		{
			switch (type.toLowerCase())
			{
				case 'dad':
					return lePlayState.DAD_Y;
				case 'gf' | 'girlfriend':
					return lePlayState.GF_Y;
				default:
					return lePlayState.BF_Y;
			}
		});
		addCallback("setCharacterY", function(type:String, value:Float)
		{
			switch (type.toLowerCase())
			{
				case 'dad':
					lePlayState.DAD_Y = value;
					lePlayState.dadGroup.forEachAlive(function(char:Character)
					{
						char.y = lePlayState.DAD_Y + char.positionArray[1];
					});
				case 'gf' | 'girlfriend':
					lePlayState.GF_Y = value;
					lePlayState.gfGroup.forEachAlive(function(char:Character)
					{
						char.y = lePlayState.GF_Y + char.positionArray[1];
					});
				default:
					lePlayState.BF_Y = value;
					lePlayState.boyfriendGroup.forEachAlive(function(char:Boyfriend)
					{
						char.y = lePlayState.BF_Y + char.positionArray[1];
					});
			}
		});
		addCallback("cameraSetTarget", function(target:String)
		{
			var isDad:Bool = false;
			if (target == 'dad')
			{
				isDad = true;
			}
			lePlayState.moveCamera(isDad);
		});
		addCallback("setRatingPercent", function(value:Float)
		{
			lePlayState.ratingPercent = value;
		});
		addCallback("setRatingString", function(value:String)
		{
			lePlayState.ratingString = value;
		});
		addCallback("getMouseX", function(camera:String)
		{
			var cam:FlxCamera = lePlayState.camGame;
			switch (camera.toLowerCase())
			{
				case 'camhud' | 'hud':
					cam = lePlayState.camHUD;
				case 'camother' | 'other':
					cam = lePlayState.camOther;
			}
			return FlxG.mouse.getScreenPosition(cam).x;
		});
		addCallback("getMouseY", function(camera:String)
		{
			var cam:FlxCamera = lePlayState.camGame;
			switch (camera.toLowerCase())
			{
				case 'camhud' | 'hud':
					cam = lePlayState.camHUD;
				case 'camother' | 'other':
					cam = lePlayState.camOther;
			}
			return FlxG.mouse.getScreenPosition(cam).y;
		});
		addCallback("spawnNoteSplashes", function(x:Float, y:Float, data:Int = 0, type:Int = 0)
		{
			lePlayState.spawnNoteSplash(x, y, data, type);
		});
		addCallback("characterPlayAnim", function(character:String, anim:String, ?forced:Bool = false)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					if (lePlayState.dad.animOffsets.exists(anim))
						lePlayState.dad.playAnim(anim, forced);
				case 'gf' | 'girlfriend':
					if (lePlayState.gf.animOffsets.exists(anim))
						lePlayState.gf.playAnim(anim, forced);
				default:
					if (lePlayState.boyfriend.animOffsets.exists(anim))
						lePlayState.boyfriend.playAnim(anim, forced);
			}
		});
		addCallback("characterDance", function(character:String)
		{
			switch (character.toLowerCase())
			{
				case 'dad':
					lePlayState.dad.dance();
				case 'gf' | 'girlfriend':
					lePlayState.gf.dance();
				default:
					lePlayState.boyfriend.dance();
			}
		});

		addCallback("makeLuaSprite", function(tag:String, image:String, x:Float, y:Float)
		{
			resetSpriteTag(tag);
			var leSprite:LuaSprite = new LuaSprite(x, y);
			leSprite.loadGraphic(Paths.image(image));
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			sprites.set(tag, leSprite);
			leSprite.active = false;
		});
		addCallback("makeAnimatedLuaSprite", function(tag:String, image:String, x:Float, y:Float)
		{
			resetSpriteTag(tag);
			var leSprite:LuaSprite = new LuaSprite(x, y);
			leSprite.frames = Paths.getSparrowAtlas(image);
			leSprite.antialiasing = ClientPrefs.globalAntialiasing;
			sprites.set(tag, leSprite);
		});

		addCallback("luaSpriteAddAnimationByPrefix", function(tag:String, name:String, prefix:String, framerate:Int = 24, loop:Bool = true)
		{
			if (sprites.exists(tag))
			{
				var cock:LuaSprite = sprites.get(tag);
				cock.animation.addByPrefix(name, prefix, framerate, loop);
				if (cock.animation.curAnim == null)
				{
					cock.animation.play(name, true);
				}
			}
		});
		addCallback("luaSpriteAddAnimationByIndices", function(tag:String, name:String, prefix:String, indices:String, framerate:Int = 24)
		{
			if (sprites.exists(tag))
			{
				var strIndices:Array<String> = indices.trim().split(',');
				var die:Array<Int> = [];
				for (i in 0...strIndices.length)
				{
					die.push(Std.parseInt(strIndices[i]));
				}
				var pussy:LuaSprite = sprites.get(tag);
				pussy.animation.addByIndices(name, prefix, die, '', framerate, false);
				if (pussy.animation.curAnim == null)
				{
					pussy.animation.play(name, true);
				}
			}
		});
		addCallback("luaSpritePlayAnimation", function(tag:String, name:String, forced:Bool = false)
		{
			if (sprites.exists(tag))
			{
				sprites.get(tag).animation.play(name, forced);
			}
		});

		addCallback("setLuaSpriteScrollFactor", function(tag:String, scrollX:Float, scrollY:Float)
		{
			if (sprites.exists(tag))
			{
				sprites.get(tag).scrollFactor.set(scrollX, scrollY);
			}
		});
		addCallback("addLuaSprite", function(tag:String, front:Bool = false)
		{
			if (sprites.exists(tag))
			{
				var shit:LuaSprite = sprites.get(tag);
				if (!shit.wasAdded)
				{
					if (front)
					{
						lePlayState.foregroundGroup.add(shit);
					}
					else
					{
						lePlayState.backgroundGroup.add(shit);
					}
					shit.isInFront = front;
					shit.wasAdded = true;
				}
			}
		});
		addCallback("removeLuaSprite", function(tag:String)
		{
			resetSpriteTag(tag);
		});

		addCallback("getPropertyLuaSprite", function(tag:String, variable:String)
		{
			if (sprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(sprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.getProperty(coverMeInPiss, killMe[killMe.length - 1]);
				}
				return Reflect.getProperty(sprites.get(tag), variable);
			}
			return null;
		});
		addCallback("setPropertyLuaSprite", function(tag:String, variable:String, value:Dynamic)
		{
			if (sprites.exists(tag))
			{
				var killMe:Array<String> = variable.split('.');
				if (killMe.length > 1)
				{
					var coverMeInPiss:Dynamic = Reflect.getProperty(sprites.get(tag), killMe[0]);
					for (i in 1...killMe.length - 1)
					{
						coverMeInPiss = Reflect.getProperty(coverMeInPiss, killMe[i]);
					}
					return Reflect.setProperty(coverMeInPiss, killMe[killMe.length - 1], value);
				}
				return Reflect.setProperty(sprites.get(tag), variable, value);
			}
		});
		addCallback("startDialogue", function(dialogueFile:String, ?song:String = null)
		{
			if (FileSystem.exists(Paths.mods('data/' + dialogueFile + '.txt')))
			{
				var shit:Array<String> = File.getContent(Paths.mods('data/' + dialogueFile + '.txt')).trim().split('\n');
				for (i in 0...shit.length)
				{
					shit[i] = shit[i].trim();
				}
				lePlayState.dialogueIntro(shit, song);
			}
		});

		var result:Dynamic = LuaL.dofile(lua, script);
		var resultStr:String = Lua.tostring(lua, result);
		if (resultStr != null && result != 0)
		{
			lime.app.Application.current.window.alert(resultStr, 'Error on .LUA script!');
			trace('Error on .LUA script! ' + resultStr);
			lua = null;
			return;
		}

		try
		{
			if (LuaL.dofile(lua, script) != Lua.OK)
			{
				final error:String = cast(Lua.tostring(lua, -1), String);
				Lua.pop(lua, 1);
				throw error;
			}
		}
		catch (e:Exception)
		{
			Lib.application.window.alert(e.message, 'Error on .LUA script!');

			trace('Error on .LUA script! ${e.message}');

			stop();
		}

		trace('Lua file loaded succesfully:' + script);

		call('onCreate', []);
		#end
	}

	function resetSpriteTag(tag:String)
	{
		if (!sprites.exists(tag))
		{
			return;
		}

		var pee:LuaSprite = sprites.get(tag);
		pee.kill();
		if (pee.wasAdded)
		{
			if (pee.isInFront)
			{
				lePlayState.foregroundGroup.remove(pee, true);
			}
			else
			{
				lePlayState.backgroundGroup.remove(pee, true);
			}
		}
		pee.destroy();
		sprites.remove(tag);
	}

	function cancelTween(tag:String)
	{
		if (tweens.exists(tag))
		{
			tweens.get(tag).cancel();
			tweens.get(tag).destroy();
			tweens.remove(tag);
		}
	}

	function tweenShit(tag:String, vars:String)
	{
		cancelTween(tag);

		var variables:Array<String> = vars.replace(' ', '').split('.');
		var sexyProp:Dynamic = Reflect.getProperty(lePlayState, variables[0]);

		if (sexyProp == null && sprites.exists(variables[0]))
		{
			sexyProp = sprites.get(variables[0]);
		}

		for (i in 1...variables.length)
			sexyProp = Reflect.getProperty(sexyProp, variables[i]);

		return sexyProp;
	}

	function cancelTimer(tag:String)
	{
		if (timers.exists(tag))
		{
			timers.get(tag).cancel();
			timers.get(tag).destroy();
			timers.remove(tag);
		}
	}

	// Better optimized than using some getProperty shit or idk
	function getFlxEaseByString(?ease:String = '')
	{
		switch (ease.toLowerCase())
		{
			case 'backin':
				return FlxEase.backIn;
			case 'backinout':
				return FlxEase.backInOut;
			case 'backout':
				return FlxEase.backOut;
			case 'bouncein':
				return FlxEase.bounceIn;
			case 'bounceinout':
				return FlxEase.bounceInOut;
			case 'bounceout':
				return FlxEase.bounceOut;
			case 'circin':
				return FlxEase.circIn;
			case 'circinout':
				return FlxEase.circInOut;
			case 'circout':
				return FlxEase.circOut;
			case 'cubein':
				return FlxEase.cubeIn;
			case 'cubeinout':
				return FlxEase.cubeInOut;
			case 'cubeout':
				return FlxEase.cubeOut;
			case 'elasticin':
				return FlxEase.elasticIn;
			case 'elasticinout':
				return FlxEase.elasticInOut;
			case 'elasticout':
				return FlxEase.elasticOut;
			case 'expoin':
				return FlxEase.expoIn;
			case 'expoinout':
				return FlxEase.expoInOut;
			case 'expoout':
				return FlxEase.expoOut;
			case 'quadin':
				return FlxEase.quadIn;
			case 'quadinout':
				return FlxEase.quadInOut;
			case 'quadout':
				return FlxEase.quadOut;
			case 'quartin':
				return FlxEase.quartIn;
			case 'quartinout':
				return FlxEase.quartInOut;
			case 'quartout':
				return FlxEase.quartOut;
			case 'quintin':
				return FlxEase.quintIn;
			case 'quintinout':
				return FlxEase.quintInOut;
			case 'quintout':
				return FlxEase.quintOut;
			case 'sinein':
				return FlxEase.sineIn;
			case 'sineinout':
				return FlxEase.sineInOut;
			case 'sineout':
				return FlxEase.sineOut;
			case 'smoothstepin':
				return FlxEase.smoothStepIn;
			case 'smoothstepinout':
				return FlxEase.smoothStepInOut;
			case 'smoothstepout':
				return FlxEase.smoothStepInOut;
			case 'smootherstepin':
				return FlxEase.smootherStepIn;
			case 'smootherstepinout':
				return FlxEase.smootherStepInOut;
			case 'smootherstepout':
				return FlxEase.smootherStepOut;
		}

		return FlxEase.linear;
	}

	public function call(name:String, ?args:Array<Dynamic>):Dynamic
	{
		if (lua == null)
			return Function_Continue;

		Lua.getglobal(lua, name);

		if (Lua.type(lua, -1) != Lua.TFUNCTION)
			return null;

		if (args != null && args.length > 0)
			for (arg in args)
				toLua(lua, arg);

		try
		{
			if (Lua.pcall(lua, args != null ? args.length : 0, 1, 0) != Lua.OK)
			{
				final error:String = cast(Lua.tostring(lua, -1), String);
				Lua.pop(lua, 1);
				throw error;
			}
		}
		catch (e:Exception)
		{
			Lib.application.window.alert(e.message, 'Error on .LUA script call!');

			trace('Error on .LUA script call! ${e.message}');

			stop();

			return null;
		}

		final ret:Dynamic = toHaxe(lua, -1);

		if (ret != null)
			Lua.pop(lua, 1);

		return ret;
	}

	public function set(key:String, val:Dynamic):Void
	{
		if (lua == null)
			return;

		toLua(lua, val);
		Lua.setglobal(lua, key);
	}

	public function setTweensActive(value:Bool)
	{
		#if LUA_ALLOWED
		if (lua == null)
			return;

		for (tween in tweens)
			tween.active = value;
		#end
	}

	public function addCallback(key:String, val:Function):Void
	{
		if (lua == null || (lua != null && !Reflect.isFunction(val)))
			return;

		callbacks.set(key, val);

		Lua.pushstring(lua, key);
		Lua.pushcclosure(lua, cpp.Function.fromStaticFunction(callback), 1);
		Lua.setglobal(lua, key);
	}

	public function removeCallback(key:String):Void
	{
		if (lua == null)
			return;

		callbacks.remove(key);

		Lua.pushnil(lua);
		Lua.setglobal(lua, key);
	}

	public function stop():Void
	{
		#if LUA_ALLOWED
		tweens.clear();
		accessedProps.clear();
		sprites.clear();
		timers.clear();

		if (lua != null)
		{
			/* cleanup Lua */
			Lua.close(lua);
			lua = null;
		}
		#end
	}

	private static function toLua(l:cpp.RawPointer<Lua_State>, val:Dynamic):Void
	{
		switch (Type.typeof(val))
		{
			case TNull:
				Lua.pushnil(l);
			case TInt:
				Lua.pushinteger(l, val);
			case TFloat:
				Lua.pushnumber(l, val);
			case TBool:
				Lua.pushboolean(l, val ? 1 : 0);
			case TClass(Array):
				Lua.createtable(l, val.length, 0);

				for (i in 0...val.length)
				{
					Lua.pushinteger(l, i + 1);
					toLua(l, val[i]);
					Lua.settable(l, -3);
				}
			case TClass(ObjectMap) | TClass(StringMap):
				var map:Map<String, Dynamic> = val;

				Lua.createtable(l, Lambda.count(map), 0);

				for (key => value in map)
				{
					Lua.pushstring(l, Std.isOfType(key, String) ? key : Std.string(key));
					toLua(l, value);
					Lua.settable(l, -3);
				}
			case TClass(String):
				Lua.pushstring(l, cast(val, String));
			case TObject:
				Lua.createtable(l, Reflect.fields(val).length, 0);

				for (key in Reflect.fields(val))
				{
					Lua.pushstring(l, key);
					toLua(l, Reflect.field(val, key));
					Lua.settable(l, -3);
				}
			default:
				Sys.println('Couldn\'t convert "${Type.typeof(val)}" to Lua.');
		}
	}

	private static function toHaxe(l:cpp.RawPointer<Lua_State>, idx:Int):Dynamic
	{
		switch (Lua.type(l, idx))
		{
			case type if (type == Lua.TNIL):
				return null;
			case type if (type == Lua.TBOOLEAN):
				return Lua.toboolean(l, idx) == 1;
			case type if (type == Lua.TNUMBER):
				return Lua.tonumber(l, idx);
			case type if (type == Lua.TSTRING):
				return cast(Lua.tostring(l, idx), String);
			case type if (type == Lua.TTABLE):
				var count:Int = 0;
				var array:Bool = true;

				Lua.pushnil(l);

				while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
				{
					if (array)
					{
						if (Lua.isnumber(l, -2) != 0)
							array = false;
						else
						{
							final index:Float = Lua.tonumber(l, -2);
							if (index < 0 || Std.int(index) != index)
								array = false;
						}
					}

					count++;
					Lua.pop(l, 1);
				}

				if (count == 0)
					return
					{
					};
				else if (array)
				{
					var ret:Array<Dynamic> = [];

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
					{
						ret[Std.int(Lua.tonumber(l, -2)) - 1] = toHaxe(l, -1);

						Lua.pop(l, 1);
					}

					return ret;
				}
				else
				{
					var ret:DynamicAccess<Dynamic> = {};

					Lua.pushnil(l);

					while (Lua.next(l, idx < 0 ? idx - 1 : idx) != 0)
					{
						switch (Lua.type(l, -2))
						{
							case type if (type == Lua.TSTRING):
								ret.set(cast(Lua.tostring(l, -2), String), toHaxe(l, -1));

								Lua.pop(l, 1);
							case type if (type == Lua.TNUMBER):
								ret.set(Std.string(Lua.tonumber(l, -2)), toHaxe(l, -1));

								Lua.pop(l, 1);
						}
					}

					return ret;
				}
			default:
				Sys.println('Couldn\'t convert "${cast (Lua.typename(l, idx), String)}" to Haxe.');
		}

		return null;
	}

	private static function print(l:cpp.RawPointer<Lua_State>):Int
	{
		final nargs:Int = Lua.gettop(l);

		/* loop through each argument */
		for (i in 0...nargs)
			Sys.println(cast(Lua.tostring(l, i + 1), String));

		/* clear the stack */
		Lua.pop(l, nargs);
		return 0;
	}

	private static function callback(l:cpp.RawPointer<Lua_State>):Int
	{
		final nargs:Int = Lua.gettop(l);

		/* loop through each argument and set it to the array */
		var args:Array<Dynamic> = [];
		for (i in 0...nargs)
			args[i] = toHaxe(l, i + 1);

		/* clear the stack */
		Lua.pop(l, nargs);

		final name:String = Lua.tostring(l, Lua.upvalueindex(1));

		if (callbacks.exists(name))
		{
			var ret:Dynamic = Reflect.callMethod(null, callbacks.get(name), args);

			if (ret != null)
			{
				toLua(l, ret);
				return 1;
			}
		}

		return 0;
	}
}

class LuaSprite extends FlxSprite
{
	public var wasAdded:Bool = false;
	public var isInFront:Bool = false;
}
