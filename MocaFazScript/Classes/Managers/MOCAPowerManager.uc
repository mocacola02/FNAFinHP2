class MOCAPowerManager extends Actor;

var() int InitialPower;			// Moca: How much power to start with each night
var() name PowerOutEvent;		// Moca: Event to send when power runs out.
var() name HundredPlaceTag;
var() name TenPlaceTag;
var() name SinglePlaceTag;
var() Texture TransparentTex;
var() Array<Texture> NumberTex;

var(MOCAFoxy) int BaseFoxyDrain;		// Moca: Base amount of power Foxy should drain when hitting the door.
var(MOCAFoxy) int FoxyDrainIncrement;	// Moca: How much power to add onto the base drain, increasing with the number of times Foxy has hit.
var(MOCAFoxy) int MaxFoxyDrain;			// Moca: Maximum amount of power Foxy is allowed to drain. < 0 means no limit.

var bool bLeftDoorClosed;
var bool bRightDoorClosed;
var bool bLeftLightOn;
var bool bRightLightOn;

var int CurrPower;

var int FoxyHits;

var MOCANightManager NightManager;
var MOCACameraManager CameraManager;
var SurfaceModifyTrigger SurfaceModifier;


event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	foreach AllActors(class'MOCANightManager', NightManager)
	{
		break;
	}

	if ( NightManager == None )
	{
		Log("ERROR: Could not find night manager!!");
	}

	foreach AllActors(class'MOCACameraManager', CameraManager)
	{
		break;
	}

	if ( CameraManager == None )
	{
		Log("ERROR: Could not find camera manager!!");
	}

	SurfaceModifier = Spawn(Class'SurfaceModifyTrigger');
	
	if ( SurfaceModifier == None )
	{
		Log("ERROR: Failed to spawn SurfaceModifier!!!");
	}
	else
	{
		SurfaceModifier.SurfaceTag = HundredPlaceTag;
		SurfaceModifier.bChangeMaterial = true;
		UpdateSurface();
	}
}

// Starts the power drain timer
function StartPowerTimer()
{
	SetTimer(1.0, true, 'HandleDrain');
}

// Stops the power drain timer
function StopPowerTimer()
{
	SetTimer(0.0, false, 'HandleDrain');
}

function StartPassiveTimer()
{
	local int TargetTime;

	switch(NightManager.CurrNight)
	{
		case 1:
			return;
		case 2:
			TargetTime = 6;
		case 3:
			TargetTime = 5;
		case 4:
			TargetTime = 4;
		default:
			TargetTime = 3;
	}

	SetTimer(TargetTime, true, 'HandlePassiveDrain');
}

function StopPassiveTimer()
{
	SetTimer(0.0, false, 'HandlePassiveDrain');
}

// this is absolute cheeks
function int GetPowerUsage()
{
	local int Usage;
	Usage = 1;

	if ( bLeftDoorClosed )
	{
		Usage++;
	}

	if ( bRightDoorClosed )
	{
		Usage++;
	}

	if ( bLeftLightOn )
	{
		Usage++;
	}

	if ( bRightLightOn )
	{
		Usage++;
	}

	if ( CameraManager.bUtilized )
	{
		Usage++;
	}

	return Usage;
}

function DrainPower(int Amount)
{
	CurrPower -= Amount;
	UpdateSurface();
	CheckPower();
}

// Determines if we should drain power yet
function HandleDrain()
{
	DrainPower(1 * GetPowerUsage());
}

function HandlePassiveDrain()
{
	DrainPower(1);
}

// Handles logic for Foxy hitting the door
function HandleFoxyHit()
{
	// Since the first hit should only take 1% power, we'll increment FoxyHits AFTER the hit drain
	local int DrainAmount;
	// Calculates the drain amount from our base drain that should be taken each time, plus an increment that is increased for each hit
	DrainAmount = BaseFoxyDrain + (FoxyDrainIncrement * FoxyHits);

	if ( MaxFoxyDrain >= 0 )
	{
		DrainAmount = Clamp(DrainAmount, 0, MaxFoxyDrain);
	}

	// Drain the calculated amount
	DrainPower(DrainAmount);

	// Increment our hit counter
	FoxyHits++;
}

function CheckPower()
{
	if ( CurrPower <= 0 )
	{
		local MOCAAnimatronic A;
		foreach AllActors(class'MOCAAnimatronic', A)
		{
			A.SetAILevel(0);
		}

		StopPowerTimer();
		StopPassiveTimer();

		TriggerEvent(PowerOutEvent, Self, None);
	}
}

function UpdateSurface()
{
	local int Offset;
	local string PowerPercent;
	PowerPercent = ItoA(Round((CurrPower / InitialPower) * 100));

	SurfaceModifier.SurfaceTag = HundredPlaceTag;

	if ( AtoI(PowerPercent) >= 100 )
	{
		Offset = 1;
		SurfaceModifier.NewMaterial = NumberTex[AtoI(Left(PowerPercent, 0))];
		SurfaceModifier.ModifyLevelSurfaces();
	}
	else
	{
		SurfaceModifier.NewMaterial = TransparentTex;
		SurfaceModifier.ModifyLevelSurfaces();
	}

	SurfaceModifier.SurfaceTag = TenPlaceTag;
	SurfaceModifier.NewMaterial = NumberTex[AtoI(Left(PowerPercent, 0 + Offset))];
	SurfaceModifier.ModifyLevelSurfaces();

	SurfaceModifier.SurfaceTag = SinglePlaceTag;
	SurfaceModifier.NewMaterial = NumberTex[AtoI(Left(PowerPercent, 1 + Offset))];
	SurfaceModifier.ModifyLevelSurfaces();
}


defaultproperties
{
	InitialPower=999
	PowerOutEvent="PowerOut"

	BaseFoxyDrain=1
	FoxyDrainIncrement=5
	MaxFoxyDrain=-1
}