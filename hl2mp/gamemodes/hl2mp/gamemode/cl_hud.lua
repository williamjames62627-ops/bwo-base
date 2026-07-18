include( "hl2skin.lua" )

DEFINE_BASECLASS( "gamemode_base" )



----
-- Pickups
----

function GM:HUDWeaponPickedUp( wep )
end

function GM:HUDItemPickedUp( item )
end

function GM:HUDAmmoPickedUp( name, amount )
end



----
-- Scoreboard
----

local function addcolumn( list, name, width )
	
	local col = list:AddColumn( name )
	col.Header:SetContentAlignment( 4 )
	col.Header:SetTextInset( 4, 0 )
	if width ~= nil then col:SetWidth( width ) end
	
	return col
	
end

local function createscoreboardteam( w, teamname, teamcolor )
	
	local listw = math.ceil( ScrW() * 0.2 )
	local headerh = math.ceil( ScrH() * 0.05 )
	
	local teambg = vgui.Create( "DPanel" )
	teambg:SetSkin( "HL2" )
	teambg:SetKeyboardInputEnabled( false )
	
	local teamlabel = vgui.Create( "DLabel", teambg )
	teamlabel:Dock( TOP )
	teamlabel:SetTall( headerh )
	teamlabel:SetSkin( "HL2" )
	teamlabel:SetFont( "HUDDefault" )
	teamlabel:SetTextColor( teamcolor )
	teamlabel:SetText( teamname )
	teamlabel:SetContentAlignment( 5 )
	
	local players = vgui.Create( "DListView", teambg )
	players:Dock( FILL )
	players:SetSkin( "HL2" )
	players:SetSortable( false )
	players:SetDataHeight( 18 )
	
	local colw = math.ceil( listw / 6 )
	local datah = players:GetDataHeight()
	
	players.AvatarColumn = addcolumn( players, "", datah )
	players.AvatarColumn:SetFixedWidth( datah )
	players.NameColumn = addcolumn( players, "#PlayerName", w - ( colw * 3 ) )
	players.KillsColumn = addcolumn( players, "#PlayerScore", colw )
	players.DeathsColumn = addcolumn( players, "#PlayerDeath", colw )
	players.PingColumn = addcolumn( players, "#PlayerPing", colw )
	
	return teambg, teamlabel, players
	
end

local function addplayer( list, ply, num )
	
	local line = list:GetLine( num )
	if IsValid( line ) == true then
		
		line:SetColumnText( 2, ply:Nick() )
		line:SetColumnText( 3, ply:Frags() )
		line:SetColumnText( 4, ply:Deaths() )
		line:SetColumnText( 5, ply:Ping() )
		
		line.Avatar:SetPlayer( ply:IsBot() ~= true and ply or nil )
		
	else
		
		line = list:AddLine( "", ply:Nick(), ply:Frags(), ply:Deaths(), ply:Ping() )
		local lineh = list:GetDataHeight()
		
		local avatar = vgui.Create( "AvatarImage", line )
		avatar:SetPos( 1, 1 )
		avatar:SetSize( lineh - 2, lineh - 2 )
		avatar:SetPlayer( ply:IsBot() ~= true and ply or nil )
		line.Avatar = avatar
		
	end
	
end

local function culllist( list, start )
	
	local lines = list:GetLines()
	for i = #lines, start, -1 do list:RemoveLine( i ) end
	
end

function GM:UpdateScoreboard()
	
	if IsValid( self.ScoreboardPanel ) ~= true then return end
	
	local tdm = self.CVar.teamplay:GetBool()
	local ffascoreboard = self.CCVar.ffascoreboard:GetBool()
	
	if team.NumPlayers( TEAM_SPECTATOR ) > 0 or team.NumPlayers( TEAM_UNASSIGNED ) > 0 then
		
		local spec = team.GetPlayers( TEAM_SPECTATOR )
		local unas = team.GetPlayers( TEAM_UNASSIGNED )
		
		local plytbl = {}
		
		for k, v in ipairs( spec ) do table.insert( plytbl, v:Nick() ) end
		for k, v in ipairs( unas ) do table.insert( plytbl, v:Nick() ) end
		
		self.ScoreboardSpectatorLabel:Show()
		self.ScoreboardSpectatorLabel:SetText( language.GetPhrase( "#Spectators" ) .. ": " .. table.concat( plytbl, ", " ) )
		
	else
		
		self.ScoreboardSpectatorLabel:Hide()
		self.ScoreboardSpectatorLabel:InvalidateParent()
		
	end
	
	if tdm ~= true and ffascoreboard == true then
		
		self.RebelScoreboard:Hide()
		self.CombineScoreboard:Hide()
		self.FFAScoreboard:Show()
		
		local plycount = 0
		
		-- Add players
		for k, p in ipairs( player.GetAll() ) do
			
			local teamid = p:Team()
			
			if teamid == TEAM_REBEL or teamid == TEAM_COMBINE then
				
				plycount = plycount + 1
				addplayer( self.FFAScoreboardList, p, plycount )
				
			end
			
		end
		
		culllist( self.FFAScoreboardList, plycount + 1 )
		
		self.FFAScoreboardList:SortByColumns( 3, true, 2 )
		
	else
		
		self.FFAScoreboard:Hide()
		self.RebelScoreboard:Show()
		self.CombineScoreboard:Show()
		
		local rebelcount = 0
		local combinecount = 0
		
		-- Add players
		for k, p in ipairs( player.GetAll() ) do
			
			local teamid = p:Team()
			
			if teamid == TEAM_REBEL then
				
				rebelcount = rebelcount + 1
				addplayer( self.RebelScoreboardList, p, rebelcount )
				
			elseif teamid == TEAM_COMBINE then
				
				combinecount = combinecount + 1
				addplayer( self.CombineScoreboardList, p, combinecount )
				
			end
			
		end
		
		culllist( self.RebelScoreboardList, rebelcount + 1 )
		culllist( self.CombineScoreboardList, combinecount + 1 )
		
		self.RebelScoreboardList:SortByColumns( 3, true, 2 )
		self.CombineScoreboardList:SortByColumns( 3, true, 2 )
		
	end
	
end

