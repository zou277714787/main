--[[
Title: ElementLayout
Author(s): wxa
Date: 2020/8/14
Desc: 实现元素CSS属性的应用
------------------------------------------------------------
]]

local ElementLayout = commonlib.inherit(commonlib.gettable("System.Core.ToolBase"), commonlib.createtable("System.Windows.mcml.ElementLayout"));

-- 属性定义
ElementLayout:Property("UseSpace", true, "IsUseSpace");  -- 是否占据文档流空间
ElementLayout:Property("Layout");        -- 元素布局
ElementLayout:Property("ParentLayout");  -- 父元素布局
-- ElementLayout:Property("Window");        -- 窗口
-- ElementLayout:Property("WindowX");        -- 窗口
-- ElementLayout:Property("WindowY");       -- 窗口纵坐标
-- ElementLayout:Property("WindowWidth");   -- 窗口宽
-- ElementLayout:Property("WindowHeight");  -- 窗口高

-- 初始化
function ElementLayout:Init(element)
	self.element = element;
	self.rightAvailableX = 0;
	self.rightAvailableY = 0;
	return self;
end

-- 获取页面元素
function ElementLayout:GetElement()
	return self.element;
end

-- 获取页面元素的CSS
function ElementLayout:GetElementStyle()
	return self:GetElement() and self:GetElement():GetStyle();
end

-- 设置填充
function ElementLayout:SetPaddings(padding_left, padding_top, padding_right, padding_bottom)
	self.padding_left, self.padding_top, self.padding_right, self.padding_bottom = padding_left, padding_top, padding_right, padding_bottom;
end
-- 获取填充
function ElementLayout:GetPaddings()
	return self.padding_left, self.padding_top, self.padding_right, self.padding_bottom;
end
-- 设置边距
function ElementLayout:SetMargins(margin_left, margin_top, margin_right, margin_bottom)
	self.margin_left, self.margin_top, self.margin_right, self.margin_bottom = margin_left, margin_top, margin_right, margin_bottom;
end
-- 获取边距
function ElementLayout:GetMargins()
	return self.margin_left, self.margin_top, self.margin_right, self.margin_bottom;
end
-- 设置宽高 非坐标 包含 padding border
function ElementLayout:SetWidthHeight(width, height)
	self.width, self.height = width, height;
end
-- 获取宽高 非坐标 包含 padding border
function ElementLayout:GetWidthHeight()
	return self.width, self.height;
end
-- 设置元素盒子宽高 非坐标 包含 margin padding border
function ElementLayout:SetBoxWidthHeight(boxWidth, boxHeight)
	self.boxWidth, self.boxHeight = boxWidth, boxHeight;
end
-- 获取元素盒子宽高 非坐标 包含 margin padding border
function ElementLayout:GetBoxWidthHeight()
	return self.boxWidth, self.boxHeight;
end
-- 设置最大宽高 非坐标
function ElementLayout:SetMaxWidthHeight(maxWidth, maxHeight)
	self.maxWidth, self.maxHeight = maxWidth, maxHeight;
end
-- 获取最大宽高 非坐标
function ElementLayout:GetMaxWidthHeight()
	return self.maxWidth, self.maxHeight;
end
-- 设置位置坐标
function ElementLayout:SetPos(left, top)
	self.left, self.top = left, top; 
end
-- 获取位置坐标
function ElementLayout:GetPos()
	return self.left, self.top; 
end
-- 获取窗口
function ElementLayout:GetWindow()
	return self:GetElement():GetPageCtrl():GetWindow();
end
-- 获取窗口位置 x, y, w, h    (w, h 为宽高, 非坐标)
function ElementLayout:GetWindowPosition()
	return self:GetWindow():GetNativeWindow():GetAbsPosition();
end
-- 获取屏幕(应用程序窗口)位置
function ElementLayout:GetScreenPosition()
	return ParaUI.GetUIObject("root"):GetAbsPosition();
end

