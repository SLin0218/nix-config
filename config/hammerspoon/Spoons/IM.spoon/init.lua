--- === IM Auto Switch ===

local obj = {}
obj.__index = obj

-- Metadata
obj.name = "IM"
obj.version = "1.0"
obj.author = "DengShiLin <dengsl.dev@gmail.com>"

-- 1. 用于记录每个 App 选择的输入法，刚开始为空
obj.appInputSources = {}

-- 固定输入法的 App 规则（微信固定使用鼠须管 Squirrel，Emacs 固定使用 ABC）
local fixedApps = {
	["微信"] = "im.rime.inputmethod.Squirrel.Hans",
	["WeChat"] = "im.rime.inputmethod.Squirrel.Hans",
	["Emacs"] = "com.apple.keylayout.ABC",
}

function obj:init()
	-- 监听 App 激活事件
	local function applicationWatcher(appName, eventType, appObject)
		if eventType == hs.application.watcher.activated then
			-- 如果是固定输入法的 App，直接使用固定值；否则使用记录的输入法或默认 ABC
			local targetInput = fixedApps[appName] or obj.appInputSources[appName] or "com.apple.keylayout.ABC"
			local currentInput = hs.keycodes.currentSourceID()
			-- 如果当前输入法与目标输入法不同，则自动切换
			if currentInput ~= targetInput then
				print(string.format("[IM] Auto Switch: %s -> %s", appName, targetInput))
				hs.keycodes.currentSourceID(targetInput)
			end
		end
	end

	-- 监听输入法切换事件（订阅系统通知，比 hs.keycodes.inputSourceChanged 更稳定）
	local function inputSourceCallback(name, object, userInfo)
		local frontApp = hs.application.frontmostApplication()
		if frontApp then
			local appName = frontApp:name()
			if appName then
				-- 如果是固定输入法的 App，不记录其输入法变更，避免污染记录
				if not fixedApps[appName] then
					local currentInput = hs.keycodes.currentSourceID()
					-- 如果当前记录值与实际输入法不一致，更新并记录
					if obj.appInputSources[appName] ~= currentInput then
						obj.appInputSources[appName] = currentInput
						print(string.format("[IM] Recorded: %s -> %s", appName, currentInput))
					end
				end
			end
		end
	end

	-- 启动 App 监听器
	appWatcher = hs.application.watcher.new(applicationWatcher)
	appWatcher:start()

	-- 启动输入法变更监听器
	inputWatcher = hs.distributednotifications.new(
		inputSourceCallback,
		"com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"
	)
	inputWatcher:start()
end

return obj
