-- Lua Health Check for Kyverno ClusterPolicy
hs = {}
if obj.status ~= nil then
  if obj.status.ready ~= nil and obj.status.ready == true then
    hs.status = "Healthy"
    hs.message = "Kyverno ClusterPolicy is active and validating admission requests"
    return hs
  end
end

hs.status = "Progressing"
hs.message = "Waiting for Kyverno admission webhook controller to acknowledge policy"
return hs
