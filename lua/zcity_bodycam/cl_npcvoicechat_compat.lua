-- NPC Voice Chat compatibility for ZC Bodycam.
-- This file intentionally does not create a second audio path: Bodycam's video
-- recorder captures the normal engine mix, which is where NPCVC's 3D channels live.
if not CLIENT then return end

hook.Add("InitPostEntity", "ZCBodycam_NPCVCCompatibility", function()
    if not ZCBodycam then return end
    ZCBodycam.NPCVoiceChatCompatible = true
end)

-- Do not stop, flatten, or replace NPCVC channels while recording. This hook is
-- informational and gives future versions of NPCVC a stable integration point.
hook.Add("Think", "ZCBodycam_NPCVCCompatibilityState", function()
    if not ZCBodycam then return end
    ZCBodycam.RecordingAudio = ZCBodycam.Recording == true
end)
