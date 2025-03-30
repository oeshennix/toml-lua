--[=[

--[[ TOML-LUA ]]--
Compatible with lua 5.2 and above
have not tested lower versions

created by Oeshen Nix
--]=]

---@class TOMLParseObject: {index:number,char:string,pos:number,line:number,lines:string[],file:string}}

local TOML={};

TOMLtypeEnum={"string","boolean","array","table","date-time","float","integer"}
---@class TOMLDate: {year:number, month:number, monthdate:number}
---@class TOMLTimeOffset: {add:boolean,offsethour:number, offsetminute:number}
---@class TOMLTime: {hours:number, minutes:number, seconds:number, secfrac:number?, timeoffset:TOMLTimeOffset?}
---@class TOMLDateTime: {Date:TOMLDate?,Time:TOMLTime?}
---@class TOMLObject: {type:number, value:any }
TOMLObject={}
TOMLObject.__index=TOMLObject;
function TOMLObject:Lua()
  ---@cast self TOMLObject
  if(self.type==3)then
    local array={};
    for _,object in ipairs(self.value)do
      table.insert(array,object:Lua());
    end;
    return array;
  elseif(self.type==4)then
    local tab={};
    for key,object in pairs(self.value)do
      tab[key]=object:Lua();
    end;
    return tab;
  end;
  return self.value;
end;
function TOMLObject:__tostring()
  ---@cast self TOMLObject
  if(self.type==1)then
    return string.format("<TOMLObject:string,\"%s\">",self.value);
  end;
  if(self.type==2)then
    return string.format("<TOMLObject:boolean,%s>",self.value);
  end;
  if(self.type==3)then
    local Output="<TOMLObject:array,["
    for _,arrayobject in ipairs(self.value) do
      Output=Output.."\n\t"..string.gsub(tostring(arrayobject),"\n","\n\t")
    end
    Output=Output.."\n]>"
    return Output;
  end;
  if(self.type==4)then
    local Output="<TOMLObject:table,{"
    for tablekey,tableobject in pairs(self.value) do
      Output=Output..string.format("\n\t[\"%s\"] = %s",tablekey,string.gsub(tostring(tableobject),"\n","\n\t"))
    end
    Output=Output.."\n}>"
    return Output;
  end;
  if(self.type==5)then
    local date=self.value.Date;
    local time=self.value.Time;
    ---@type TOMLTimeOffset
    local timeoffset=time and time.timeoffset;
    local timestr
    if(not date and time)then
      timestr=string.format("%02d:%02d:%02d",time.hours,time.minutes,time.seconds);
    elseif(date and not time)then
      timestr=
      string.format("%04d-%02d-%02d",date.year,date.month,date.monthdate)
    elseif(date and time and not timeoffset)then
      timestr=
      string.format("%04d-%02d-%02d",date.year,date.month,date.monthdate)
      .."t"
      ..string.format("%02d:%02d:%02d",time.hours,time.minutes,time.seconds)
    elseif(date and time and timeoffset)then
      timestr=
      string.format("%04d-%02d-%02d",date.year,date.month,date.monthdate)
      .."t"
      ..string.format("%02d:%02d:%02d",time.hours,time.minutes,time.seconds)
      ..(
        ((timeoffset.offsethour==0 and timeoffset.offsetminute==0) and "Z")
        or (string.format("%s%02d:02d",(time.add and "+" or "-"),timeoffset.offsethour,timeoffset.offsetminute))
      )
    end
    return string.format("<TOMLObject:DateTime,%s>",timestr)
  elseif(self.type==6)then
    return string.format("<TOMLObject:float,%s>",self.value);
  elseif(self.type==7)then
    return string.format("<TOMLObject:int,%s>",self.value);
  end;
  return "<TOML:UNKNOWN>"
end

