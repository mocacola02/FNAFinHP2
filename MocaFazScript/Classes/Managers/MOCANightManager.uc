class MOCANightManager extends MOCAFNAFManagers;

const NUM_OF_HOURS = 6;

var() int NightLength;	// Moca: Night length in seconds.
var() float NightDesaturation;	// Moca: How much desaturation to apply to the screen during the night.
var() float FirstPersonHeight;	// Moca: How high up the first person camera should be.
var() name TimeSurfaceTag;
var() Array<Texture> HourTextures;

var bool bActive;

var int CurrNight;
var int CurrTime;
var int CurrHour;

var SurfaceModifyTrigger SurfaceModifier;


event PostBeginPlay()
{
	super.PostBeginPlay();

	SurfaceModifier = Spawn(Class'SurfaceModifyTrigger');
	
	if ( SurfaceModifier == None )
	{
		Log("ERROR: Failed to spawn SurfaceModifier!!!");
	}
	else
	{
		SurfaceModifier.SurfaceTag = TimeSurfaceTag;
		SurfaceModifier.bChangeMaterial = true;
		UpdateSurface(0);
	}
}

// Updates the camera screen surface to a new camera screen, or blank if bBlank
function UpdateSurface(int Hour)
{
	if ( Hour > HourTextures.Length || HourTextures[Hour] == None )
	{
		return;
	}

	SurfaceModifier.NewMaterial = HourTextures[Hour];
	SurfaceModifier.ModifyLevelSurfaces();
}

function SetNight(int NewNight)
{
	CurrNight = NewNight;
}

function StartNight()
{
	bActive = true;

	local MOCAAnimatronic A;
	
	foreach AllActors(class'MOCAAnimatronic', A)
	{
		A.OnStartNight();
	}

	PlayerHarry.SetBWPercent(NightDesaturation);
	HPConsole(PlayerHarry.Player.Console).FPSMode();
	PlayerHarry.Cam.SetZOffset(FirstPersonHeight);

	StartNightTimer();
}

function StartNightTimer()
{
	SetTimer(1.0, true, 'IncrementTime');
}

function StopNightTimer()
{
	SetTimer(0.0, false, 'IncrementTime');
}

function IncrementTime()
{
	local MOCAAnimatronic A;

	if ( bActive )
	{
		CurrTime++;

		Log("Time is " $ CurrTime);

		local int HourCheck;
		HourCheck = GetCurrentHour();

		if ( CurrHour != HourCheck )
		{
			CurrHour = HourCheck;

			Log("Hour is now " $ CurrHour);

			UpdateSurface(CurrHour);

			foreach AllActors(class'MOCAAnimatronic', A)
			{
				A.OnNewHour(CurrHour);
			}
		}

		if ( CurrTime >= NightLength )
		{
			bActive = false;
			StopNightTimer();
			
			foreach AllActors(class'MOCAAnimatronic', A)
			{
				A.OnNightEnd();
			}
		}
	}
	
}

function int GetHourInSeconds(int Hour)
{
	Hour = Clamp(Hour, 0, NUM_OF_HOURS);

	local int SecondsLen;
	SecondsLen = NightLength / NUM_OF_HOURS;
	return Hour * SecondsLen;
}

function int GetCurrentHour()
{
	local int i;

	for ( i = 0; i < NUM_OF_HOURS; i++ )
	{
		local int HourTime, NextHourTime;
		HourTime = GetHourInSeconds(i);
		NextHourTime = GetHourInSeconds(Clamp(i + 1, 0, NUM_OF_HOURS));

		if ( CurrTime >= HourTime && CurrTime < NextHourTime )
		{
			return i;
		}
	}

	return 0;
}

//==============
// CutCommands
//==============

function bool CutCommand(string command, optional string cue, optional bool bFastFlag)
{
	local string sActualCommand;

	sActualCommand = ParseDelimitedString( command, " ", 1, false );
	
	if( sActualCommand ~= "StartNight" )
	{
		return CutCommand_StartNight(command, cue, bFastFlag);
	}

	
	return Super.CutCommand(command, cue, bFastFlag);
}

function bool CutCommand_StartNight(string command, optional string cue, optional bool bFastFlag)
{
	local int TargetNight;
	TargetNight = AtoI(ParseDelimitedString( command, " ", 2, false ));
	TargetNight = Clamp(TargetNight, 1, 6);

	SetNight(TargetNight);
	StartNight();
	CutCue(cue);
	return TargetNight == CurrNight;
}


//=====================
// Default Properties
//=====================

defaultproperties
{
	NightLength=534
	NightDesaturation=0.4
	FirstPersonHeight=60.0
}