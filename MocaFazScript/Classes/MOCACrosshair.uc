class MOCACrosshair extends Actor;

var() float CrosshairOffset;

// incredibly lazy, i just need something that works quick
// mostly copied from MOCAWandless trace logic, since i want it to line up with that
event Tick(float DeltaTime)
{
    local harry PlayerHarry;
    PlayerHarry = harry(Level.PlayerHarryActor);

    local vector TraceStart, TraceEnd, TraceDirection;

    TraceStart = PlayerHarry.Cam.Location;
    TraceDirection = vector(PlayerHarry.Cam.Rotation);
    TraceEnd = TraceStart + TraceDirection * CrosshairOffset;

    SetLocation(TraceEnd);
}

defaultproperties
{
    CrosshairOffset=5.0

    DrawType=DT_Sprite
    Texture=Texture'UWindow.Icons.MouseMove'
}