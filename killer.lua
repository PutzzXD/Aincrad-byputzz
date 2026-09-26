--[[
CATATAN DEBUG:

Masalah sebelumnya: Killer tidak terdeteksi, hanya ESP biru yang muncul.

Penyebab: detectRole() lama hanya cek Tool name ("knife"/"weapon").
Di game STK versi sekarang, Tool mungkin tidak selalu ada di Character,
atau nama Tool berbeda.

Fix: isKiller() sekarang pakai 5 metode:
1. Attribute "Role" di Character/Player
2. ObjectValue/StringValue/BoolValue di Character
3. Team name
4. Tool name (fallback)
5. Folder "Killers" di Workspace

Jika MASIH tidak terdeteksi, kemungkinan:
- Game pakai sistem role yang di-encode (bukan string biasa)
- Role disimpan di module script yang tidak bisa diakses client

Untuk debug, jalankan ini di executor:
for _, p in pairs(game.Players:GetPlayers()) do
    print(p.Name, p.Team, p:GetAttribute("Role"))
    if p.Character then
        for _, o in pairs(p.Character:GetChildren()) do
            print("  ", o.ClassName, o.Name, o:IsA("ValueBase") and o.Value or "")
        end
    end
end
]]