function GM:ScoreboardShow()
	
	self.ScoreboardVisible = true
	
	local skin = self.Skin
	
	local scrw = ScrW()
	local scrh = ScrH()
	local listx = math.ceil( scrw / 2 )
	local listy = math.ceil( scrh * 0.1 )
	local listw = math.ceil( scrw * 0.2 )
	local headerh = math.ceil( scrh * 0.05 )
	
	if IsValid( self.ScoreboardPanel ) == true then self.ScoreboardPanel:Remove() end
	
	self.ScoreboardPanel = vgui.Create( "DPanel" )
	self.ScoreboardPanel:SetPos( listx - listw, listy )
	self.ScoreboardPanel:SetSize( listw * 2, scrh - ( listy * 2 ) )
	self.ScoreboardPanel:SetSkin( "HL2" )
	self.ScoreboardPanel:MakePopup()
	self.ScoreboardPanel:SetKeyboardInputEnabled( false )
	
	local speclabel = vgui.Create( "DLabel", self.ScoreboardPanel )
	self.ScoreboardSpectatorLabel = speclabel
	speclabel:Dock( BOTTOM )
	speclabel:SetSkin( "HL2" )
	speclabel:SetWrap( true )
	speclabel:SetAutoStretchVertical( true )
	speclabel:SetTextInset( 2, 0 )
	
	-- Free-for-all
	local ffabg, ffalabel, ffa = createscoreboardteam( listw * 2, "FREE-FOR-ALL", skin.text_normal )
	
	self.FFAScoreboard = ffabg
	ffabg:SetParent( self.ScoreboardPanel )
	ffabg:Dock( FILL )
	
	self.FFAScoreboardList = ffa
	
	-- Rebels
	local rebelbg, rebellabel, rebel = createscoreboardteam( listw, "REBEL", team.GetColor( TEAM_REBEL ) )
	
	self.RebelScoreboard = rebelbg
	rebelbg:SetParent( self.ScoreboardPanel )
	rebelbg:Dock( LEFT )
	rebelbg:SetWide( listw )
	
	self.RebelScoreboardList = rebel
	
	-- Combine
	local combinebg, combinelabel, combine = createscoreboardteam( listw, "COMBINE", team.GetColor( TEAM_COMBINE ) )
	
	self.CombineScoreboard = combinebg
	combinebg:SetParent( self.ScoreboardPanel )
	combinebg:Dock( RIGHT )
	combinebg:SetWide( listw )
	
	self.CombineScoreboardList = combine
	
	self:UpdateScoreboard()
	
end

function GM:ScoreboardHide()
	
	self.ScoreboardVisible = false
	
	if IsValid( self.ScoreboardPanel ) == true then self.ScoreboardPanel:Remove() end
	
end

local lastleadercheck = -9999
local leader
local lastscoreboardupdate = -9999

function GM:HUDDrawScoreBoard()
	
	local curtime = CurTime()
	
	if self.ScoreboardVisible == true and curtime > lastscoreboardupdate + 1 then
		
		lastscoreboardupdate = curtime
		
		self:UpdateScoreboard()
		
	end
	
	if self.ScoreboardVisible ~= true and self.CCVar.mapinfo:GetBool() ~= true then return end
	
	local teamplay = self.CVar.teamplay:GetBool()
	if teamplay ~= true then
		
		if curtime > lastleadercheck + 1 then
			
			lastleadercheck = curtime
			local l
			local s
			for k, v in ipairs( player.GetAll() ) do
				
				local frags = v:Frags()
				if s == nil or frags > s then
					
					l = v
					s = frags
					
				end
				
			end
			
			leader = l
			
		end
		
	end
	
	local ply = LocalPlayer()
	
	surface.SetFont( "HUDHintTextLarge" )
	
	local scrw = ScrW()
	local scrh = ScrH()
	
	local x = math.ceil( scrw * 0.4 )
	local w = scrw - ( x * 2 )
	local h = math.ceil( scrh / 16 )
	local pad = math.ceil( h / 6 )
	
	local skin = self.Skin
	
	surface.SetDrawColor( skin.bg_color )
	surface.DrawRect( x, 0, w, h )
	
	surface.SetTextColor( skin.text_normal )
	
	-- Map name
	local map = game.GetMap()
	local mtw, mth = surface.GetTextSize( map )
	
	surface.SetTextPos( x + ( ( w - mtw ) / 2 ), pad )
	surface.DrawText( game.GetMap() )
	
	-- Time limit
	local text = "-"
	
	local timelimit = self.CVar.timelimit:GetFloat()
	if timelimit ~= 0 then
		
		local timeleft = ( timelimit * 60 ) + ( ( self:GetStartTime() or 0 ) - CurTime() )
		if timeleft >= 0 then text = string.ToMinutesSeconds( timeleft ) else text = "00:00" end
		
	end
	
	local ttw, tth = surface.GetTextSize( text )
	
	surface.SetTextPos( x + ( ( w - ttw ) / 2 ), h - ( pad + tth ) )
	surface.DrawText( text )
	
	local fraglimit = self.CVar.fraglimit:GetInt()
	
	
	-- Rebel/self frags
	surface.SetTextColor( team.GetColor( TEAM_REBEL ) )
	
	local rebeltitle = teamplay == true and "REBEL" or "YOU"
	local rebelscore = teamplay == true and team.GetScore( TEAM_REBEL ) or ply:Frags()
	if fraglimit > 0 then rebelscore = rebelscore .. "/" .. fraglimit end
	
	local rtw, rth = surface.GetTextSize( rebeltitle )
	local rsw, rsh = surface.GetTextSize( rebelscore )
	
	surface.SetTextPos( x + pad, pad )
	surface.DrawText( rebelscore )
	
	surface.SetTextPos( x + pad, h - ( pad + rth ) )
	surface.DrawText( rebeltitle )
	
	-- Combine/leader frags
	surface.SetTextColor( team.GetColor( TEAM_COMBINE ) )
	
	local combinetitle = teamplay == true and "COMBINE" or ( leader == ply and "LEADER (YOU)" or "LEADER" )
	local combinescore = teamplay == true and team.GetScore( TEAM_COMBINE ) or ( IsValid( leader ) == true and leader:Frags() or 0 )
	if fraglimit > 0 then combinescore = combinescore .. "/" .. fraglimit end
	
	local ctw, cth = surface.GetTextSize( combinetitle )
	local csw, csh = surface.GetTextSize( combinescore )
	
	surface.SetTextPos( ( x + w ) - ( pad + csw ), pad )
	surface.DrawText( combinescore )
	
	surface.SetTextPos( ( x + w ) - ( pad + ctw ), h - ( pad + cth ) )
	surface.DrawText( combinetitle )
	
