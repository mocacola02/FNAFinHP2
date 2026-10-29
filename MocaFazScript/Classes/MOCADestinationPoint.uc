class MOCADestinationPoint extends Actor;

var() name AnimToPlay;	// Moca: What animation to play at this point?
var() name EventOnMove;
var() Array<MOCADestinationPoint> Destinations;	// Moca: What destinations are available from this point?
var() bool bBlockedByCamera;	// Moca: Can this destination point be blocked if it is being watched?
var() MOCASecurityCamera RelevantCamera; // Moca: What camera, if any, is watching this point?
var() bool bIsKillPoint;

function MOCADestinationPoint GetValidDestination()
{
	local int i;
	local Array<MOCADestinationPoint> ValidDPs;

	for ( i = 0; i < Destinations.Length; i++ )
	{
		if ( bBlockedByCamera )
		{
			continue;
		}

		ValidDPs.AddItem(Destinations[i]);
	}

	if ( ValidDPs.Length <= 0 )
	{
		return None;
	}

	local int rnd;
	rnd = Rand(ValidDPs.Length);

	return ValidDPs[rnd];
}

defaultproperties
{
	AnimToPlay="GenericStandIdle"
}