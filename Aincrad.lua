for _, v in pairs(workspace:GetDescendants()) do
    if v:IsA("Model") or v:IsA("BasePart") then
        print(v.Name, "|", v.ClassName)
    end
end