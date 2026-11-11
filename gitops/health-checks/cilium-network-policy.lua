-- Lua Health Check for CiliumNetworkPolicy
hs = {}
if obj.status ~= nil then
  if obj.status.derivativePolicies ~= nil then
    hs.status = "Healthy"
    hs.message = "Cilium Network Policy successfully enforced across endpoints"
    return hs
  end
end

hs.status = "Healthy"
hs.message = "Cilium Network Policy applied"
return hs