-- 更新布局
function ElementLayout:UpdateLayout(parentLayout)
	-- 检测是否符合布局条件
	if (not parentLayout) then return echo("parentLayout is nil") end
	if (not self:GetElementStyle()) then return echo("element style is nil") end
	local page = self:GetElement():GetPageCtrl();
	local window = page and page:GetWindow();
	local nativeWindow = window and window:GetNativeWindow();
	if (not nativeWindow) then return echo("native window is nil") end;

	-- 准备布局
	self:PrepareUpdateLayout(parentLayout);

	-- 调整位置信息
	self:ApplyPositionStyle();

	-- 更新子布局
	self:ApplyUpdateChildLayout();

	-- 调整排列, 依赖于子布局, 只有子布局执行完成, 元素大小才能确定, 才可以进行排列
	self:ApplyAfterChildLayout();

	-- 添加至父布局
	self:ApplyUseSpace();
end

-- CSS 相关属性实现
--[[
元素宽高: 包含边框, 填充, 内容 width = border + margin + contentWidth
元素百分比: 取父元素最大大小的百分比 size = parentMaxSize * percentage
]]

-- 百分比转数字
function ElementLayout:PercentageToNumber(percentage, maxsize)
	if (not percentage) then return end
	percentage = tostring(percentage); -- 确保为字符串
	local number = tonumber(string.match(percentage, "[%+%-]?%d+"));
	if (string.match(percentage, "%%$")) then
		number = math.floor(maxsize * number /100);
	end
	return number;
end

-- 块元素识别
function ElementLayout:IsBlockElement(display)
	return not display or display == "block";
end

-- 处理布局准备工作, 
function ElementLayout:PrepareUpdateLayout(parentLayout)
	local css = self:GetElementStyle();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local padding_left, padding_top, padding_right, padding_bottom = css:paddings();
	local margin_left, margin_top, margin_right, margin_bottom = css:margins();
	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
	local ScreenX, ScreenY, ScreenWidth, ScreenHeight = self:GetScreenPosition();
	-- 保存父布局
	self:SetParentLayout(parentLayout);
	-- 保存布局最大大小
	self:SetMaxWidthHeight(maxWidth, maxHeight);
	-- 保存边距与填充
	margin_left = self:PercentageToNumber(margin_left, maxWidth);
	margin_right = self:PercentageToNumber(margin_right, maxWidth);
	margin_top = self:PercentageToNumber(margin_top, maxHeight);
	margin_bottom = self:PercentageToNumber(margin_bottom, maxHeight);
	self:SetMargins(margin_left, margin_top, margin_right, margin_bottom);
	padding_left = self:PercentageToNumber(padding_left, maxWidth);
	padding_right = self:PercentageToNumber(padding_right, maxWidth);
	padding_top = self:PercentageToNumber(padding_top, maxHeight);
	padding_bottom = self:PercentageToNumber(padding_bottom, maxHeight);
	self:SetPaddings(padding_left, padding_top, padding_right, padding_bottom);
	-- z-index 序
	css["z-index"] = tonumber(string.match(css["z-index"] or "0", "[%+%-]?%d+")) or 0;
	-- 计算宽高
	local width = self:GetElement():GetAttribute("width") or css.width;      -- 支持百分比, px
	local height = self:GetElement():GetAttribute("height") or css.height;   -- 支持百分比, px
	if(width) then
		if(css.position == "screen") then
			width = self:PercentageToNumber(width, ScreenWidth);
		else	
			width=self:PercentageToNumber(width, maxWidth - margin_left - margin_right);
			if(availWidth < (width + margin_left + margin_right)) then 
				width=availWidth-margin_left-margin_right;
			end
			if(width<=0) then
				width = nil;
			end
		end	
	end
	if(height) then
		if(css.position == "screen") then
			height = self:PercentageToNumber(height, ScreenHeight);
		else	
			height = self:PercentageToNumber(height, maxHeight - margin_top - margin_bottom);
			if(availHeight < (height + margin_top + margin_bottom)) then
				height = availHeight - margin_top - margin_bottom;
			end
			if(height <= 0) then
				height = nil;
			end
		end	
	end
	-- 保存宽高
	self:SetWidthHeight(width, height);

	-- 确定元素是否新起一行
	if (css.float) then  
		-- 浮动元素
		if (width and availWidth < (width + margin_left + margin_right)) then
			parentLayout:NewLine();
		end
	else
		-- 默认为块元素
		if (self:IsBlockElement(css.display)) then
			parentLayout:NewLine();
		end
	end

	-- 构建自身布局
	self:SetLayout(parentLayout:clone());
	-- 设置起始点 父元素的可用位置即为元素起始点
	self:SetPos(parentLayout:GetAvailablePos());
