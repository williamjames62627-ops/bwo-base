local SKIN = table.Copy( derma.GetDefaultSkin() )

SKIN.PrintName = "Half-Life 2 Skin"
SKIN.Author = ""

SKIN.color_background = Color( 0, 0, 0, 200 )
SKIN.color_background_hover = Color( 148, 14, 0, 200 )

SKIN.color_outline = Color( 171, 127, 79, 200 )
SKIN.color_outline_hover = Color( 171, 82, 0, 200 )
SKIN.color_outline_panel = Color( 198, 179, 83, 200 )

SKIN.color_text = Color( 255, 177, 0, 255 )
SKIN.font = "HUDDefault"



SKIN.bg_color = SKIN.color_background
SKIN.bg_color_sleep = SKIN.color_background
SKIN.bg_color_dark = SKIN.color_background
SKIN.bg_color_bright = SKIN.color_background

SKIN.fontFrame = SKIN.font

SKIN.text_bright = SKIN.color_text
SKIN.text_normal = SKIN.color_text
SKIN.text_dark = SKIN.color_text
SKIN.text_highlight = SKIN.color_text

SKIN.colTabText = SKIN.color_text
SKIN.colTabTextInactive = SKIN.color_text
SKIN.fontTab = SKIN.font

SKIN.colCategoryText = SKIN.color_text
SKIN.colCategoryTextInactive = SKIN.color_text
SKIN.fontCategoryHeader = SKIN.font

SKIN.colTextEntryText = SKIN.color_text
SKIN.colTextEntryTextHighlight = SKIN.color_text

SKIN.colButtonText = SKIN.color_text
SKIN.colButtonTextDisabled = SKIN.color_text

SKIN.Colours.Button.Normal = SKIN.color_text
SKIN.Colours.Button.Hover = SKIN.color_text
SKIN.Colours.Button.Down = Color( 255, 255, 255, 255 )

SKIN.Colours.Label.Default = SKIN.color_text
SKIN.Colours.Label.Bright = SKIN.color_text
SKIN.Colours.Label.Dark = SKIN.color_text
SKIN.Colours.Label.Highlight = SKIN.color_text

SKIN.Colours.Category.Line.Text = SKIN.color_text
SKIN.Colours.Category.Line.Text_Hover = SKIN.color_text
SKIN.Colours.Category.Line.Text_Selected = SKIN.color_text
SKIN.Colours.Category.LineAlt.Text = SKIN.color_text
SKIN.Colours.Category.LineAlt.Text_Hover = SKIN.color_text
SKIN.Colours.Category.LineAlt.Text_Selected = SKIN.color_text

SKIN.Colours.TooltipText = SKIN.color_text



function SKIN:HL2DrawVGUI( panel, w, h, outline, hover, color, color_outline, color_hover, color_outline_hover )
	
	if color == nil then
		
		if panel:GetParent() ~= vgui.GetWorldPanel() and panel:GetParent():GetName() ~= "SpawnMenu" then
			
			surface.SetDrawColor( 0, 0, 0, 0 )
			
		else
			
			surface.SetDrawColor( self.color_background )
			
		end
		
	else
		
		surface.SetDrawColor( color )
		
	end
	
	if hover == true and panel:IsHovered() == true then
		
		if color_hover == nil then
			
			surface.SetDrawColor( self.color_background_hover )
			
		else
			
			surface.SetDrawColor( color_hover )
			
		end
		
	end
	
	surface.DrawRect( 0, 0, w, h )
	
	if outline == true then
			
		if color_outline == nil then
			
			surface.SetDrawColor( self.color_outline )
			
		else
			
			surface.SetDrawColor( color_outline )
			
		end
		
		if hover == true and panel:IsHovered() == true then
			
			if color_outline_hover == nil then
				
				surface.SetDrawColor( self.color_outline_hover )
				
			else
				
				surface.SetDrawColor( color_outline_hover )
				
			end
			
		end
		
		surface.DrawOutlinedRect( 0, 0, w, h )
		
	end
	
end

function SKIN:PaintPanel( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, nil, self.color_outline_panel )
	
end

function SKIN:PaintShadow( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h )
	
end

function SKIN:PaintFrame( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h )
	
end

function SKIN:PaintButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintTree( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintCheckBox( panel, w, h )
	
	if panel:GetChecked() == true then
		
		self:HL2DrawVGUI( panel, w, h )
		
	else
		
		self:HL2DrawVGUI( panel, w, h )
		
	end
	
end

function SKIN:PaintExpandButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintTextEntry( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:SchemeTextEntry( panel )
	
	panel:SetTextColor( SKIN.color_text )
	panel:SetHighlightColor( self.colTextEntryTextHighlight )
	panel:SetCursorColor( self.colTextEntryTextCursor )
	
end

function SKIN:PaintMenu( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintMenuSpace( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h )
	
end

function SKIN:PaintMenuOption( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintMenuRightArrow( panel, w, h )
	
	self.tex.Menu.RightArrow( 0, 0, w, h )
	
end

function SKIN:PaintPropertySheet( panel, w, h )
	
	--self:HL2DrawVGUI( panel, w, h, true, false, self.color_background )
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintWindowCloseButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintWindowMinimizeButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintWindowMaximizeButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintVScrollBar( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintScrollBarGrip( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, self.color_text )
	
end

function SKIN:PaintButtonDown( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, self.color_text )
	
end

function SKIN:PaintButtonUp( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, self.color_text )
	
end

function SKIN:PaintButtonLeft( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, self.color_text )
	
end

function SKIN:PaintButtonRight( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, self.color_text )
	
end

function SKIN:PaintComboDownArrow( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true, self.color_text )
	
end

function SKIN:PaintComboBox( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintListBox( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintNumberUp( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintNumberDown( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintTreeNode( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintTreeNodeButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintSelection( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h )
	
end

function SKIN:PaintSliderKnob( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintNumSlider( panel, w, h )

	surface.SetDrawColor( Color( 0, 0, 0, 100 ) )
	surface.DrawRect( 8, h / 2 - 1, w - 15, 1 )
	
	PaintNotches( 8, h / 2 - 1, w - 16, 1, panel.m_iNotches )

end

function SKIN:PaintProgress( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, false, Color( 0, 0, 0, 0 ) )
	self:HL2DrawVGUI( panel, w * panel:GetFraction(), h, self.color_text )
	
end

function SKIN:PaintCollapsibleCategory( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintCategoryList( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintCategoryButton( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true, true )
	
end

function SKIN:PaintListViewLine( panel, w, h )
	
	if panel:IsSelected() == true then
		
		self:HL2DrawVGUI( panel, w, h, true, false, self.color_hover )
		
	else
		
		self:HL2DrawVGUI( panel, w, h, true, true )
		
	end
	
end

function SKIN:PaintListView( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintTooltip( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

function SKIN:PaintMenuBar( panel, w, h )
	
	self:HL2DrawVGUI( panel, w, h, true )
	
end

derma.DefineSkin( "HL2", "Made to look like Half-Life 2 VGUI", SKIN )



GM.Skin = SKIN