end



----
-- Help menu
----

local function getbindkey( bind )
	
	return input.LookupBinding( bind ) or bind
	
end

local botskillname = {
	
	[ 0 ] = "Very Easy",
	[ 1 ] = "Easy",
	[ 2 ] = "Normal",
	[ 3 ] = "Hard",
	[ 4 ] = "Very Hard",
	[ 5 ] = "Impossible",
	
}

function GM:ShowHelp()
	
	if IsValid( self.TeamMenu ) == true then self.TeamMenu:Remove() end
	if IsValid( self.HelpMenu ) == true then self.HelpMenu:Remove() return end
	
	local scrpad = math.ceil( ScrH() * 0.1 )
	
	local helpmenu = vgui.Create( "DFrame" )
	self.HelpMenu = helpmenu
	helpmenu:SetPos( scrpad, scrpad )
	helpmenu:SetSize( ScrW() - ( scrpad * 2 ), ScrH() - ( scrpad * 2 ) )
	helpmenu:SetSkin( "HL2" )
	helpmenu:SetScreenLock( true )
	helpmenu:SetTitle( "" )
	helpmenu:ShowCloseButton( false )
	helpmenu:MakePopup()
	helpmenu:SetKeyboardInputEnabled( false )
	helpmenu:SetDraggable( false )
	
	local wide = helpmenu:GetWide()
	local tall = helpmenu:GetTall()
	
	local pad = math.ceil( tall * 0.01 )
	local buttonw = math.ceil( tall * 0.25 )
	local buttonh = math.ceil( tall * 0.05 )
	
	local teambutton = vgui.Create( "DButton", helpmenu )
	teambutton:SetPos( pad, pad )
	teambutton:SetSize( buttonw, buttonh )
	teambutton:SetSkin( "HL2" )
	teambutton:SetFont( "HUDDefault" )
	teambutton:SetText( language.GetPhrase( "GameUI_ChangeTeam" ) .. " (" .. getbindkey( "gm_showteam" ) .. ")" )
	function teambutton.DoClick()
		
		helpmenu:Remove()
		self:ShowTeam()
		
	end
	
	local closebutton = vgui.Create( "DButton", helpmenu )
	closebutton:SetPos( wide - ( buttonw + pad ), pad )
	closebutton:SetSize( buttonw, buttonh )
	closebutton:SetSkin( "HL2" )
	closebutton:SetFont( "HUDDefault" )
	closebutton:SetText( "#GameUI_Close" )
	function closebutton:DoClick() helpmenu:Remove() end
	
	local helppad = ( buttonh + ( pad * 2 ) ) * 2
	local helptext = vgui.Create( "RichText", helpmenu )
	helptext:SetPos( helppad * 2, helppad )
	helptext:SetSize( wide - ( helppad * 4 ), tall - ( helppad * 2 ) )
	helptext:SetSkin( "HL2" )
	function helptext:PerformLayout() self:SetFontInternal( "HUDDefault" ) end
	
	local textcolor = self.Skin.text_normal
	
	local teamplay = self.CVar.teamplay:GetBool()
	local fraglimit = self.CVar.fraglimit:GetInt()
	local timelimit = self.CVar.timelimit:GetFloat()
	local botquota = self.CVar.bot_quota:GetInt()
	local botskill = botskillname[ math.Clamp( self.CVar.bot_skill:GetInt(), 0, 5 ) ]
	
	helptext:InsertColorChange( textcolor.r, textcolor.g, textcolor.b, textcolor.a )
	
	helptext:AppendText( "Press " .. getbindkey( "gm_showhelp" ) .. " to open this help menu\n" )
	helptext:AppendText( "Press " .. getbindkey( "gm_showteam" ) .. " to open the team selection menu\n\n\n" )
	
	helptext:AppendText( "Currently playing " )
	helptext:AppendText( teamplay == true and "Team Deathmatch" or "Free-For-All" )
	helptext:AppendText( " on " .. game.GetMap() )
	helptext:AppendText( ", with " )
	helptext:AppendText( fraglimit > 0 and ( "a score limit of " .. fraglimit ) or "no score limit" )
	helptext:AppendText( ", and " )
	helptext:AppendText( timelimit > 0 and ( "a time limit of " .. timelimit .. " minutes" ) or "no time limit" )
	
	if botquota > 0 then
		
		helptext:AppendText( "\n\n\nThe bot quota is currently " .. botquota .. ", and the bot difficulty is " .. botskill )
		
	end
	
end



----
-- Team menu
----

