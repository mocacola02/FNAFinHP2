class MOCAFNAFManagers extends HPawn;

function bool IsFacingOther(Actor SourceActor, Actor Other, float MinDot)
{
	local float DotProduct;

	DotProduct = Vector(SourceActor.Rotation) Dot Normal(Other.Location - SourceActor.Location);

	return DotProduct > MinDot;
}