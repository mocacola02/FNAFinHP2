class MOCAAnimatronic extends MOCAPawn;

var() name EventOnKill;

var int AILevel;
var int MaxAI;

var Sound WarbledVoiceSFX;
var Array<Sound> FootstepSFX;
var Array<Sound> GotInSFX;


defaultproperties
{
	EventOnKill="BonnieKill"
	MaxAI=20
}