---@param parseobject TOMLParseObject 
function ContinueUTF8(parseobject)
  if(not string.byte(parseobject.file,parseobject.index,parseobject.index))then
    parseobject.char="\x00"
    return parseobject.char;
  end
  if(math.floor(string.byte(parseobject.file, parseobject.index,parseobject.index)/0x80) == 0)then -- [0yyyzzzz]
    parseobject.char=string.sub(parseobject.file, parseobject.index,parseobject.index)
    parseobject.index=parseobject.index+1;
    return parseobject.char;
  elseif(math.floor(string.byte(parseobject.file, parseobject.index,parseobject.index)/0x20)==0x6)then --[110x xxyy|
    assert(math.floor(string.byte(parseobject.file, parseobject.index+1,parseobject.index+1)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10yy zzzz]
    parseobject.char=string.sub(parseobject.file, parseobject.index,parseobject.index+1)
    parseobject.index=parseobject.index+2;
    return parseobject.char;
  elseif(math.floor(string.byte(parseobject.file, parseobject.index,parseobject.index)/0x10)==0xE)then --[1110 wwww
    assert(math.floor(string.byte(parseobject.file, parseobject.index+1,parseobject.index+1)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10xx xxyy|
    assert(math.floor(string.byte(parseobject.file, parseobject.index+2,parseobject.index+2)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10yy zzzz]
    parseobject.char=string.sub(parseobject.file, parseobject.index,parseobject.index+2)
    parseobject.index=parseobject.index+3;
    return parseobject.char;
  elseif(math.floor(string.byte(parseobject.file, parseobject.index,parseobject.index)/0x08)==0x1E)then --[1111 0uvv|
    assert(math.floor(string.byte(parseobject.file, parseobject.index+1,parseobject.index+1)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10vv wwww|
    assert(math.floor(string.byte(parseobject.file, parseobject.index+2,parseobject.index+2)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10xx xxyy|
    assert(math.floor(string.byte(parseobject.file, parseobject.index+3,parseobject.index+3)/0x40)==0x2,"invalid UTF8 at "..parseobject.index) --|10yy zzzz]
    parseobject.char=string.sub(parseobject.file, parseobject.index,parseobject.index+3)
    parseobject.index=parseobject.index+4;
    return parseobject.char;
  end

  error("UTF8 error: how did this happen???");
end;

---@param char string
function UTF8CharByte(char)
end;

---@param parseObject TOMLParseObject 
function SkipWhiteSpaces(parseObject)--char is passed since I dont want a function like IsUTF8At since it does not continue the file;
  local char=parseObject.char;
  if(char~=" " and char~="\x09")then
    return
  end;
  while(true)do
    char=ContinueUTF8(parseObject);
    if(char~=" " and char~="\x09")then
      return
    end
  end
end;
---@param char parseObject
---@return boolean
function IsNewLine(parseObject)
  if(parseObject.char=="\x0A")then
    return true
  elseif(parseObject.char=="\x0D")then
    ContinueUTF8(parseObject);
    assert(char =="\x0A","CR must be followed by LF");
    return true
  end;
  return false;
end
---@param parseObject TOMLParseObject 
---@return boolean
function TryComment(parseObject);
  if(parseObject.char=="#")then
    ContinueUTF8(parseObject);
    local byte=string.byte(parseObject.char,1);
    while(byte>=0x20 or byte==0x09)do
      ContinueUTF8(parseObject);
      byte=string.byte(parseObject.char,1);
    end
    return true
  end
  return false
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetBasicUnescaped(parseObject)
    local byte=string.byte(parseObject.char,1,1);
    local char=parseObject.char;
    if ((byte>=20 and char~="\"" and char~="\\") or char=="\x09")then
      ContinueUTF8(parseObject);
      return char;
    end;
    return nil;
end;

local EscapedCharacters={
  ["\""]="\"",
  ["\\"]="\\",
  ["b"]="\x08",
  ["f"]="\x0C",
  ["n"]="\x0A",
  ["r"]="\x0D",
  ["t"]="\x09"
}

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetEscaped(parseObject)
  if(parseObject.char=="\x5C")then;--\
    ContinueUTF8(parseObject);
    if(parseObject.char=="u" or parseObject.char=="U")then
      local str="";
      if(parseObject.char=="u")then
        ContinueUTF8(parseObject);
        for _=1,4 do
          str=str..parseObject.char;
          ContinueUTF8(parseObject);
        end
      elseif(parseObject.char=="U")then
        ContinueUTF8(parseObject);
        for _=1,8 do
          str=str..parseObject.char;
          ContinueUTF8(parseObject);
        end
      end;
      local num=tonumber(str,16);
      if(num<=0x7F)then
        return string.char(num);
      elseif(num<=0x7FF)then
        return string.char(
          0xC0+(math.floor(num/0x40)),
          0x80+(num%0x40)
        )
      elseif(num<=0xFFFF)then
        return string.char(
          0xE0+(math.floor(num/0x1000)),
          0x80+(math.floor(num/0x40)%0x40),
          0x80+(num%0x40)
        )
      elseif(num<=0x10FFFF)then
        return string.char(
          0xF0+(math.floor(num/0x40000)),
          0x80+(math.floor(num/0x1000)%0x40),
          0x80+(math.floor(num/0x40)%0x40),
          0x80+num%0x40
        )
      end;
      --error("unimplented escape character");
    end
    local escapeCharacter=EscapedCharacters[parseObject.char]
    ContinueUTF8(parseObject);
    return escapeCharacter;
  end;
  return nil;
end;
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetBasicChar(parseObject)
  local basicChar;
  basicChar=GetBasicUnescaped(parseObject);
  if(basicChar)then
    return basicChar;
  end
  basicChar=GetEscaped(parseObject);
  if(basicChar)then
    return basicChar;
  end
  return nil;
end;
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlbChar(parseObject)
  --wschar \x20 and \x09
  --\x21
  --\x23-5B
  --\x5D-7E
  --non ascii \x80 and beyond
  if(string.match(parseObject.char,"[\x5D-\x7E\x80-\xFF\x23-\x5B\x09\x20\x21\x0A]"))then
    local char=parseObject.char;
    ContinueUTF8(parseObject);
    return char;
  end
  return GetEscaped(parseObject);
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlbContent(parseObject)
  local start,startchar=parseObject.index,parseObject.char;
  local char=GetMlbChar(parseObject)
  if(char)then
    return char
  end
  parseObject.index=start;
  parseObject.char=startchar;
  if(parseObject.char=="\x0A" or parseObject.char=="\x0D\x0A")then
    char=parseObject.char;
    ContinueUTF8(parseObject);
    return char;
  end
  --mlbescapenl
  if(parseObject.char=="\\")then
    ContinueUTF8(parseObject);
    SkipWhiteSpaces(parseObject);
    if(parseObject.char~="\x0A" and parseObject.char~="\x0D\x0A")then
      parseObject.index=start;
      parseObject.char=startchar;
      return nil
    end
    while(true)do
      start,startchar=parseObject.index,parseObject.char;
      if(not string.match(parseObject.char,"[\x0A\x20\x09]") and parseObject.char~="\x0D\x0A")then
        parseObject.index=start;
        parseObject.char=startchar;
        return nil;
      end
      ContinueUTF8(parseObject);
    end;
  end
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlBasicBody(parseObject)
  local mlstring=""
  while(true)do
    local char=GetMlbContent(parseObject);
    if(not char)then
      break
    end
    mlstring=mlstring..char;
  end
  local start,startchar=parseObject.index,parseObject.char;
  while(true)do
    start,startchar=parseObject.index,parseObject.char;
    local extrachar=""
    --mlbquotes
    if(parseObject.char=="\"")then
      extrachar=extrachar..parseObject.char;
      ContinueUTF8(parseObject);
      if(parseObject.char=="\"")then
        extrachar=extrachar..parseObject.char;
        ContinueUTF8(parseObject);
      end
    end;
    --mlbcontent
    local char=GetMlbContent(parseObject);
    if(not char)then
      parseObject.index=start;
      parseObject.char=startchar;
      break;
    end
    mlstring=mlstring..extrachar..char;
    while(true)do
      char=GetMlbContent(parseObject);
      if(not char)then
        break;
      end
      mlstring=mlstring..char;
    end;
  end
  local quotes=0;
  local steps={parseObject.index};
  for _=1,5 do
    if(parseObject.char~="\"")then
      break
    end
    ContinueUTF8(parseObject);
    table.insert(steps,parseObject.index);
    quotes=quotes+1;
  end
  if(quotes<3)then
    return nil;
  end;
  mlstring=mlstring..string.rep("\"",quotes-3);
  parseObject.index=steps[quotes-2];
  parseObject.char="\""
  ---TODO add [mlb-quotes] that isnt referring to baseball
  return mlstring;

end;
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlBasicString(parseObject)
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(IsNewLine(parseObject))then
    ContinueUTF8(parseObject);
  end;
  local basicString=GetMlBasicBody(parseObject)
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  return basicString
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetBasicString(parseObject)
  if(parseObject.char~="\"")then
    return nil;
  end
  local basicString="";
  ContinueUTF8(parseObject);

  while(true)do
    local basicChar;
    basicChar=GetBasicChar(parseObject);
    if(not basicChar)then
      break
    end
    basicString=basicString..basicChar;
  end;
  if(parseObject.char~="\"")then
    return nil;
  end
  ContinueUTF8(parseObject);
  return basicString
end;
function GetMllChar(parseObject)
  --\x09
  --\x20-\x26
  --\x28-7E
  --non ascii \x80 and beyond
  if(string.match(parseObject.char,"[\x20-\x26\x28-\x7E\x80-\xFF\x09]"))then
    local char=parseObject.char;
    ContinueUTF8(parseObject);
    return char;
  end
  return GetEscaped(parseObject);
end;
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMllContent(parseObject)
  local start,startchar=parseObject.index,parseObject.char;
  local char=GetMllChar(parseObject)
  if(char)then
    return char
  end
  parseObject.index=start;
  parseObject.char=startchar;
  if(parseObject.char=="\x0A" or parseObject.char=="\x0D\x0A")then
    char=parseObject.char;
    ContinueUTF8(parseObject);
    return char;
  end
  return nil;
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlLiteralBody(parseObject)
  local mlstring=""
  while(true)do
    local char=GetMllContent(parseObject);
    if(not char)then
      break
    end
    mlstring=mlstring..char;
  end
  local start,startchar=parseObject.index,parseObject.char;
  while(true)do
    start,startchar=parseObject.index,parseObject.char;
    local extrachar=""
    --mlbquotes
    if(parseObject.char=="\'")then
      extrachar=extrachar..parseObject.char;
      ContinueUTF8(parseObject);
      if(parseObject.char=="\'")then
        extrachar=extrachar..parseObject.char;
        ContinueUTF8(parseObject);
      end
    end;
    --mlbcontent
    local char=GetMllContent(parseObject);
    if(not char)then
      parseObject.index=start;
      parseObject.char=startchar;
      break;
    end
    mlstring=mlstring..extrachar..char;
    while(true)do
      char=GetMllContent(parseObject);
      if(not char)then
        break;
      end
      mlstring=mlstring..char;
    end;
  end
  local quotes=0;
  local steps={parseObject.index};
  for _=1,5 do
    if(parseObject.char~="\'")then
      break
    end
    ContinueUTF8(parseObject);
    table.insert(steps,parseObject.index);
    quotes=quotes+1;
  end
  if(quotes<3)then
    return nil;
  end;
  mlstring=mlstring..string.rep("\'",quotes-3);
  parseObject.index=steps[quotes-2];
  parseObject.char="\'"
  ---TODO add [mlb-quotes] that isnt referring to baseball
  return mlstring;

end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetMlLiteralString(parseObject)
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(IsNewLine(parseObject))then
    ContinueUTF8(parseObject);
  end;
  local literalString=GetMlLiteralBody(parseObject)
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="\'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  return literalString
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetLiteralChar(parseObject);
  local char=parseObject.char;
  local byte=string.byte(char,1,1);
  if ((byte>=20 and char~="'") or char=="\x09")then
    ContinueUTF8(parseObject);
    return char;
  end;
  return nil;
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetLiteralString(parseObject)
  if(parseObject.char~="'")then
    return nil;
  end
  local basicString="";
  ContinueUTF8(parseObject);

  while(true)do
    local basicChar;
    basicChar=GetLiteralChar(parseObject);
    if(not basicChar)then
      break
    end
    basicString=basicString..basicChar;
  end;
  if(parseObject.char~="'")then
    return nil;
  end
  ContinueUTF8(parseObject);
  return basicString
end;

--:TODO
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetString(parseObject)
  local start,startchar=parseObject.index,parseObject.char;
  local tString;
  tString=GetMlBasicString(parseObject);
  if(tString)then
    return tString;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  tString=GetBasicString(parseObject);
  if(tString)then
    return tString;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  tString=GetMlLiteralString(parseObject);
  if(tString)then
    return tString;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  tString=GetLiteralString(parseObject);
  if(tString)then
    return tString;
  end
  return nil;
end;

--:TODO
---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetQuotedKey(parseObject)
  local tString;
  tString=GetBasicString(parseObject);
  if(tString)then
    return tString;
  end
  tString=GetLiteralString(parseObject);
  if(tString)then
    return tString;
  end
  return nil;
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetUnquotedKey(parseObject)
  local unquotedKey=string.match(parseObject.char,"[A-Za-z0-9%-_]");
  if(not unquotedKey)then
    return nil
  end
  ContinueUTF8(parseObject);
  while(true)do
    local matchedchar=string.match(parseObject.char,"[A-Za-z0-9%-_]");
    if(not matchedchar)then
      return unquotedKey;
    end
    unquotedKey=unquotedKey..parseObject.char;
    ContinueUTF8(parseObject);
  end;
end;

--:TODO
---@param parseObject TOMLParseObject 
---@return string?
function GetSimpleKey(parseObject)
  local tString;
  local start,startchar=parseObject.index,parseObject.char;
  tString=GetQuotedKey(parseObject);
  if(tString)then
    return tString;
  end
  parseObject.index=start
  parseObject.char=startchar;
  tString=GetUnquotedKey(parseObject);
  if(tString)then
    return tString;
  end
  parseObject.index=start
  parseObject.char=startchar;
  return nil;
end

--:TODO add dotted keys
---@param parseObject TOMLParseObject 
---@return string[]?
function GetKey(parseObject)
  local key=GetSimpleKey(parseObject);
  if(not key)then
    return nil;
  end
  local keyorder={key};
  local endindex,endchar=parseObject.index,parseObject.char;
  SkipWhiteSpaces(parseObject);
  if(parseObject.char~=".")then
    parseObject.index=endindex;
    parseObject.char=endchar;
    return keyorder
  end
  ContinueUTF8(parseObject);
  SkipWhiteSpaces(parseObject);
  local anothersimplekey=GetSimpleKey(parseObject);
  assert(anothersimplekey,"hi");
  table.insert(keyorder,anothersimplekey);
  --transform to dotted key
  while(true)do
    endindex,endchar=parseObject.index,parseObject.char;
    SkipWhiteSpaces(parseObject);
    if(parseObject.char~=".")then
      parseObject.index=endindex;
      parseObject.char=endchar;
      return keyorder
    end
    ContinueUTF8(parseObject);
    SkipWhiteSpaces(parseObject);
    table.insert(keyorder,GetSimpleKey(parseObject));
  end
end

---@param parseObject TOMLParseObject 
---@return boolean?
function GetBoolean(parseObject)
  local boolstring=""
  while(string.match(parseObject.char,"[A-Za-z]"))do
    boolstring=boolstring..parseObject.char;
    ContinueUTF8(parseObject);
  end;
  if(boolstring=="true")then
    return true
  elseif(boolstring=="false")then
    return false
  end
  return nil
end;

---@param parseObject TOMLParseObject 
function SkipWSCommentNewline(parseObject)
  while(true)do
    SkipWhiteSpaces(parseObject);
    local didcomment=TryComment(parseObject);
    if(IsNewLine(parseObject))then
      ContinueUTF8(parseObject);
    else
      break;
    end
  end
end;

---@param parseObject TOMLParseObject 
---@return any[]?
---@nodiscard
function GetArrayValues(parseObject)--I dont like that This is recursive in the documents
  SkipWSCommentNewline(parseObject);
  local value;
  local start,startchar=parseObject.index,parseObject.char;
  value=GetVal(parseObject);
  if(not value)then
    parseObject.index=start
    parseObject.char=startchar
    return nil;
  end
  SkipWSCommentNewline(parseObject);
  if(parseObject.char~="\x2C")then
    return  {value}
  end;
  ContinueUTF8(parseObject);
  local morevalues;
  morevalues=GetArrayValues(parseObject);
  if(morevalues)then
    return  {value,table.unpack(morevalues)}
  else
    return  {value}
  end
end;

---@param parseObject TOMLParseObject 
---@return {number:any}?
function GetArray(parseObject)
  if(parseObject.char~="[")then
    return nil
  end
  ContinueUTF8(parseObject);
  local arrayvalues
  local start,startchar=parseObject.index,parseObject.char;
  arrayvalues=GetArrayValues(parseObject);
  if(not arrayvalues)then
    parseObject.index=start;
    parseObject.char=startchar;
    arrayvalues={};
  end
  SkipWSCommentNewline(parseObject);
  assert(parseObject.char=="]","malformed array");
  ContinueUTF8(parseObject);
  return arrayvalues
end;

---@param parseObject TOMLParseObject 
---@return {number:any}?
---@nodiscard
function GetInlineTableKeyVals(parseObject);
  local keyval;
  keyval=GetKeyVal(parseObject);
  if(not keyval)then
    return nil;
  end

  local start,startchar=parseObject.index,parseObject.char;
  SkipWhiteSpaces(parseObject);
  if(parseObject.char~="\x2C")then -- ,
    parseObject.index=start;
    parseObject.char=startchar;
    return {keyval};
  end
  ContinueUTF8(parseObject);
  SkipWhiteSpaces(parseObject);
  --print(parseObject.char,keyval.key,keyval.value);
  local otherkeyvals;
  otherkeyvals=GetInlineTableKeyVals(parseObject);
  assert(otherkeyvals,"table cannot end with a comma");
  return {keyval,table.unpack(otherkeyvals)};
end;

---@param parseObject TOMLParseObject 
---@return {string:any}?
---@nodiscard
function GetInlineTable(parseObject);
  if(parseObject.char~="{")then
    return nil
  end
  ContinueUTF8(parseObject);
  SkipWhiteSpaces(parseObject);
  local keylist;
  local start,startchar=parseObject.index,parseObject.char;
  keylist=GetInlineTableKeyVals(parseObject);
  if(not keylist)then

  end;
  SkipWhiteSpaces(parseObject);
  assert(parseObject.char=="}","malformed table");
  ContinueUTF8(parseObject);
  if(not keylist)then
    return  {};
  end
  local tab={};
  for _,v in ipairs(keylist)do
    local dp=tab;
    local final=v.key[#v.key]
    v.key[#v.key]=nil;

    for _, key in ipairs(v.key)do
      if(not dp[key])then
        dp[key]=setmetatable({type=4,value={}},TOMLObject);
      end
      dp=dp[key].value;
    end;
    dp[final]=v.value;
  end
  return tab;
end

---@param parseObject TOMLParseObject 
---@return TOMLDate?
---@nodiscard
function GetFullDate(parseObject)
  local yearstr="";
  for _=1,4 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    yearstr=yearstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~="-")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local monthstr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    monthstr=monthstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~="-")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local monthdatestr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    monthdatestr=monthdatestr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  ---@type TOMLDate
  return {year=tonumber(yearstr),month=tonumber(monthstr),monthdate=tonumber(monthdatestr)}
end

---@param parseObject TOMLParseObject 
---@return TOMLTime?
---@nodiscard
function GetPartialTime(parseObject);
  local hourstr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    hourstr=hourstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~=":")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local minutestr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    minutestr=minutestr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~=":")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local secondstr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    secondstr=secondstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~=".")then
    return {hours=tonumber(hourstr),minutes=tonumber(minutestr),seconds=tonumber(secondstr)}
  end
  ContinueUTF8(parseObject);
  local secfracstr="";
  while(string.match(parseObject.char,"[0-9]"))do
    secfracstr=secfracstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  ---@type TOMLTime
  return {hours=tonumber(hourstr),minutes=tonumber(minutestr),seconds=tonumber(secondstr),secfrac=(tonumber(secfracstr)/10^#secfracstr)}
end

---@param parseObject TOMLParseObject 
---@return TOMLTimeOffset?
---@nodiscard
function GetTimeOffset(parseObject);
  if(parseObject.char=="Z" or parseObject.char=="z")then
    ContinueUTF8(parseObject);
    return {add=true,offsethour=0,offsetminute=0};
  end;
  if(parseObject.char~="+" and parseObject.char ~="-")then
    return nil
  end
  ContinueUTF8(parseObject);
  local o={}
  o.add=parseObject.char=="+"
  local hourstr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    hourstr=hourstr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  if(parseObject.char~=":")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local minutestr="";
  for _=1,2 do
    if(not string.match(parseObject.char,"[0-9]"))then
      return nil;
    end
    minutestr=minutestr..parseObject.char;
    ContinueUTF8(parseObject);
  end
  o.offsethour=tonumber(hourstr)
  o.offsetminute=tonumber(minutestr)
  return  o;
end

---@param parseObject TOMLParseObject 
---@return TOMLTime?
---@nodiscard
function GetFullTime(parseObject);
  local partialtime;
  partialtime = GetPartialTime(parseObject);
  if(not partialtime)then
    return nil;
  end
  local timeOffset
  timeOffset = GetTimeOffset(parseObject);
  if(not timeOffset)then
    return nil;
  end
  partialtime.timeoffset=timeOffset;
  return partialtime;
end

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetOffsetDateTime(parseObject);
  local fulldate
  fulldate=GetFullDate(parseObject);
  if(not fulldate)then
    return nil;
  end
  if(parseObject.char~="T" and parseObject.char~="t" and parseObject.char~=" ")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local fulltime
  fulltime=GetFullTime(parseObject);
  if(not fulltime)then
    return nil;
  end
  local DateTime={
    Date=fulldate,
    Time=fulltime
  }
  return DateTime;
end

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetLocalDateTime(parseObject);
  local fulldate
  fulldate=GetFullDate(parseObject);
  if(not fulldate)then
    return nil;
  end
  if(parseObject.char~="T" and parseObject.char~="t" and parseObject.char~=" ")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local fulltime
  fulltime=GetPartialTime(parseObject);
  if(not fulltime)then
    return nil;
  end
  local DateTime={
    Date=fulldate,
    Time=fulltime
  }
  return DateTime;
end

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetLocalDate(parseObject);
  local fulldate
  fulldate=GetFullDate(parseObject);
  if(not fulldate)then
    return nil;
  end
  local DateTime={
    Date=fulldate
  }
  return DateTime;
end

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetLocalTime(parseObject);
  local fulltime
  fulltime=GetPartialTime(parseObject);
  if(not fulltime)then
    return nil;
  end
  local DateTime={
    Time=fulltime
  }
  return DateTime;
end

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetDateTime2(parseObject);
  local start,startchar=parseObject.index,parseObject.char;
  local datetime=GetOffsetDateTime(parseObject);
  if(datetime)then
    return datetime;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  datetime=GetLocalDateTime(parseObject);
  if(datetime)then
    return datetime;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  datetime=GetLocalDate(parseObject);
  if(datetime)then
    return datetime;
  end
  parseObject.index=start;
  parseObject.char=startchar;
  datetime=GetLocalTime(parseObject);
  if(datetime)then
    return datetime;
  end
end

function IsLeapYear(year)
  return (year % 4 == 0) and ((year % 100 ~= 0) or (year % 400 ==0));
end;
local MaximumValueOfMDay={
  31,--January
  28,--February
  31,--March
  30,--April
  31,--May
  30,--June
  31,--July
  31,--August
  30,--September
  31,--October
  30,--November
  31 --December
}

---@param parseObject TOMLParseObject 
---@return TOMLDateTime?
---@nodiscard
function GetDateTime(parseObject);
  local datetime=GetDateTime2(parseObject);
  if(not datetime)then
    return nil;
  end
  local date=datetime.Date;
  if(not date)then
    return datetime;
  end
  assert(date.month<=12,"Month Date Cannot Exceed Days of Month");
  local MaxDays=MaximumValueOfMDay[date.month];
  if(date.month==02 and IsLeapYear(date.year))then
    MaxDays=29;
  end;
  assert(date.monthdate<=MaxDays,"Month Date Cannot Exceed Days of Month");
  --legit could not find table of leap seconds.
  return datetime;
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetUnsignedDecInt(parseObject);
  if(not string.match(parseObject.char,"[0-9]"))then
    return  nil
  end;
  local strint=parseObject.char;
  ContinueUTF8(parseObject);
  if(strint=="0")then
    return strint;
  end;
  if(not string.match(parseObject.char,"[0-9_]"))then
    return strint;
  end
  while(true)do
    if(string.match(parseObject.char,"[0-9]"))then
      strint=strint..parseObject.char;
      ContinueUTF8(parseObject);
    elseif(parseObject.char=="_")then
      ContinueUTF8(parseObject);
      if(not string.match(parseObject.char,"[0-9]"))then
        return nil
      end
      strint=strint..parseObject.char;
      ContinueUTF8(parseObject);
    else
      break
    end
  end
  return strint;
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetDecInt(parseObject)
  local sign=""
  if(parseObject.char=="-" or parseObject.char=="+")then
    sign=parseObject.char;
    ContinueUTF8(parseObject);
  end
  local udecint
  udecint=GetUnsignedDecInt(parseObject);
  if(not udecint)then
    return nil;
  end
  return sign..udecint;
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetZeroPrefixableInt(parseObject);
  if(not string.match(parseObject.char,"[0-9]"))then
    return  nil
  end;
  local strint=parseObject.char;
  ContinueUTF8(parseObject);
  while(true)do
    if(string.match(parseObject.char,"[0-9]"))then
      strint=strint..parseObject.char;
      ContinueUTF8(parseObject);
    elseif(parseObject.char=="_")then
      ContinueUTF8(parseObject);
      if(not string.match(parseObject.char,"[0-9]"))then
        return nil
      end
      strint=strint..parseObject.char;
      ContinueUTF8(parseObject);
    else
      break
    end
  end
  return strint;
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetFloatExpPart(parseObject)
  local expsign="";
  if(parseObject.char=="-" or parseObject.char=="+")then
    expsign=parseObject.char;
    ContinueUTF8(parseObject)
  end
  local expint
  expint=GetZeroPrefixableInt(parseObject);
  if(not expint)then
    return nil;
  end
  return expsign..expint
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetExp(parseObject)
  if(parseObject.char~="e" and parseObject.char~="E")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local floatexp;
  floatexp=GetFloatExpPart(parseObject);
  return "e"..floatexp;
end;

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetFrac(parseObject)
  if(parseObject.char~=".")then
    return nil;
  end
  ContinueUTF8(parseObject);
  local zeroprefixableint
  zeroprefixableint=GetZeroPrefixableInt(parseObject);
  return zeroprefixableint
end;

local inf=1/0;
local nan=-(0/0);

---@param parseObject TOMLParseObject 
---@return number?
---@nodiscard
function GetSpecialFloat(parseObject)
  local sign=""
  if(parseObject.char=="-" or parseObject.char=="+")then
    sign=parseObject.char;
    ContinueUTF8(parseObject)
  end
  local specialstring=""
  while(string.match(parseObject.char,"[A-Za-z]"))do
    specialstring=specialstring..parseObject.char;
    ContinueUTF8(parseObject);
  end;
  if(specialstring=="inf")then
    return ((sign=="-")and -inf or inf)
  elseif(specialstring=="nan")then
    --return ((sign=="-")and -nan or nan)
    return nan
  end
  return nil
end

---@param parseObject TOMLParseObject 
---@return number?
---@nodiscard
function GetFloat2(parseObject)
  --float int part; -> decint
  local decint
  decint=GetDecInt(parseObject);
  if(not decint)then
    return nil;
  end
  local exp;
  exp=GetExp(parseObject);
  if(exp)then
    return tonumber(decint..exp);
  end;
  local frac;
  frac=GetFrac(parseObject);
  if(not frac)then
    return nil;
  end;
  exp=GetExp(parseObject);
  if(exp)then
    return tonumber(decint.."."..frac..exp);
  end;
  return tonumber(decint.."."..frac);
end

---@param parseObject TOMLParseObject 
---@return number?
---@nodiscard
function GetFloat(parseObject)
  local start,startchar=parseObject.index,parseObject.char;
  local float;
  float=GetFloat2(parseObject);
  if(float)then
    return float
  end
  parseObject.index=start;
  parseObject.char=startchar;
  float=GetSpecialFloat(parseObject);
  if(not float)then
    return nil
  end
  return float
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetHexInt(parseObject);
  --prefix
  if(parseObject.char~="0")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="x")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(not string.match(parseObject.char,"[0-9a-fA-F]"))then
    return nil
  end
  local hexint=parseObject.char;
  ContinueUTF8(parseObject);
  while(true)do
    if(string.match(parseObject.char,"[0-9a-fA-F]"))then
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    elseif(parseObject.char=="_")then
      ContinueUTF8(parseObject);
      if(not string.match(parseObject.char,"[0-9a-fA-F]"))then
        return nil
      end
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    else
      break
    end
  end
  return hexint;
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetOctInt(parseObject);
  --prefix
  if(parseObject.char~="0")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="o")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(not string.match(parseObject.char,"[0-7]"))then
    return nil
  end
  local hexint=parseObject.char;
  ContinueUTF8(parseObject);
  while(true)do
    if(string.match(parseObject.char,"[0-7]"))then
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    elseif(parseObject.char=="_")then
      ContinueUTF8(parseObject);
      if(not string.match(parseObject.char,"[0-7]"))then
        return nil
      end
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    else
      break
    end
  end
  return hexint;
end

---@param parseObject TOMLParseObject 
---@return string?
---@nodiscard
function GetBinInt(parseObject);
  --prefix
  if(parseObject.char~="0")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="b")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(not string.match(parseObject.char,"[01]"))then
    return nil
  end
  local hexint=parseObject.char;
  ContinueUTF8(parseObject);
  while(true)do
    if(string.match(parseObject.char,"[01]"))then
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    elseif(parseObject.char=="_")then
      ContinueUTF8(parseObject);
      if(not string.match(parseObject.char,"[01]"))then
        return nil
      end
      hexint=hexint..parseObject.char;
      ContinueUTF8(parseObject);
    else
      break
    end
  end
  return hexint;
end

---@param parseObject TOMLParseObject 
---@return number?
---@nodiscard
function GetInteger(parseObject);
  local start,startchar=parseObject.index,parseObject.char;
  local int;
  int=GetDecInt(parseObject);
  if(int and int~="0")then
    return tonumber(int);
  elseif(int and (int=="0" and not string.match(parseObject.char,"[xob]")))then
    return tonumber(int);
  end
  parseObject.index=start;
  parseObject.char=startchar;
  int=GetHexInt(parseObject);
  if(int)then
    return tonumber(int,16);
  end
  parseObject.index=start;
  parseObject.char=startchar;
  int=GetOctInt(parseObject);
  if(int)then
    return tonumber(int,8);
  end
  parseObject.index=start;
  parseObject.char=startchar;
  int=GetBinInt(parseObject);
  if(int)then
    return tonumber(int,2);
  end
  return nil
end

---@param parseObject TOMLParseObject 
---@return TOMLObject?
---@nodiscard
function GetVal(parseObject);
  --return value as a type
  --getstring first
  local start=parseObject.index;
  local startchar=parseObject.char;
  local value;
  value=GetString(parseObject);
  if(value)then
    return setmetatable({["type"]=1,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetBoolean(parseObject);
  if(value~=nil)then
    return setmetatable({["type"]=2,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetArray(parseObject);
  if(value)then
    return setmetatable({["type"]=3,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetInlineTable(parseObject);
  if(value)then
    return setmetatable({["type"]=4,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetDateTime(parseObject);--well here we go
  if(value)then
    return setmetatable({["type"]=5,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetFloat(parseObject);
  if(value)then
    return setmetatable({["type"]=6,["value"]=value,inline=true},TOMLObject);
  end;
  parseObject.index=start
  parseObject.char=startchar
  value=GetInteger(parseObject);
  if(value)then
    return setmetatable({["type"]=7,["value"]=value,inline=true},TOMLObject);
  end;
  return nil;
end;

---@param parseObject TOMLParseObject 
---@return {["key"]:string[],["value"]:TOMLObject}?
function GetKeyVal(parseObject)
  local key=GetKey(parseObject);
  if(not key)then
    return nil;
  end
  --keyval-sep
  --ws %x3D ws
  SkipWhiteSpaces(parseObject);
  assert(parseObject.char=="\x3D","not an equal");
  ContinueUTF8(parseObject);
  SkipWhiteSpaces(parseObject);
  local value;
  value=GetVal(parseObject);
  assert(value,"not valid val");
  return {["key"]=key,["value"]=value};
end;

---@param parseObject TOMLParseObject 
---@return string[]?
function GetStdTable(parseObject)
  if(parseObject.char~="[")then
    return nil
  end
  ContinueUTF8(parseObject);
  local key
  SkipWhiteSpaces(parseObject);
  key=GetKey(parseObject);
  SkipWhiteSpaces(parseObject);
  if(parseObject.char~="]")then
    return nil
  end
  ContinueUTF8(parseObject);
  return key
end;

---@param parseObject TOMLParseObject 
---@return string[]?
function GetArrayTable(parseObject)
  local start,startchar=parseObject.index,parseObject.char;
  if(parseObject.char~="[")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="[")then
    parseObject.index=start
    parseObject.char=startchar;
    return nil
  end
  ContinueUTF8(parseObject);
  SkipWhiteSpaces(parseObject);

  local key=GetKey(parseObject);
  if(not key)then
    return;
  end
  SkipWhiteSpaces(parseObject);
  if(parseObject.char~="]")then
    return nil
  end
  ContinueUTF8(parseObject);
  if(parseObject.char~="]")then
    return nil
  end
  ContinueUTF8(parseObject);
  return key
end;

---@param parseObject TOMLParseObject 
---@return {type:number, key:string[]}?;
function GetTable(parseObject);
  local start,startchar=parseObject.index,parseObject.char
  local tab;
  tab=GetStdTable(parseObject);
  if(tab)then
    return {type=1,key=tab}
  end
  parseObject.index=start;
  parseObject.char=startchar;
  tab=GetArrayTable(parseObject);
  if(tab)then
    return {type=2,key=tab}
  end
  return nil
end;

---@class TOMLClass
local TOMLClass={};
TOMLClass.__index=TOMLClass;
function TOMLClass:Lua()
  local tab={};
  for key,object in pairs(self)do
    tab[key]=object:Lua();
  end
  return tab;
end

---@param TOMLString string TOML string to parse
---@return TOMLObject
function TOML.parse(TOMLString)
  local Object=setmetatable({type=4,value={}},TOMLObject);

  ---@type TOMLParseObject
  local parseObject={}
  parseObject.pos=0;
  parseObject.index=1;
  parseObject.file=TOMLString;
  parseObject.line=0;
  parseObject.lines={};
  local ParentTable=Object;
  ContinueUTF8(parseObject);

  local function doExpression()--I do not usually like local functions
    SkipWhiteSpaces(parseObject);
    ----COMMENT
    local didComment;
    didComment=TryComment(parseObject);
    if(didComment)then
      return true;
    end;
    local start,startchar=parseObject.index,parseObject.char;
    local keyval
    keyval=GetKeyVal(parseObject);
    if(keyval)then
      local ftable=ParentTable;
      local final=keyval.key[#keyval.key]
      keyval.key[#keyval.key]=nil;
      for _,v in ipairs(keyval.key)do
        if(not ftable.value[v])then
          ftable.value[v]=setmetatable({["type"]=4,["value"]={}},TOMLObject);
        end
        ftable=ftable.value[v];
      end
      ftable.value[final]=keyval.value;
      SkipWhiteSpaces(parseObject);
      TryComment(parseObject);
      return true
    end;
    parseObject.index=start;
    parseObject.char=startchar;
    local tab
    tab=GetTable(parseObject);
    if(tab)then
      local ftable=Object;
      if(tab.type==1)then
        for _,v in ipairs(tab.key)do
          if(ftable.type==3)then
            assert(not ftable.inline,"attempted to append data to inline array");
            ftable=ftable.value[#ftable.value];
          end
          assert(not ftable.inline,"attempted to append data to inline table");
          if(not ftable.value[v])then
            ftable.value[v]=setmetatable({["type"]=4,["value"]={}},TOMLObject);
          end
          ftable=ftable.value[v];
        end;
      elseif(tab.type==2)then
        local final=tab.key[#tab.key]
        tab.key[#tab.key]=nil;
        for _,v in ipairs(tab.key)do
          if(ftable.type==3)then
            assert(not ftable.inline,"attempted to append data to array");
            ftable=ftable.value[#ftable.value];
          end
          assert(not ftable.inline,"attempted to append data to inline table");
          if(not ftable.value[v])then
            ftable.value[v]=setmetatable({["type"]=4,["value"]={}},TOMLObject);
          end
          ftable=ftable.value[v];
        end;

        if(ftable.type==3)then
          assert(not ftable.inline,"attempted to append data to array");
          ftable=ftable.value[#ftable.value];
        end
        assert(not ftable.inline,"attempted to append data to inline table");
        if(not ftable.value[final])then
          ftable.value[final]=setmetatable({["type"]=3,["value"]={}},TOMLObject);
        end

        ftable=ftable.value[final];
        assert(not ftable.inline,"attempted to append data to array");
        local newtable=setmetatable({["type"]=4,["value"]={}},TOMLObject)
        --ftable.value[#ftable.value].defined=true;
        table.insert(ftable.value,newtable);
        ftable=newtable
      end;
      ParentTable=ftable;
      SkipWhiteSpaces(parseObject);
      TryComment(parseObject);
      return true;
    end;
    parseObject.index=start;
    parseObject.char=startchar;
    return true;
  end;

  --toml = expression *(newline expression);
  --get first expression 
  doExpression();
  while(IsNewLine(parseObject))do
    ContinueUTF8(parseObject);
    doExpression()
  end

  return Object;
end

return TOML
