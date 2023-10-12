package;

#if DISCORD_ALLOWED
import hxdiscord_rpc.Discord as RichPresence;
import hxdiscord_rpc.Types;
import openfl.Lib;
import sys.thread.Thread;

class DiscordClient
{
	public static function initialize():Void
	{
		var handlers:DiscordEventHandlers = DiscordEventHandlers.create();
		handlers.ready = cpp.Function.fromStaticFunction(onReady);
		handlers.disconnected = cpp.Function.fromStaticFunction(onDisconnected);
		handlers.errored = cpp.Function.fromStaticFunction(onError);
		RichPresence.Initialize("863222024192262205", cpp.RawPointer.addressOf(handlers), 1, null);

		// Daemon Thread
		Thread.create(function()
		{
			while (true)
			{
				#if FEATURE_DISCORD_DISABLE_IO_THREAD
				RichPresence.UpdateConnection();
				#end
				RichPresence.RunCallbacks();

				// Wait 2 seconds until the next loop...
				Sys.sleep(2);
			}
		});

		Lib.application.onExit.add((exitCode:Int) -> RichPresence.Shutdown());

		trace("Discord Client initialized");
	}

	public static function changePresence(details:String, state:String, ?smallImageKey:String, ?hasStartTimestamp:Bool, ?endTimestamp:Float):Void
	{
		var startTimestamp:Float = hasStartTimestamp ? Date.now().getTime() : 0;

		if (endTimestamp > 0)
			endTimestamp = startTimestamp + endTimestamp;

		var discordPresence:DiscordRichPresence = DiscordRichPresence.create();
		discordPresence.details = details;
		discordPresence.state = state;
		discordPresence.largeImageKey = "icon";
		discordPresence.largeImageText = "Engine Version: " + MainMenuState.psychEngineVersion;
		discordPresence.smallImageKey = smallImageKey;
		discordPresence.startTimestamp = Std.int(startTimestamp / 1000);
		discordPresence.endTimestamp = Std.int(endTimestamp / 1000);
		RichPresence.UpdatePresence(cpp.RawConstPointer.addressOf(discordPresence));
	}

	private static function onReady(request:cpp.RawConstPointer<DiscordUser>):Void
	{
		Discord.changePresence('In the Menus', null);
	}

	private static function onDisconnected(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Disconnected! $errorCode : ${cast (message, String)}');
	}

	private static function onError(errorCode:Int, message:cpp.ConstCharStar):Void
	{
		trace('Error! $errorCode : ${cast (message, String)}');
	}
}
#end