function GM:ShowTeamTDM( teammenu )
	
	local allplayermodels = self.CVar.allplayermodels:GetBool()
	local playercolor = self.CVar.playercolor:GetBool()
	
	local wide = teammenu:GetWide()
	local tall = teammenu:GetTall()
	
	local pad = math.ceil( tall * 0.01 )
	local buttonw = math.ceil( tall * 0.25 )
	local buttonh = math.ceil( tall * 0.05 )
	
	local helpbutton = vgui.Create( "DButton", teammenu )
	helpbutton:SetPos( pad, pad )
	helpbutton:SetSize( buttonw, buttonh )
	helpbutton:SetSkin( "HL2" )
	helpbutton:SetFont( "HUDDefault" )
	helpbutton:SetText( language.GetPhrase( "Valve_Help" ) .. " (" .. getbindkey( "gm_showhelp" ) .. ")" )
	function helpbutton.DoClick()
		
		teammenu:Remove()
		self:ShowHelp()
		
	end
	
	local closebutton = vgui.Create( "DButton", teammenu )
	closebutton:SetPos( wide - ( buttonw + pad ), pad )
	closebutton:SetSize( buttonw, buttonh )
	closebutton:SetSkin( "HL2" )
	closebutton:SetFont( "HUDDefault" )
	closebutton:SetText( "#GameUI_Close" )
	function closebutton:DoClick() teammenu:Remove() end
	
	local rebelbutton = vgui.Create( "DButton", teammenu )
	rebelbutton:SetPos( pad, tall - ( buttonh + pad ) )
	rebelbutton:SetSize( buttonw, buttonh )
	rebelbutton:SetSkin( "HL2" )
	rebelbutton:SetFont( "HUDDefault" )
	rebelbutton:SetText( "Rebel" )
	function rebelbutton:DoClick()
		
		RunConsoleCommand( "cl_hl2mp_team", "1" )
		RunConsoleCommand( "kill" )
		RunConsoleCommand( "cl_hl2mp_spectate", "0" )
		teammenu:Remove()
		
	end
	
	local specbutton = vgui.Create( "DButton", teammenu )
	specbutton:SetPos( math.ceil( ( wide - buttonw ) / 2 ), tall - ( buttonh + pad ) )
	specbutton:SetSize( buttonw, buttonh )
	specbutton:SetSkin( "HL2" )
	specbutton:SetFont( "HUDDefault" )
	specbutton:SetText( "#Spectators" )
	function specbutton:DoClick()
		
		RunConsoleCommand( "cl_hl2mp_spectate", "1" )
		teammenu:Remove()
		
	end
	
	local combinebutton = vgui.Create( "DButton", teammenu )
	combinebutton:SetPos( wide - ( buttonw + pad ), tall - ( buttonh + pad ) )
	combinebutton:SetSize( buttonw, buttonh )
	combinebutton:SetSkin( "HL2" )
	combinebutton:SetFont( "HUDDefault" )
	combinebutton:SetText( "Combine" )
	function combinebutton:DoClick()
		
		RunConsoleCommand( "cl_hl2mp_team", "2" )
		RunConsoleCommand( "kill" )
		RunConsoleCommand( "cl_hl2mp_spectate", "0" )
		teammenu:Remove()
		
	end
	
	--local listpad = math.ceil( tall * 0.1 )
	local listpad = buttonh + ( pad * 2 )
	local panelw = math.ceil( ( wide / 2 ) - listpad )
	local listw = math.ceil( panelw / 2 )
	local headerh = buttonh + ( ( tall - ( listpad * 2 ) ) % buttonh )
	
	-- Rebel
	local rebelpanel = vgui.Create( "DPanel", teammenu )
	rebelpanel:SetPos( listpad, listpad )
	rebelpanel:SetSize( panelw, tall - ( listpad * 2 ) )
	rebelpanel:SetSkin( "HL2" )
	
	local rebellabel = vgui.Create( "DLabel", rebelpanel )
	rebellabel:Dock( TOP )
	rebellabel:SetTall( headerh )
	rebellabel:SetSkin( "HL2" )
	rebellabel:SetFont( "HUDDefault" )
	rebellabel:SetTextColor( Color( 255, 255, 255, 255 ) )
	rebellabel:SetText( "REBEL" )
	rebellabel:SetContentAlignment( 5 )
	function rebellabel.Paint( panel, w, h )
		
		surface.SetDrawColor( self.Skin.color_outline )
		surface.DrawOutlinedRect( 0, 0, w, h )
		
		surface.SetDrawColor( team.GetColor( TEAM_REBEL ) )
		surface.DrawRect( 1, 1, w - 2, h - 2 )
		
	end
	
	local rebelscroll = vgui.Create( "DScrollPanel", rebelpanel )
	rebelscroll:Dock( LEFT )
	rebelscroll:SetWide( listw )
	rebelscroll:SetSkin( "HL2" )
	
	local rebelpreview = vgui.Create( "DModelPanel", rebelpanel )
	rebelpreview:Dock( FILL )
	rebelpreview:SetSkin( "HL2" )
	rebelpreview:SetFOV( 40 )
	function rebelpreview:LayoutEntity( ent )
		
		self:SetCamPos( Vector( 60, 40, 65 ) )
		self:SetLookAt( Vector( 0, 0, 40 ) )
		
	end
	
	function rebelpreview.SetPlayerModel( panel, model )
		
		panel:SetModel( model )
		
		local color = playercolor == true and Vector( self.CCVar.playercolor:GetString() ) or team.GetColor( TEAM_REBEL ):ToVector()
		
		local ent = panel:GetEntity()
		if IsValid( ent ) == true then function ent.GetPlayerColor() return color end end
		
	end
	
	local rebelmodel = self.CCVar.playermodel_rebel:GetString()
	if self.ModelTeam[ rebelmodel ] == TEAM_REBEL or allplayermodels == true then
		
		rebelpreview:SetPlayerModel( player_manager.TranslatePlayerModel( rebelmodel ) )
		
	else
		
		rebelpreview:SetPlayerModel( player_manager.TranslatePlayerModel( self.Models_Rebel[ 1 ] ) )
		
	end
	
	-- Combine
	local combinepanel = vgui.Create( "DPanel", teammenu )
	combinepanel:SetPos( wide - ( panelw + listpad ), listpad )
	combinepanel:SetSize( panelw, tall - ( listpad * 2 ) )
	combinepanel:SetSkin( "HL2" )
	
	local combinelabel = vgui.Create( "DLabel", combinepanel )
	combinelabel:Dock( TOP )
	combinelabel:SetTall( headerh )
	combinelabel:SetSkin( "HL2" )
	combinelabel:SetFont( "HUDDefault" )
	combinelabel:SetTextColor( Color( 255, 255, 255, 255 ) )
	combinelabel:SetText( "COMBINE" )
	combinelabel:SetContentAlignment( 5 )
	function combinelabel.Paint( panel, w, h )
		
		surface.SetDrawColor( self.Skin.color_outline )
		surface.DrawOutlinedRect( 0, 0, w, h )
		
		surface.SetDrawColor( team.GetColor( TEAM_COMBINE ) )
		surface.DrawRect( 1, 1, w - 2, h - 2 )
		
	end
	
	local combinescroll = vgui.Create( "DScrollPanel", combinepanel )
	combinescroll:Dock( RIGHT )
	combinescroll:SetWide( listw )
	combinescroll:SetSkin( "HL2" )
	
	local combinepreview = vgui.Create( "DModelPanel", combinepanel )
	combinepreview:Dock( FILL )
	combinepreview:SetSkin( "HL2" )
	combinepreview:SetFOV( 40 )
	function combinepreview:LayoutEntity( ent )
		
		self:SetCamPos( Vector( 60, -40, 65 ) )
		self:SetLookAt( Vector( 0, 0, 40 ) )
		
	end
	
	function combinepreview.SetPlayerModel( panel, model )
		
		panel:SetModel( model )
		
		local color = playercolor == true and Vector( self.CCVar.playercolor:GetString() ) or team.GetColor( TEAM_COMBINE ):ToVector()
		
		local ent = panel:GetEntity()
		if IsValid( ent ) == true then function ent.GetPlayerColor() return color end end
		
	end
	
	local combinemodel = self.CCVar.playermodel_combine:GetString()
	if self.ModelTeam[ combinemodel ] == TEAM_COMBINE or allplayermodels == true then
		
		combinepreview:SetPlayerModel( player_manager.TranslatePlayerModel( combinemodel ) )
		
	else
		
		combinepreview:SetPlayerModel( player_manager.TranslatePlayerModel( self.Models_Combine[ 1 ] ) )
		
	end
	
	if allplayermodels == true then
		
		for k, v in SortedPairs( player_manager.AllValidModels() ) do
			
			local rebelmodelbutton = vgui.Create( "DButton", rebelscroll )
			rebelmodelbutton:Dock( TOP )
			rebelmodelbutton:SetTall( buttonh )
			rebelmodelbutton:SetSkin( "HL2" )
			rebelmodelbutton:SetFont( "HUDHintTextLarge" )
			rebelmodelbutton:SetText( k )
			function rebelmodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel_rebel", k )
				rebelpreview:SetPlayerModel( v )
				
			end
			
			local combinemodelbutton = vgui.Create( "DButton", combinescroll )
			combinemodelbutton:Dock( TOP )
			combinemodelbutton:SetTall( buttonh )
			combinemodelbutton:SetSkin( "HL2" )
			combinemodelbutton:SetFont( "HUDHintTextLarge" )
			combinemodelbutton:SetText( k )
			function combinemodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel_combine", k )
				combinepreview:SetPlayerModel( v )
				
			end
			
		end
		
	else
		
		for k, v in SortedPairsByValue( self.Models_Rebel ) do
			
			local rebelmodelbutton = vgui.Create( "DButton", rebelscroll )
			rebelmodelbutton:Dock( TOP )
			rebelmodelbutton:SetTall( buttonh )
			rebelmodelbutton:SetSkin( "HL2" )
			rebelmodelbutton:SetFont( "HUDHintTextLarge" )
			rebelmodelbutton:SetText( v )
			function rebelmodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel_rebel", v )
				rebelpreview:SetPlayerModel( player_manager.TranslatePlayerModel( v ) )
				
			end
			
		end
		
		for k, v in SortedPairsByValue( self.Models_Combine ) do
			
			local combinemodelbutton = vgui.Create( "DButton", combinescroll )
			combinemodelbutton:Dock( TOP )
			combinemodelbutton:SetTall( buttonh )
			combinemodelbutton:SetSkin( "HL2" )
			combinemodelbutton:SetFont( "HUDHintTextLarge" )
			combinemodelbutton:SetText( v )
			function combinemodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel_combine", v )
				combinepreview:SetPlayerModel( player_manager.TranslatePlayerModel( v ) )
				
			end
			
		end
		
	end
	
