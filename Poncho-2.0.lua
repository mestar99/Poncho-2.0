local Lib = LibStub:NewLibrary('Poncho-2.0', 1)
if not Lib then return end

local setmetatable, getmetatable, tinsert, tremove, type = setmetatable, getmetatable, tinsert, tremove, type
local Base = {__type = 'Abstract'}

local ClassMeta =  {
  __index = function(class, key)
    return class.__super[key] or Lib.Types[class.__type][key]
  end,

  __call = function(class, ...)
    return class:New(...)
  end
}

local SuperCall = {
  __index = function(tmp, key)
    local var = ClassMeta.__index(tmp.class, key) or Lib.Types[tmp.frame.__type][key]
    if type(var) == 'function' then
      return function(tmp, ...)  return var(tmp.frame, ...) end
    end

    return var
  end
}


--[[ Static ]]--

function Base:NewClass(kind, name, template)
  assert(not kind or type(kind) == 'string', 'Bad argument #1 to `:NewClass` (string or nil expected)')
  assert(not name or type(name) == 'string', 'Bad argument #2 to `:NewClass` (string or nil expected)')
  assert(not template or type(template) == 'string', 'Bad argument #3 to `:NewClass` (string or nil expected)')

  if kind and not Lib.Types[kind] then
    Lib.Types[kind] = getmetatable(CreateFrame(kind)).__index
  end

  local class = setmetatable({}, ClassMeta)
  class.__super = self
  class.__template = template
  class.__index = class
  class.__type = kind
  class.__name = name

  if class.__type ~= 'Abstract' then
    class.__frames = {}
    class.__count = 0
  end

  return class
end

function Base:New(parent)
  assert(self.__type ~= 'Abstract', 'Cannot initialize frame for absract class')

  local frame = tremove(self.__frames)
  if not frame then
    self.__count = self.__count + 1
    frame = self:Construct()
  end

  self.__frames[frame] = true
  frame:ClearAllPoints()
  frame:SetParent(parent)
  return frame
end

function Base:Bind(frame)
  return setmetatable(frame, self)
end

function Base:Construct()
  return self:Bind(CreateFrame(self.__type, self.__name and (self.__name .. self.__count) or nil, UIParent, self.__template))
end

function Base:IsAbstract()
  return self.__type == 'Abstract'
end


--[[ Flexible ]]--

function Base:GetClassName()
  return self.__name
end

function Base:GetSuper()
  return self.__super
end

function Base:GetTemplate()
  return self.__template
end

function Base:GetFrameType()
  return self.__type
end

function Base:NumActive()
  return self.__count - #self.__frames
end

function Base:NumInactive()
  return #self.__frames
end

function Base:NumFrames()
  return self.__count
end


--[[ Instance ]]--

function Base:GetClass()
  return getmetatable(self)
end

function Base:Release()
  if self:IsActive() then
    tinsert(self.__frames, 1, self)
    self.__frames[self] = nil
    self:Reset()
  end
end

function Base:Reset()
  self:SetParent(UIParent)
  self:ClearAllPoints()
  self:SetPoint('BOTTOM', UIParent, 'TOP', 0, GetScreenHeight()) -- twice outside of screen
end

function Base:IsActive()
  return self.__frames[self]
end

function Base:Super(class)
  assert(class, 'No argument #1 to `:Super`')
  return setmetatable({class = class, frame = self}, SuperCall)
end


--[[ Public ]]--

function Lib:NewClass(kind, name, template)
  return Base:NewClass(kind, name, template)
end

function Lib:Embed(object)
  object.NewClass = Lib.NewClass
end


--[[ Proprieties ]]--

setmetatable(Lib, Lib)
Lib.__call = Lib.NewClass
Lib.Base, Lib.ClassMeta, Lib.SuperCall = Base, ClassMeta, SuperCall
Lib.Types = Lib.Types or {
  Abstract = {},
  Frame = getmetatable(GameMenuFrame).__index,
  Button = getmetatable(GameMenuButtonContinue).__index,
  CheckButton = getmetatable(AddonListForceLoad).__index,
  EditBox = getmetatable(ChatFrame1EditBox).__index,
}
