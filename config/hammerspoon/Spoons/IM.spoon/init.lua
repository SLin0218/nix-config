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

-- 面板/代理类应用（这些应用在获得和失去焦点时不会触发系统的 applicationWatcher）
local panelApps = {
	["Raycast"] = true,
	["Alfred"] = true,
	["Spotlight"] = true,
	["Search"] = true,
}

function obj:init()
	-- 统一的自动切换输入法逻辑
	local function switchInputForApp(appName)
		if not appName then
			return
		end
		local targetInput = fixedApps[appName] or obj.appInputSources[appName] or "com.apple.keylayout.ABC"
		local currentInput = hs.keycodes.currentSourceID()
		if currentInput ~= targetInput then
			print(string.format("[IM] Auto Switch (%s): %s -> %s", "Focus/Activate", appName, targetInput))
			hs.keycodes.currentSourceID(targetInput)
		end
	end

	-- 监听 App 激活事件（常规应用）
	local function applicationWatcher(appName, eventType, appObject)
		if eventType == hs.application.watcher.activated then
			switchInputForApp(appName)
		end
	end

	-- 监听输入法切换事件（订阅系统通知，比 hs.keycodes.inputSourceChanged 更稳定）
	local function inputSourceCallback(name, object, userInfo)
		print(string.format("[IM] Debug Focus: name=%s, object=%s, userInfo=%s", name, object, userInfo))
		local focusedWindow = hs.window.focusedWindow()
		local focusedApp = focusedWindow and focusedWindow:application()
		local focusedAppName = focusedApp and focusedApp:name() or "nil"

		local frontApp = hs.application.frontmostApplication()
		local frontAppName = frontApp and frontApp:name() or "nil"

		print(string.format("[IM] Debug Focus: focusedWindowApp=%s, frontmostApp=%s", focusedAppName, frontAppName))

		-- 优先通过当前获得键盘焦点的窗口来获取当前活动 App
		local activeApp = focusedApp or frontApp
		if activeApp then
			local appName = activeApp:name()
			if appName then
				-- 如果是 Raycast、Alfred 等特殊面板应用，我们不记录其输入法状态（避免污染前台应用记录）
				-- 而是开启一个临时的轻量级监听定时器，等它失焦后切回当前聚焦窗口 of the active app
				if panelApps[appName] then
					if not obj.panelFocusTimer then
						print(string.format("[IM] Started temporary focus timer for panel app: %s", appName))
						obj.panelFocusTimer = hs.timer.doEvery(0.1, function()
							local w = hs.window.focusedWindow()
							local app = w and w:application()
							local currentAppName = app and app:name()
							if not currentAppName then
								local fApp = hs.application.frontmostApplication()
								currentAppName = fApp and fApp:name()
							end

							-- 如果焦点已经不是这些面板应用了，说明面板已关闭或失焦
							if currentAppName and not panelApps[currentAppName] then
								print(
									string.format(
										"[IM] Panel app lost focus. Restoring input source for active app: %s",
										currentAppName
									)
								)
								switchInputForApp(currentAppName)
								-- 停止并清理定时器
								obj.panelFocusTimer:stop()
								obj.panelFocusTimer = nil
							end
						end)
					end
				else
					-- 正常应用，如果不是固定输入法的 App，则记录其输入法变更
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
	end

	-- 启动 App 监听器 (绑定在 obj 上以防止垃圾回收)
	obj.appWatcher = hs.application.watcher.new(applicationWatcher)
	obj.appWatcher:start()

	-- 启动输入法变更监听器 (绑定在 obj 上以防止垃圾回收)
	obj.inputWatcher = hs.distributednotifications.new(
		inputSourceCallback,
		"com.apple.Carbon.TISNotifySelectedKeyboardInputSourceChanged"
	)
	obj.inputWatcher:start()
end

return obj
