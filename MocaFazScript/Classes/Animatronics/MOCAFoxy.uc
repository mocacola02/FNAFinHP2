// some REAL jank shit in here, this definitely needs a full rewrite for V2
class MOCAFoxy extends MOCAAnimatronic;

var() float WaitTime;
var() float RunTime;
var() name SignSurfaceTag;
var() name RunAnim;
var() Texture NormalSignTexture;
var() Texture SpookySignTexture;
var() Sound BangSound;
var() Sound RunSound;
var() MOCADestinationPoint RunStartDP;
var() Array<SkeletalMesh> CurtainMeshes;

var bool bPendingKill;
var bool bCanDoOpportunity;
var int CurrPhase;
var float StunTimer;
var float RunTimer;

var SurfaceModifyTrigger SurfaceModifier;
var MOCADestinationPoint HomeDP;
var MOCAProp Curtain;


event PostBeginPlay()
{
	super.PostBeginPlay();

	HomeDP = CurrDP;

	SurfaceModifier = Spawn(Class'SurfaceModifyTrigger');
	
	if ( SurfaceModifier == None )
	{
		Log("ERROR: Failed to spawn SurfaceModifier!!!");
	}
	else
	{
		SurfaceModifier.SurfaceTag = SignSurfaceTag;
		SurfaceModifier.bChangeMaterial = true;
		UpdateSurface(NormalSignTexture);
	}
}

function bool IsBeingWatched()
{
	return CameraManager.bUtilized;
}

function bool IsSameCameraBeingWatched()
{
	return CurrDP.RelevantCamera == CameraManager.GetCurrentCamera();
}

function bool IsStunned()
{
	return StunTimer > 0.0;
}

function bool ShouldMove()
{
	if ( IsBeingWatched() || IsStunned() )
	{
		return false;
	}

	return super.ShouldMove();
}

function float GetStunTime()
{
	local float RandFloat;
	RandFloat = RandRange(50, 1050);
	RandFloat /= 60;
	return RandFloat;
}

function UpdateSurface(Texture NewTexture)
{
	SurfaceModifier.NewMaterial = NewTexture;
	Log("Changing to material " $ SurfaceModifier.NewMaterial $ " ...");
	SurfaceModifier.ModifyLevelSurfaces();
}

function bool IsPlayingSound(Sound SoundToTest)
{
	local int i;
	for ( i = 0; i < PlayingSounds.Length; i++ )
	{
		if ( PlayingSounds[i].Sound == SoundToTest )
		{
			return true;
		}
	}

	return false;
}

auto state stateAtCove
{
	function HandleMovementOpportunity()
	{
		if ( ShouldMove() )
		{
			local MOCADestinationPoint NewDP;
			NewDP = GetNewDestination();

			if ( NewDP == None )
			{
				Log(CutName $ ": Could not find a new destination!!!");
				return;
			}

			CurrDP = NewDP;
			SetLocation(NewDP.Location);
			SetRotation(NewDP.Rotation);
			PlayAnim(CurrDP.AnimToPlay);

			CurrPhase++;

			Curtain.Mesh = CurtainMeshes[CurrPhase];

			Log(CutName $ ": Increasing phase to " $ CurrPhase $ "!");
		}
	}

	event Tick(float DeltaTime)
	{
		StunTimer -= DeltaTime;

		if ( IsBeingWatched() )
		{
			bCanDoOpportunity = false;
			StunTimer = GetStunTime();
		}
		else if ( StunTimer <= 0.0 )
		{
			StunTimer = 0.0;
			bCanDoOpportunity = true;

			if ( CurrPhase > 2 )
			{
				GotoState('stateAwaitingRun');
			}
		}
	}
}

state stateAwaitingRun
{
	function HandleMovementOpportunity()
	{
	}

	event BeginState()
	{
		Log(CutName $ ": AWAITING RUN!!!!");

		WaitTime = MapDefault.WaitTime;

		if ( RunStartDP != None )
		{
			SetLocation(RunStartDP.Location);
		}
	}

	event EndState()
	{
		WaitTime = MapDefault.WaitTime;
	}

	event Tick(float DeltaTime)
	{
		WaitTime -= DeltaTime;

		if ( IsSameCameraBeingWatched() || WaitTime <= 0.0 )
		{
			Log(CutName $ ": We've been seen, BOOK IT!!!!");
			GotoState('stateRun');
		}
		else if ( WaitTime <= 0.0 )
		{
			Log(CutName $ ": This bum won't watch me, going directly to door");
			GotoState('stateAttack');
		}
	}
}

state stateRun
{
	function HandleMovementOpportunity()
	{
	}

	event Tick(float DeltaTime)
	{
		local vector NewPos;
		NewPos = Location - vec(768.0 * DeltaTime, 0.0, 0.0);
		SetLocation(NewPos);
	}

	begin:
		Log(Cutname $ ": RUNNING NOW!!!!!");
		PlayAnim(RunAnim);
		PlaySound(RunSound, SLOT_Foley);
		Sleep(RunTime);
		GotoState('stateAttack');
}

state stateAttack
{
	function HandleMovementOpportunity()
	{
	}

	event BeginState()
	{
		Log(CutName $ ": ATTACKING!!!!!!!");
		if ( !PowerManager.bLeftDoorClosed )
		{
			Log(CutName $ ": Fool didn't close his door");
			if ( CanKill() )
			{
				Log(CutName $ ": Killing player");
				Disable('Tick');
				Jumpscare();
			}
		}
		else
		{
			Log(CutName $ ": YARRRGH the door was closed!");
			PlaySound(BangSound, SLOT_Foley);
		}
	}
	
	event Tick(float DeltaTime)
	{
		if ( !IsPlayingSound(BangSound) )
		{
			local MOCADestinationPoint NewDP;
			NewDP = HomeDP;

			if ( NewDP == None )
			{
				Log(CutName $ ": Could not find a new destination!!!");
				return;
			}

			Log(CutName $ ": Our CurrDP is " $ CurrDP $ " with the camera " $ CurrDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

			// If we're looking at the pre-movement position, block cams
			if ( CurrDP != None && CameraManager.GetCurrentCamera() == CurrDP.RelevantCamera )
			{
				Log(CutName $ ": screw you and your cameras, BLOCKED");
				CameraManager.BlockCams();
			}

			Log(CutName $ ": Our NewDP is " $ NewDP $ " with the camera " $ NewDP.RelevantCamera $ " and the current camera is " $ CameraManager.GetCurrentCamera());

			// If we're looking at the destination position, block cams
			if ( CameraManager.GetCurrentCamera() == NewDP.RelevantCamera )
			{
				Log(CutName $ ": screw you and your cameras, BLOCKED");
				CameraManager.BlockCams();
			}

			CurrDP = NewDP;
			SetLocation(NewDP.Location);
			SetRotation(NewDP.Rotation);
			PlayAnim(CurrDP.AnimToPlay);

			CurrPhase = 0;
			Curtain.Mesh = CurtainMeshes[0];
			GotoState('stateAtCove');
		}
		else if ( !PowerManager.bLeftDoorClosed )
		{
			if ( CanKill() && !bPendingKill )
			{
				bPendingKill = true;
				SetTimer(0.2, false, 'Jumpscare');
			}
		}
	}
}

defaultproperties
{
	WaitTime=25.0
	RunTime=1.667
	SignSurfaceTag="SignSurface"
}