end

function GM:ShowTeamFFA( teammenu )
	
	local allplayermodels = self.CVar.allplayermodels:GetBool()
	local playercolor = self.CVar.playercolor:GetBool()
	
	local wide = teammenu:GetWide()
	local tall = teammenu:GetTall()
	
	local pad = math.ceil( tall * 0.01 )
	local buttonw = math.ceil( tall * 0.25 )
	local buttonh = math.ceil( tall * 0.05 )
	
	local helpbutton = vgui.Create( "DButton", teammenu )
	helpbutton:SetPos( pad, pad )
	helpbutton:SetSize( buttonw, buttonh )
	helpbutton:SetSkin( "HL2" )
	helpbutton:SetFont( "HUDDefault" )
	helpbutton:SetText( language.GetPhrase( "Valve_Help" ) .. " (" .. getbindkey( "gm_showhelp" ) .. ")" )
	function helpbutton.DoClick()
		
		teammenu:Remove()
		self:ShowHelp()
		
	end
	
	local closebutton = vgui.Create( "DButton", teammenu )
	closebutton:SetPos( wide - ( buttonw + pad ), pad )
	closebutton:SetSize( buttonw, buttonh )
	closebutton:SetSkin( "HL2" )
	closebutton:SetFont( "HUDDefault" )
	closebutton:SetText( "#GameUI_Close" )
	function closebutton:DoClick() teammenu:Remove() end
	
	local specbutton = vgui.Create( "DButton", teammenu )
	specbutton:SetPos( pad, tall - ( buttonh + pad ) )
	specbutton:SetSize( buttonw, buttonh )
	specbutton:SetSkin( "HL2" )
	specbutton:SetFont( "HUDDefault" )
	specbutton:SetText( "#Spectators" )
	function specbutton:DoClick()
		
		RunConsoleCommand( "cl_hl2mp_spectate", "1" )
		teammenu:Remove()
		
	end
	
	local spawnbutton = vgui.Create( "DButton", teammenu )
	spawnbutton:SetPos( wide - ( buttonw + pad ), tall - ( buttonh + pad ) )
	spawnbutton:SetSize( buttonw, buttonh )
	spawnbutton:SetSkin( "HL2" )
	spawnbutton:SetFont( "HUDDefault" )
	spawnbutton:SetText( "#Valve_Force_Respawn" )
	function spawnbutton:DoClick()
		
		RunConsoleCommand( "cl_hl2mp_team", "2" )
		RunConsoleCommand( "kill" )
		RunConsoleCommand( "cl_hl2mp_spectate", "0" )
		teammenu:Remove()
		
	end
	
	--local listpad = math.ceil( tall * 0.1 )
	local listpad = buttonh + ( pad * 2 )
	local panelw = math.ceil( ( wide / 2 ) - listpad )
	local listw = math.ceil( panelw / 2 )
	local headerh = buttonh + ( ( tall - ( listpad * 2 ) ) % buttonh )
	
	-- Free-for-all
	local ffapanel = vgui.Create( "DPanel", teammenu )
	ffapanel:SetPos( math.ceil( ( wide - panelw ) / 2 ), listpad )
	ffapanel:SetSize( panelw, tall - ( listpad * 2 ) )
	ffapanel:SetSkin( "HL2" )
	
	local ffalabel = vgui.Create( "DLabel", ffapanel )
	ffalabel:Dock( TOP )
	ffalabel:SetTall( headerh )
	ffalabel:SetSkin( "HL2" )
	ffalabel:SetFont( "HUDDefault" )
	ffalabel:SetTextColor( Color( 255, 255, 255, 255 ) )
	ffalabel:SetText( "FREE-FOR-ALL" )
	ffalabel:SetContentAlignment( 5 )
	function ffalabel.Paint( panel, w, h )
		
		surface.SetDrawColor( self.Skin.color_outline )
		surface.DrawOutlinedRect( 0, 0, w, h )
		
		surface.SetDrawColor( self.Skin.text_normal )
		surface.DrawRect( 1, 1, w - 2, h - 2 )
		
	end
	
	local ffascroll = vgui.Create( "DScrollPanel", ffapanel )
	ffascroll:Dock( LEFT )
	ffascroll:SetWide( listw )
	ffascroll:SetSkin( "HL2" )
	
	local ffapreview = vgui.Create( "DModelPanel", ffapanel )
	ffapreview:Dock( FILL )
	ffapreview:SetSkin( "HL2" )
	ffapreview:SetFOV( 40 )
	function ffapreview:LayoutEntity( ent )
		
		self:SetCamPos( Vector( 60, 40, 65 ) )
		self:SetLookAt( Vector( 0, 0, 40 ) )
		
	end
	
	function ffapreview.SetPlayerModel( panel, model, teamcolor )
		
		panel:SetModel( model )
		
		local color = playercolor == true and Vector( self.CCVar.playercolor:GetString() ) or teamcolor:ToVector()
		
		local ent = panel:GetEntity()
		if IsValid( ent ) == true then function ent.GetPlayerColor() return color end end
		
	end
	
	local ffamodel = self.CCVar.playermodel:GetString()
	if self.ModelTeam[ ffamodel ] ~= nil or allplayermodels == true then
		
		ffapreview:SetPlayerModel( player_manager.TranslatePlayerModel( ffamodel ), team.GetColor( self.ModelTeam[ ffamodel ] or TEAM_REBEL ) )
		
	else
		
		ffapreview:SetPlayerModel( player_manager.TranslatePlayerModel( self.Models_Combine[ 1 ] ), team.GetColor( TEAM_COMBINE ) )
		
	end
	
	if allplayermodels == true then
		
		for k, v in SortedPairs( player_manager.AllValidModels() ) do
			
			local ffamodelbutton = vgui.Create( "DButton", ffascroll )
			ffamodelbutton:Dock( TOP )
			ffamodelbutton:SetTall( buttonh )
			ffamodelbutton:SetSkin( "HL2" )
			ffamodelbutton:SetFont( "HUDHintTextLarge" )
			ffamodelbutton:SetText( k )
			function ffamodelbutton.DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel", k )
				ffapreview:SetPlayerModel( v, team.GetColor( self.ModelTeam[ k ] or TEAM_REBEL ) )
				
			end
			
		end
		
	else
		
		for k, v in SortedPairsByValue( self.Models_Rebel ) do
			
			local ffamodelbutton = vgui.Create( "DButton", ffascroll )
			ffamodelbutton:Dock( TOP )
			ffamodelbutton:SetTall( buttonh )
			ffamodelbutton:SetSkin( "HL2" )
			ffamodelbutton:SetFont( "HUDHintTextLarge" )
			ffamodelbutton:SetText( v )
			function ffamodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel", v )
				ffapreview:SetPlayerModel( player_manager.TranslatePlayerModel( v ), team.GetColor( TEAM_REBEL ) )
				
			end
			
		end
		
		for k, v in SortedPairsByValue( self.Models_Combine ) do
			
			local ffamodelbutton = vgui.Create( "DButton", ffascroll )
			ffamodelbutton:Dock( TOP )
			ffamodelbutton:SetTall( buttonh )
			ffamodelbutton:SetSkin( "HL2" )
			ffamodelbutton:SetFont( "HUDHintTextLarge" )
			ffamodelbutton:SetText( v )
			function ffamodelbutton:DoClick()
				
				RunConsoleCommand( "cl_hl2mp_playermodel", v )
				ffapreview:SetPlayerModel( player_manager.TranslatePlayerModel( v ), team.GetColor( TEAM_COMBINE ) )
				
			end
			
		end
		
	end
	