end

-- 应用CSS的定位样式
function ElementLayout:ApplyPositionStyle()
	local css = self:GetElementStyle();
	local parentLayout = self:GetParentLayout();
	local layout = self:GetLayout();
	local layoutLeft, layoutTop = self:GetPos();
	local layoutWidth, layoutHeight = layout:GetSize();
	local availWidth, availHeight = parentLayout:GetPreferredSize();
	local maxWidth, maxHeight = parentLayout:GetMaxSize();
	local width, height = self:GetWidthHeight();
	local WindowX, WindowY, WindowWidth, WindowHeight = self:GetWindowPosition();
	local ScreenX, ScreenY, ScreenWidth, ScreenHeight = self:GetScreenPosition();
	local padding_left, padding_top, padding_right, padding_bottom = self:GetPaddings();
	local margin_left, margin_top, margin_right, margin_bottom = self:GetMargins();
	
	-- 定位
	self:SetUseSpace(true);
	local float, position = css.float, css.position;
	local left, top, right, bottom = css.left, css.top, css.right, css.bottom;
	-- 浮动与定位不共存
	if (float == "right") then

	elseif (float == "left") then
	elseif(position == "absolute" or position == "fixed") then
		local parent = self:GetElement():GetParent();
		if (position == "absolute") then
			-- 获取已定位的父元素
			while (parent and parent:GetParent() and (not parent:GetStyle() and not parent:GetStyle().position)) do
				parent = parent:GetParent();
			end
		else
			-- 取根元素
			while (parent and parent:GetParent()) do
				parent = parent:GetParent();
			end
		end
		-- 相对定位的布局
		local relLeft, relTop, relWidth, relHeight = 0, 0, 0, 0;
		if (parent) then 
			relLeft, relTop = parent:GetElementLayout():GetPos();
			relWidth, relHeight = parent:GetElementLayout():GetLayout():GetSize();
		else
			relLeft, relTop = parentLayout:GetNewlinePos();
			relWidth, relHeight = parentLayout:GetSize();
		end
		if (left or top) then
			left = left or 0;
			top = top or 0;
			left = self:PercentageToNumber(left, relWidth - relLeft);
			top = self:PercentageToNumber(top, relHeight - relTop);
			layout:SetPos(relLeft + left, relTop + top);
		end
		if (right or bottom) then
			right = right or 0;
			bottom = bottom or 0;
			right = relWidth - self:PercentageToNumber(right, relWidth - relLeft);
			bottom = relHeight - self:PercentageToNumber(bottom, relHeight - relTop);
		else
			-- 没有宽高使用容器宽高
			right = relLeft + left + (width or (layoutWidth - layoutLeft));
			bottom = relTop + top + (height or (layoutHeight - layoutTop));
		end
		layout:SetSize(right, bottom);
		self:SetUseSpace(false);
	elseif(position == "relative") then
		-- 相对定位进行偏移
		layout:OffsetPos(css.left or 0, css.top or 0);
	elseif(position == "screen") then	
		-- relative positioning in screen client area
		left = self:PercentageToNumber(left, WindowWidth);
		top = self:PercentageToNumber(top, WindowHeight);
		right = self:PercentageToNumber(right, WindowWidth);
		bottom = self:PercentageToNumber(bottom, WindowHeight);
		left = (left or 0) - WindowX;
		top = (top or 0) - WindowY;
		layout:SetPos(left, top);
		if (right or bottom) then
			right = ScreenWidth - (right or 0);
			bottom = ScreenHeight - (bottom or 0);
		else
			right = left + (width or (layoutWidth - layoutLeft));
			bottom = top +(height or (layoutHeight - layoutTop));
		end
		layout:SetSize(right, bottom);
		self:SetUseSpace(false);
	end
