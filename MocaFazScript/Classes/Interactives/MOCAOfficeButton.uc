class MOCAOfficeButton extends MOCAInteractiveProp;

enum ButtonPurpose
{
	BP_LeftDoor,
	BP_RightDoor,
	BP_LeftLight,
	BP_RightLight
};

var() ButtonPurpose ButtonTarget;
var() name EventToEmit;
var() name SurfaceTag;
var() Texture OnTexture;
var() Texture OffTexture;

var bool bButtonEnabled;
var MOCAPowerManager PowerManager;
var SurfaceModifyTrigger SurfaceModifier;


event PostBeginPlay()
{
	Super.PostBeginPlay();
	
	foreach AllActors(class'MOCAPowerManager', PowerManager)
	{
		break;
	}

	if ( PowerManager == None )
	{
		Log("ERROR: Power manager not found!!");
	}

	SurfaceModifier = Spawn(class'SurfaceModifyTrigger');

	if ( SurfaceModifier == None )
	{
		Log("ERROR: Could not spawn surface modifier");
	}
	else
	{
		SurfaceModifier.SurfaceTag = SurfaceTag;
		SurfaceModifier.bChangeMaterial = true;
	}
}

function SetOnSurface()
{
	SurfaceModifier.NewMaterial = OnTexture;
	SurfaceModifier.ModifyLevelSurfaces();
}

function SetOffSurface()
{
	SurfaceModifier.NewMaterial = OffTexture;
	SurfaceModifier.ModifyLevelSurfaces();
}

// this sucks
function ProcessInteract()
{
	if ( bButtonEnabled )
	{
		bButtonEnabled = false;

		SetOffSurface();

		TriggerEvent(EventToEmit, Self, None);

		switch(ButtonTarget)
		{
			case BP_LeftDoor:
				PowerManager.bLeftDoorClosed = false;
				break;
			case BP_RightDoor:
				PowerManager.bRightDoorClosed = false;
				break;
			case BP_LeftLight:
				PowerManager.bLeftLightOn = false;
				break;
			case BP_RightLight:
				PowerManager.bRightLightOn = false;
				break;
			default:
				break;
		}
	}
	else
	{
		bButtonEnabled = true;

		SetOnSurface();

		TriggerEvent(EventToEmit, Self, None);

		switch(ButtonTarget)
		{
			case BP_LeftDoor:
				PowerManager.bLeftDoorClosed = true;
				break;
			case BP_RightDoor:
				PowerManager.bRightDoorClosed = true;
				break;
			case BP_LeftLight:
				PowerManager.bLeftLightOn = true;
				break;
			case BP_RightLight:
				PowerManager.bRightLightOn = true;
				break;
			default:
				break;
		}
	}
}


defaultproperties
{
	bHidden=true
	DrawType=DT_Sprite
}