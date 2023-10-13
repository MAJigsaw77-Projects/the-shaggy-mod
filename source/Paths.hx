package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.system.FlxAssets;
import flixel.FlxG;
import openfl.utils.AssetType;
import openfl.utils.Assets;
#if MODS_ALLOWED
import flixel.graphics.FlxGraphic;
import openfl.display.BitmapData;
import sys.io.File;
import sys.FileSystem;
#end

using StringTools;

class Paths
{
	#if MODS_ALLOWED
	public static var customImagesLoaded:Map<String, FlxGraphic> = [];
	#end

	private static var currentLevel:String;

	public static function setCurrentLevel(name:String):Void
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null):String
	{
		if (library != null)
			return getLibraryPath(file, library);

		if (currentLevel != null)
		{
			var levelPath:String = '';

			if (currentLevel != 'shared')
			{
				levelPath = getLibraryPathForce(file, currentLevel);
				if (Assets.exists(levelPath, type))
					return levelPath;
			}

			levelPath = getLibraryPathForce(file, "shared");
			if (Assets.exists(levelPath, type))
				return levelPath;
		}

		return getPreloadPath(file);
	}

	public static function getLibraryPath(file:String, library = "preload"):String
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String):String
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String):String
	{
		return 'assets/$file';
	}

	public static inline function file(file:String, type:AssetType = TEXT, ?library:String):String
	{
		return getPath(file, type, library);
	}

	public static inline function txt(key:String, ?library:String):String
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	public static inline function xml(key:String, ?library:String):String
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	public static inline function json(key:String, ?library:String):String
	{
		return getPath('data/$key.json', TEXT, library);
	}

	public static inline function lua(key:String, ?library:String):String
	{
		return getPath('$key.lua', TEXT, library);
	}

	public static function sound(key:String, ?library:String):String
	{
		return getPath('sounds/$key.ogg', SOUND, library);
	}

	public static inline function soundRandom(key:String, min:Int, max:Int, ?library:String):String
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	public static inline function video(key:String, ?library:String):String
	{
		return getPath('videos/$key.mp4', BINARY, library);
	}

	public static inline function music(key:String, ?library:String):String
	{
		return getPath('music/$key.ogg', MUSIC, library);
	}

	public static inline function voices(song:String):String
	{
		return getPath('${song.toLowerCase()}/Voices.ogg', MUSIC, 'songs');
	}

	public static inline function inst(song:String):String
	{
		if (song.toLowerCase() == "whats-new" && Main.drums)
			return getPath('${song.toLowerCase()}/Fuck.ogg', MUSIC, 'songs');
		else
			return getPath('${song.toLowerCase()}/Inst.ogg', MUSIC, 'songs');
	}

	public static inline function image(key:String, ?library:String):FlxGraphicAsset
	{
		#if MODS_ALLOWED
		var imageToReturn:FlxGraphic = addCustomGraphic(key);
		if (imageToReturn != null)
			return imageToReturn;
		#end

		return getPath('images/$key.png', IMAGE, library);
	}

	public static function font(key:String):String
	{
		final path:String = getPreloadPath('fonts/$key');

		if (Assets.exists(path, FONT))
			return Assets.getFont(path).fontName;

		return null;
	}

	public static inline function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String):Bool
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(key)))
			return true;
		#end

		if (Assets.exists(Paths.getPath(key, type)))
			return true;

		return false;
	}

	public static inline function getSparrowAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = addCustomGraphic(key);

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)),
			(FileSystem.exists(modsXml(key)) ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	public static inline function getPackerAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = addCustomGraphic(key);

		return FlxAtlasFrames.fromSpriteSheetPacker((imageLoaded != null ? imageLoaded : image(key, library)),
			(FileSystem.exists(modsTxt(key)) ? File.getContent(modsTxt(key)) : file('images/$key.txt', library)));
		#else
		return FlxAtlasFrames.fromSpriteSheetPacker(image(key, library), file('images/$key.txt', library));
		#end
	}

	#if MODS_ALLOWED
	static private function addCustomGraphic(key:String):FlxGraphic
	{
		if (FileSystem.exists(modsImages(key)))
		{
			if (!customImagesLoaded.exists(key))
			{
				var newGraphic:FlxGraphic = FlxGraphic.fromBitmapData(BitmapData.fromFile(Sys.getCwd() + modsImages(key)));
				newGraphic.persist = true;
				customImagesLoaded.set(key, newGraphic);
			}

			return customImagesLoaded.get(key);
		}

		return null;
	}

	public static inline function mods(key:String):String
	{
		return 'mods/' + key;
	}

	public static inline function modsImages(key:String):String
	{
		return mods('images/' + key + '.png');
	}

	public static inline function modsXml(key:String):String
	{
		return mods('images/' + key + '.xml');
	}

	public static inline function modsTxt(key:String):String
	{
		return mods('images/' + key + '.xml');
	}
	#end
}