end

-- 更新子布局
function ElementLayout:ApplyUpdateChildLayout()
	local css = self:GetElementStyle();
	local layout = self:GetLayout();
	local width, height = self:GetWidthHeight();
	local avaliLeft, avaliTop = layout:GetAvailablePos();
	local layoutWidth, layoutHeight = layout:GetSize();
	local padding_left, padding_top, padding_right, padding_bottom = self:GetPaddings();
	local margin_left, margin_top, margin_right, margin_bottom = self:GetMargins();

	-- 保存开始子元素布局时使用大小
	layout:ResetUsedSize();
	-- 保存开始子元素布局时的位置坐标
	self:SetPos(avaliLeft, avaliTop);

	-- 获取显示使用大小并调整布局
	local left, top = self:GetPos();
	-- local usedWidth, usedHeight = layout:GetUsedSize();
	local usedWidth = width and (left + width + margin_left + margin_right);
	local usedHeight = height and (top + height + margin_top + margin_bottom);
	if(usedWidth) then layout:IncWidth(usedWidth - layoutWidth) end
	if(usedHeight) then layout:IncHeight(usedHeight - layoutHeight) end	
	
	-- 设置起始位置和宽高
	layout:SetPos(left, top);
	-- 缩小至内容大小
	layout:OffsetPos(margin_left + padding_left, margin_top + padding_top);
	layout:IncWidth(-margin_right-padding_right)
	layout:IncHeight(-margin_bottom-padding_bottom)

	-- 子元素布局
	if(not self:GetElement():OnBeforeChildLayout(layout)) then
		self:GetElement():UpdateChildLayout(layout);
	end

	-- 获取元素(含子元素)布局后的大小, 用于计算元素真实大小(又子元素使用情况而定)
	local newUsedWidth, newUsedHeight = layout:GetUsedSize(); -- 左上点坐标  由于子元素是在父元素的内容区,  故使用大小未包含当元素的padding_right, margin_right, border_right
	local realWidth = newUsedWidth + padding_right - left - margin_left;
	local realHeight = newUsedHeight + padding_bottom - top - margin_top;
	layout:SetRealSize(realWidth, realHeight);  -- 真实元素大小
	-- 元素真实大小 优先显示指定大小, 其次使用子元素占据大小
	usedWidth = usedWidth or (newUsedWidth + padding_right + margin_right);
	usedHeight = usedHeight or (newUsedHeight + padding_bottom + margin_bottom);

	-- 处理最大, 最小属性值
	if(css["min-width"]) then
		local min_width = css["min-width"];
		if((usedWidth - left - margin_left - margin_right) < min_width) then
			usedWidth = left + min_width + margin_left + margin_right;
		end
	end
	if(css["max-width"]) then
		local max_width = css["max-width"];
		-- 可以忽略右边距
		if((usedWidth - left - margin_left - margin_right) > max_width) then
		-- if((usedWidth - avaliLeft - margin_left) > max_width) then
			usedWidth = left + max_width + margin_left + margin_right;
		end
	end
	if(css["min-height"]) then
		local min_height = css["min-height"];
		if((usedHeight - top - margin_top - margin_bottom) < min_height) then
			usedHeight = top + min_height + margin_top + margin_bottom;
		end
	end
	if(css["max-height"]) then
		local max_height = css["max-height"];
		if((usedHeight - top - margin_top - margin_bottom) < max_height) then
			usedHeight = top + max_height + margin_top + margin_bottom;
		end
	end
	-- 设置布局完成后的使用大小
	layout:SetUsedSize(usedWidth, usedHeight);
	-- 布局完成后回调
	self:GetElement():OnAfterChildLayout(layout, left + margin_left, top + margin_top, usedWidth - margin_right, usedHeight - margin_bottom);
	-- 获取重新使用大小
	usedWidth, usedHeight = layout:GetUsedSize();
	self:SetBoxWidthHeight(usedWidth - left, usedHeight - top);
