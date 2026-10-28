class MOCAPhone extends MOCAInteractiveProp;

function StopAllSounds()
{
	local int i;

	for ( i = 0; i < PlayingSounds.Length; i++ )
	{
		StopSound(PlayingSounds[i].Sound, PlayingSounds[i].Slot, 0.0);
	}
}

function ProcessInteract()
{
    StopAllSounds();
}