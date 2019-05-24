--[[
Title: UITextElement
Author(s): LiXizhi
Date: 2015/4/29
Desc:
use the lib:
------------------------------------------------------------
NPL.load("(gl)script/ide/System/Windows/UITextElement.lua");
local UITextElement = commonlib.gettable("System.Windows.UITextElement");
------------------------------------------------------------

]]
NPL.load("(gl)script/ide/System/Windows/UIStyleElement.lua");
NPL.load("(gl)script/ide/math/Rect.lua");
local Rect = commonlib.gettable("mathlib.Rect");

local UITextElement = commonlib.inherit(commonlib.gettable("System.Windows.UIStyleElement"), commonlib.gettable("System.Windows.UITextElement"));
UITextElement:Property("Name", "UITextElement");

UITextElement:Property({"text", nil, "GetText", "SetText", auto=true});
UITextElement:Property({"Color", "#000000", auto=true});
UITextElement:Property({"Font", nil, auto=true});
UITextElement:Property({"FontSize", nil, auto=true});
UITextElement:Property({"FontScaling", nil, auto=true});
-- default to centered and no clipping. 
UITextElement:Property({"Alignment", 0+4+256, auto=true, desc="text alignment"});
UITextElement:Property({"TextShadow", false, "HasTextShadow", "SetTextShadow", auto=true});
UITextElement:Property({"ShadowColor", "#00000088", auto=true});
--UITextElement:Property({"ShadowQuality", 1, auto=true});
UITextElement:Property({"ShadowOffsetX", 3, auto=true});
UITextElement:Property({"ShadowOffsetY", 3, auto=true});


function UITextElement:ctor()

end

function UITextElement:DrawText(painter, x, y, w, h, sText, textOption)
	painter:SetFont(self:GetFont());

	if(self:HasTextShadow()) then
		painter:SetPen(self:GetShadowColor());
		painter:DrawText(x + self.ShadowOffsetX, y + self.ShadowOffsetY, w, h, sText, textOption);
	end

	painter:SetPen(self:GetColor());
	painter:DrawText(x, y, w, h, sText, textOption);
end

function UITextElement:DrawTextScaled(painter, x, y, text, scale)
	painter:SetFont(self:GetFont());

	if(self:HasTextShadow()) then
		painter:SetPen(self:GetShadowColor());
		painter:DrawTextScaled(x + self.ShadowOffsetX, y + self.ShadowOffsetY, text, scale);
	end

	painter:SetPen(self:GetColor());
	painter:DrawTextScaled(x, y, text, scale);
end

function UITextElement:DrawTextScaledEx(painter, x, y, width, height, text, alignment, scale)
	painter:SetFont(self:GetFont());

	if(self:HasTextShadow()) then
		painter:SetPen(self:GetShadowColor());
		painter:DrawTextScaledEx(x + self.ShadowOffsetX, y + self.ShadowOffsetY, width, height, text, alignment, scale);
	end

	painter:SetPen(self:GetColor());
	painter:DrawTextScaledEx(x, y, width, height, text, alignment, scale);
end

function UITextElement:DrawTextScaledEx2(painter, x, y, width, height, text, alignment, scale)
	if(self:HasTextShadow()) then
		painter:SetPen(self:GetShadowColor());
		painter:DrawTextScaledEx(x + self.ShadowOffsetX, y + self.ShadowOffsetY, width, height, text, alignment, scale);
	end

	painter:DrawTextScaledEx(x, y, width, height, text, alignment, scale);
end

-- virtual: apply css style
function UITextElement:ApplyCss(css)
	UITextElement._super.ApplyCss(self, css);
	self:SetFont(css:Font():ToString());
	self:SetColor(css:Color():ToString());
	
	local text_shadow = css:TextShadow();
	if(text_shadow) then
		self:SetTextShadow(true);
		self:SetShadowOffsetX(text_shadow:X());
		self:SetShadowOffsetY(text_shadow:Y());
		self:SetShadowColor(text_shadow:Color():ToString());
	else
		self:SetTextShadow(false);
	end
end