end

function GM:ShowTeam()
	
	if IsValid( self.HelpMenu ) == true then self.HelpMenu:Remove() end
	if IsValid( self.TeamMenu ) == true then self.TeamMenu:Remove() return end
	
	local scrpad = math.ceil( ScrH() * 0.1 )
	
	local teammenu = vgui.Create( "DFrame" )
	self.TeamMenu = teammenu
	teammenu:SetPos( scrpad, scrpad )
	teammenu:SetSize( ScrW() - ( scrpad * 2 ), ScrH() - ( scrpad * 2 ) )
	teammenu:SetSkin( "HL2" )
	teammenu:SetScreenLock( true )
	teammenu:SetTitle( "" )
	teammenu:ShowCloseButton( false )
	teammenu:MakePopup()
	teammenu:SetKeyboardInputEnabled( false )
	teammenu:SetDraggable( false )
	
	if self.CVar.teamplay:GetBool() == true then self:ShowTeamTDM( teammenu )
	else self:ShowTeamFFA( teammenu ) end
	
end



----
-- Spectating
----

local obsmodename = {
	
	[ OBS_MODE_NONE ] = "#Spec_Mode0",
	[ OBS_MODE_DEATHCAM ] = "#Spec_Mode1",
	[ OBS_MODE_FREEZECAM ] = "",
	[ OBS_MODE_FIXED ] = "#Spec_Mode2",
	[ OBS_MODE_IN_EYE ] = "#Spec_Mode3",
	[ OBS_MODE_CHASE ] = "#Spec_Mode4",
	[ OBS_MODE_ROAMING ] = "#Spec_Mode5",
	
}

