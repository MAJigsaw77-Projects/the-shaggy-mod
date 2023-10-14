package;

#if android
import android.content.Context;
#end
import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxGame;
import flixel.FlxState;
import haxe.io.Path;
import haxe.CallStack;
import haxe.Exception;
import haxe.Log;
#if hl
import hl.Api;
#end
import lime.system.System;
import openfl.display.FPS;
import openfl.display.Sprite;
import openfl.errors.Error;
import openfl.events.ErrorEvent;
import openfl.events.UncaughtErrorEvent;
import openfl.system.System;
import openfl.utils.AssetCache;
import openfl.utils.Assets;
import openfl.Lib;
#if sys
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class Main extends Sprite
{
	public static var fpsVar:FPS;

	public static var drums:Bool = false;
	public static var menuBad:Bool = false;
	public static var menuMusPlay:Bool = false;
	public static var skipDes:Bool = false;
	public static var ammo:Array<Int> = [4, 6, 7, 9];
	public static var gfxIndex:Array<Dynamic> = [
		[0, 1, 2, 3],
		[0, 2, 3, 5, 1, 8],
		[0, 2, 3, 4, 5, 1, 8],
		[0, 1, 2, 3, 4, 5, 6, 7, 8]
	];
	public static var gfxHud:Array<Dynamic> = [
		[0, 1, 2, 3],
		[0, 2, 3, 0, 1, 3],
		[0, 2, 3, 4, 0, 1, 3],
		[0, 1, 2, 3, 4, 0, 1, 2, 3]
	];
	public static var gfxAlterInd:Array<Dynamic> = [
		[2, 3, 3, 2],
		[0, 1, 2, 2, 1, 0],
		[0, 1, 2, 3, 2, 1, 0],
		[0, 1, 2, 1, 3, 1, 2, 1, 0]
	];
	public static var letterMax:Array<Int> = [9, 4];
	public static var skinName:Array<String> = ['assets', 'alter'];
	public static var gfxDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'SPACE'];
	public static var charDir:Array<String> = ['LEFT', 'DOWN', 'UP', 'RIGHT', 'UP'];
	public static var gfxLetter:Array<String> = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I'];

	// You can pretty much ignore everything from here on - your code should go in your states.

	public function new():Void
	{
		super();

		#if android
		Sys.setCwd(Path.addTrailingSlash(Context.getExternalFilesDir()));
		#elseif (ios || switch)
		Sys.setCwd(System.applicationStorageDirectory);
		#end

		Lib.current.loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, onUncaughtError);

		#if (mobile || switch)
		Storage.copyNecessaryFiles();
		#end

		#if hl
		Api.setErrorHandler(onCriticalError);
		#elseif cpp
		untyped __global__.__hxcpp_set_critical_error_handler(onCriticalError);
		#end

		FlxG.signals.gameResized.add(onResizeGame);
		FlxG.signals.preStateCreate.add(onPreStateCreate);

		// Run the garbage colector after the state switched...
		FlxG.signals.postStateSwitch.add(System.gc);

		addChild(new FlxGame(1280, 720, TitleState, 60, 60, true, false));

		#if android
		FlxG.android.preventDefaultKeys = [BACK];
		#end

		FlxGraphic.defaultPersist = ClientPrefs.imagesPersist;

		fpsVar = new FPS(10, 3, 0xFFFFFF);
		#if (mobile || switch)
		fpsVar.scaleX = fpsVar.scaleY = Math.min(FlxG.stage.stageWidth / FlxG.width, FlxG.stage.stageHeight / FlxG.height);
		#end
		addChild(fpsVar);

		if (fpsVar != null)
			fpsVar.visible = ClientPrefs.showFPS;
	}

	private inline function onUncaughtError(event:UncaughtErrorEvent):Void
	{
		event.preventDefault();
		event.stopImmediatePropagation();

		final log:Array<String> = [];

		if (Std.isOfType(event.error, Error))
			log.push(cast(event.error, Error).message);
		else if (Std.isOfType(event.error, ErrorEvent))
			log.push(cast(event.error, ErrorEvent).text);
		else
			log.push(Std.string(event.error));

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					log.push('C Function');
				case Module(m):
					log.push('Module [$m]');
				case FilePos(s, file, line, column):
					log.push('$file [line $line]');
				case Method(classname, method):
					log.push('$classname [method $method]');
				case LocalFunction(name):
					log.push('Local Function [$name]');
			}
		}

		final msg:String = log.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('errors'))
				FileSystem.createDirectory('errors');

			File.saveContent('errors/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', msg);
		}
		catch (e:Exception)
			Log.trace('Couldn\'t save error message "${e.message}"', null);
		#end

		Log.trace(msg, null);
		Lib.application.window.alert(msg, 'Error!');
		System.exit(1);
	}

	private inline function onCriticalError(error:Dynamic):Void
	{
		final log:Array<String> = [Std.isOfType(error, String) ? error : Std.string(error)];

		for (item in CallStack.exceptionStack(true))
		{
			switch (item)
			{
				case CFunction:
					log.push('C Function');
				case Module(m):
					log.push('Module [$m]');
				case FilePos(s, file, line, column):
					log.push('$file [line $line]');
				case Method(classname, method):
					log.push('$classname [method $method]');
				case LocalFunction(name):
					log.push('Local Function [$name]');
			}
		}

		final msg:String = log.join('\n');

		#if sys
		try
		{
			if (!FileSystem.exists('errors'))
				FileSystem.createDirectory('errors');

			File.saveContent('errors/' + Date.now().toString().replace(' ', '-').replace(':', "'") + '.txt', msg);
		}
		catch (e:Exception)
			Log.trace('Couldn\'t save error message "${e.message}"', null);
		#end

		Log.trace(msg, null);
		Lib.application.window.alert(msg, 'Error!');
		System.exit(1);
	}

	private inline function onResizeGame(width:Int, height:Int):Void
	{
		if (FlxG.cameras != null && (FlxG.cameras.list != null && FlxG.cameras.list.length > 0))
		{
			for (camera in FlxG.cameras.list)
			{
				if (camera != null && (camera.filters != null && camera.filters.length > 0))
				{
					// Shout out to Ne_Eo for bringing this to my attention.
					@:privateAccess
					if (camera.flashSprite != null)
					{
						camera.flashSprite.__cacheBitmap = null;
						camera.flashSprite.__cacheBitmapData = null;
					}
				}
			}
		}
		@:privateAccess
		if (FlxG.game != null)
		{
			FlxG.game.__cacheBitmap = null;
			FlxG.game.__cacheBitmapData = null;
		}
	}

	private inline function onPreStateCreate(state:FlxState):Void
	{
		var cache:AssetCache = cast(Assets.cache, AssetCache);

		// Clear the loaded graphics if they are no longer in flixel cache...
		for (key in cache.bitmapData.keys())
			if (!FlxG.bitmap.checkCache(key))
				cache.bitmapData.remove(key);

		// Clear all the loaded sounds from the cache...
		for (key in cache.sound.keys())
			cache.sound.remove(key);

		// Clear all the loaded fonts from the cache...
		for (key in cache.font.keys())
			cache.font.remove(key);
	}
}
