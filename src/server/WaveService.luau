-- WaveService: the Banjir Begal. Every 100 seconds a red wave sweeps the
-- whole map from west to east. Players caught outside their own base are
-- thrown back home and lose 10% of their cash, so every catch ends in a
-- dash home. The wave is announced 10 seconds ahead, with a countdown.

local TweenService = game:GetService("TweenService")

local PlayerData = require(script.Parent:WaitForChild("PlayerData"))
local BaseManager = require(script.Parent:WaitForChild("BaseManager"))
local Notifier = require(script.Parent:WaitForChild("Notifier"))

local WaveService = {}

local WAVE_INTERVAL = 100
local WARN_SECONDS = 10
local ACTIVE_SECONDS = 8

local waveRemote = nil

function WaveService.init(remotes)
	waveRemote = remotes:WaitForChild("WaveUpdate")

	task.spawn(function()
		while true do
			task.wait(WAVE_INTERVAL)

			-- Warning: 10 seconds to get home.
			for s = WARN_SECONDS, 1, -1 do
				waveRemote:FireAllClients({ phase = "warn", secondsLeft = s })
				task.wait(1)
			end

			-- The wave itself: a red wall sweeping west to east.
			waveRemote:FireAllClients({ phase = "active", secondsLeft = ACTIVE_SECONDS })
			Notifier.all("BANJIR BEGAL! Lari pulang ke base sekarang!", "warn")
			local wall = Instance.new("Part")
			wall.Name = "BanjirWall"
			wall.Size = Vector3.new(2, 24, 220)
			wall.Color = Color3.fromRGB(255, 40, 40)
			wall.Material = Enum.Material.Neon
			wall.Transparency = 0.4
			wall.Anchored = true
			wall.CanCollide = false
			wall.CFrame = CFrame.new(-110, 12, 20)
			wall.Parent = workspace
			local sweep = TweenService:Create(wall, TweenInfo.new(ACTIVE_SECONDS, Enum.EasingStyle.Linear), {
				CFrame = CFrame.new(110, 12, 20),
			})
			sweep:Play()

			local started = os.clock()
			while os.clock() - started < ACTIVE_SECONDS do
				for _, data in ipairs(PlayerData.all()) do
					local player = data.player
					if not BaseManager.isInsideOwnBase(player) then
						local base = BaseManager.baseOf(player)
						local character = player.Character
						if base ~= nil and character ~= nil then
							local root = character:FindFirstChild("HumanoidRootPart")
							if root ~= nil then
								local lost = math.floor(data.cash * 0.1)
								data.cash = data.cash - lost
								root.CFrame = CFrame.new(base.center.X, 3, base.center.Z)
								Notifier.to(player, "Kamu kena banjir! -$" .. lost .. " dan dilempar pulang ke base.", "warn")
							end
						end
					end
				end
				task.wait(0.5)
			end

			wall:Destroy()
			waveRemote:FireAllClients({ phase = "clear", secondsLeft = 0 })
			Notifier.all("Banjir lewat. Aman!", "good")
		end
	end)
end

return WaveService