function GM:DrawSpectateHUD()
	
	if IsValid( self.HelpMenu ) == true or IsValid( self.TeamMenu ) == true then return end
	
	local ply = LocalPlayer()
	local obs = ply:GetObserverMode()
	
	local scrw = ScrW()
	local scrh = ScrH()
	
	local h = math.ceil( scrh / 8 )
	local y = scrh - h
	local pad = math.ceil( h / 6 )
	
	local skin = self.Skin
	
	surface.SetDrawColor( skin.bg_color )
	surface.DrawRect( 0, y, scrw, h )
	
	local font = "HUDDefault"
	
	local tw, th = draw.SimpleText( obsmodename[ obs ] or "", font, pad, y + pad, skin.text_normal )
	draw.SimpleText( getbindkey( "+jump" ) .. ": Change mode", font, pad, y + pad + th, skin.text_normal )
	
	draw.SimpleText( getbindkey( "gm_showhelp" ) .. ": Open help menu", font, scrw - pad, ( y + h ) - ( pad + ( th * 2 ) ), skin.text_normal, TEXT_ALIGN_RIGHT )
	draw.SimpleText( getbindkey( "gm_showteam" ) .. ": Open team menu", font, scrw - pad, ( y + h ) - ( pad + th ), skin.text_normal, TEXT_ALIGN_RIGHT )
	
	if obs ~= OBS_MODE_ROAMING then
		
		draw.SimpleText( getbindkey( "+attack" ) .. ": Next target", font, pad, ( y + h ) - ( pad + ( th * 2 ) ), skin.text_normal )
		draw.SimpleText( getbindkey( "+attack2" ) .. ": Previous target", font, pad, ( y + h ) - ( pad + th ), skin.text_normal )
		
	end
	
	local target = ply:GetObserverTarget()
	if IsValid( target ) ~= true or target:IsPlayer() ~= true then return end
	
	local col = team.GetColor( target:Team() )
	
	draw.SimpleText( target:Nick(), font, scrw - pad, y + pad, col, TEXT_ALIGN_RIGHT )
	
	col = skin.text_normal
	
	local x = scrw / 3
	
	draw.SimpleText( language.GetPhrase( "Valve_Hud_HEALTH" ) .. ": " .. target:Health() .. "/" .. target:GetMaxHealth(), font, x, y + pad, col )
	draw.SimpleText( language.GetPhrase( "Valve_Hud_SUIT" ) .. ": " .. target:Armor() .. "/" .. target:GetMaxArmor(), font, x, y + pad + th, col )
	
	draw.SimpleText( language.GetPhrase( "Valve_Hud_AUX_POWER" ) .. ": " .. math.ceil( target:GetAUX() ) .. "/" .. math.ceil( target:GetMaxAUX() ), font, x, ( y + h ) - ( pad + th ), col )
	
	local wep = target:GetActiveWeapon()
	if IsValid( wep ) ~= true then return end
	
	x = scrw / 1.8
	
	draw.SimpleText( language.GetPhrase( "Valve_Hud_AMMO" ) .. ": " .. wep:Clip1() .. "/" .. wep:GetMaxClip1() .. " (" .. target:GetAmmoCount( wep:GetPrimaryAmmoType() ) .. ")", font, x, y + pad, col )
	draw.SimpleText( language.GetPhrase( "Valve_Hud_AMMO_ALT" ) .. ": " .. wep:Clip2() .. "/" .. wep:GetMaxClip2() .. " (" .. target:GetAmmoCount( wep:GetSecondaryAmmoType() ) .. ")", font, x, y + pad + th, col )
	
	draw.SimpleText( wep:GetPrintName(), font, x, ( y + h ) - ( pad + th ), col )
	
end

local lasttarget
local lasttargettime
local targetshowtime = 0.5

function GM:HUDDrawTargetID()
	
	local ply = LocalPlayer()
	local obsmode = ply:GetObserverMode()
	if obsmode == OBS_MODE_IN_EYE then
		
		local obs = ply:GetObserverTarget()
		if IsValid( obs ) == true and obs:IsPlayer() then ply = obs end
		
	elseif obsmode == OBS_MODE_CHASE then return end
	
	local curtime = CurTime()
	
	local tr = ply:GetEyeTrace()
	if IsValid( tr.Entity ) == true and tr.Entity:IsPlayer() == true then
		
		lasttarget = tr.Entity
		lasttargettime = curtime
		
	end
	
	if IsValid( lasttarget ) ~= true or lasttargettime == nil or curtime > lasttargettime + targetshowtime then return end
	
	local alpha = ( 1 - ( ( curtime - lasttargettime ) / targetshowtime ) ) * 255
	
	local scrw = ScrW()
	local scrh = ScrH()
	
	surface.SetFont( "HUDDefault" )
	
	local name = lasttarget:Nick()
	local ntw, nth = surface.GetTextSize( name )
	
	local hp = lasttarget:Health() .. "%"
	local htw, hth = surface.GetTextSize( hp )
	
	local shadow = 2
	
	surface.SetTextColor( 0, 0, 0, alpha )
	surface.SetTextPos( ( ( scrw - ntw ) / 2 ) + shadow, ( ( scrh / 2 ) + nth ) + shadow )
	surface.DrawText( name )
	surface.SetTextPos( ( ( scrw - htw ) / 2 ) + shadow, ( ( scrh / 2 ) + nth + hth ) + shadow )
	surface.DrawText( hp )
	
	local col = team.GetColor( lasttarget:Team() )
	
	surface.SetTextColor( col.r, col.g, col.b, alpha )
	surface.SetTextPos( ( scrw - ntw ) / 2, ( scrh / 2 ) + nth )
	surface.DrawText( name )
	surface.SetTextPos( ( scrw - htw ) / 2, ( scrh / 2 ) + nth + hth )
	surface.DrawText( hp )
	
end


----
-- AUX
----

local function scale( size, height ) return math.floor( ( size / 480 ) * ( height or ScrH() ) ) end

local alpha = 0
local auxgreen = 1

local bgalpha = 76
local auxalpha = 220
local auxemptyalpha = 70
local auxred = 255
local auxhighgreen = 220

local bgcolor = Color( 0, 0, 0, bgalpha )
local auxcolor = Color( auxred, auxhighgreen, 0, auxalpha )

