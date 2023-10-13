package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.addons.ui.FlxUIState;
import flixel.math.FlxRect;
import flixel.util.FlxTimer;
import flixel.addons.transition.FlxTransitionableState;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;
import flixel.util.FlxColor;
import flixel.util.FlxGradient;
import flixel.FlxState;
#if mobile
import flixel.input.actions.FlxActionInput;
import flixel.mobile.FlxHitbox;
import flixel.mobile.FlxVirtualPad;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
#end

class MusicBeatState extends FlxUIState
{
	private var lastBeat:Float = 0;
	private var lastStep:Float = 0;

	private var curStep:Int = 0;
	private var curBeat:Int = 0;
	private var controls(get, never):Controls;

	inline function get_controls():Controls
		return PlayerSettings.player1.controls;

	#if mobile
	var hitbox:FlxHitbox;
	var vPad:FlxVirtualPad;

	var trackedInputsHitbox:Array<FlxActionInput> = [];
	var trackedInputsVirtualPad:Array<FlxActionInput> = [];

	public function addVPad(dPad:FlxDPadMode, action:FlxActionMode, ?visible = true):Void
	{
		if (vPad != null)
			removeVirtualPad();

		vPad = new FlxVirtualPad(dPad, action);
		vPad.visible = visible;
		add(vPad);

		controls.setVPad(vPad, dPad, action);
		trackedInputsVirtualPad = controls.trackedInputs;
		controls.trackedInputs = [];
	}

	public function addVPadCamera(defaultDrawTarget:Bool = true):Void
	{
		if (vPad != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, defaultDrawTarget);
			camControls.bgColor.alpha = 0;
			vPad.cameras = [camControls];
		}
	}

	public function removeVirtualPad():Void
	{
		if (trackedInputsVirtualPad.length > 0)
			controls.removeVControlsInput(trackedInputsVirtualPad);

		if (vPad != null)
			remove(vPad);
	}

	public function addHitbox(?visible = true):Void
	{
		if (hitbox != null)
			removeHitbox();

		final ammo:Int = Main.ammo[PlayState.SONG.song.mania];

		// [0xFF00FF, 0x00FFFF, 0x00FF00, 0xFF0000] mania colors
		hitbox = new FlxHitbox(ammo, Std.int(FlxG.width / ammo), FlxG.height, []);
		hitbox.visible = visible;
		add(hitbox);

		controls.setHitbox(hitbox, PlayState.SONG.song.mania);
		trackedInputsHitbox = controls.trackedInputs;
		controls.trackedInputs = [];
	}

	public function addHitboxCamera(DefaultDrawTarget:Bool = true):Void
	{
		if (hitbox != null)
		{
			var camControls:FlxCamera = new FlxCamera();
			FlxG.cameras.add(camControls, DefaultDrawTarget);
			camControls.bgColor.alpha = 0;
			hitbox.cameras = [camControls];
		}
	}

	public function removeHitbox():Void
	{
		if (trackedInputsHitbox.length > 0)
			controls.removeVControlsInput(trackedInputsHitbox);

		if (hitbox != null)
			remove(hitbox);
	}
	#end

	override function create():Void
	{
		#if MODS_ALLOWED
		if (!ClientPrefs.imagesPersist)
			Paths.customImagesLoaded.clear();
		#end

		super.create();

		// Custom made Trans out
		if (!FlxTransitionableState.skipNextTransOut)
		{
			openSubState(new CustomFadeTransition(1, true));
		}
		FlxTransitionableState.skipNextTransOut = false;
	}

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		updateBeat();

		if (oldStep != curStep && curStep > 0)
			stepHit();

		super.update(elapsed);
	}

	override function destroy():Void
	{
		#if mobile
		if (trackedInputsHitbox.length > 0)
			controls.removeVControlsInput(trackedInputsHitbox);

		if (trackedInputsVirtualPad.length > 0)
			controls.removeVControlsInput(trackedInputsVirtualPad);
		#end

		super.destroy();

		#if mobile
		if (vPad != null)
			vPad = FlxDestroyUtil.destroy(vPad);

		if (hitbox != null)
			hitbox = FlxDestroyUtil.destroy(hitbox);
		#end
	}

	private function updateBeat():Void
	{
		curBeat = Math.floor(curStep / 4);
	}

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition >= Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor(((Conductor.songPosition - ClientPrefs.noteOffset) - lastChange.songTime) / Conductor.stepCrochet);
	}

	public static function switchState(nextState:FlxState)
	{
		// Custom made Trans in
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		if (!FlxTransitionableState.skipNextTransIn)
		{
			leState.openSubState(new CustomFadeTransition(0.7, false));
			if (nextState == FlxG.state)
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.resetState();
				};
				// trace('resetted');
			}
			else
			{
				CustomFadeTransition.finishCallback = function()
				{
					FlxG.switchState(nextState);
				};
				// trace('changed state');
			}
			return;
		}
		FlxTransitionableState.skipNextTransIn = false;
		FlxG.switchState(nextState);
	}

	public static function resetState()
	{
		MusicBeatState.switchState(FlxG.state);
	}

	public static function getState():MusicBeatState
	{
		var curState:Dynamic = FlxG.state;
		var leState:MusicBeatState = curState;
		return leState;
	}

	public function stepHit():Void
	{
		if (curStep % 4 == 0)
			beatHit();
	}

	public function beatHit():Void
	{
		// do literally nothing dumbass
	}
}
