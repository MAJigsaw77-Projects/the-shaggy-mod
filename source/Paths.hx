package;

import flixel.graphics.frames.FlxAtlasFrames;
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
	public static var customImagesLoaded:Map<String, FlxGraphic> = new Map();
	#end

	private static var currentLevel:String;

	static public function setCurrentLevel(name:String)
	{
		currentLevel = name.toLowerCase();
	}

	public static function getPath(file:String, type:AssetType, ?library:Null<String> = null)
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

	static public function getLibraryPath(file:String, library = "preload")
	{
		return if (library == "preload" || library == "default") getPreloadPath(file); else getLibraryPathForce(file, library);
	}

	inline static function getLibraryPathForce(file:String, library:String)
	{
		return '$library:assets/$library/$file';
	}

	inline public static function getPreloadPath(file:String)
	{
		return 'assets/$file';
	}

	inline static public function file(file:String, type:AssetType = TEXT, ?library:String)
	{
		return getPath(file, type, library);
	}

	inline static public function txt(key:String, ?library:String)
	{
		return getPath('data/$key.txt', TEXT, library);
	}

	inline static public function xml(key:String, ?library:String)
	{
		return getPath('data/$key.xml', TEXT, library);
	}

	inline static public function json(key:String, ?library:String)
	{
		return getPath('data/$key.json', TEXT, library);
	}

	inline static public function lua(key:String, ?library:String)
	{
		return getPath('$key.lua', TEXT, library);
	}

	static public function sound(key:String, ?library:String)
	{
		return getPath('sounds/$key.ogg', SOUND, library);
	}

	inline static public function soundRandom(key:String, min:Int, max:Int, ?library:String)
	{
		return sound(key + FlxG.random.int(min, max), library);
	}

	inline static public function video(key:String, ?library:String)
	{
		return getPath('videos/$key.mp4', BINARY, library);
	}

	inline static public function music(key:String, ?library:String)
	{
		return getPath('music/$key.ogg', MUSIC, library);
	}

	inline static public function voices(song:String)
	{
		return getPath('${song.toLowerCase()}/Voices.ogg', MUSIC, 'songs');
	}

	inline static public function inst(song:String)
	{
		if (song.toLowerCase() == "whats-new" && Main.drums)
			return getPath('${song.toLowerCase()}/Fuck.ogg', MUSIC, 'songs');
		else
			return getPath('${song.toLowerCase()}/Inst.ogg', MUSIC, 'songs');
	}

	inline static public function image(key:String, ?library:String):Dynamic
	{
		#if MODS_ALLOWED
		var imageToReturn:FlxGraphic = addCustomGraphic(key);
		if (imageToReturn != null)
			return imageToReturn;
		#end

		return getPath('images/$key.png', IMAGE, library);
	}

	inline static public function font(key:String)
	{
		return getPreloadPath('fonts/$key');
	}

	inline static public function fileExists(key:String, type:AssetType, ?ignoreMods:Bool = false, ?library:String)
	{
		#if MODS_ALLOWED
		if (FileSystem.exists(mods(key)))
			return true;
		#end

		if (Assets.exists(Paths.getPath(key, type)))
			return true;

		return false;
	}

	inline static public function getSparrowAtlas(key:String, ?library:String)
	{
		#if MODS_ALLOWED
		var imageLoaded:FlxGraphic = addCustomGraphic(key);

		return FlxAtlasFrames.fromSparrow((imageLoaded != null ? imageLoaded : image(key, library)),
			(FileSystem.exists(modsXml(key)) ? File.getContent(modsXml(key)) : file('images/$key.xml', library)));
		#else
		return FlxAtlasFrames.fromSparrow(image(key, library), file('images/$key.xml', library));
		#end
	}

	inline static public function getPackerAtlas(key:String, ?library:String)
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

	inline static public function mods(key:String)
	{
		return 'mods/' + key;
	}

	inline static public function modsImages(key:String)
	{
		return mods('images/' + key + '.png');
	}

	inline static public function modsXml(key:String)
	{
		return mods('images/' + key + '.xml');
	}

	inline static public function modsTxt(key:String)
	{
		return mods('images/' + key + '.xml');
	}
	#end
}
