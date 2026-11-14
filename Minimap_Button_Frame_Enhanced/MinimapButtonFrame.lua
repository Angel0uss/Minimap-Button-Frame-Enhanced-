MBFversion = GetAddOnMetadata("Minimap_Button_Frame_Enhanced", "Version");
MBF_DRAGTITLE = "MBF " .. MBFversion;

local LibStub = LibStub
MBF = LibStub("AceAddon-3.0"):NewAddon("Minimap Button Frame Enhanced", "AceConsole-3.0", "AceEvent-3.0", "AceTimer-3.0")
local L = LibStub("AceLocale-3.0"):GetLocale("Minimap Button Frame", true)
if not L then
	-- No locale table got registered (e.g. Locale\Locale-*.lua files missing from
	-- the install). Fall back to a built-in English table instead of nil, so the
	-- addon works correctly even without the Locale folder present. Keys that are
	-- already plain English sentences aren't listed here; the __index fallback
	-- below returns the key itself for those, which reads fine as-is.
	local MBF_FallbackEnglish = {
		["ADDON"]                 = "Minimap Button Frame Enhanced",
		["MBF"]                   = "MBF",
		["MBF_LDB_TOOLTIP"]       = "Left-click to show/hide, shift-click for options.",
		["MBF_TOOLTIP_ROLLUP"]    = "Right-click and drag to move.",
		["MBF_UnnamedObject"]     = "Unnamed Object",

		["MBF_ERR1"]              = "Could not restore this button's original settings",
		["MBF_ERR2"]              = "Cannot remove.  Protected or parent frame is restricted",
		["MBF_ERR3"]              = "Could not restore settings for invisible button",
		["MBF_ERR4"]              = "Cannot add.  Protected or already included",
		["MBF_ERR5"]              = "Could not remove stored script information for this button",
		["MBF_ERR6"]              = "Could not add this button to the frame",
		["MBF_ERR7"]              = "That button does not exist",

		["MBF_SLASH_Detail1"]     = "/mbf - displays the command line options in the chat frame",
		["MBF_SLASH_Detail2"]     = "/mbf add <button> - adds a non gathered button to the frame",
		["MBF_SLASH_Detail3"]     = "/mbf remove <button> - removes a gathered button from the frame",
		["MBF_SLASH_Detail4"]     = "/mbf show - shows the Main MBF Frame",
		["MBF_SLASH_Detail5"]     = "/mbf hide - hides the Main MBF Frame",
		["MBF_SLASH_Detail6"]     = "/mbf info - shows information about the object under the cursor",
		["MBF_SLASH_Detail7"]     = "/mbf config - shows the configuration screen",
		["MBF_SLASH_Detail8"]     = "/mbf help - shows this command help",

		["SBR_DESC"]              = "Sort buttons into rows instead of columns.",
		["ANIMATE_DESC"]          = "Slide buttons smoothly into place when they get reordered, instead of snapping instantly.",
		["CUSTOMORDER_DESC"]      = "When \"Custom\" is the sort order, turn on icon dragging above, then drag any icon on the frame to a new spot to reorder it.",
		["REARRANGE_DESC"]        = "Lets you pick up and drag icons to reorder them. Off by default so an ordinary click can never accidentally move something -- turn this on only while you're actively rearranging, then off again.",
		["SORTORDER_DESC"]        = "Choose how the buttons on the frame are sorted.",
		["GROWUP_DESC"]           = "Buttons fill the frame starting from the bottom instead of the top.",
		["PADDING_DESC"]          = "Adjust the spacing between buttons.",
		["SCALE_DESC"]            = "Adjust the scale of the MBF frame.",
		["OPACITY_DESC"]          = "Adjust the opacity of the MBF frame background.",
		["LOCKED_DESC"]           = "Lock the frame in place to prevent it from being moved.",
		["HIDELOCKED_DESC"]       = "Hide the frame background when the frame is locked.",
		["SHOWBUTTON_DESC"]       = "Show a minimap button for MBF.",
		["MBFANCHOR_DESC"]        = "Choose which corner the MBF frame is anchored at.",
		["BUTTONSKIN_DESC"]       = "Choose the skin used for the buttons on the frame.",
		["ALTTITLE_DESC"]         = "Use an alternate location for the title/drag bar.",
		["ALTTITLEDESC_DESC"]     = "Places the title bar on an alternate side of the frame.",
		["DOWN_DESC"]             = "Move the selected item down in the list.",
		["UP_DESC"]               = "Move the selected item up in the list.",
		["DOWN"]                  = "Down",
		["UP"]                    = "Up",

		["COLLECT1_DESC"]         = "Collect this button onto the MBF frame.",
		["COLLECT2_DESC"]         = "Automatically collect Blizzard minimap buttons.",
		["GATHERHEAD1_DESC"]      = "Gathering",
		["GATHERHEAD2_DESC"]      = "Gathering Options",
		["GATHERDESC1_DESC"]      = "MBF will automatically gather most minimap buttons onto the frame.",
		["GATHERDESC2_DESC"]      = "Buttons that were not automatically gathered can be added manually.",
		["CURRENTEXCEPTIONS_DESC"]= "Buttons currently excluded from being gathered.",
		["CLR_DESC"]              = "Clear this list.",

		["ICONADDTITLE_DESC"]     = "Minimap Icons",
		["ICONSDESC_DESC"]        = "Icons on this list will not be collected by MBF (for example, gathering node icons).",
		["ICONADD_DESC"]          = "Add the icon under the cursor to this list.",
		["ICONREMOVE_DESC"]       = "Remove the icon under the cursor from this list.",

		["OVERRIDEDESC_DESC"]     = "Buttons on this list will be captured even though they normally can't be gathered automatically.",
		["OVERRIDEADD_DESC"]      = "Add the button under the cursor to the override list.",
		["OVERRIDEREMOVE_DESC"]   = "Remove the button under the cursor from the override list.",

		["HIDEMAIL_DESC"]         = "Hide the Blizzard mail icon.",
		["NOMAIL_DESC"]           = "Show a greyed-out mail icon when there is no new mail.",
		["TRACKING_DESC"]         = "Hide the Blizzard tracking icon.",
		["CALENDAR_DESC"]         = "Hide the Blizzard calendar icon.",
		["VOICECHAT_DESC"]        = "Hide the Blizzard voice chat icon.",
		["WORLDMAP_DESC"]         = "Hide the Blizzard world map icon.",
		["ZOOM_DESC"]             = "Hide the minimap zoom in/out buttons.",
	};

	L = setmetatable(MBF_FallbackEnglish, { __index = function(t, k) return k end });
end

-- AceLocale-3.0 throws a hard error (not a nil return) when a key isn't
-- registered in a locale that DID successfully load -- so "L[key] or fallback"
-- doesn't actually protect anything; the error fires while evaluating L[key],
-- before "or" ever runs. rawget() reads the table directly without going
-- through that error-throwing lookup at all (registered translations are
-- stored as real keys; only genuinely-missing ones rely on the metamethod),
-- so there's no error raised in the first place -- unlike pcall, which only
-- catches the error after it's already fired and still gets seen by addons
-- like !BugGrabber that hook error() itself.
local function T(key, fallback)
	local result = rawget(L, key);
	if result then
		return result;
	end
	return fallback;
end

local libdbicon = LibStub("LibDBIcon-1.0", true)

-- Internal Variables
local scanned = false;
local MBF_ButtonInfoStorage = {};
local MBF_ChildEventStorage = {};
local tBackdrop = {};
local tBorder = {};
local tList = {};
local tSize = {};
local currentProfile;
local numButtons = 2;

local oldParentName;
local oldPoint;
local oldRelativeTo;
local oldRelativePoint;
local oldXofs;
local oldYofs;
local oldOnEvent;
local oldOnDragStart;
local oldOnDragStop;
local oldName;
local oldFrameLevel;
local oldWidth;
local oldHeight;
local oldScale;
local oldLevel;
local oldStrata;


local BlizzButtons = { "MiniMapTracking", "MiniMapVoiceChatFrame", "MiniMapWorldMapButton", "MiniMapLFGFrame", "MinimapZoomIn", "MinimapZoomOut", "MiniMapMailFrame", "MiniMapBattlefieldFrame", "GameTimeFrame", "FeedbackUIButton" };

-- O(1) lookup for isBlizzButton() instead of a per-call linear scan with repeated
-- strlower() calls. BlizzButtons is a fixed static list, so this only needs building once.
local BlizzButtonSet = {};
for i, name in ipairs(BlizzButtons) do
	BlizzButtonSet[strlower(name)] = true;
end

