class MOCACameraButton extends MOCAInteractiveProp;

var() int CameraIndex;

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
}

defaultproperties
{
	Lives=1
	CooldownDuration=1.0
}