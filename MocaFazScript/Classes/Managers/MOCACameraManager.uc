class MOCACameraManager extends MOCAFNAFManagers;

struct CameraEntry
{
	var() name CameraTag;
	var() Texture CameraTexture;
};

var() int 	PowerUsage;		// Moca: How much power usage using the cameras adds.
var() float RequiredMinDot;	// Moca: Required dot product for Harry to be considered as looking at cameras.
var() float ActivationDistance;

var() name CameraSurfaceTag;			// Moca: Surface tag of the camera screen surface.
var() Array<CameraEntry> Cameras;// Moca: List of cameras to manage.
var() Texture BlankScreenTexture;		// Moca: Texture to use for the blank (inactive) camera screen.
var() Texture BlockedScreenTexture;		// Moca: Texture to use for blocked cameras.
var() float CameraBlockDuration;	// Moca: How long cameras stay blocked.
var() Array<Sound> CameraBlockSFX;	// Moca: Sounds to play when the cameras get blocked.

var() Sound OpenSFX;
var() Sound CloseSFX;

var bool bUtilized;
var bool bBlocked;
var int CurrCamera;

var SurfaceModifyTrigger SurfaceModifier;
var MOCAPowerManager PowerManager;


// Finds and stores a reference to the power manager and surface modifier
event PostBeginPlay()
{
	super.PostBeginPlay();
	
	foreach AllActors(class'MOCAPowerManager', PowerManager)
	{
		break;
	}

	if ( PowerManager == None )
	{
		Log("ERROR: CameraManager could not find the PowerManager!!!");
	}

	SurfaceModifier = Spawn(Class'SurfaceModifyTrigger');
	
	if ( SurfaceModifier == None )
	{
		Log("ERROR: Failed to spawn SurfaceModifier!!!");
	}
	else
	{
		SurfaceModifier.SurfaceTag = CameraSurfaceTag;
		SurfaceModifier.bChangeMaterial = true;
		UpdateSurface(true);
	}
}

// Checks if Harry is facing the camera, and calls the proper utilization function based on that
event Tick(float DeltaTime)
{
	super.Tick(DeltaTime);

	if ( IsFacingOther(Level.PlayerHarryActor, Self, RequiredMinDot) && VSize(Location - PlayerHarry.Location) <= ActivationDistance )
	{
		OnCameraUtilized();
	}
	else
	{
		OnCameraNotUtilized();
	}
}

// This utilization system feels a bit dicey, but we'll see if it works

// Called when the camera is being utilized
function OnCameraUtilized()
{
	if ( bUtilized )
	{
		return;
	}

	Log("Camera is being utilized");
	Log("Distance: " $ VSize(PlayerHarry.Location - Location));

	bUtilized = true;
	PowerManager.CurrentUsage += PowerUsage;
	UpdateSurface();

	if ( OpenSFX != None )
	{
		PlaySound(OpenSFX, SLOT_Foley);
	}
}

// Called when the camera is not being utilized
function OnCameraNotUtilized()
{
	if ( !bUtilized )
	{
		return;
	}

	Log("Camera is not being utilized");
	Log("Distance: " $ VSize(PlayerHarry.Location - Location));

	bUtilized = false;
	PowerManager.CurrentUsage -= PowerUsage;
	UpdateSurface(true);

	if ( CloseSFX != None )
	{
		PlaySound(CloseSFX, SLOT_Foley);
	}
}

function SetCamera(int CameraIndex)
{
	CurrCamera = CameraIndex;

	Log("Our camera is now index " $ CameraIndex $ " which is the actor " $ GetCurrentCamera());

	OnCameraChanged();
}

// Called when the camera is changed to another camera
function OnCameraChanged()
{
	UpdateSurface();
}

// Returns the render texture of a given camera
function Texture GetCameraTexture(int idx)
{
	if ( idx > Cameras.Length )
	{
		return BlankScreenTexture;
	}

	return Cameras[idx].CameraTexture;
}

function int GetCameraIndex(MOCASecurityCamera Cam)
{
	local name CamTag;

	CamTag = Cam.Tag;

	local int i;

	for ( i = 0; i < Cameras.Length; i++ )
	{
		if ( Cameras[i].CameraTag == CamTag )
		{
			return i;
		}
	}

	return -1;
}

function MOCASecurityCamera GetCameraFromIndex(int idx)
{
	if ( idx > Cameras.Length )
	{
		return None;
	}

	local MOCASecurityCamera A;
	
	foreach AllActors(class'MOCASecurityCamera', A, Cameras[idx].CameraTag)
	{
		return A;
	}

	return None;
}

function MOCASecurityCamera GetCurrentCamera()
{
	return GetCameraFromIndex(CurrCamera);
}

function BlockCams()
{
	bBlocked = true;
	SetTimer(CameraBlockDuration, false, 'UnblockCams');
	
	local Sound BlockedSFX;
	BlockedSFX = GetBlockedSFX();

	if ( BlockedSFX != None )
	{
		PlaySound(BlockedSFX, SLOT_Foley);
	}

	UpdateSurface();
}

function Sound GetBlockedSFX()
{
	if ( CameraBlockSFX.Length <= 0 )
	{
		return None;
	}

	local int rnd;
	rnd = Rand(CameraBlockSFX.Length);

	return CameraBlockSFX[rnd];
}

function UnblockCams()
{
	bBlocked = false;
	UpdateSurface();
}

// Updates the camera screen surface to a new camera screen, or blank if bBlank
function UpdateSurface(optional bool bBlank)
{
	Log("Updating camera surface");

	if ( bBlank )
	{
		SurfaceModifier.NewMaterial = BlankScreenTexture;
	}
	else if ( bBlocked )
	{
		Log("CameraManager: Setting camera material to blocked texture");
		SurfaceModifier.NewMaterial = BlockedScreenTexture;
	}
	else
	{
		SurfaceModifier.NewMaterial = GetCameraTexture(CurrCamera);
	}
	
	Log("Changing to material " $ SurfaceModifier.NewMaterial $ " ...");
	SurfaceModifier.ModifyLevelSurfaces();
}



defaultproperties
{
	PowerUsage=1
	RequiredMinDot=0.25
	ActivationDistance=192.0

	CameraSurfaceTag="CameraScreen"
	
	BlankScreenTexture=Texture'HGame.Icons.leftPanel'
	BlockedScreenTexture=Texture'HGame.Icons.leftPanel'
	CameraBlockDuration=5.0
}