local BlizzUI = { "ActionBar", "BonusActionButton", "MainMenu", "ShapeshiftButton", "MultiBar", "KeyRingButton", "PlayerFrame", "TargetFrame", "PartyMemberFrame", "ChatFrame", "ExhaustionTick", "TargetofTargetFrame", "WorldFrame", "ActionButton", "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "QuestLogMicroButton", "SocialsMicroButton", "LFGMicroButton", "HelpMicroButton", "CharacterBag", "PetFrame",  "MinimapCluster", "MinimapBackdrop", "UIParent", "WorldFrame", "Minimap", "BuffButton", "BuffFrame", "TimeManagerClockButton", "CharacterFrame" };
local BlizzParentStop = { "WorldFrame", "Minimap", "MinimapBackdrop", "UIParent", "MinimapCluster" }
local SkinProtect = { "MinimapButtonFrameDragButton", "MBFRestoreButton", "GameTimeFrame" }

-- Configuration Screens

local hidewhenlocked_options = {
	["Nothing"]	= L["Nothing"],
	["Border"]	= L["Border"],
	["Background"]	= L["Background"],
	["All"]	= L["All"],
}

local sortorder_options = {
	["Alphabetical"]	= L["Alphabetical"],
	["Blizzard First"]	= L["Blizzard First"],
	["Blizzard Last"]	= L["Blizzard Last"],
	["Custom"]		= L["Custom"],
}

local frameanchor_options = {
	["TOPLEFT"]	= L["Top Left"],
	["TOPRIGHT"]	= L["Top Right"],
	["BOTTOMRIGHT"]	= L["Bottom Right"],
	["BOTTOMLEFT"]  = L["Bottom Left"],
}

-- Fill Order: which direction icons are placed first, then which direction new
-- rows/columns get added once the Columns/Rows count wraps. The first word is
-- the primary fill direction (uses the Columns setting if Left/Right, Rows if
-- Up/Down); the second word is the wrap direction.
local MBF_FillOrderLabels = {
	["RightDown"]	= T("Right, then Down", "Right, then Down"),
	["RightUp"]	= T("Right, then Up", "Right, then Up"),
	["LeftDown"]	= T("Left, then Down", "Left, then Down"),
	["LeftUp"]	= T("Left, then Up", "Left, then Up"),
	["DownRight"]	= T("Down, then Right", "Down, then Right"),
	["DownLeft"]	= T("Down, then Left", "Down, then Left"),
	["UpRight"]	= T("Up, then Right", "Up, then Right"),
	["UpLeft"]	= T("Up, then Left", "Up, then Left"),
}

local MBF_FillOrders = {
	["RightDown"]	= { primaryAxis = "Horizontal", horizontalDir = "Right", verticalDir = "Down" },
	["RightUp"]	= { primaryAxis = "Horizontal", horizontalDir = "Right", verticalDir = "Up" },
	["LeftDown"]	= { primaryAxis = "Horizontal", horizontalDir = "Left",  verticalDir = "Down" },
	["LeftUp"]	= { primaryAxis = "Horizontal", horizontalDir = "Left",  verticalDir = "Up" },
	["DownRight"]	= { primaryAxis = "Vertical",   horizontalDir = "Right", verticalDir = "Down" },
	["DownLeft"]	= { primaryAxis = "Vertical",   horizontalDir = "Left",  verticalDir = "Down" },
	["UpRight"]	= { primaryAxis = "Vertical",   horizontalDir = "Right", verticalDir = "Up" },
	["UpLeft"]	= { primaryAxis = "Vertical",   horizontalDir = "Left",  verticalDir = "Up" },
}

local minimapIconList = {};
local buttonOverrideList = {};
local childList = {};

local display = {
	order = 1,
	type = "group",
	name = L["Display"],
	desc = L["Display Settings"],
	handler = MBF,
	args = {		
		hidewhenlocked = {
			order	= 1,
			type	= "select",
			name	= L["Hide when Locked"],
			desc	= L["HIDELOCKED_DESC"],
			get	= function() return MBF.db.profile.colorLocked end,
			set	= function(info,name) MBF.db.profile.colorLocked = name 
					MBFC_ColorLocked()
				end,
			values	= hidewhenlocked_options,
		},
		locked = {
			order	= 2,
			type	= "toggle",
			name	= L["Locked"],
			desc	= L["LOCKED_DESC"],
			get	= function() return MBF.db.profile.locked end,
			set	= function() MBF.db.profile.locked = not MBF.db.profile.locked 
					if not MBF.db.profile.locked and not MBF.db.profile.mbfHidden then
						MinimapButtonFrameDragButton:Show()
						MBFRestoreButtonFrame:Show()
					else
						MinimapButtonFrameDragButton:Hide()
						MBFRestoreButtonFrame:Hide()
					end	
					MBFC_ColorLocked()
				end,
		},
		altTitle = {
			order	= 3,
			type	= "toggle",
			name	= L["ALTTITLE_DESC"],
			desc	= L["ALTTITLEDESC_DESC"],
			get	= function() return MBF.db.profile.altTitle end,
			set	= function() MBF.db.profile.altTitle = not MBF.db.profile.altTitle
					MBF:SwapTitleLocation()
				end,
		},
		space = {
			order	= 4,
			name	= "\n",
			type	= "description",
		},
		backgroundcolor = {
			order	= 10,
			type	= 'color',
			name	= L['Background Color'],
			desc	= L['COLOR_DESC'],
			hasAlpha = true,
			get	= function() 
					local t = MBF.db.profile.MBFBackdropColor 
					return t.Red, t.Green, t.Blue, t.Alpha 
				end,
			set	= function(info, r, g, b, a)
					local t = MBF.db.profile.MBFBackdropColor
					t.Red = r
					t.Green = g
					t.Blue = b
					t.Alpha = a
					MBFC_ColorLocked()
				end,
		},
		space1 = {
			order	= 11,
			name	= "",
			type	= "description",
		},
		opacity = {
			order	= 20,
			type	= "range",
			name	= L["Opacity"],
			desc	= L["OPACITY_DESC"],
			min	= 0,
			max	= 1,
			step	= .1,
			get	= function() return MBF.db.profile.opacity end,
			set	= function(info, v) MBF.db.profile.opacity = v 
					MinimapButtonFrame:SetAlpha(MBF.db.profile.opacity)
					MBFRestoreButtonFrame:SetAlpha(MBF.db.profile.opacity)
				end,
		},
		space2 = {
			order	= 21,
			name	= "",
			type	= "description",
		},
		mbfanchor = {
			order	= 31,
			type	= "select",
			name	= L["MBF Anchor"],
			desc	= L["MBFANCHOR_DESC"],
			get	= function() return MBF.db.profile.mbfAnchor end,
			set	= function(info,name) MBF.db.profile.mbfAnchor = name 
					MBF:SavePosition();
				end,
			values	= frameanchor_options,
		},
		space3 = {
			order	= 32,
			name	= "",
			type	= "description",
		},
		padding = {
			order	= 40,
			type	= "range",
			name	= L["Padding"],
			desc	= L["PADDING_DESC"],
			min	= 0,
			max	= 20,
			step	= .5,
			get	= function() return MBF.db.profile.padding end,
			set	= function(info, v) MBF.db.profile.padding = v 
					MBF:Scan()
				end,
		},
		space4 = {
			order	= 41,
			name	= "",
			type	= "description",
		},
		scale = {
			order	= 50,
			type	= "range",
			name	= L["Scale"],
			desc	= L["SCALE_DESC"],
			min	= .5,
			max	= 2,
			step	= .1,
			get	= function() return MBF.db.profile.addonScale end,
			set	= function(info, v) MBF.db.profile.addonScale = v 
					MinimapButtonFrame:SetScale(MBF.db.profile.addonScale)
					MBFRestoreButtonFrame:SetScale(MBF.db.profile.addonScale)
				end,
		},
		space5 = {
			order	= 51,
			name	= "",
			type	= "description",
		},
		buttonskin = {
			order	= 60,
			type	= "select",
			name	= L["Buttonskin"],
			desc	= L["BUTTONSKIN_DESC"],
			get	= function() return MBF.db.profile.currentTexture end,
			set	= function(info,name) MBF.db.profile.currentTexture = name 
					textureFrame(MinimapButtonFrame)
					MBF:Scan()
				end,
			values	= tList,
		},
	},
}

local gathering = {
	order = 2,
	type = "group",
	name = L["Gathering"],
	desc = L["Gathering Settings"],
	handler = MBF,
	args = {		
		header1 = {
			order	= 1,
			type	= "header",
			name	= L["GATHERHEAD1_DESC"],
		},
		desc1 = {
			order	= 2,
			type	= "description",
			name	= L["GATHERDESC1_DESC"] .. "\n",
		},
		ShowMinimapButton = {
			order	= 3,
			type	= "toggle",
			name	= L["Show Minimap Button"],
			desc	= L["SHOWBUTTON_DESC"],
			get	= function() return not MBF.db.profile.minimapButton.hide end,
			set	= function(_,v) MBF.db.profile.minimapButton.hide = not(v)
					if MBF.db.profile.minimapButton.hide then
						libdbicon:Hide("MBF")
					else
						libdbicon:Show("MBF")
					end
					MBF:Scan()
				end,
			disabled = function() if libdbicon then return false end return true end,
		},
		GatherMBFButton = {
			order	= 4,
			type	= "toggle",
			name	= L["Collect Button"],
			desc	= L["COLLECT1_DESC"],
			get	= function() return MBF.db.profile.grabMBFButton end,
			set	= function(info, value) MBF.db.profile.grabMBFButton = not MBF.db.profile.grabMBFButton 
					if (MBF.db.profile.grabMBFButton) then
						MinimapButtonFrame:Show();
						MBF.db.profile.mbfHidden = false;
					else
						removeButton(LibDBIcon10_MBF, 0);
					end
					MBF:Scan()
				end,
			disabled = function() if MBF.db.profile.minimapButton.hide then return true end return false end,
		},
		spacer0 = {
			order	= 5,
			name	= "\n",
			type	= "description",
		},
		header2 = {
			order	= 10,
			type	= "header",
			name	= L["GATHERHEAD2_DESC"],
		},
		desc2 = {
			order	= 11,
			type	= "description",
			name	= L["GATHERDESC2_DESC"] .. "\n",
		},
		GatherBlizz = {
			order	= 12,
			type	= "toggle",
			name	= L["Collect Buttons"],
			desc	= L["COLLECT2_DESC"],
			get	= function() return MBF.db.profile.grabBlizzButtons end,
			set	= function(info, value) MBF.db.profile.grabBlizzButtons = not MBF.db.profile.grabBlizzButtons 
					if not (MBF.db.profile.grabBlizzButtons) then
						removeBlizzButtons()
						MBF.db.profile.disabledMail = false
					end
					MBF:Scan()
				end,
		},
		spacer1 = {
			order	= 13,
			name	= "",
			type	= "description",
		},
		HideBlizzMail = {
			order	= 14,
			type	= "toggle",
			name	= L["Hide Mail"],
			desc	= L["HIDEMAIL_DESC"],
			get	= function() return MBF.db.profile.MBFHideMiniMapMailFrame end,
			set	= function(info, value) MBF.db.profile.MBFHideMiniMapMailFrame = not MBF.db.profile.MBFHideMiniMapMailFrame 
					if MBF.db.profile.MBFHideMiniMapMailFrame then
						MiniMapMailFrame:Hide()
						MBF.db.profile.disabledMail = false
					else
						if (HasNewMail() == 1) then
							MiniMapMailFrame:Show()
						end
					end
					MBF:Scan()
				end,
		},
		ShowNoMail = {
			order	= 15,
			type	= "toggle",
			name	= L["Show No Mail Icon"],
			desc	= L["NOMAIL_DESC"],
			get	= function() return MBF.db.profile.disabledMail end,
			set	= function(info, value) MBF.db.profile.disabledMail = not MBF.db.profile.disabledMail 
					MBF:Scan()
				end,
			disabled = function() if MBF.db.profile.MBFHideMiniMapMailFrame or (MBF.db.profile.grabBlizzButtons == false) then return true end return false end,
		},
		spacer2 = {
			order	= 16,
			name	= "",
			type	= "description",
		},
		HideTracking = {
			order	= 17,
			type	= "toggle",
			name	= L["Hide Tracking"],
			desc	= L["TRACKING_DESC"],
			get	= function() return MBF.db.profile.MBFHideMiniMapTracking end,
			set	= function(info, value) MBF.db.profile.MBFHideMiniMapTracking = not MBF.db.profile.MBFHideMiniMapTracking 
					if MBF.db.profile.MBFHideMiniMapTracking then
						MiniMapTracking:Hide()
					else
						MiniMapTracking:Show()
					end
					MBF:Scan()
				end,
		},
		spacer4 = {
			order	= 18,
			name	= "",
			type	= "description",
		},
		HideVoiceChat = {
			order	= 19,
			type	= "toggle",
			name	= L["Hide Voice Chat"],
			desc	= L["VOICECHAT_DESC"],
			get	= function() return MBF.db.profile.MBFHideMiniMapVoiceChatFrame end,
			set	= function(info, value) MBF.db.profile.MBFHideMiniMapVoiceChatFrame = not MBF.db.profile.MBFHideMiniMapVoiceChatFrame 
					if MBF.db.profile.MBFHideMiniMapVoiceChatFrame then
						MiniMapVoiceChatFrame:Hide()
					else
						MiniMapVoiceChatFrame:Show()
					end
					MBF:Scan()
				end,
		},
		spacer5 = {
			order	= 20,
			name	= "",
			type	= "description",
		},
		 HideGameTime = {
			order	= 21,
			type	= "toggle",
			name	= L["Hide Calendar"],
			desc	= L["CALENDAR_DESC"],
			get	= function() return MBF.db.profile.MBFHideGameTimeFrame end,
			set	= function(info, value) MBF.db.profile.MBFHideGameTimeFrame = not MBF.db.profile.MBFHideGameTimeFrame 
					if MBF.db.profile.MBFHideGameTimeFrame then
						GameTimeFrame:Hide()
					else
						GameTimeFrame:Show()
					end
					MBF:Scan()
				end,
		},
		spacer6 = {
			order	= 22,
			name	= "",
			type	= "description",
		},
		HideMinimapZoom = {
			order	= 23,
			type	= "toggle",
			name	= L["Hide Zoom Buttons"],
			desc	= L["ZOOM_DESC"],
			get	= function() return MBF.db.profile.MBFHideMinimapZoomIn end,
			set	= function(info, value) MBF.db.profile.MBFHideMinimapZoomIn = not MBF.db.profile.MBFHideMinimapZoomIn 
					if MBF.db.profile.MBFHideMinimapZoomIn then
						MinimapZoomIn:Hide()
						MinimapZoomOut:Hide()
					else
						MinimapZoomIn:Show()
						MinimapZoomOut:Show()
					end
					MBF:Scan()
				end,
		},
		spacer7 = {
			order	= 24,
			name	= "",
			type	= "description",
		},
		HideWorldMap = {
			order	= 25,
			type	= "toggle",
			name	= L["Hide World Map"],
			desc	= L["WORLDMAP_DESC"],
			get	= function() return MBF.db.profile.MBFHideMiniMapWorldMapButton end,
			set	= function(info, value) MBF.db.profile.MBFHideMiniMapWorldMapButton = not MBF.db.profile.MBFHideMiniMapWorldMapButton 
					if MBF.db.profile.MBFHideMiniMapWorldMapButton then
						MiniMapWorldMapButton:Hide()
					else
						MiniMapWorldMapButton:Show()
					end
					MBF:Scan()
				end,
		},
	},
}

local exceptions = {
	order = 1,
	type = "group",
	name = L["Exceptions"],
	desc = L["Exceptions Settings"],
	handler = MBF,
	args = {		
		header1 = {
			order	= 1,
			type	= "header",
			name	= L["Protected Items"],
		},
		desc1 = {
			order	= 2,
			type	= "description",
			name	= L["ICONSDESC_DESC"] .. "\n",
		},
		minimapIcons = {
			order	= 3,
			type	= "select",
			name	= L["Protected Items"],
			desc	= L["CURRENTEXCEPTIONS_DESC"],
			get	= function() return MBF.db.profile.currentMinimapIcon end,
			set	= function(info,name) MBF.db.profile.currentMinimapIcon = name end,
			values	= minimapIconList,
		},
		removeIcon = {
			order	= 4, 
			type	= "execute",
			name	= L["Remove"],
			desc	= L["ICONREMOVE_DESC"],
			func	= function() 
					local miniButton = MBF.db.profile.currentMinimapIcon
					removeFromTable(MBF.db.profile.MinimapIcons, miniButton)
					minimapIconList[miniButton] = nil;
					for i, name in pairs(MBF.db.profile.MinimapIcons) do
						minimapIconList[name] = name
						if i == 1 then 
							MBF.db.profile.currentMinimapIcon = name
						end
					end
					MBF:Scan()
				end,
		},
		spacer1 = {
			order	= 5,
			name	= "\n",
			type	= "description",
		},
		iconInput = {
			order	= 6,		
			type	= "input",
			name	= L["ICONADDTITLE_DESC"],
			desc	= L["ICONADD_DESC"],
			set	= function(info, newValue)
					local liveButton
					tinsert(MBF.db.profile.MinimapIcons, newValue)
					minimapIconList[newValue] = newValue
					for i, liveButton in ipairs({MinimapButtonFrame:GetChildren()}) do
						if (isMinimapIcon(liveButton:GetName())) then	
							removeButton(liveButton, 1)
						end
					end
					MBF:Scan()
				end,
		},
		header2 = {
			order	= 10,
			type	= "header",
			name	= L["Button Override"],
		},
		desc2 = {
			order	= 11,
			type	= "description",
			name	= L["OVERRIDEDESC_DESC"] .. "\n",
		},
		buttonOverride = {
			order	= 12,
			type	= "select",
			name	= L["Button Override"],
			desc	= L["Current Button Overrides"],
			get	= function() return MBF.db.profile.currentButtonOverride end,
			set	= function(info,name) MBF.db.profile.currentButtonOverride = name end,
			values	= buttonOverrideList,
		},
		removeOverride = {
			order	= 13, 
			type	= "execute",
			name	= L["Remove"],
			desc	= L["OVERRIDEREMOVE_DESC"],
			func	= function() 
					local liveButton
					local miniButton = MBF.db.profile.currentButtonOverride
					if isInTable(MBF.db.profile.ButtonOverride, miniButton) then
						removeFromTable(MBF.db.profile.ButtonOverride, miniButton)
						liveButton = _G[miniButton]
						if ((liveButton ~= nil) and (MBF_ButtonInfoStorage[miniButton] ~= nil)) then
							removeButton(liveButton, 0)
						end
						for i, name in pairs(MBF.db.profile.ButtonOverride) do
							buttonOverrideList[name] = name
							if i == 1 then 
								MBF.db.profile.currentButtonOverride = name
							end
						end
						buttonOverrideList[miniButton] = nil;
						MBF:Scan()
					end
				end,
		},
		spacer2 = {
			order	= 14,
			name	= "\n",
			type	= "description",
		},
		overrideInput = {
			order	= 15,
			type	= "input",
			name	= L["Add Button Override"],
			desc	= L["OVERRIDEADD_DESC"],
			set	= function(info, newValue)
					tinsert(MBF.db.profile.ButtonOverride, newValue)
					buttonOverrideList[newValue] = newValue
					MBF:Scan()
				end,
		},
	},
}

local sorting = {
	order = 1,
	type = "group",
	name = L["Sorting"],
	desc = L["Sorting Settings"],
	handler = MBF,
	args = {
		sortOrder = {
			order	= 1,
			type	= "select",
			name	= L["Sort Order"],
			desc	= L["SORTORDER_DESC"],
			get	= function() return MBF.db.profile.sortOrder end,
			set	= function(info,name) MBF.db.profile.sortOrder = name 
					MBF:Scan()
				end,
			values	= sortorder_options,
		},
		fillOrder = {
			order	= 2,
			type	= "select",
			name	= T("Fill Order", "Fill Order"),
			desc	= T("FILLORDER_DESC", "Which direction icons fill first, then which direction new rows/columns are added."),
			get	= function() return MBF.db.profile.fillOrder end,
			set	= function(info, key) MBF.db.profile.fillOrder = key
					MBF:Scan()
				end,
			values	= MBF_FillOrderLabels,
		},
		columns = {
			order	= 3.1,
			type	= "range",
			name	= T("Columns", "Columns"),
			desc	= T("COLUMNS_DESC", "How many buttons fit in a row before wrapping to a new row. Used when Fill Order's primary direction is Left or Right."),
			min	= 1,
			max	= 50,
			step	= 1,
			get	= function() return MBF.db.profile.columns end,
			set	= function(info, v) MBF.db.profile.columns = v
					MBF:Scan()
				end,
		},
		rows = {
			order	= 3.2,
			type	= "range",
			name	= T("Rows", "Rows"),
			desc	= T("ROWS_DESC", "How many buttons fit in a column before wrapping to a new column. Used when Fill Order's primary direction is Up or Down."),
			min	= 1,
			max	= 50,
			step	= 1,
			get	= function() return MBF.db.profile.rows end,
			set	= function(info, v) MBF.db.profile.rows = v
					MBF:Scan()
				end,
		},
		animateRearrange = {
			order	= 4,
			type	= "toggle",
			name	= T("Animate Rearranging", "Animate Rearranging"),
			desc	= T("ANIMATE_DESC", "Slide buttons smoothly into place when they get reordered, instead of snapping instantly."),
			get	= function() return MBF.db.profile.animateRearrange end,
			set	= function(info, value) MBF.db.profile.animateRearrange = not MBF.db.profile.animateRearrange end,
		},
		space = {
			order	= 9,
			name	= "\n",
			type	= "description",
		},
		rearrangeMode = {
			order	= 10,
			type	= "toggle",
			name	= T("Enable Icon Dragging", "Enable Icon Dragging"),
			desc	= T("REARRANGE_DESC", "Lets you pick up and drag icons to reorder them. Off by default so an ordinary click can never accidentally move something -- turn this on only while you're actively rearranging, then off again."),
			get	= function() return MBF.db.profile.iconDragEnabled end,
			set	= function(info, value)
					MBF.db.profile.iconDragEnabled = not MBF.db.profile.iconDragEnabled;
					MBF:ApplyIconDragState();
				end,
		},
		customOrderHint = {
			order	= 11,
			type	= "description",
			name	= T("CUSTOMORDER_DESC", "When \"Custom\" is the sort order, turn on icon dragging above, then drag any icon on the frame to a new spot to reorder it."),
		},
	}
}

local defaults = {
	profile = {
		version = MBFversion,
		-- Display Vars
		locked = false,
		colorLocked = "Nothing",
		altTitle = false,
		mbfAnchor = "TOPRIGHT",
		currentTexture = "Default",
		MBFBackdropColor = { Red = 0, Green = 0, Blue = 0, Alpha = 1 },
		columns_or_rows = 3,
		columns = 5,
		rows = 3,
		migratedColumnsRows = false,
		sort_by_rows = false,
		fillOrder = "LeftUp",
		migratedFillOrder = false,
		padding = 5,
		opacity = 1,
		addonScale = .8,
		MBF_FrameLocation = { "TOPRIGHT", "TOPRIGHT", 0, 0 },
		mbfHidden = false,
		rollUp = false,
		-- Gathering Vars
		minimapButton = { hide = true },
		grabMBFButton = false,
		grabBlizzButtons = false,
		disabledMail = true,
		MBFHideMiniMapMailFrame = false,
		MBFHideMiniMapTracking = false,
		MBFHideMiniMapVoiceChatFrame = false,
		MBFHideGameTimeFrame = false,
		MBFHideMinimapZoomIn  = false,
		MBFHideMiniMapWorldMapButton = false,
		MBFHideMiniMapLFGFrame = false,
		MBFHideMiniMapBattlefieldFrame = false,
		-- Exception Vars
		currentMinimapIcon = "Note",
		MinimapIcons = { "Note", "JQuest", "NauticusMiniIcon", "MinimapIcon", "GatherMatePin", "WestPointer", "Chinchilla_", "SmartMinimapZoom", "pMinimap", "GuildMap3Mini", "MiniButton", "DropCount" },
		currentButtonOverride = "notesiconframe",
		ButtonOverride = { "notesiconframe", "duckiebank_minimapicon", "cta_minimapicon", "BejeweledMinimapIcon", "EMPMINIMAPBUTTON", "MobMapMinimapButtonFrame", "Karma_MinimapIconFrame", "FuBarPluginCraftNotesFrameMinimapButton", "PeggledMinimapIcon", "DropCount_MinimapIcon" },
		UserUIProtected = { "TitanPanel", "AutoBarButton", "FuBarFrame", "RicoMinimap_CoordinatesFrame", "MinimapZoom", "MinimapButtonFrame", "Xparky", "MBFRestoreButton", "BasicMiniMap", "CT_RASetsFrame", "SMM", "GuildOrg_Toggle" },
		ParentStop = { "CECBMiniMapButtonFrame", "CT_RASetsFrame", "GuildOrg_Toggle", "PoisonerStateHeader" },
		MBF_Ignore = { "MetamapButton" },
		MBF_Include = { },
		-- Sorting Vars
		sortOrder = "Alphabetical",
		growUp = false,
		currentChild = "",
		customChildren = {},
		animateRearrange = true,
		iconDragEnabled = false,
	}
}


-- Init and Event Handler Functions

local MBF_RearrangeMenuFrame = CreateFrame("Frame", "MBFRearrangeMenuFrame", UIParent, "UIDropDownMenuTemplate")

local function MBF_ShowRearrangeMenu()
	local menuList = {
		{
			text = T("Enable Icon Dragging", "Enable Icon Dragging"),
			checked = function() return MBF.db.profile.iconDragEnabled end,
			func = function()
				MBF.db.profile.iconDragEnabled = not MBF.db.profile.iconDragEnabled;
				MBF:ApplyIconDragState();
			end,
			isNotRadio = true,
			keepShownOnClick = true,
		},
		{
			text = T("Options", "Options"),
			-- Structured the same checkable-style way as the item above rather
			-- than notCheckable=true - mixing checkable and plain-action items
			-- in the same dropdown level is a known rough edge in the Blizzard
			-- template (they get sized/laid out differently, which can leave
			-- the visible text and the real clickable hit-region misaligned:
			-- looks fine, silently swallows every click, no error). Always
			-- returning false just means it never shows a checkmark.
			checked = function() return false end,
			isNotRadio = true,
			func = function()
				InterfaceAddOnsList_Update();
				InterfaceOptionsFrame_OpenToCategory(MBF.optionsFrame);
				InterfaceOptionsFrame_OpenToCategory(MBF.optionsFrame);
			end,
		},
	};
	EasyMenu(menuList, MBF_RearrangeMenuFrame, "cursor", 0, 0, "MENU");
end

function MBF:OnInitialize()
    -- Called when the addon is loaded
	self.db = LibStub("AceDB-3.0"):New("MBFDB", defaults, true)

	-- Every options panel below needs to agree on the exact same top-level
	-- display name to nest correctly.
	local MBF_TOPNAME = "Minimap Button Frame Enhanced";

	LibStub("AceConfig-3.0"):RegisterOptionsTable("MinimapButtonFrame", display)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MBF Gathering", gathering)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MBF Exceptions", exceptions)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MBF Sorting", sorting)
	LibStub("AceConfig-3.0"):RegisterOptionsTable("MBF Profiles", LibStub("AceDBOptions-3.0"):GetOptionsTable(self.db))

	-- AddToBlizOptions(appName, name, parent): a panel only nests under another
	-- if "parent" exactly matches an ALREADY-REGISTERED top-level panel's
	-- displayed name. The first call here (no parent argument) creates that
	-- top-level entry, using the Display options table's content ("MinimapButtonFrame",
	-- its actual registered key above) but MBF_TOPNAME as what's shown in the
	-- list; the other four then correctly attach to it by matching that exact
	-- same name. Its return value is a real, correctly-nested category frame,
	-- so use THAT for self.optionsFrame (what /mbf with no arguments opens to)
	-- rather than LibAboutPanel's separately-registered panel below.
	self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MinimapButtonFrame", MBF_TOPNAME)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MBF Gathering", L["Gathering"], MBF_TOPNAME)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MBF Exceptions", L["Exceptions"], MBF_TOPNAME)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MBF Sorting", L["Sorting"], MBF_TOPNAME)
	LibStub("AceConfigDialog-3.0"):AddToBlizOptions("MBF Profiles", L["Profiles"], MBF_TOPNAME)

	-- LibAboutPanel's second argument must be the LITERAL addon folder name
	-- (it looks up Title/Author/Version via GetAddOnMetadata using this exact
	-- string) - not a display label. That's confirmed fixed below. Separately,
	-- passing nil as the first argument (parentframe) is documented to always
	-- create a standalone panel ("will not anchor the about panel to any
	-- frame") - passing our own main panel frame here instead links it in.
	if LibStub:GetLibrary("LibAboutPanel", true) then
		LibStub:GetLibrary("LibAboutPanel").new(self.optionsFrame, "Minimap_Button_Frame_Enhanced")
	else
		self:Print("Lib AboutPanel not loaded.")
	end

	self:RegisterChatCommand(L["MBF"], "ChatCommand")

	self:fillDropdowns();

	MBFC_LoadStandardSkins();

	MBF.obj = LibStub:GetLibrary("LibDataBroker-1.1"):NewDataObject("MinimapButtonFrame", {
		type = "launcher",
		text = "MBF",
		OnClick = function(_, msg, down)
			if (IsShiftKeyDown()) then						
				MBFC_Toggle();
			elseif ( msg == "LeftButton" ) then
				MBFC_Visible(2, MinimapButtonFrame:GetParent():GetName());
			elseif ( msg == "RightButton" ) then
				MBF_ShowRearrangeMenu();
			end
		end,
		icon = "Interface\\Icons\\INV_Misc_Coin_11",
		OnTooltipShow = function(tooltip)
			if not tooltip or not tooltip.AddLine then return end
			tooltip:AddLine(L["ADDON"]);
			tooltip:AddLine(L["MBF_LDB_TOOLTIP"])
		end,
	})

	-- register MBF with LibDBicon and show minimap icon
	if libdbicon then
		libdbicon:Register("MBF", MBF.obj, MBF.db.profile.minimapButton)
	end

	self:Init();

	MinimapButtonFrame:RegisterForDrag("LeftButton");
	MinimapButtonFrameDragButton:RegisterForClicks("RightButtonUp");
	MBFRestoreButton:RegisterForClicks("RightButtonUp");

	self:ScheduleRepeatingTimer("Scan", 5)

	-- The stuck-drag watchdog only matters while icon dragging is actually
	-- enabled (see MBF:ApplyIconDragState, which starts/stops it) - no need to
	-- tick every 0.2s for the entire session when it's off, which is the default.
	if MBF.db.profile.iconDragEnabled then
		self.watchdogHandle = self:ScheduleRepeatingTimer("WatchStuckDrags", 0.2)
	end

	-- Some addons set their minimap icon's actual texture after their own
	-- delayed init rather than at button-creation time. If MBF gathers and
	-- textures a button before that happens, it never gets revisited. One
	-- extra pass a few seconds into the session, after most addons have
	-- settled, catches those without touching anything already working.
	self:ScheduleTimer("RetextureLateIcons", 5)
	self:ScheduleTimer("RetextureLateIcons", 10)
	self:ScheduleTimer("RetextureLateIcons", 20)
	self:ScheduleTimer("RetextureLateIcons", 35)
end

function MBF:Init()
	currentProfile = self.db:GetCurrentProfile();

	-- Columns and Rows used to be one shared value (columns_or_rows) whose meaning
	-- flipped based on the Sort By Rows toggle. If this profile had it customized
	-- away from the old default, carry that value into both new independent
	-- fields once, so existing users don't lose their prior layout.
	if (MBF.db.profile.columns_or_rows ~= 3) and (not MBF.db.profile.migratedColumnsRows) then
		MBF.db.profile.columns = MBF.db.profile.columns_or_rows;
		MBF.db.profile.rows = MBF.db.profile.columns_or_rows;
	end
	MBF.db.profile.migratedColumnsRows = true;

	-- Sort By Rows + Grow Up used to be two separate toggles controlling layout
	-- direction. Carry their combination into the new single Fill Order setting
	-- once, so existing users keep the same layout direction they already had.
	if (not MBF.db.profile.migratedFillOrder) then
		if MBF.db.profile.sort_by_rows then
			MBF.db.profile.fillOrder = MBF.db.profile.GrowUp and "UpRight" or "DownRight";
		else
			MBF.db.profile.fillOrder = MBF.db.profile.GrowUp and "RightUp" or "RightDown";
		end
	end
	MBF.db.profile.migratedFillOrder = true;

	setMBFLocation();
	
	if (((MBF.db.profile.disabledMail == true) and (HasNewMail() ~= 1)) and (((MBF.db.profile.grabBlizzButtons == true) and (isInTable(MBF.db.profile.MBF_Ignore,"MiniMapMailFrame") == false)) or ((MBF.db.profile.grabBlizzButtons == false) and (isInTable(MBF.db.profile.MBF_Include,"MiniMapMailFrame") == true)))) then
		MiniMapMailFrameDisabled:Show();
		MiniMapMailFrameDisabled:SetFrameLevel(MinimapButtonFrame:GetFrameLevel()+1)
	end

	if (MBF.db.profile.locked) then
		MinimapButtonFrameDragButton:Hide();
		MBFRestoreButtonFrame:Hide();
	end

	self:SwapTitleLocation()

	MBFRestoreButtonFrame:SetAlpha(MBF.db.profile.opacity);
	MBFRestoreButtonFrame:SetScale(MBF.db.profile.addonScale);
	
	MinimapButtonFrame:SetAlpha(MBF.db.profile.opacity);
	MinimapButtonFrame:SetScale(MBF.db.profile.addonScale);
	MBFC_ColorLocked();

	if MBF.db.profile.mbfHidden then
		MinimapButtonFrame:Hide();
		MBFRestoreButtonFrame:Hide();
	end
	if MBF.db.profile.rollUp and not MBF.db.profile.locked then
		MBFRestoreButton:Show();
		MBFRestoreButtonFrame:Show();
	end

	if libdbicon then
		if MBF.db.profile.minimapButton.hide then
			libdbicon:Hide("MBF")
		else
			libdbicon:Show("MBF")
		end
	end
	numButtons = MinimapButtonFrame:GetNumChildren();
end

function MBF:ChatCommand(input)
	if not input or input:trim() == "" then
		InterfaceAddOnsList_Update();
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
		InterfaceOptionsFrame_OpenToCategory(self.optionsFrame)
	else
		local startPos, endPos, firstWord, restOfString = strfind(input, "(%w+)[%s%p]*(.*)");
		firstWord = strlower(firstWord)

		if (firstWord == L["usage"]) then
			self:Print(L["Version"] .. " " .. MBFversion);
			self:Print(L["MBF_SLASH_Detail1"]);
		end
		if (firstWord == L["info"]) then
			displayInfo(GetMouseFocus());
		end 
		if (firstWord == L["show"]) then
			MBFC_Visible(3);
		end
		if (firstWord == L["hide"]) then
			MBFC_Visible(4);
		end
		if (firstWord == L["help"]) then
			self:Print(L["MBF_SLASH_Detail1"]);
			self:Print(L["MBF_SLASH_Detail2"]);
			self:Print(L["MBF_SLASH_Detail3"]);
			self:Print(L["MBF_SLASH_Detail4"]);
			self:Print(L["MBF_SLASH_Detail5"]);
			self:Print(L["MBF_SLASH_Detail6"]);
			self:Print(L["MBF_SLASH_Detail7"]);
			self:Print(L["MBF_SLASH_Detail8"]);
		end
		if (firstWord == L["config"]) then
			MBFC_Toggle();
		end
		if (firstWord == L["remove"]) then
			if (restOfString == "") then
				if (GetMouseFocus():GetName() ~= "WorldFrame") then
					removeButton(GetMouseFocus(), 0)
				end
			else
				if (restOfString ~= "WorldFrame") then
					local miniButton = _G[restOfString];
					if (miniButton ~= nil) then
						removeButton(miniButton, 0)
					else
						self:Print(L["MBF_ERR7"]);
					end
				end
			end
		end
		if (firstWord == L["add"]) then
			if (restOfString == "") then 
				includeButton(GetMouseFocus());
			else
				local miniButton = _G[restOfString];
				if (miniButton ~= nil) then
					includeButton(miniButton)
				else
					self:Print(L["MBF_ERR7"]);
				end
			end
		end
	end
end

function displayInfo(target)
	local rName, rTex, rDL;
	MBF:Print("----------------------------------------------------------");
	MBF:Print("----------------------------------------------------------");
	MBF:Print(format(target:GetName() or '(' .. L["Unnamed Object"] .. ')'));
	MBF:Print("----------------------------------------------------------");
	if (target:GetName() ~= "WorldFrame") then
		MBF:Print(L["Parent"] .. " : " .. format(target:GetParent():GetName() or '(' .. L["Unknown Parent Name"] .. ')'));
	else
		MBF:Print(L["Parent"] .. " : " .. L["No Parent"]);
	end 
	MBF:Print(L["Object Type"] .. " : " .. format(target:GetObjectType() or '(' .. L["Unknown Object Type"] .. ')'));
	MBF:Print("----------------------------------------------------------");
	MBF:Print("Textures");
	MBF:Print("----------------------------------------------------------");
	for _, r in pairs({target:GetRegions()}) do
		if r:GetObjectType() == "Texture" then
			rName = r:GetName();
			rTex = r:GetTexture();
			rDL = r:GetDrawLayer();
			MBF:Print("Texture Name : " .. format(rName or "nil"));
			MBF:Print("Texture Path : " .. format(rTex or "nil"));
			MBF:Print("Draw Layer   : " .. format(rDL or "nil"));
			MBF:Print("----------------------------------------------------------");
		end
	end
	MBF:Print("----------------------------------------------------------");
	MBF:Print("Size");
	MBF:Print("----------------------------------------------------------");
	MBF:Print("Width : " .. target:GetWidth());
	MBF:Print("Height : " .. target:GetHeight());
end

function MBF:OnDragStart()
	if (MBF.db.profile.locked == false) then
		MinimapButtonFrame:StartMoving();
		MinimapButtonFrame.isMoving = true;
	end
end

function MBF:OnDragStop()
	if (MBF.db.profile.locked == false) then
		MinimapButtonFrame:StopMovingOrSizing();
		MinimapButtonFrame.isMoving = false;
		MinimapButtonFrame:SetUserPlaced(false);
		MinimapButtonFrame:SetFrameLevel(2);
		
		MBF:SavePosition();
	end
end 

function MBF:SavePosition()

	local bPoint;
	local bRelativeTo;
	local bRelativePoint;
	local bXofs;
	local bYofs;
	local width;
	local height;

	bPoint, bRelativeTo, bRelativePoint, bXofs, bYofs = MinimapButtonFrame:GetPoint();

	if MBF.db.profile.mbfAnchor == bPoint then
		MBF.db.profile.MBF_FrameLocation = { bPoint, bRelativePoint, bXofs, bYofs }
	else
		width = MinimapButtonFrame:GetWidth();
		height = MinimapButtonFrame:GetHeight();

		if bPoint == "TOP" then
			bXofs = bXofs - (width / 2)
		elseif bPoint == "LEFT" then
			bYofs = bYofs + (height / 2)
		elseif bPoint == "BOTTOMLEFT" then
			bYofs = bYofs + height
		elseif bPoint == "TOPRIGHT" then
			bXofs = bXofs - width
		elseif bPoint == "RIGHT" then
			bYofs = bYofs + (height / 2)
			bXofs = bXofs - width
		elseif bPoint == "BOTTOM" then
			bYofs = bYofs + height
			bXofs = bXofs - (width / 2)
		elseif bPoint == "BOTTOMRIGHT" then
			bYofs = bYofs + height
			bXofs = bXofs - width
		elseif bPoint == "CENTER" then
			bYofs = bYofs + (height / 2)
			bXofs = bXofs - (width / 2)
		end
	
		if MBF.db.profile.mbfAnchor == "TOPRIGHT"then
			bXofs = bXofs + width
		elseif MBF.db.profile.mbfAnchor == "BOTTOMRIGHT" then
			bYofs = bYofs - height
			bXofs = bXofs + width
		elseif MBF.db.profile.mbfAnchor == "BOTTOMLEFT" then
			bYofs = bYofs - height
		end

		MBF.db.profile.MBF_FrameLocation = { MBF.db.profile.mbfAnchor, bRelativePoint, bXofs, bYofs }
	end

	setMBFLocation();
end

-- Utility Functions


function CloneTable(t)			--Code by Grayhoof (SCT)
	local new = {};
	local i, v = next(t, nil);
	while i do
		if type(v)=="table" then
			v=CloneTable(v);
		end
		new[i] = v;
		i, v = next(t, i);
	end
	return new;
end

function setMBFLocation()
	local bPoint;
	local bRelativePoint;
	local bXofs;
	local bYofs;

	if not MinimapButtonFrame.isMoving then

		bPoint, bRelativePoint, bXofs, bYofs = unpack(MBF.db.profile.MBF_FrameLocation);

		MinimapButtonFrame:ClearAllPoints();
		MinimapButtonFrame:SetPoint(bPoint, UIParent, bRelativePoint, bXofs, bYofs);
		MinimapButtonFrame:SetFrameLevel(2);
		MinimapButtonFrame:SetUserPlaced(false);
	end
end

isInTable = function(tab, frameName)
	if frameName == nil then
		return false;
	end
	for k,v in ipairs(tab) do
		if (v ~= nil) and (strlower(v) == strlower(frameName)) then
			return true;
		end
	end
	return false;
end

isPartialMatch = function(frameName, tab)
	local result = false

	for k,v in ipairs(tab) do
		startpos, endpos = strfind(strlower(frameName), strlower(v))
		if (startpos == 1) then
			result = true;
		end
	end

	return result;
end

isBlizzButton = function(frameName)
	if frameName == nil then
		return false;
	end
	return BlizzButtonSet[strlower(frameName)] == true;
end

getTopParent = function(frame) 
-- returns 1 for ParentStop parent, and 0 for MBF
	local result;
	local parent = frame:GetParent();

	if (parent == nil) then
		-- Reached the top of the frame hierarchy without finding MBF or a
		-- known stop-point; treat that the same as a ParentStop match rather
		-- than crashing on GetName() against a nil parent.
		return 1;
	end

	local parentName = parent:GetName();

	if (isInTable(MBF.db.profile.ParentStop,parentName) or isInTable(BlizzParentStop,parentName)) then 
		result = 1
	elseif (parentName == "MinimapButtonFrame") then
		result = 0
	else
		-- Either a genuinely different named ancestor, or an unnamed frame
		-- (common for anonymous container frames some addons use) -- either
		-- way, keep walking up rather than crashing or stopping short.
		result = getTopParent(parent);
	end
	
	return result;
end

isMinimapIcon = function(frame)
	local foundPos = 0;
	local frameName = strlower(frame);
	local result = false;
	local k, v;

	for k,v in ipairs(MBF.db.profile.MinimapIcons) do
		foundPos = strfind(frameName,strlower(v),1);
		
		if (foundPos) then
			if not isInTable(MBF.db.profile.ButtonOverride, frameName) then
				result = true;
			end
		end
	end
	return result;
end

isValidAdd = function(frame, autoGather)
	local result = true;
	local frameName = frame:GetName();

	if (frameName ~= nil) then
		if (frame:IsShown()) then
			if (getTopParent(frame) == 1) then
				if (isPartialMatch(frameName, BlizzUI) or isPartialMatch(frameName,MBF.db.profile.UserUIProtected)) then
					result = false;
				end

				if (isMinimapIcon(frameName)) then
					result = false;
				end

				if (frameName == "LibDBIcon10_MBF") then
					if (MBF.db.profile.grabMBFButton == false) then
						result = false;
					else
						result = true;
					end
				end 

				if (frameName == "GuildOrgButtonFrame") then
					result = false;
				end

				if (autoGather) then
					if (isBlizzButton(frameName)) then
						if (MBF.db.profile.grabBlizzButtons == true) then
							result = true;
						else
							result = false;
						end
					end
					if (isInTable(MBF.db.profile.MBF_Ignore,frameName)) then
						result = false;
					end
				else
					if (isBlizzButton(frameName)) then
						if ((MBF.db.profile.grabBlizzButtons == true) and (isInTable(MBF.db.profile.MBF_Ignore,frameName))) then
							result = true;
						elseif (MBF.db.profile.grabBlizzButtons == false) then
							result = true;
						end
					end
				end
			else
				result = false;
			end
		elseif (frameName == "MiniMapMailFrame") then
			if ((MBF.db.profile.disabledMail == false) or (MBF.db.profile.MBFHideMiniMapMailFrame == true) or ((MBF.db.profile.grabBlizzButtons == false) and (isInTable(MBF.db.profile.MBF_Include, frameName) == false)) or ((MBF.db.profile.grabBlizzButtons == true) and (isInTable(MBF.db.profile.MBF_Ignore, frameName) == true))) then
				result = false;
			end
		else
			result = false;
		end
	else
		result = false;
	end
	return result

end

isButtonFrame = function(frame)
	return (frame:GetObjectType() == ("Frame"))
end

function removeFromTable(tab, buttonName)
	for k,v in ipairs(tab) do
		if (strlower(v) == strlower(buttonName)) then
			tremove(tab,k);
		end
	end
end

displayDisabledMail = function()
	-- Will return if the button should be shown
	local result = true;
	if (((MBF.db.profile.disabledMail == false) or (MBF.db.profile.MBFHideMiniMapMailFrame == true) or (HasNewMail() == 1)) or ((MBF.db.profile.grabBlizzButtons == true) and (isInTable(MBF.db.profile.MBF_Ignore,"MiniMapMailFrame") == true)) or ((MBF.db.profile.grabBlizzButtons == false) and (isInTable(MBF.db.profile.MBF_Include,"MiniMapMailFrame") == false))) then
		result = false;
	end
	return result;
end

-- Button Skinning Functions

function MBFAddSkin(tID, tBorderPath, tBackdropPath, size)
	tList[tID] = tID;
	tBorder[tID] = tBorderPath;
	tBackdrop[tID] = tBackdropPath;
	tSize[tID] = size;
end

function textureFrame(frame)
local miniButton;

	for i = 1, select("#", frame:GetChildren()) do
		miniButton = select(i, frame:GetChildren());
		textureButton(miniButton);
	end
	
	-- Blizz Button Tweaks
	MiniMapVoiceChatFrameIcon:ClearAllPoints();
	MiniMapVoiceChatFrameIcon:SetPoint("CENTER");
	if ((MBF.db.profile.grabBlizzButtons == true) and (isInTable(MBF.db.profile.MBF_Ignore,"GameTimeFrame") == false)) or (isInTable(MBF.db.profile.MBF_Include,"GameTimeFrame") == true) then
			MBFSkinMinimapButton(GameTimeFrame,1);
	end	
end

function removeTextures(miniButton)
	local rName, rTex, rDL;

	if miniButton:GetName() == "MiniMapTracking" then
		miniButton = _G["MiniMapTrackingButton"];
	end

	for _, r in pairs({miniButton:GetRegions()}) do
		if r:GetObjectType() == "Texture" then
			rName = r:GetName();
			rTex = r:GetTexture();
			rDL = r:GetDrawLayer();
			if (rTex and string.find(rTex, "TrackingBorder")) then
				r:Show();
			end
		end
	end

	if miniButton.MBFoTex then
		miniButton.MBFoTex:SetTexture(nil);
		miniButton.MBFoTex:Hide();
	end

	if miniButton.MBFbTex then
		miniButton.MBFbTex:SetTexture(nil);
		miniButton.MBFbTex:Hide();
	end
end

function textureButton(miniButton)
local buttonName, buttonType, rName, rTex, rDL, foundOverlay;
local override = 0

	buttonName = miniButton:GetName();
	buttonType = miniButton:GetObjectType();
	if (buttonName == "MiniMapTrackingButton") then
		override = 1;
	end
	
	if buttonName and (buttonType == "Button" or (buttonType == "Frame" and (buttonName == "MiniMapMailFrame" or buttonName == "BejeweledMinimapIcon" or buttonName == "PeggledMinimapIcon"))) and (not isInTable(SkinProtect, buttonName)) then
		foundOverlay = false;

		-- Does this button already have its own texture sitting on the ARTWORK
		-- layer (the layer real icon content normally lives on)? If so, a
		-- separate BACKGROUND-layer texture almost certainly belongs behind it
		-- on purpose, and promoting it up to ARTWORK too would stack the two and
		-- can hide the real icon behind the (formerly background) one. Only
		-- counts if that ARTWORK texture is reasonably large -- a small badge or
		-- indicator icon on ARTWORK isn't the main icon, and shouldn't block the
		-- actual icon art (sitting on BACKGROUND) from being promoted instead.
		local hasArtwork = false;
		local btnWidth, btnHeight = miniButton:GetWidth(), miniButton:GetHeight();
		for _, r in pairs({miniButton:GetRegions()}) do
			local rTexPre = r:GetTexture();
			if (r:GetObjectType() == "Texture") and (r:GetDrawLayer() == "ARTWORK") and (r:GetName() ~= "MBFOverlay") and (r:GetName() ~= "MBFBackground") and (not (rTexPre and string.find(rTexPre, "TrackingBorder"))) then
				local rWidth, rHeight = r:GetWidth(), r:GetHeight();
				if (btnWidth and btnHeight and btnWidth > 0 and btnHeight > 0 and rWidth and rHeight) then
					if ((rWidth / btnWidth) > 0.5) and ((rHeight / btnHeight) > 0.5) then
						hasArtwork = true;
					end
				else
					hasArtwork = true;	-- can't measure, err on the side of the old (safer) behavior
				end
			end
		end

		for _, r in pairs({miniButton:GetRegions()}) do
			if r:GetObjectType() == "Texture" then
				rName = r:GetName();
				rTex = r:GetTexture();
				rDL = r:GetDrawLayer();
				if ((rDL == "OVERLAY") or (rTex and string.find(rTex, "TrackingBorder"))) then
					-- Some addons draw their actual icon artwork on the OVERLAY
					-- layer (not just decorative borders). Only treat this as a
					-- border to swap out if MBF actually has a border texture
					-- configured to replace it with -- otherwise leave the
					-- button's own texture alone rather than hiding it for nothing.
					if (tBorder[MBF.db.profile.currentTexture] ~= nil) or (rTex and string.find(rTex, "TrackingBorder")) then
						foundOverlay = true;
						r:Hide();
						MBFSkinMinimapButton(miniButton,override);
					end
				elseif (((rDL == "BACKGROUND") or (rDL == "BORDER") or (rDL == "ARTWORK")) and (buttonName ~= "WIM3MinimapButton")) then
					if (rName == "MBFBackground") then
						r:SetDrawLayer("BACKGROUND");
					elseif (rDL == "BACKGROUND") and hasArtwork then
						-- Leave it on BACKGROUND: this button already has a real
						-- icon texture on ARTWORK, so this one belongs behind it.
					else
						r:SetDrawLayer("ARTWORK");
					end
				end
			end
		end
		if (foundOverlay == false) then
			MBFSkinMinimapButton(miniButton);
		end
	elseif (buttonName and (buttonType == "Frame")) then
		textureFrame(miniButton);
	end
end

function MBFSkinMinimapButton(miniButton, override)
	local size = tSize[MBF.db.profile.currentTexture];

	if (override == nil) then
		override = 0;
	end

	if not miniButton.MBFoTex then 
		miniButton.MBFoTex = miniButton:CreateTexture("MBFOverlay");
	end

	if (tBorder[MBF.db.profile.currentTexture] == nil) then
		miniButton.MBFoTex:SetTexture(nil);
		miniButton.MBFoTex:Hide();
	else
		miniButton.MBFoTex:Show();
		miniButton.MBFoTex:SetTexture(tBorder[MBF.db.profile.currentTexture]);
		miniButton.MBFoTex:SetWidth(size);
		miniButton.MBFoTex:SetHeight(size);
		miniButton.MBFoTex:ClearAllPoints();
		miniButton.MBFoTex:SetPoint("CENTER");
		miniButton.MBFoTex:SetDrawLayer("OVERLAY");
	end
	
	if (override ~= 1) then
		if not miniButton.MBFbTex then 
			miniButton.MBFbTex = miniButton:CreateTexture("MBFBackground"); 
		end

		if (tBackdrop[MBF.db.profile.currentTexture] == nil) then
			miniButton.MBFbTex:SetTexture(nil);
			miniButton.MBFbTex:Hide();
		else
			miniButton.MBFbTex:Show();
			miniButton.MBFbTex:SetDrawLayer("BACKGROUND");
			miniButton.MBFbTex:SetTexture(tBackdrop[MBF.db.profile.currentTexture]);
			miniButton.MBFbTex:ClearAllPoints();
			miniButton.MBFbTex:SetPoint("CENTER");
			miniButton.MBFbTex:SetWidth(size); 
			miniButton.MBFbTex:SetHeight(size);
		end
	end
end

-- Button Gathering Functions

function findButtons(frame)
	local i, child

	for i, child in ipairs({frame:GetChildren()}) do
		if (child:GetName() == "CECBMiniMapButtonFrame") then
			child = CECBMiniMapButton;
		end
		if (isValidAdd(child, true)) then
			addButton(child);
		end
	end
end

function findIncluded()
	local miniButton, k, v;
	for k,v in ipairs(MBF.db.profile.MBF_Include) do
		miniButton = _G[v];
		if (miniButton ~= nil) and (miniButton:IsShown()) then
			addButton(miniButton);
		end
	end
end

saveOldData = function(miniButton)
	local result = false;
	oldPoint = nil;

	oldPoint, oldRelativeTo, oldRelativePoint, oldXofs, oldYofs = miniButton:GetPoint();

	if oldPoint ~= nil then
		oldName = miniButton:GetName();
		oldParentName = miniButton:GetParent():GetName();
		oldFrameLevel = miniButton:GetFrameLevel();
		oldOnDragStart = miniButton:GetScript('OnDragStart');
		oldOnDragStop = miniButton:GetScript('OnDragStop');
		oldOnEvent = miniButton:GetScript('OnEvent');
		oldWidth = miniButton:GetWidth();
		oldHeight = miniButton:GetHeight();
		oldScale = miniButton:GetScale();
		oldLevel = miniButton:GetFrameLevel();
		oldStrata = miniButton:GetFrameStrata();

		MBF_ButtonInfoStorage[miniButton:GetName()] = { oldName, oldParentName, oldFrameLevel, oldPoint, oldRelativeTo, oldRelativePoint, oldXofs, oldYofs, oldOnDragStart, oldOnDragStop, oldOnEvent, oldWidth, oldHeight, oldScale, oldLevel, oldStrata };
		result = true;
	end
	return result;
end

function saveAndDisableChildScripts(miniButton)
	local childName;
	local childParentName;
	local childOnDragStart;
	local childOnDragStop;
	local childOnEvent;

	if not isInTable(BlizzButtons, miniButton:GetName()) then
		for i, child in ipairs({miniButton:GetChildren()}) do
			childName = child:GetName();

			if (childName ~= nil) then
				childParentName = child:GetParent():GetName();
				childOnDragStart = child:GetScript('OnDragStart');
				childOnDragStop = child:GetScript('OnDragStop');
				childOnEvent = child:GetScript('OnEvent');

				MBF_ChildEventStorage[childName] = {childParentName, childName, childOnDragStart, childOnDragStop, childOnEvent};	

				child:SetScript('OnDragStart', nil);
				child:SetScript('OnDragStop', nil);
				
				if (isInTable(BlizzButtons, childName) == false) then
					child:SetScript('OnEvent', nil);
				end
			end
		end
	end
end

removeChildScriptStorageRow = function(buttonName)
	local childName;
	local childParentName;
	local childOnDragStart;
	local childOnDragStop;
	local childOnEvent;
	local result = false;
	local DummyTable = {};	

	for k,v in pairs(MBF_ChildEventStorage) do
		childParentName, childName, childOnDragStart, childOnDragStop, childOnEvent = unpack(v);

		if(childParentName == buttonName) then
			result = true;
		else
			DummyTable[childName] = { childParentName, childName, childOnDragStart, childOnDragStop, childOnEvent };
		end
	end
	MBF_ChildEventStorage = DummyTable;
	DummyTable = {};
	return result;
end

function restoreChildScripts(miniButton)
	local oldChild;
	local childName;
	local childParentName;
	local childOnDragStart;
	local childOnDragStop;
	local childOnEvent;
	local buttonName = miniButton:GetName();
	local success = false;

	if not isInTable(BlizzButtons, buttonName) then
		for i, child in ipairs({miniButton:GetChildren()}) do

			oldChild = MBF_ChildEventStorage[child:GetName()]
			if oldChild ~= nil then

				childParentName, childName, childOnDragStart, childOnDragStop, childOnEvent = unpack(oldChild);

				child:SetScript('OnDragStart', childOnDragStart);
				child:SetScript('OnDragStop', childOnDragStop);
				child:SetScript('OnEvent', childOnEvent);
			end
		end
		
		if oldChild ~= nil then
			success = removeChildScriptStorageRow(buttonName);

			if (success == false) then
				MBF:Print(L["MBF_ERR5"] .. " : " .. buttonName);
			end
		end
	end
 end

addButton = function(miniButton)
	local transferResult = false;

	if miniButton:GetParent() ~= MinimapButtonFrame then
		local buttonName = miniButton:GetName();

		if saveOldData(miniButton) then

			miniButton:SetParent(MinimapButtonFrame)
			miniButton:SetMovable(true);
			if MBF.db.profile.iconDragEnabled then
				MBF:StashMouseScripts(miniButton);
				miniButton:RegisterForDrag("LeftButton");
				miniButton:SetScript('OnDragStart', MBF_IconDragStart);
				miniButton:SetScript('OnDragStop', MBF_IconDragStop);
			end
			miniButton:SetScript('OnUpdate', nil);
			
			if (isButtonFrame(miniButton)) then
				saveAndDisableChildScripts(miniButton);
			end
			
			if (isBlizzButton(buttonName) == false) then
				miniButton:SetScript('OnEvent', nil);
			end
			if (buttonName == "BigFootMinimapButton") then
				miniButton:SetScript('OnShow', nil);
				miniButton:SetFrameLevel(MinimapButtonFrame:GetFrameLevel()+1)
			end
			if ((buttonName == "MiniMapTracking") or (buttonName == "GameTimeFrame") or (buttonName == "FeedbackUIButton")) then
				miniButton:SetWidth(36);
				miniButton:SetHeight(34);
			end
			if (buttonName == "MonkeyBuddyIconButton") then
				miniButton:SetWidth(33);
				miniButton:SetHeight(33);
			end
			if ((miniButton:GetHeight() ~= 33) and (buttonName ~= "AM_MinimapButton") and (buttonName ~= "BejeweledMinimapIcon") and (buttonName == "PeggledMinimapIcon")) then
				miniButton:SetScale(33 / miniButton:GetHeight());
			end

			textureButton(miniButton);
			transferResult = true;
		end
	end
	return transferResult;
end

restoreButtonSettings = function(miniButton)
	local buttonName = miniButton:GetName();
	local foundButton = false;

	-- Load row and Remove from Storage
	
	if MBF_ButtonInfoStorage[buttonName] ~= nil then
		
		oldName, oldParentName, oldFrameLevel, oldPoint, oldRelativeTo, oldRelativePoint, oldXofs, oldYofs, oldOnDragStart, oldOnDragStop, oldOnEvent, oldWidth, oldHeight, oldScale, oldLevel, oldStrata = unpack(MBF_ButtonInfoStorage[buttonName]);

		miniButton:ClearAllPoints();
		if (oldPoint ~= nil) then
			miniButton:SetPoint(oldPoint, oldRelativeTo, oldRelativePoint, oldXofs, oldYofs);
		end
		miniButton:SetParent(oldParentName);
		miniButton:SetFrameLevel(oldFrameLevel);
		MBF:RestoreMouseScripts(miniButton);
		miniButton:SetScript('OnDragStart', oldOnDragStart);
		miniButton:SetScript('OnDragStop', oldOnDragStop);
		miniButton:RegisterForDrag();
		miniButton:SetScript('OnEvent', oldOnEvent);
		miniButton:SetWidth(oldWidth);
		miniButton:SetHeight(oldHeight);
		miniButton:SetScale(oldScale);
		miniButton:SetFrameLevel(oldLevel);
		miniButton:SetFrameStrata(oldStrata);

		if (miniButton:GetNumChildren() > 0) then
			restoreChildScripts(miniButton);
		end

		miniButton:GetParent():Show();
		
		removeTextures(miniButton);

		foundButton = true;
		MBF_ButtonInfoStorage[buttonName] = nil;
	end
	return foundButton;
end

function ClearMBF()
	for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
		removeButton(miniButton, 1);
	end
end

function removeButton(miniButton, clear)
	local success = false;
	local isBlizz = false;

	if (miniButton:GetParent() == MinimapButtonFrame and (miniButton:GetName() ~= "MinimapButtonFrameDragButton")) then
		MBF_ForgetSlidePosition(miniButton:GetName());

		if (miniButton:GetName() == "MiniMapMailFrameDisabled") then
			miniButton = MiniMapMailFrame;
			MiniMapMailFrameDisabled:Hide();
		elseif (miniButton:GetName() == "MiniMapMailFrame") then
			MiniMapMailFrameDisabled:Hide();
		end
		
		success = restoreButtonSettings(miniButton);
		
		if ((success) and (clear == 0)) then
			if (isInTable(MBF.db.profile.MBF_Include, miniButton:GetName())) then
				removeFromTable(MBF.db.profile.MBF_Include, miniButton:GetName());
			elseif (isInTable(MBF.db.profile.MBF_Ignore, miniButton:GetName()) == false) then
				isBlizz = isBlizzButton(miniButton:GetName());
				if (((isBlizz and MBF.db.profile.grabBlizzButtons) or (isBlizz == false)) and (miniButton:GetName() ~= "LibDBIcon10_MBF")) then
					tinsert(MBF.db.profile.MBF_Ignore, miniButton:GetName());
				end 
			end
		elseif (success == false) and (clear == 0) then
			MBF:Print(L["MBF_ERR1"] .. " : " .. miniButton:GetName());
		end

		if (clear == 0) then
			MBF:Scan()
		end
	else
		if (((isInTable(MBF.db.profile.ParentStop, miniButton:GetParent():GetName()) == true) or (isInTable(BlizzParentStop, miniButton:GetParent():GetName()) == true)) and (miniButton:GetName() ~= "MiniMapMailFrame")) then
			MBF:Print(L["MBF_ERR2"] .. " : " .. miniButton:GetName());
		elseif (miniButton:GetName() ~= "MinimapButtonFrameDragButton") and (miniButton:GetName() ~= "MiniMapMailFrame") then 
			removeButton(miniButton:GetParent(), clear);
		end
	end
end

function removeInvisible(miniButton)
	local success = false;
	if ((miniButton:GetParent() == MinimapButtonFrame) and (miniButton:GetName() ~= "MinimapButtonFrameDragButton"))then
		success = restoreButtonSettings(miniButton);
		if (success == false) then
			MBF:Print(L["MBF_ERR3"] .. " : " .. miniButton:GetName());
		end
	end
end

function removeBlizzButtons()
local miniButton;
local mbfHide = MBF.db.profile.mbfHidden;

	if (mbfHide == true) then
		MinimapButtonFrame:Show();
		MBFRestoreButtonFrame:Show();
	end
	for k,v in pairs(BlizzButtons) do
		miniButton = _G[v];
		if (miniButton ~= nil) and (miniButton:IsShown()) and (isInTable(MBF.db.profile.MBF_Ignore,v) == false) then
			removeButton(miniButton, 0)
		elseif ((v == "MiniMapMailFrame") and (isInTable(MBF.db.profile.MBF_Ignore,v) == false)) then
			removeButton(miniButton, 0)
		end
	end
	if (mbfHide == true) then
		MinimapButtonFrame:Hide();
		MBFRestoreButtonFrame:Hide();
	end
end

function includeButton(miniButton)
	local buttonName = miniButton:GetName();
	local parentName;

	if (buttonName ~= "WorldFrame") then
		parentName = miniButton:GetParent():GetName();
		if (isValidAdd(miniButton,false)) then
			if (isInTable(MBF.db.profile.ParentStop, parentName) or isInTable(BlizzParentStop, parentName)) then
				if addButton(miniButton) then
					if (isInTable(MBF.db.profile.MBF_Ignore, buttonName)) then
						removeFromTable(MBF.db.profile.MBF_Ignore, buttonName);
					else
						tinsert(MBF.db.profile.MBF_Include, buttonName);
					end
					MBF:Scan()
				else
					MBF:Print(L["MBF_ERR6"] .. " : " .. miniButton:GetName());
				end
			else
				includeButton(miniButton:GetParent())
			end
		else
			if (miniButton:GetName() ~= nil) then
				MBF:Print(L["MBF_ERR4"] .. " : " .. miniButton:GetName());
			else
				MBF:Print(L["MBF_ERR4"] .. " : " .. L["MBF_UnnamedObject"]);
			end
		end 
	else
		MBF:Print(L["MBF_ERR4"] .. " : " .. miniButton:GetName());
	end
end

local function caseInsensitiveLess(a, b)
	return strlower(a) < strlower(b);
end

-- MiniMapMailFrameDisabled (the greyed-out "no mail" overlay) isn't itself in
-- BlizzButtons, but it stands in for MiniMapMailFrame and must sort alongside
-- the real Blizzard buttons, not alphabetically among addon buttons.
local function isBlizzPriority(name)
	return isBlizzButton(name) or (name == "MiniMapMailFrameDisabled");
end

local sortChildren = function()
	local sortOrder = MBF.db.profile.sortOrder;

	if sortOrder == "Custom" then
		updateCustomChildren();	-- pick up any newly-gathered buttons not yet listed

		-- customChildren never gets pruned when a button is removed from MBF, so it
		-- can carry stale names for buttons that no longer belong to the frame.
		-- Placing one of those into a real grid slot pushes every button after it
		-- into the wrong position and can visually collide with the stale button's
		-- own (unrelated) position elsewhere on screen. Filter to only buttons MBF
		-- currently actually owns.
		local valid = {};
		for i, name in ipairs(MBF.db.profile.customChildren) do
			local btn = _G[name];
			if btn and btn:GetParent() == MinimapButtonFrame then
				tinsert(valid, name);
			end
		end
		return valid;
	end

	-- "Blizzard First" / "Blizzard Last" both need Blizzard-button status factored
	-- into the ordering; everything else is a plain alphabetical sort.
	local blizzFirst = (sortOrder == "Blizzard First");
	local prioritizeBlizz = blizzFirst or (sortOrder == "Blizzard Last");

	local Children = {};

	for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
		local buttonName = miniButton:GetName();

		if (miniButton:IsShown()) or (MBF.db.profile.mbfHidden) then
			tinsert(Children, buttonName);
		else
			if ((buttonName ~= "MiniMapMailFrame") or (MBF.db.profile.MBFHideMiniMapMailFrame == true) or (MBF.db.profile.disabledMail == false)) and (buttonName ~= "MiniMapMailFrameDisabled") then
				if (MinimapButtonFrame:IsShown()) then
					removeInvisible(miniButton);
				end
			elseif (displayDisabledMail()) or (buttonName == "MiniMapMailFrame") then
				tinsert(Children, buttonName);
			end
		end
	end

	if prioritizeBlizz then
		sort(Children, function(a, b)
			local aBlizz, bBlizz = isBlizzPriority(a), isBlizzPriority(b);
			if aBlizz ~= bBlizz then
				if blizzFirst then
					return aBlizz;
				else
					return not aBlizz;
				end
			end
			return strlower(a) < strlower(b);
		end);
	else
		sort(Children, caseInsensitiveLess);
	end

	return Children;
end

-- Smooth Rearrange Animation

local MBF_SlidePos = {};	-- [buttonName] = { relPoint = ..., x = ..., y = ... }  (last placed position)
local MBF_SLIDE_DURATION = 0.2;

local function MBF_SlideOnUpdate(self, elapsed)
	local data = self.MBFSlide;
	if not data then
		self:SetScript("OnUpdate", nil);
		return;
	end

	data.t = data.t + elapsed;
	local pct = data.t / MBF_SLIDE_DURATION;

	if pct >= 1 then
		self:ClearAllPoints();
		self:SetPoint("CENTER", MinimapButtonFrame, data.relPoint, data.toX, data.toY);
		self.MBFSlide = nil;
		self:SetScript("OnUpdate", nil);
		return;
	end

	local eased = 1 - (1 - pct) * (1 - pct);	-- ease-out, feels smoother than linear
	local curX = data.fromX + (data.toX - data.fromX) * eased;
	local curY = data.fromY + (data.toY - data.fromY) * eased;

	self:ClearAllPoints();
	self:SetPoint("CENTER", MinimapButtonFrame, data.relPoint, curX, curY);
end

function MBF_PlaceButton(miniButton, relPoint, toX, toY)
	local buttonName = miniButton:GetName();
	local prev = MBF_SlidePos[buttonName];

	if InCombatLockdown() or (not MBF.db.profile.animateRearrange) or (prev == nil) or (prev.relPoint ~= relPoint) then
		miniButton:ClearAllPoints();
		miniButton:SetPoint("CENTER", MinimapButtonFrame, relPoint, toX, toY);
		miniButton.MBFSlide = nil;
		miniButton:SetScript("OnUpdate", nil);
	elseif ((abs(prev.x - toX) < 0.5) and (abs(prev.y - toY) < 0.5)) then
		-- Already where it should be, nothing to animate. If MBFSlide is set but
		-- nothing is actually driving it anymore (its OnUpdate got cleared by
		-- something else without matching cleanup), that's orphaned state from an
		-- interrupted slide -- force a clean placement instead of trusting it.
		if (not miniButton.MBFSlide) or (miniButton:GetScript("OnUpdate") ~= MBF_SlideOnUpdate) then
			miniButton.MBFSlide = nil;
			miniButton:ClearAllPoints();
			miniButton:SetPoint("CENTER", MinimapButtonFrame, relPoint, toX, toY);
		end
	else
		miniButton.MBFSlide = { relPoint = relPoint, fromX = prev.x, fromY = prev.y, toX = toX, toY = toY, t = 0 };
		miniButton:ClearAllPoints();
		miniButton:SetPoint("CENTER", MinimapButtonFrame, relPoint, prev.x, prev.y);
		miniButton:SetScript("OnUpdate", MBF_SlideOnUpdate);
	end

	MBF_SlidePos[buttonName] = { relPoint = relPoint, x = toX, y = toY };
end

function MBF_ForgetSlidePosition(buttonName)
	MBF_SlidePos[buttonName] = nil;
	local miniButton = _G[buttonName];
	if miniButton then
		miniButton.MBFSlide = nil;
		miniButton:SetScript("OnUpdate", nil);
	end
end

-- Stuck-Drag Watchdog
--
-- Some addons implement their minimap icon's "orbit the minimap while dragging"
-- behavior with a manual OnMouseDown -> OnUpdate -> OnMouseUp cycle instead of the
-- native OnDragStart/OnDragStop system. MBF only clears OnDragStart/OnDragStop when
-- it gathers a button, so that OnMouseDown handler can still be live. If the user
-- drags a gathered icon, the OnUpdate loop repositions it using minimap-relative
-- math even though MBF has since reparented it elsewhere, and the mouse can end up
-- not over the button when released -- so OnMouseUp (and thus the loop) never stops.
-- This watchdog force-clears any such leftover OnUpdate once the mouse button is
-- verifiably no longer held, regardless of which library is behind the icon.

function MBF:RetextureLateIcons()
	textureFrame(MinimapButtonFrame);
end

function MBF:WatchStuckDrags()
	if IsMouseButtonDown("LeftButton") then
		return;
	end

	for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
		local handler = miniButton:GetScript("OnUpdate");
		if (handler ~= nil) and (handler ~= MBF_SlideOnUpdate) and (miniButton ~= MinimapButtonFrameDragButton) then
			miniButton:SetScript("OnUpdate", nil);
			miniButton.MBFSlide = nil;
		end

		for j, child in ipairs({miniButton:GetChildren()}) do
			local childHandler = child:GetScript("OnUpdate");
			if (childHandler ~= nil) and (childHandler ~= MBF_SlideOnUpdate) then
				child:SetScript("OnUpdate", nil);
				child.MBFSlide = nil;
			end
		end
	end
end

function updatePositions()

	local processMail = false;

	local avgButtonSize = 33 + MBF.db.profile.padding;
	local spacer = avgButtonSize / 2;
	local originOffset = spacer + 5;

	local order = MBF_FillOrders[MBF.db.profile.fillOrder] or MBF_FillOrders["RightDown"];
	local primaryVertical = (order.primaryAxis == "Vertical");
	local goRight = (order.horizontalDir == "Right");
	local goDown = (order.verticalDir == "Down");

	-- WoW's SetPoint offsets are sign-consistent no matter which corner you
	-- anchor from: positive X is always further right, positive Y is always
	-- further up. So the starting offset and per-step increments just need the
	-- right sign for the chosen direction; the anchor corner (picked below)
	-- handles where that origin actually sits on screen.
	local x = goRight and originOffset or -originOffset;
	local y = goDown and -originOffset or originOffset;
	local xStep = goRight and avgButtonSize or -avgButtonSize;
	local yStep = goDown and -avgButtonSize or avgButtonSize;

	local relPoint = (goDown and "TOP" or "BOTTOM") .. (goRight and "LEFT" or "RIGHT");

	local crPad;
	local iterator = 1;

	-- The "fixed" dimension depends on Fill Order's primary direction: Left/Right
	-- wraps after a set number of columns, Up/Down wraps after a set number of
	-- rows -- each remembered independently.
	local fixedCount = primaryVertical and MBF.db.profile.rows or MBF.db.profile.columns;

	-- Call sortChildren() once and reuse it for both the count below and the
	-- placement loop, instead of calling it twice. Count only entries that will
	-- actually get a slot (same filter as the placement loop uses) - GetNumChildren()
	-- also counts gathered-but-currently-hidden buttons (e.g. Blizzard's LFG or
	-- Battleground icon when not queued), which previously inflated the frame
	-- size beyond what's actually visible.
	local orderedChildren = sortChildren();
	local realCount = 0;
	for i, buttonName in ipairs(orderedChildren) do
		local miniButton = _G[buttonName];
		if ((buttonName ~= "MinimapButtonFrameDragButton") and (buttonName ~= "MiniMapMailFrameDisabled") and (miniButton ~= nil) and (((MinimapButtonFrame:IsShown()) and (buttonName == "MiniMapMailFrame") or (miniButton:IsShown())))) then
			realCount = realCount + 1;
		end
	end
	if realCount < 1 then realCount = 1; end

	local numChildrenRC = ceil(realCount / fixedCount);
	local userSize = (fixedCount * avgButtonSize)
	local dynamicSize = (numChildrenRC * avgButtonSize)

	if primaryVertical then
		MinimapButtonFrame:SetHeight(userSize + 10);
		MinimapButtonFrame:SetWidth(dynamicSize + 10);
	else
		MinimapButtonFrame:SetWidth(userSize + 10);
		MinimapButtonFrame:SetHeight(dynamicSize + 10);
	end		

	setMBFLocation();
	
	for i, buttonName in ipairs(orderedChildren) do

		local miniButton = _G[buttonName];

		if ((buttonName ~= "MinimapButtonFrameDragButton") and (buttonName ~= "MiniMapMailFrameDisabled") and (miniButton ~= nil) and (((MinimapButtonFrame:IsShown()) and (buttonName == "MiniMapMailFrame") or (miniButton:IsShown())))) then
			
			miniButton:SetFrameStrata("MEDIUM");
			miniButton:SetFrameLevel(MinimapButtonFrame:GetFrameLevel() + 1);
			
			if ((mod(iterator-1,fixedCount) == 0) and iterator > 1) then
				if primaryVertical then
					y = goDown and -originOffset or originOffset;
					x = x + xStep;
				else
					x = goRight and originOffset or -originOffset;
					y = y + yStep;
				end
			end

			miniButton:ClearAllPoints();
			
			if (miniButton:GetScale() ~= 1) then
				MBF_PlaceButton(miniButton, relPoint, x + (x * (1 - miniButton:GetScale())), y + (y * (1 - miniButton:GetScale())));
			else
				MBF_PlaceButton(miniButton, relPoint, x, y);
			end
			
			if primaryVertical then
				y = y + yStep;
			else
				x = x + xStep;
			end

			iterator = iterator + 1;
			
			if (buttonName == "MiniMapMailFrame") then
				MiniMapMailFrameDisabled:ClearAllPoints();
				MiniMapMailFrameDisabled:SetAllPoints(miniButton);
				if (HasNewMail() == 1) then
					MiniMapMailFrameDisabled:Hide();
					MiniMapMailFrameDisabled:SetFrameLevel(MiniMapMailFrame:GetFrameLevel()-1)
					MiniMapMailFrame:Show()
				elseif ((MBF.db.profile.grabBlizzButtons == true) and (MBF.db.profile.disabledMail == true)) then
					MiniMapMailFrameDisabled:Show();
					MiniMapMailFrameDisabled:SetFrameLevel(MiniMapMailFrame:GetFrameLevel()+1)
				end
			end
		elseif (buttonName == "MiniMapMailFrameDisabled") then
			if (displayDisabledMail()) then 
				MiniMapMailFrameDisabled:Show();
				MiniMapMailFrameDisabled:SetFrameLevel(MiniMapMailFrame:GetFrameLevel()+1)
			else
				MiniMapMailFrameDisabled:Hide();
				MiniMapMailFrameDisabled:SetFrameLevel(MinimapButtonFrame:GetFrameLevel()-1)
			end
		end
	end
end

function MBF:Scan()
	if currentProfile ~= self.db:GetCurrentProfile() then
		setFrameDefaults()

		MiniMapTracking:Show()
		MiniMapVoiceChatFrame:Show()
		MiniMapWorldMapButton:Show()
		MinimapZoomIn:Show()
		MinimapZoomOut:Show()
		GameTimeFrame:Show()
		if HasNewMail() then
			MiniMapMailFrame:Show()
		end
		ClearMBF()
	end

	MBFC_KeepBlizzHidden()
	findButtons(Minimap)
	findButtons(MinimapBackdrop)
	findIncluded()
	if isValidAdd(GameTimeFrame, true) then
		addButton(GameTimeFrame)
	end
	updatePositions()
	if currentProfile ~= self.db:GetCurrentProfile() then self:Init() end
	self:SwapTitleLocation()

	if MinimapButtonFrame:GetNumChildren() ~= numButtons then
		for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
			if miniButton:GetName() ~= "MinimapButtonFrameDragButton" and miniButton:GetName() ~= "MiniMapMailFrameDisabled" then 
				childList[miniButton:GetName()] = miniButton:GetName()
			end
		end

		updateCustomChildren();
		numButtons = MinimapButtonFrame:GetNumChildren()
	end
	
	if not scanned then
		MBFC_CheckSkin();
		textureFrame(MinimapButtonFrame);
		scanned = true
	end
end

-- Config Functions

function MBFC_Toggle ()
	if InterfaceOptionsFrame:IsShown() then
		InterfaceOptionsFrame:Hide();
	else
		-- InterfaceOptionsFrame_OpenToCategory has a long-documented Blizzard bug:
		-- the first call in a session opens the options window but fails to
		-- actually switch to the requested category, because the addon list's
		-- buttons haven't been populated yet at that point. Forcing that list to
		-- populate first (InterfaceAddOnsList_Update) fixes the actual root
		-- cause; calling OpenToCategory twice is a secondary safety net on top.
		InterfaceAddOnsList_Update();
		InterfaceOptionsFrame_OpenToCategory(MBF.optionsFrame);
		InterfaceOptionsFrame_OpenToCategory(MBF.optionsFrame);
	end
end

function MBFC_Visible(source, parentName) 
local activate = false;
	
	if (source == 1) then -- From MBF Minimap Button
		if (MBF.db.profile.grabMBFButton == false) then
			activate = true;
		end
	elseif (source == 2) then -- From FuBar or Titan Plugin
		if (parentName ~= "MinimapButtonFrame") then
			activate = true;
		end
	elseif (source == 3) then -- Command Line Show
		if (MBF.db.profile.mbfHidden == true) then
			activate = true;
		end	
	elseif (source == 4) then -- Command Line Hide
		if (MBF.db.profile.mbfHidden == false) then
			activate = true;
		end
	end

	if (activate) then 
		if MinimapButtonFrame:IsShown() then
			MinimapButtonFrame:Hide();
			MBFRestoreButtonFrame:Hide();
			MBF.db.profile.mbfHidden = true;
		else
			MinimapButtonFrame:Show();
			if not MBF.db.profile.locked then
				MBFRestoreButtonFrame:Show();
				MinimapButtonFrameDragButton:Show();
			end
			MBFRestoreButton:Hide();
			MBF.db.profile.mbfHidden = false;
		end
	end
end

function setFrameDefaults()
	-- Set the MBF Frame, dragButton, and restore button to their default visiblility
		MinimapButtonFrame:Show();
		if not MBF.db.profile.locked then
			MinimapButtonFrameDragButton:Show();
			MBFRestoreButtonFrame:Show();
		else
			MinimapButtonFrameDragButton:Hide();
			MBFRestoreButtonFrame:Hide();
		end
		MBFRestoreButton:Hide();		
end

function MBFC_KeepBlizzHidden()
	if MBF.db.profile.MBFHideMiniMapTracking == true then
		MiniMapTracking:Hide();
	end
	if MBF.db.profile.MBFHideMiniMapVoiceChatFrame == true then
		MiniMapVoiceChatFrame:Hide();
	end
	if MBF.db.profile.MBFHideMiniMapWorldMapButton == true then
		MiniMapWorldMapButton:Hide();
	end
	if MBF.db.profile.MBFHideMinimapZoomIn  == true then
		MinimapZoomIn:Hide();
		MinimapZoomOut:Hide();
	end
	if MBF.db.profile.MBFHideMiniMapMailFrame == true then
		MiniMapMailFrame:Hide();
		MiniMapMailFrameDisabled:Hide();	
	end
	if MBF.db.profile.MBFHideGameTimeFrame == true then
		GameTimeFrame:Hide();
	end
end

function MBFC_LoadStandardSkins()
	-- No border/backdrop paths -- this just leaves the button's own native
	-- appearance alone. Registered explicitly (rather than just relying on an
	-- unregistered id safely no-op'ing) so it shows up as a real, selectable
	-- choice in the Button Skin dropdown, not a blank/missing entry.
	MBFAddSkin("Default", nil, nil, 35);
	MBFAddSkin("Blizzard", "Interface\\AddOns\\Minimap_Button_Frame_Enhanced\\Textures\\BlizzBorder.tga", nil, 55);
	MBFAddSkin("Blizzard Square", "Interface\\AddOns\\Minimap_Button_Frame_Enhanced\\Textures\\BlizzSquare.tga", "Interface\\Buttons\\UI-EmptySlot", 45);
end

function MBFC_CheckSkin()
	local tLoaded = false;
	for i, id in pairs(tList) do
		if MBF.db.profile.currentTexture == id then
			tLoaded = true;
			break;
		end
	end
	if tLoaded == false then
		MBF.db.profile.currentTexture = "Default";
	end
end

function MBFC_ColorLocked() 
	local red = MBF.db.profile.MBFBackdropColor.Red;
	local green = MBF.db.profile.MBFBackdropColor.Green;
	local blue = MBF.db.profile.MBFBackdropColor.Blue;
	local opacity = MBF.db.profile.MBFBackdropColor.Alpha;	

	MBFRestoreButtonFrame:SetBackdropColor(red, green, blue, opacity);

	if ((MBF.db.profile.locked) and (MBF.db.profile.colorLocked == "All")) then
		MinimapButtonFrame:SetBackdropColor(0,0,0,0);
		MinimapButtonFrame:SetBackdropBorderColor(0,0,0,0);
	elseif ((MBF.db.profile.locked) and (MBF.db.profile.colorLocked == "Border")) then
		MinimapButtonFrame:SetBackdropColor(red, green, blue, opacity);
		MinimapButtonFrame:SetBackdropBorderColor(0,0,0,0);
	elseif ((MBF.db.profile.locked) and (MBF.db.profile.colorLocked == "Background")) then
		MinimapButtonFrame:SetBackdropColor(0,0,0,0);
		MinimapButtonFrame:SetBackdropBorderColor(1,1,1,1);
	else
		MinimapButtonFrame:SetBackdropColor(red, green, blue, opacity);
		MinimapButtonFrame:SetBackdropBorderColor(1,1,1,1);
	end
end

function MBFC_RollUp(setting)
	if (setting == 1) then
		MBFRestoreButton:ClearAllPoints();
		MBFRestoreButton:SetPoint(MinimapButtonFrameDragButton:GetPoint());
		MBFRestoreButton:Show();
		MBFRestoreButton:SetFrameLevel(MinimapButtonFrameDragButton:GetFrameLevel());
		MBFRestoreButton:SetFrameStrata(MinimapButtonFrameDragButton:GetFrameStrata());
		MBF.db.profile.rollUp = true;
		MBF.db.profile.mbfHidden = true;
		MinimapButtonFrame:Hide();
	elseif (setting == 2) then
		MinimapButtonFrameDragButton:ClearAllPoints();
		MinimapButtonFrameDragButton:SetPoint(MBFRestoreButton:GetPoint());
		MBFRestoreButton:Hide();
		MBF.db.profile.rollUp = false;
		MBF.db.profile.mbfHidden = false;
		MinimapButtonFrame:Show();
	end
end

function MBF:SetTitleSize(mbfWidth, mbfHeight)
	if mbfWidth <= mbfHeight then
		MinimapButtonFrameDragButton:SetWidth(mbfWidth);
		MinimapButtonFrameDragButton:SetHeight(28);
		MBFRestoreButtonFrame:SetWidth(mbfWidth);
		MBFRestoreButtonFrame:SetHeight(28);
		MBFRestoreButton:SetWidth(mbfWidth);
		MBFRestoreButton:SetHeight(28);
	else
		MinimapButtonFrameDragButton:SetWidth(28);
		MinimapButtonFrameDragButton:SetHeight(mbfHeight);
		MBFRestoreButtonFrame:SetWidth(28);
		MBFRestoreButtonFrame:SetHeight(mbfHeight);
		MBFRestoreButton:SetWidth(28);
		MBFRestoreButton:SetHeight(mbfHeight);
	end
end

function MBF:SwapTitleLocation()
	local mbfWidth = MinimapButtonFrame:GetWidth();
	local mbfHeight = MinimapButtonFrame:GetHeight();

	MinimapButtonFrameDragButton:ClearAllPoints();
	MBFRestoreButtonFrame:ClearAllPoints();

	self:SetTitleSize(mbfWidth, mbfHeight);

	if (mbfWidth <= mbfHeight) and (mbfWidth < 80) then
		MBFRestoreButton:SetText("MBF")
		MinimapButtonFrameDragButton:SetText("MBF")
	elseif (mbfWidth <= mbfHeight) and (mbfWidth >= 80) then
		MBFRestoreButton:SetText("MBF " .. MBFversion)
		MinimapButtonFrameDragButton:SetText("MBF " .. MBFversion)
	else
		MBFRestoreButton:SetText("M\nB\nF")
		MinimapButtonFrameDragButton:SetText("M\nB\nF")
	end

	if (MBF.db.profile.altTitle) and (mbfWidth <= mbfHeight) then
		MinimapButtonFrameDragButton:SetPoint("BOTTOMLEFT", "MinimapButtonFrame", "BOTTOMLEFT", 0, -30)
		MBFRestoreButtonFrame:SetPoint("BOTTOMLEFT", "MinimapButtonFrame", "BOTTOMLEFT", 0, -31)
	elseif (MBF.db.profile.altTitle) and (mbfWidth > mbfHeight) then
		MinimapButtonFrameDragButton:SetPoint("TOPRIGHT", "MinimapButtonFrame", "TOPRIGHT", 30, 0)
		MBFRestoreButtonFrame:SetPoint("TOPRIGHT", "MinimapButtonFrame", "TOPRIGHT", 31, 0)
	elseif (mbfWidth <= mbfHeight) then
		MinimapButtonFrameDragButton:SetPoint("TOPLEFT", "MinimapButtonFrame", "TOPLEFT", 0, 30)
		MBFRestoreButtonFrame:SetPoint("TOPLEFT", "MinimapButtonFrame", "TOPLEFT", 0, 31)
	else
		MinimapButtonFrameDragButton:SetPoint("BOTTOMLEFT", "MinimapButtonFrame", "BOTTOMLEFT", -30, 0)
		MBFRestoreButtonFrame:SetPoint("BOTTOMLEFT", "MinimapButtonFrame", "BOTTOMLEFT", -31, 0)
	end	

	MBFRestoreButton:ClearAllPoints();
	MBFRestoreButton:SetPoint(MinimapButtonFrameDragButton:GetPoint());
	MBFRestoreButton:SetFrameLevel(MinimapButtonFrameDragButton:GetFrameLevel());
	MBFRestoreButton:SetFrameStrata(MinimapButtonFrameDragButton:GetFrameStrata());
end

function MBF:fillDropdowns()
	for i, name in pairs(self.db.profile.MinimapIcons) do
		minimapIconList[name] = name
	end
	for i, name in pairs(self.db.profile.ButtonOverride) do
		buttonOverrideList[name] = name
	end
end

-- Drag-to-Reorder
--
-- Replaces the old "select a button from a dropdown, click Up/Down" approach:
-- when sort order is Custom, gathered icons can be picked up and dropped onto a
-- new spot in the frame to reorder them directly.

function MBF:ReorderCustomChild(draggedName, targetName)
	if draggedName == targetName then
		return;
	end

	updateCustomChildren();

	local custom = MBF.db.profile.customChildren;
	local draggedIndex, targetIndex;

	for i, name in ipairs(custom) do
		if name == draggedName then
			draggedIndex = i;
		elseif name == targetName then
			targetIndex = i;
		end
	end

	if (draggedIndex == nil) or (targetIndex == nil) then
		return;
	end

	tremove(custom, draggedIndex);
	if targetIndex > draggedIndex then
		targetIndex = targetIndex - 1;
	end
	tinsert(custom, targetIndex, draggedName);
end

-- Buttons whose OnMouseDown/OnMouseUp we've temporarily borrowed while rearrange
-- mode is on, keyed by button name, so they can be handed back exactly as they
-- were. Populated by MBF:StashMouseScripts, drained by MBF:RestoreMouseScripts.
local MBF_OrigMouseScripts = {};

function MBF:StashMouseScripts(miniButton)
	local buttonName = miniButton:GetName();

	-- Many minimap-icon libraries implement their own "orbit the minimap while
	-- dragging" behavior through OnMouseDown/OnMouseUp instead of the native
	-- OnDragStart/OnDragStop system. If we leave those live while we've also
	-- registered our own native drag, both try to reposition the button at once,
	-- fighting each other -- which looks exactly like the old stuck-orbit bug.
	-- Borrowing them only while rearrange mode is actually on keeps normal
	-- clicking untouched the rest of the time.
	if MBF_OrigMouseScripts[buttonName] == nil then
		MBF_OrigMouseScripts[buttonName] = {
			miniButton:GetScript("OnMouseDown"),
			miniButton:GetScript("OnMouseUp"),
		};
	end

	miniButton:SetScript("OnMouseDown", nil);
	miniButton:SetScript("OnMouseUp", nil);
end

function MBF:RestoreMouseScripts(miniButton)
	local buttonName = miniButton:GetName();
	local orig = MBF_OrigMouseScripts[buttonName];

	if orig then
		miniButton:SetScript("OnMouseDown", orig[1]);
		miniButton:SetScript("OnMouseUp", orig[2]);
		MBF_OrigMouseScripts[buttonName] = nil;
	end
end

function MBF:ApplyIconDragState()
	local enabled = MBF.db.profile.iconDragEnabled;

	if enabled and (not MBF.watchdogHandle) then
		MBF.watchdogHandle = MBF:ScheduleRepeatingTimer("WatchStuckDrags", 0.2);
	elseif (not enabled) and MBF.watchdogHandle then
		MBF:CancelTimer(MBF.watchdogHandle);
		MBF.watchdogHandle = nil;
	end

	for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
		if (miniButton ~= MinimapButtonFrameDragButton) and (miniButton:GetName() ~= "MiniMapMailFrameDisabled") then
			if enabled then
				MBF:StashMouseScripts(miniButton);

				miniButton:SetMovable(true);
				miniButton:RegisterForDrag("LeftButton");
				miniButton:SetScript('OnDragStart', MBF_IconDragStart);
				miniButton:SetScript('OnDragStop', MBF_IconDragStop);
			else
				miniButton:RegisterForDrag();
				miniButton:SetScript('OnDragStart', nil);
				miniButton:SetScript('OnDragStop', nil);

				MBF:RestoreMouseScripts(miniButton);
			end
		end
	end
end

function MBF_IconDragStart(self)
	if InCombatLockdown() then
		return;
	end

	self.MBF_DragStartX, self.MBF_DragStartY = self:GetCenter();
	self:SetFrameStrata("TOOLTIP");
	self:StartMoving();
end

function MBF_IconDragStop(self)
	local miniButton = self;
	miniButton:StopMovingOrSizing();

	if InCombatLockdown() then
		return;
	end

	-- A drag that barely moved the icon isn't a real reorder intent (mouse jitter,
	-- a slightly-imprecise click, etc.) -- just snap it back without reordering
	-- or touching the sort order at all.
	local dragX, dragY = miniButton:GetCenter();
	local startX, startY = miniButton.MBF_DragStartX, miniButton.MBF_DragStartY;

	if dragX and dragY and startX and startY then
		local moved = ((dragX - startX) * (dragX - startX)) + ((dragY - startY) * (dragY - startY));
		if moved < 100 then	-- ~10px
			MBF_ForgetSlidePosition(miniButton:GetName());
			miniButton.MBF_DragStartX, miniButton.MBF_DragStartY = nil, nil;
			MBF:Scan();
			return;
		end
	end

	if MBF.db.profile.sortOrder ~= "Custom" then
		MBF.db.profile.sortOrder = "Custom";
	end

	-- Find whichever other gathered icon is currently closest to where this one
	-- was dropped, and slot the dragged icon in right before it.
	local closest, closestDist;

	if dragX and dragY then
		for i, other in ipairs({MinimapButtonFrame:GetChildren()}) do
			if (other ~= miniButton) and (other ~= MinimapButtonFrameDragButton) and (other:GetName() ~= "MiniMapMailFrameDisabled") then
				local otherName = other:GetName();
				-- Mirrors the same visibility rule updatePositions() itself uses,
				-- so we only match against buttons that actually have a current,
				-- meaningful position in the visible grid -- not a hidden button's
				-- stale coordinates from whenever it was last shown.
				local otherRelevant = other:IsShown() or ((otherName == "MiniMapMailFrame") and MinimapButtonFrame:IsShown());

				if otherRelevant then
					local ox, oy = other:GetCenter();
					if ox and oy then
						local dist = ((ox - dragX) * (ox - dragX)) + ((oy - dragY) * (oy - dragY));
						if (closestDist == nil) or (dist < closestDist) then
							closestDist = dist;
							closest = other;
						end
					end
				end
			end
		end
	end

	if closest then
		MBF:ReorderCustomChild(miniButton:GetName(), closest:GetName());
	end

	-- The button was just being hand-positioned by the drag itself, so snap it
	-- straight into its new slot rather than sliding it there a second time;
	-- everything else that shifts as a result still animates normally.
	MBF_ForgetSlidePosition(miniButton:GetName());

	miniButton.MBF_DragStartX, miniButton.MBF_DragStartY = nil, nil;

	MBF:Scan();
end

function updateCustomChildren()
-- This will make sure that all the MBF Children are in the customChildren table
-- Don't remove any children from the list.  Should only run on whenever the # of buttons on MBF changes.
	local buttonName
	local miniButton
	local result = false
	local newButtons = {};

	for i, miniButton in ipairs({MinimapButtonFrame:GetChildren()}) do
		buttonName = miniButton:GetName()
		result = false
		for i, customButtonName in ipairs(MBF.db.profile.customChildren) do
			if buttonName == customButtonName then
				result = true
			end
		end
		if result == false then
			tinsert(newButtons, buttonName)
		end
	end

	-- MinimapButtonFrame:GetChildren() returns buttons in an arbitrary internal
	-- order, not the alphabetical order the user was just looking at. Appending
	-- them in that raw order (especially the very first time customChildren gets
	-- seeded, when it's empty) would silently reshuffle every icon instead of
	-- preserving the order already on screen. Sort just the newly-discovered ones
	-- alphabetically before appending, so a first drag only moves the one icon
	-- that was actually dragged.
	sort(newButtons, caseInsensitiveLess);

	for i, buttonName in ipairs(newButtons) do
		tinsert(MBF.db.profile.customChildren, buttonName)
	end
end

-- Tooltips

function NoMail_OnEnter()
	GameTooltip:SetOwner(MiniMapMailFrameDisabled, "ANCHOR_LEFT");
	GameTooltip:SetText(L["No New Mail"]);
	GameTooltip:Show();
end

function RollUp_OnEnter(setting)
	if (setting == 1) then
		GameTooltip:SetOwner(MinimapButtonFrameDragButton, "ANCHOR_LEFT");
	elseif (setting == 2) then
		GameTooltip:SetOwner(MBFRestoreButton, "ANCHOR_LEFT");
	end
	GameTooltipTextLeft1:SetTextColor(1, 1, 1);
	GameTooltip:AddLine(L["MBF_TOOLTIP_ROLLUP"]);
	GameTooltip:Show();
end
