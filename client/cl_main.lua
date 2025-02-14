local QBCore = exports['qb-core']:GetCoreObject()
local ent
local pos
local animdict
local anim
local breakchance
local overheated = false
local loop = false


local boneoffsets = {
    ["w_am_digiscanner"] = {
        bone = 18905,
        offset = vector3(0.15, 0.1, 0.0),
        rotation = vector3(270.0, 90.0, 80.0),
    },
}

local function AttachEntity(ped, model)
    if boneoffsets[model] then
        QBCore.Functions.LoadModel(model)
        pos = GetEntityCoords(PlayerPedId())
        ent = CreateObjectNoOffset(model, pos, 1, 1, 0)
        AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, boneoffsets[model].bone), boneoffsets[model].offset, boneoffsets[model].rotation, 1, 1, 0, 0, 2, 1)
    end
end

RegisterNetEvent('qb-metaldetecting:startdetect', function(data)
    if inZone == 1 then 
        if not overheated then 
            QBCore.Functions.Progressbar('start_detect', 'Szukanie...', Config.DetectTime, false, true, { -- Name | Label | Time | useWhileDead | canCancel
            disableMovement = true,
            disableCarMovement = true,
            disableMouse = false,
            disableCombat = true,
            }, {
            animDict = 'mini@golfai',
            anim = 'wood_idle_a',
            flags = 49,
            }, {}, {}, function()
                TriggerServerEvent("InteractSound_SV:PlayWithinDistance", 10, 'metaldetector', 0.2)
                Wait(2000)
                TriggerServerEvent('qb-metaldetecting:DetectReward')
                breakchance = math.random(1,100)
                if breakchance <= Config.OverheatChance then
                    overheated = true
                    QBCore.Functions.Notify('Your metal detector has overheated! Let it cool down.', 'error', 4000)
                    Wait(Config.OverheatTime)
                    overheated = false
                    QBCore.Functions.Notify('Your metal detector has cooled down.', 'info', 4000)
                end
            end, function() 
                Wait(100)
            end)
        else 
            QBCore.Functions.Notify('Your metal detector is still too hot!', 'error', 5000)
        end 
    else 
        QBCore.Functions.Notify('You cannot detect here. Find a suitable location.', 'error', 5000)
    end
end)

AddEventHandler('onResourceStart', function(resourceName)
	if (GetCurrentResourceName() ~= resourceName) then return end
    loop = false
    LoopItem()
end)

RegisterNetEvent("QBCore:Client:OnPlayerLoaded", function()
    Wait(7000)
    loop = false
    LoopItem()
end)

RegisterNetEvent('QBCore:Client:OnPlayerUnload', function()
    loop = true
end)

function LoopItem()
    CreateThread(function()
        while true do
            if loop == true and DoesEntityExist(ent) then
                DeleteEntity(ent)
                DeleteObject(ent)
                for _, v in pairs(GetGamePool("CObject")) do
                    if IsEntityAttachedToEntity(PlayerPedId(), v) then
                      SetEntityAsMissionEntity(v, true, true)
                      DeleteObject(v)
                      DeleteEntity(v)
                    end
                end
				break
			end
            local hasItem = QBCore.Functions.HasItem('metaldetector')
            if hasItem then
                model = 'w_am_digiscanner'
                ped = PlayerPedId()
                if boneoffsets[model] and not DoesEntityExist(ent) then
                    QBCore.Functions.LoadModel(model)
                    pos = GetEntityCoords(PlayerPedId())
                    ent = CreateObject(model, pos, 1, 1, 0)
                    AttachEntityToEntity(ent, ped, GetPedBoneIndex(ped, boneoffsets[model].bone), boneoffsets[model].offset, boneoffsets[model].rotation, 1, 1, 0, 0, 2, 1)
                end
            else
                if DoesEntityExist(ent) then
                    for _, v in pairs(GetGamePool("CObject")) do
                        if IsEntityAttachedToEntity(PlayerPedId(), v) then
                          SetEntityAsMissionEntity(v, true, true)
                          DeleteObject(v)
                          DeleteEntity(v)
                        end
                    end
                end
            end
            Citizen.Wait(250)
        end
    end)
end

CreateThread(function()
    for k, v in pairs(Config.DetectZones) do
        local MetalZone = PolyZone:Create(v.zones, {
            name = v.label,
            debugPoly = Config.DebugPoly
        })
        
        MetalZone:onPlayerInOut(function(isPointInside)
            if isPointInside then
                inZone = 1
            else
                inZone = 0
            end
        end)
    end
end)