end

-- 应用排列属性
function ElementLayout:ApplyAfterChildLayout()
	local css = self:GetElementStyle();
	local layout = self:GetLayout();
	local boxWidth, boxHeight = self:GetBoxWidthHeight();
	local maxWidth, maxHeight = self:GetMaxWidthHeight();
	local usedWidth, usedHeight = layout:GetUsedSize();
	local left, top = self:GetPos();
	local padding_left, padding_top, padding_right, padding_bottom = self:GetPaddings();
	local margin_left, margin_top, margin_right, margin_bottom = self:GetMargins();
	local align = self:GetElement():GetAttribute("align") or css["align"];
	local valign = self:GetElement():GetAttribute("valign") or css["valign"];
	local offset_x, offset_y = 0, 0;
	-- align at center. 
	if(align == "center") then 
		offset_x = (maxWidth - boxWidth) / 2;
	elseif(align == "right") then
		offset_x = (maxWidth - boxWidth);
	end	
	
	if(valign == "center") then
		offset_y = (maxHeight - boxHeight) / 2;
	elseif(valign == "bottom") then
		offset_y = (maxHeight - boxHeight);
	end	
	-- 应用排列
	if(offset_x~=0 or offset_y~=0) then
		-- offset and recalculate if there is special alignment. 
		left, top = left + offset_x, top + offset_y;
		usedWidth, usedHeight = left + boxWidth, top + boxHeight;
		self:SetLayout(self:GetParentLayout():clone());
		self:SetPos(left, top);
		layout = self:GetLayout();
		layout:SetPos(left, top);
		layout:SetSize(usedWidth, usedHeight);
		layout:OffsetPos(margin_left + padding_left, margin_top + padding_top);
		layout:IncWidth(-margin_right - padding_right);
		layout:IncHeight(-margin_bottom - padding_bottom);
		layout:ResetUsedSize();
		if(not self:GetElement():OnBeforeChildLayout(layout)) then
			self:GetElement():UpdateChildLayout(layout);
		end
		layout:SetUsedSize(usedWidth, usedHeight);
		self:GetElement():OnAfterChildLayout(layout, left + margin_left, top + margin_top, usedWidth - margin_right, usedHeight - margin_bottom);
		usedWidth, usedHeight = layout:GetUsedSize();
		self:SetBoxWidthHeight(usedWidth - left, usedHeight - top);
	elseif (css.float == "right") then
		-- 只支持一个右浮动
		local parentLayoutWidth, parentLayoutHeight = self:GetParentLayout():GetSize();
		local layoutWidth, layoutHeight = layout:GetSize();
		self:SetLayout(self:GetParentLayout():clone());
		self:SetPos(parentLayoutWidth - boxWidth, top);
		layout = self:GetLayout();
		layout:SetPos(parentLayoutWidth - boxWidth, top);
		layout:SetSize(parentLayoutWidth, top + boxHeight);
		layout:OffsetPos(margin_left + padding_left, margin_top + padding_top);
		layout:IncWidth(-margin_right - padding_right);
		layout:IncHeight(-margin_bottom - padding_bottom);
		layout:ResetUsedSize();
		if(not self:GetElement():OnBeforeChildLayout(layout)) then
			self:GetElement():UpdateChildLayout(layout);
		end
		layout:SetUsedSize(usedWidth, usedHeight);
		self:GetElement():OnAfterChildLayout(layout, parentLayoutWidth - boxWidth + margin_left, top + margin_top, parentLayoutWidth - margin_right, top + boxHeight - margin_bottom);
		usedWidth, usedHeight = layout:GetUsedSize();
		self:SetBoxWidthHeight(usedWidth - (parentLayoutWidth - boxWidth), usedHeight - top);
	end
end

-- 应用元素使用空间
function ElementLayout:ApplyUseSpace()
	if (not self:IsUseSpace()) then return end

	local css = self:GetElementStyle();

	self:GetParentLayout():AddObject(self:GetBoxWidthHeight());

	if (not css.float and self:IsBlockElement(css.display)) then
		self:GetParentLayout():NewLine();
	end
end
