local meta = FindMetaTable("Entity")
/// MANIFEST LINKS:
/// Principles: P-080 (Readability - Entity outlines/halos)
if not meta then return end

function meta:SetRenderBoundsNumber(fNum)
	local fNumNegative = -fNum
	self:SetRenderBounds(Vector(fNumNegative, fNumNegative, fNumNegative), Vector(fNum, fNum, fNum))
end
