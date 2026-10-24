class MOCACameraButton extends MOCAInteractiveProp;

var() int CameraIndex;
var() Sound ClickSound;

var MOCACameraManager CameraManager;

event PostBeginPlay()
{
	super.PostBeginPlay();
	
	foreach AllActors(class'MOCACameraManager', CameraManager)
	{
		break;
	}

	if ( CameraManager == None )
	{
		Log("ERROR: Could not find CameraManager!!!");
	}
}

function ProcessInteract()
{
	Log("Setting camera to index " $ CameraIndex);
	CameraManager.SetCamera(CameraIndex);

	if ( ClickSound != None )
	{
		PlaySound(ClickSound, SLOT_Foley);
	}
}

defaultproperties
{
	Lives=99999999
	CooldownDuration=0.1
}