package;

import Conductor.BPMChangeEvent;
import flixel.FlxG;
import flixel.FlxSubState;
#if mobile
import flixel.input.actions.FlxActionInput;
import flixel.mobile.FlxHitbox;
import flixel.mobile.FlxVirtualPad;
import flixel.util.FlxDestroyUtil;
import flixel.FlxCamera;
#end

class MusicBeatSubstate extends FlxSubState
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

		final ammo:Int = Main.ammo[PlayState.SONG.mania];

		// [0xFF00FF, 0x00FFFF, 0x00FF00, 0xFF0000] mania colors
		hitbox = new FlxHitbox(ammo, Std.int(FlxG.width / ammo), FlxG.height, []);
		if (PlayState.SONG.mania == 2)

			hitbox.x += 3;
		else if (PlayState.SONG.mania == 3)
			hitbox.x += 1;

		hitbox.visible = visible;
		add(hitbox);

		controls.setHitbox(hitbox, PlayState.SONG.mania);
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

	override function update(elapsed:Float)
	{
		// everyStep();
		var oldStep:Int = curStep;

		updateCurStep();
		curBeat = Math.floor(curStep / 4);

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

	private function updateCurStep():Void
	{
		var lastChange:BPMChangeEvent = {
			stepTime: 0,
			songTime: 0,
			bpm: 0
		}
		for (i in 0...Conductor.bpmChangeMap.length)
		{
			if (Conductor.songPosition > Conductor.bpmChangeMap[i].songTime)
				lastChange = Conductor.bpmChangeMap[i];
		}

		curStep = lastChange.stepTime + Math.floor((Conductor.songPosition - lastChange.songTime) / Conductor.stepCrochet);
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
