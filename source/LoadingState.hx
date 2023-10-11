package;

import flixel.FlxG;
import flixel.FlxState;

class LoadingState
{
	inline static public function loadAndSwitchState(target:FlxState, stopMusic:Bool = false)
	{
		Paths.setCurrentLevel(WeekData.getWeekDirectory());

		if (stopMusic && FlxG.sound.music != null)
			FlxG.sound.music.stop();

		MusicBeatState.switchState(target);
	}
}
