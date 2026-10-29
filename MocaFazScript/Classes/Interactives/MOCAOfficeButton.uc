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
var() Sound StingerSound;
var() Sound ErrorSFX;

var bool bBtnDisabled;

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
		SurfaceModifier.TriggerType = TT_EventOnly;
		SurfaceModifier.bDoActionWhenTriggered = true;
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
	if ( bBtnDisabled )
	{
		PlaySound(ErrorSFX, SLOT_Foley);
		return;
	}

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
				PlayStinger();
				break;
			case BP_RightLight:
				PowerManager.bRightLightOn = true;
				PlayStinger();
				break;
			default:
				break;
		}
	}
}

function PlayStinger()
{
	local MOCAAnimatronic A;
	foreach AllActors(class'MOCAAnimatronic', A)
	{
		if ( ( A.DoorToAttack == DTA_Left && ButtonTarget == BP_LeftLight ) || ( A.DoorToAttack == DTA_Right && ButtonTarget == BP_RightLight) )
		{
			if ( !A.bStingerCooldown && A.CurrDP.bIsKillPoint )
			{
				A.bStingerCooldown = true;
				A.PlaySound(StingerSound, SLOT_Effect);
				return;
			}
		}
	}
}


defaultproperties
{
	bHidden=true
	DrawType=DT_Sprite
}