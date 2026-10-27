class MOCAPowerManager extends Actor;

var() float InitialPower;			// Moca: How much power to start with each night
var() name PowerOutEvent;		// Moca: Event to send when power runs out.
var() name TenPlaceTag;
var() name SinglePlaceTag;
var() Texture TransparentTex;
var() Array<Texture> NumberTex;
var() Texture GreenBarTex;
var() Texture YellowBarTex;
var() Texture RedBarTex;
var() name UsageBarTags[6];

var bool bLeftDoorClosed;
var bool bRightDoorClosed;
var bool bLeftLightOn;
var bool bRightLightOn;

var float CurrPower;

var int PowerUsage;
var int FoxyHits;

var MOCANightManager NightManager;
var MOCACameraManager CameraManager;
var SurfaceModifyTrigger SurfaceModifier;


event PostBeginPlay()
{
	Super.PostBeginPlay();

	CurrPower = InitialPower;
	
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
		SurfaceModifier.bChangeMaterial = true;
		UpdatePercentSurface();
	}
}

// Starts the power drain timer
function StartPowerTimer()
{
	CurrPower = InitialPower;
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
			break;
		case 3:
			TargetTime = 5;
			break;
		case 4:
			TargetTime = 4;
			break;
		default:
			TargetTime = 3;
			break;
	}

	SetTimer(TargetTime, true, 'HandlePassiveDrain');
}

function StopPassiveTimer()
{
	SetTimer(0.0, false, 'HandlePassiveDrain');
}

event Tick(float DeltaTime)
{
	// i HATE this, this needs a recode in V2
	PowerUsage = GetPowerUsage();
	UpdateUsageSurface();
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

function DrainPower(float Amount)
{
	CurrPower -= Amount;
	Log("Power is now " $ CurrPower $ " | Usage is " $ PowerUsage);
	UpdatePercentSurface();
	CheckPower();
}

// Determines if we should drain power yet
function HandleDrain()
{
	DrainPower(0.1 * PowerUsage);
}

function HandlePassiveDrain()
{
	DrainPower(0.1);
}

// Handles logic for Foxy hitting the door
function HandleFoxyHit()
{
	// Since the first hit should only take 1% power, we'll increment FoxyHits AFTER the hit drain
	local int DrainAmount;
	// Calculates the drain amount from our base drain that should be taken each time, plus an increment that is increased for each hit
	DrainAmount = 5.0 * FoxyHits + 1.0;

	// Drain the calculated amount
	DrainPower(DrainAmount);

	// Increment our hit counter
	FoxyHits++;
}

function CheckPower()
{
	if ( CurrPower <= 0.0 )
	{
		local MOCAAnimatronic A;
		foreach AllActors(class'MOCAAnimatronic', A)
		{
			A.OnNightEnd();
		}

		StopPowerTimer();
		StopPassiveTimer();

		local MOCAPowerOutManager POM;
		foreach AllActors(class'MOCAPowerOutManager', POM)
		{
			Log("!!!!!!!!!!!!!!!!!!!!!! STARTING POWER OUT !!!!!!!!!!!!!!!!!!!!!!!!!!!!");
			POM.Start();
			break;
		}
	}
}

function UpdatePercentSurface()
{
	local string PowerPercent;
	PowerPercent = ItoA(Clamp(Round((CurrPower / InitialPower) * 100), 0, 99));

	SurfaceModifier.SurfaceTag = TenPlaceTag;

	if ( AtoI(PowerPercent) >= 10 )
	{
		SurfaceModifier.NewMaterial = NumberTex[AtoI(CharAt(PowerPercent, 0))];
	}
	else
	{
		SurfaceModifier.NewMaterial = TransparentTex;
	}

	SurfaceModifier.ModifyLevelSurfaces();
	
	SurfaceModifier.SurfaceTag = SinglePlaceTag;
	SurfaceModifier.NewMaterial = NumberTex[AtoI(CharAt(PowerPercent, 1))];
	SurfaceModifier.ModifyLevelSurfaces();
}

function UpdateUsageSurface()
{
	local int i;

	for ( i = 0; i < 6; i++ )
	{
		SurfaceModifier.SurfaceTag = UsageBarTags[i];

		if ( PowerUsage >= i + 1 )
		{
			// more ass manuevers
			switch(i)
			{
				case 0:
				case 1:
					SurfaceModifier.NewMaterial = GreenBarTex;
					break;
				case 2:
				case 3:
					SurfaceModifier.NewMaterial = YellowBarTex;
					break;
				default:
					SurfaceModifier.NewMaterial = RedBarTex;
					break;
			}
		}
		else
		{
			SurfaceModifier.NewMaterial = TransparentTex;
		}

		SurfaceModifier.ModifyLevelSurfaces();
	}
}


defaultproperties
{
	InitialPower=99.9
	PowerOutEvent="PowerOut"
}