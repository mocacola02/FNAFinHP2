class MOCAFlickerController extends Actor;

var() bool bStartActive;
var() float FlickerFreq;
var() Sound OnSound;
var() Array<Light> LightsToFlicker;

var bool bIsActive;

event PostBeginPlay()
{
    Super.PostBeginPlay();
    
    if ( bStartActive )
    {
        bIsActive = true;
        SetTimer(FlickerFreq, true, 'FlickerLights');
    }
}

event Trigger(Actor Other, Pawn EventInstigator)
{
    if ( bIsActive )
    {
        Log("Deactivating flicker");
        bIsActive = false;
        SetTimer(0.0, false, 'FlickerLights');
        local int i;
        for ( i = 0; i < LightsToFlicker.Length; i++ )
        {
            LightsToFlicker[i].LightBrightness = 0;
        }
    }
    else
    {
        Log("Activating flicker");
        bIsActive = true;
        SetTimer(FlickerFreq, true, 'FlickerLights');
    }
}

function FlickerLights()
{
    local int RandInt;
    RandInt = Rand(3);

    if ( RandInt == 0 )
    {
        local int i;
        for ( i = 0; i < LightsToFlicker.Length; i++ )
        {
            if ( LightsToFlicker[i].LightBrightness == 0 )
            {
                LightsToFlicker[i].LightBrightness = LightsToFlicker[i].MapDefault.LightBrightness;
                LightsToFlicker[i].PlaySound(OnSound, SLOT_Ambient);
            }
            else
            {
                LightsToFlicker[i].LightBrightness = 0;
                LightsToFlicker[i].StopSound(OnSound, SLOT_Ambient);
            }
        }
    }
}

function bool CutCommand(string command, optional string cue, optional bool bFastFlag)
{
	local string sActualCommand;

	sActualCommand = ParseDelimitedString( command, " ", 1, false );
	
	if( sActualCommand ~= "ToggleFlicker" )
	{
		return CutCommand_ToggleFlicker(command, cue, bFastFlag);
	}

	return Super.CutCommand(command, cue, bFastFlag);
}

function bool CutCommand_ToggleFlicker(string command, optional string cue, optional bool bFastFlag)
{
	Trigger(Self, None);
	CutCue(cue);
	return true;
}


defaultproperties
{
    FlickerFreq=0.1

    bHidden=true
}