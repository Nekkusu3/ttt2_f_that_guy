-- f_that_guy.lua

AddCSLuaFile()

SWEP.ClassName = "weapon_ttt2_f_that_guy"
SWEP.PrintName = "f_that_guy"
SWEP.Author = "Your Name"
SWEP.Contact = "Your Email"
SWEP.Purpose = "Select a player to set their HP to 1."
SWEP.Instructions = "Left click to open selection GUI."

SWEP.Slot = 7
SWEP.SlotPos = 1
SWEP.Kind = WEAPON_EQUIP
SWEP.Spawnable = true
SWEP.AdminOnly = false

SWEP.ViewModel = "models/weapons/v_pistol.mdl"
SWEP.WorldModel = "models/weapons/w_pistol.mdl"

SWEP.Primary.ClipSize = 1 -- One use
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = false
SWEP.Primary.Ammo = "none"

SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = -1
SWEP.Secondary.Automatic = false
SWEP.Secondary.Ammo = "none"

SWEP.Base = "weapon_tttbase"

SWEP.Icon = "VGUI/ttt/icon_f_that_guy.vtf" -- Corrected to explicitly use .vtf

-- Custom variables for our SWEP
SWEP.Selecting = false
SWEP.TargetPlayer = nil
SWEP.Used = false  -- New variable to track if the weapon has been used

-- For the equipment menu in TTT
SWEP.EquipMenuData = {
    type = "item_weapon",
    desc = "Select a player to set their HP to 1."
}

if SERVER then
    -- Server-side functions
    resource.AddFile("sound/fuckyou.wav") -- Add the sound file for clients to download
    resource.AddFile("materials/vgui/ttt/icon_f_that_guy.vtf")
    resource.AddFile("materials/vgui/ttt/icon_f_that_guy.vmt")

    util.AddNetworkString("OpenPlayerSelection")
    util.AddNetworkString("SetPlayerHealth")

    sound.Add({
        name = "FuckYouSound",
        channel = CHAN_STATIC,
        volume = 1.0,
        level = 75,
        pitch = 100,
        sound = "fuckyou.wav"
    })

    local function SlowHeal(ply, originalHealth)
        if not IsValid(ply) or not ply:Alive() then return end
        local currentHealth = ply:Health()
        if currentHealth < originalHealth then
            ply:SetHealth(math.min(originalHealth, currentHealth + 2)) -- Heal by 2 HP per second
            timer.Simple(1, function() SlowHeal(ply, originalHealth) end) -- Repeat every second
        end
    end

    net.Receive("SetPlayerHealth", function(len, ply)
        local target = net.ReadEntity()
        if IsValid(target) and target:IsPlayer() then
            local originalHealth = target:Health()
            target:SetHealth(1)
            -- Play sound directly from target, omitting the full path
            target:EmitSound("fuckyou.wav", 75, 100)
            timer.Simple(1, function() SlowHeal(target, originalHealth) end)
        end
    end)
else -- CLIENT
    -- Function to handle the selection logic
    local function HandleSelection(self)
        if self.Used then return end  -- Prevent use if already used
        self.Selecting = true
        local frame = vgui.Create("DFrame")
        frame:SetSize(300, 400)
        frame:Center()
        frame:SetTitle("Select a Player to 'f_that_guy'")
        frame:MakePopup()

        local list = vgui.Create("DListView", frame)
        list:Dock(FILL)
        list:AddColumn("Players")

        -- Fill the list with alive players
        for k, v in pairs(player.GetAll()) do
            if v:Alive() then
                list:AddLine(v:Nick())
            end
        end

        local button = vgui.Create("DButton", frame)
        button:SetText("fuck that guy")
        button:Dock(BOTTOM)
        button.DoClick = function()
            local selected = list:GetSelected()[1]
            if selected then
                local playerName = selected:GetValue(1)
                for _, ply in pairs(player.GetAll()) do
                    if ply:Nick() == playerName then
                        self.TargetPlayer = ply
                        frame:Close()
                        -- Send network message to server to apply effect
                        net.Start("SetPlayerHealth")
                        net.WriteEntity(self.TargetPlayer)
                        net.SendToServer()
                        if SERVER then  -- This block should only execute on the server side
                            self:TakePrimaryAmmo(1)
                            self:SetClip1(0)  -- Reflect this in the HUD
                        end
                        self.Used = true  -- Mark as used
                        break
                    end
                end
            end
        end
    end

    -- Primary Attack does nothing but calls the selection logic
    function SWEP:PrimaryAttack()
        if not IsFirstTimePredicted() then return end
        HandleSelection(self)
        return false -- Prevent any bullet firing or sound playing for shooting
    end

    -- Remove functionality from SecondaryAttack
    function SWEP:SecondaryAttack()
        -- Do nothing
    end
end