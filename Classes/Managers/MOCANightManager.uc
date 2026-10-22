class MOCANightManager extends MOCAFNAFManagers;

var() int NightLength;	// Moca: Night length in seconds.

var int CurrNight;
var int CurrTime;


function SetNight(int NewNight)
{
	CurrNight = NewNight;
}

function StartNight();

//==============
// CutCommands
//==============

function bool CutCommand(string command, optional string cue, optional bool bFastFlag)
{
	local string sActualCommand;
	local string targetName;
	local actor tempActor;
	local sound tempSound;
	local bool bTemp;
	local string tempStr;


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
}


//=====================
// Default Properties
//=====================

defaultproperties
{
	NightLength=534
}