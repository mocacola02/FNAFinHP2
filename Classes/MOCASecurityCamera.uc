class MOCASecurityCamera extends RTCamera;

var() int MaxRotation;		// Moca: How far the camera's Yaw can rotate in each direction.
var() float PauseTime;		// Moca: How long the camera pauses before turning in the other direction.
var() float RotationSpeed;	// Moca: How fast the camera rotates.

var int LeftRot, RightRot, TargetRot, PrevRot;

var float TurnAlpha;
var float CurrPauseTime;


// Prep rotation values
event PostBeginPlay()
{
	super.PostBeginPlay();

	// Our "previous" rot should just be the default at start
	PrevRot  = Rotation.Yaw;

	// Calculate our allowed left and right rotation
	LeftRot  = PrevRot - MaxRotation;
	RightRot = PrevRot + MaxRotation;
}

// Handles camera rotation
// a little clunky but it should work
event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	// If our pause time isn't 0.0 or less then we aren't paused, so move
	if ( CurrPauseTime <= 0.0 )
	{
		// If we're offset by 0.0 and turn alpha is 0.0, that should mean we're in the default rot, so let's pick a direction
		if ( GetCurrentRotOffset() == 0.0 && TurnAlpha == 0.0 )
		{
			// Get a random number, 0 or 1
			local int rnd;
			rnd = Rand(2);

			// If 0 then we'll turn left, otherwise turn right
			if ( rnd == 0 )
			{
				TargetRot = LeftRot;
			}
			else
			{
				TargetRot = RightRot;
			}
		}

		// Increase our turn alpha
		TurnAlpha += DeltaTime * RotationSpeed;
		// Clamp our alpha between 0.0 and 1.0 so we don't overshoot
		TurnAlpha = FClamp(TurnAlpha, 0.0, 1.0);

		local Rotator NewRot;

		NewRot.Pitch = Rotation.Pitch;
		NewRot.Yaw = Round(Lerp(TurnAlpha, PrevRot, TargetRot));
		NewRot.Roll = Rotation.Roll;

		// Lerp our yaw, we gotta round cuz floats aren't ints
		SetRotation(NewRot);

		// If we're at or above 1.0 alpha (which we shouldn't go above anyway but lets be safe), then reset alpha and prepare to pause
		if ( TurnAlpha >= 1.0 )
		{
			local Rotator FinalRot;
			FinalRot.Pitch = Rotation.Pitch;
			FinalRot.Yaw = TargetRot;
			FinalRot.Roll = Rotation.Roll;
			SetRotation(FinalRot);
			
			TurnAlpha = 0.0;
			PrevRot = Rotation.Yaw;
			CurrPauseTime += DeltaTime;
		}
	}
	else
	{
		// Increment pause time
		CurrPauseTime += DeltaTime;

		// If we've paused long enough
		if ( CurrPauseTime >= PauseTime )
		{
			// Reset pause time
			CurrPauseTime = 0.0;

			// If our target was left, we'll now go right
			if ( TargetRot == LeftRot )
			{
				TargetRot = RightRot;
			}
			// And vice versa
			else
			{
				TargetRot = LeftRot;
			}
		}
	}
}

// Returns the current yaw offset from the default yaw
function int GetCurrentRotOffset()
{
	return MapDefault.Rotation.Yaw - Rotation.Yaw;
}



defaultproperties
{
	MaxRotation=1024
	PauseTime=2.0
	RotationSpeed=0.5
}