function GM:DrawAUX()
	
	local ply = LocalPlayer()
	local aux = ply:GetAUX()
	local maxaux = ply:GetMaxAUX()
	
	if aux < maxaux then alpha = math.min( 1, alpha + ( FrameTime() / 0.4 ) )
	else alpha = math.max( 0, alpha - ( FrameTime() / 0.4 ) ) end
	
	if aux > maxaux / 4 then auxgreen = math.min( 1, auxgreen + ( FrameTime() / 0.4 ) )
	else auxgreen = math.max( 0, auxgreen - ( FrameTime() / 0.4 ) ) end
	
	local xpos = scale( 16 )
	local ypos = scale( 400 )
	local wide = scale( 102 )
	local tall = scale( 26 )
	
	local barx = xpos + scale( 8 )
	local bary = ypos + scale( 15 )
	local barh = scale( 4 )
	local chunkw = scale( 6 )
	local chunkgap = scale( 3 )
	
	bgcolor.a = bgalpha * alpha
	draw.RoundedBox( 8, xpos, ypos, wide, tall, bgcolor )
	
	auxcolor.r = auxred * alpha
	auxcolor.g = auxhighgreen * auxgreen * alpha
	auxcolor.a = auxalpha * alpha
	
	surface.SetFont( "HudDefault" )
	surface.SetTextColor( auxcolor )
	surface.SetTextPos( barx, ypos + scale( 4 ) )
	surface.DrawText( "#Valve_Hud_AUX_POWER" )
	
	for i = 0, 9 do
		
		auxcolor.a = ( ( aux < maxaux * ( ( i + 0.5 ) / 10 ) ) and auxemptyalpha or auxalpha ) * alpha
		surface.SetDrawColor( auxcolor )
		surface.DrawRect( barx + ( ( chunkw + chunkgap ) * i ), bary, chunkw, barh )
		
	end
	
end

--[[
local l = 0
local l2 = 0
local ceil = math.ceil
local floor = math.floor
function GM:DrawAUX()
	
	if ScrW() / ScrH() > 1.24 and ScrW() / ScrH() < 1.26 then
		
		--4:3
		--1.25
		
		local sw = ceil( ScrW() * 0.012 )
		local sh = ceil( ScrW() * 0.008 )
		
		draw.RoundedBox( 8, ceil( ScrW() * 0.026 ), ceil( ScrH() * 0.82 ), ceil( ScrW() * 0.169 ), ceil( ScrH() * 0.075 ), Color( 15, 15, 15, l ) )
		
		if l2 > 100 then
			
			if LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * 0.25 then
				
				surface.SetDrawColor( 255, 255, 0, 55 )
				
			else
				
				surface.SetDrawColor( 255, 0, 0, 55 )
				
			end
			
			for i = 0, 9 do
				
				surface.DrawRect( ceil( ScrW() * 0.041 ) + ceil( ScrW() * 0.014 * i ), ceil( ScrH() * 0.865 ), sw, sh )
				
			end
			
		end
		
		if LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * 0.25 then
			
			surface.SetDrawColor( 255, 255, 0, l2 )
			draw.SimpleText( "#Valve_Hud_AUX_POWER", "HudDefault", ceil( ScrW() * 0.042 ), ceil( ScrH() * 0.835 ), Color( 255, 255, 0, l2 ) )
			
		else
			
			surface.SetDrawColor( 255, 0, 0, l2 )
			draw.SimpleText( "#Valve_Hud_AUX_POWER", "HudDefault", ceil( ScrW() * 0.042 ), ceil( ScrH() * 0.835 ), Color( 255, 0, 0, l2 ) )
			
		end
		for i = 0, 9 do
			
			if i == 0 and LocalPlayer():GetAUX() > 1 then
				
				surface.DrawRect( ceil( ScrW() * 0.041 ), ceil( ScrH() * 0.865 ), sw, sh )
				
			elseif i ~= 0 and LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * ( 0.1 * i ) then
				
				surface.DrawRect( ceil( ScrW() * 0.041 ) + ceil( ScrW() * 0.014 * i ), ceil( ScrH() * 0.865 ), sw, sh )
				
			end
			
		end
		
		if LocalPlayer():GetAUX() < LocalPlayer():GetMaxAUX() then
			
			l = Lerp( 0.025, l, 100 )
			l2 = Lerp( 0.05, l2, 255 )
			
		else
			
			l = Lerp( 0.025, l, 0 )
			l2 = Lerp( 0.05, l2, 0 )
			
		end
		
	else
		
		--16:9
		--1.77
		
		local sw = floor( ScrW() * 0.009 )
		local sh = floor( ScrW() * 0.0055 )
		
		draw.RoundedBox( 8, floor( ScrW() * 0.019 ), floor( ScrH() * 0.82 ), floor( ScrW() * 0.1196 ), floor( ScrH() * 0.075 ), Color( 15, 15, 15, l ) )
		
		if l2 > 100 then
			
			if LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * 0.25 then
				
				surface.SetDrawColor( 255, 255, 0, 55 )
				
			else
				
				surface.SetDrawColor( 255, 0, 0, 55 )
				
			end
			
			for i = 0, 9 do
				
				surface.DrawRect( floor( ScrW() * 0.0295 ) + floor( ScrW() * 0.01 * i ), floor( ScrH() * 0.865 ), sw, sh )
				
			end
			
		end
		
		if LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * 0.25 then
			
			surface.SetDrawColor( 255, 255, 0, l2 )
			draw.SimpleText( "#Valve_Hud_AUX_POWER", "HudDefault", floor( ScrW() * 0.03 ), floor( ScrH() * 0.835 ), Color( 255, 255, 0, l2 ) )
			
		else
			
			surface.SetDrawColor( 255, 0, 0, l2 )
			draw.SimpleText( "#Valve_Hud_AUX_POWER", "HudDefault", floor( ScrW() * 0.03 ), floor( ScrH() * 0.835 ), Color( 255, 0, 0, l2 ) )
			
		end
		for i = 0, 9 do
			
			if i == 0 and LocalPlayer():GetAUX() > 1 then
				
				surface.DrawRect( floor( ScrW() * 0.0295 ), floor( ScrH() * 0.865 ), sw, sh )
				
			elseif i ~= 0 and LocalPlayer():GetAUX() > LocalPlayer():GetMaxAUX() * ( 0.1 * i ) then
				
				surface.DrawRect( floor( ScrW() * 0.0295 ) + floor( ScrW() * 0.01 * i ), floor( ScrH() * 0.865 ), sw, sh )
				
			end
			
		end
		
		if LocalPlayer():GetAUX() < LocalPlayer():GetMaxAUX() then
			
			l = Lerp( 0.025, l, 100 )
			l2 = Lerp( 0.05, l2, 255 )
			
		else
			
			l = Lerp( 0.025, l, 0 )
			l2 = Lerp( 0.05, l2, 0 )
			
		end
		
	end
	
end
]]--



function GM:HUDPaint()
	
	local ply = LocalPlayer()
	
	if ply:Team() == TEAM_SPECTATOR then self:DrawSpectateHUD()
	elseif ply:Alive() == true then self:DrawAUX() end
	
	BaseClass.HUDPaint( self )
	
end
