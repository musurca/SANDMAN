--[[
---------------------------------------------------------------------------------
SANDMAN v0.1.0b by Nicholas Musurca (nick.musurca@gmail.com)
Licensed under GNU GPLv3. (https://www.gnu.org/licenses/gpl-3.0-standalone.html)
---------------------------------------------------------------------------------

How to add SANDMAN to your scenario:
1) Open the scenario in the Scenario Editor.
2) Go to Editor -> Lua Script Console
3) Paste the contents of this file into the white box, then click Run.
4) Complete the SANDMAN wizard and voila! You now have sleepy pilots.

]]--

function ForEachDo(table,a)for b=1,#table do a(table[b])end end;function ForEachDo_Break(table,a)for b=1,#table do if a(table[b])==false then break end end end;function IsIn(c,d)for e,f in pairs(d)do if c==f then return true end end;return false end;function PadDigits(g)local h=tostring(g)if#h==1 then h='0'..h end;return h end;function RStrip(i)i=string.gsub(i,"^%s*","")return string.gsub(i,"%s*$","")end;function Format(i,j)for b=1,#j do i=string.gsub(i,"[%%]["..b.."]",j[b])end;return i end;function Round(k)return tonumber(math.floor(k+0.5))end;function DictionaryEmpty(l)for m,n in pairs(l)do return false end;return true end;function String_Split(o,p)if p==nil then p="%s"end;local d={}for i in string.gmatch(o,"([^"..p.."]+)")do table.insert(d,i)end;return d end;function Input_OK(q)ScenEdit_MsgBox(q,0)end;function Input_YesNo(q)local r={['Yes']=true,['No']=false}while true do local s=ScenEdit_MsgBox(q,4)if s~='Cancel'then return r[s]end end;return false end;function Input_Number(q)while true do local n=ScenEdit_InputBox(q)if n then n=tonumber(n)if n then return n end else return nil end end end;function Input_Number_Default(q,t)local n=ScenEdit_InputBox(q)if n then n=tonumber(n)if n then return n end end;return t end;function Input_String(q)local n=ScenEdit_InputBox(q)if n then return tostring(n)end;return""end;function StoreBoolean(u,n)if n then ScenEdit_SetKeyValue(u,'Yes')else ScenEdit_SetKeyValue(u,'No')end end;function GetBoolean(u)local n=ScenEdit_GetKeyValue(u)if n then if n=='Yes'then return true end end;return false end;function StoreString(u,n)ScenEdit_SetKeyValue(u,n)end;function GetString(u)return ScenEdit_GetKeyValue(u)end;function StoreNumber(u,n)ScenEdit_SetKeyValue(u,tostring(n))end;function GetNumber(u)local n=tonumber(ScenEdit_GetKeyValue(u))if n then return n end;return 0 end;function StoreArrayString(u,v)local w=""for b=1,#v-1 do w=w..tostring(v[b]).."∧"end;w=w..tostring(v[#v])StoreString(u,w)end;function GetArrayString(u)return String_Split(GetString(u),"∧")end;function StoreArrayNumber(u,v)local w=""for b=1,#v-1 do w=w..tostring(v[b]).."∧"end;w=w..tostring(v[#v])StoreString(u,w)end;function GetArrayNumber(u)local v=String_Split(GetString(u),"∧")for b=1,#v do v[b]=tonumber(v[b])end;return v end;DEFAULT_CRASH_INCIDENCE=3.5;DEFAULT_PARKED_PERCENTAGE=1/2;DEFAULT_READYING_PERCENTAGE=1/6;DEFAULT_MIN_HOURS_AWAKE=4;DEFAULT_MAX_HOURS_AWAKE=12;function Sandman_RefreshSettings()CRASH_INCIDENCE=GetNumber("SANDMAN_DEF_CRASH_INCID")PARKED_PERCENTAGE=GetNumber("SANDMAN_DEF_PARKED_PERC")READYING_PERCENTAGE=GetNumber("SANDMAN_DEF_READYING_PERC")MIN_HOURS_AWAKE=GetNumber("SANDMAN_DEF_MIN_HRS")MAX_HOURS_AWAKE=GetNumber("SANDMAN_DEF_MAX_HRS")end;function Sandman_UseDefaults()MIN_HOURS_AWAKE=DEFAULT_MIN_HOURS_AWAKE;MAX_HOURS_AWAKE=DEFAULT_MAX_HOURS_AWAKE;CRASH_INCIDENCE=DEFAULT_CRASH_INCIDENCE;PARKED_PERCENTAGE=DEFAULT_PARKED_PERCENTAGE;READYING_PERCENTAGE=DEFAULT_READYING_PERCENTAGE;StoreNumber("SANDMAN_DEF_CRASH_INCID",CRASH_INCIDENCE)StoreNumber("SANDMAN_DEF_PARKED_PERC",PARKED_PERCENTAGE)StoreNumber("SANDMAN_DEF_READYING_PERC",READYING_PERCENTAGE)StoreNumber("SANDMAN_DEF_MIN_HRS",MIN_HOURS_AWAKE)StoreNumber("SANDMAN_DEF_MAX_HRS",MAX_HOURS_AWAKE)end;function Sandman_InputDefaults()MIN_HOURS_AWAKE=-1;MAX_HOURS_AWAKE=-1;CRASH_INCIDENCE=-1;repeat MIN_HOURS_AWAKE=Input_Number_Default("Enter the MINIMUM number of hours a pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MIN_HOURS_AWAKE,DEFAULT_MIN_HOURS_AWAKE)until MIN_HOURS_AWAKE>=0;repeat MAX_HOURS_AWAKE=Input_Number_Default("Enter the MAXIMUM number of hours a pilot may have been awake at the start of the scenario.\n\nDEFAULT: "..DEFAULT_MAX_HOURS_AWAKE,DEFAULT_MAX_HOURS_AWAKE)until MAX_HOURS_AWAKE>=0;repeat CRASH_INCIDENCE=Input_Number_Default("Enter the NORMAL number of crashes an airforce may experience in 100,000 flight hours.\n\nDEFAULT: "..DEFAULT_CRASH_INCIDENCE,DEFAULT_CRASH_INCIDENCE)until CRASH_INCIDENCE>=0;CRASH_INCIDENCE=CRASH_INCIDENCE/100000;PARKED_PERCENTAGE=DEFAULT_PARKED_PERCENTAGE;READYING_PERCENTAGE=DEFAULT_READYING_PERCENTAGE;StoreNumber("SANDMAN_DEF_CRASH_INCID",CRASH_INCIDENCE)StoreNumber("SANDMAN_DEF_PARKED_PERC",PARKED_PERCENTAGE)StoreNumber("SANDMAN_DEF_READYING_PERC",READYING_PERCENTAGE)StoreNumber("SANDMAN_DEF_MIN_HRS",MIN_HOURS_AWAKE)StoreNumber("SANDMAN_DEF_MAX_HRS",MAX_HOURS_AWAKE)end;Sandman_RefreshSettings()SLEEP_RESERVOIR_CAPACITY=2880;SLEEP_UNITS_LOST_MIN=0.5;UNIT_PROFICIENCIES={"Novice","Cadet","Regular","Veteran","Ace"}UNIT_RESTSTATES={"⇓","","⇑","⇑⇑"}STATE_AWAKE=1;STATE_REST_NONE=2;STATE_REST_LIGHT=3;STATE_REST_HEAVY=4;function RestStateByCondition(x,y)if x=="Parked"then if y>-0.05 then return STATE_REST_LIGHT else return STATE_REST_HEAVY end elseif string.find(x,"Readying")then if y>-0.05 then return STATE_REST_NONE else return STATE_REST_LIGHT end end;return STATE_AWAKE end;function ProfByEffectiveness(z,A)return tonumber(math.floor((0.25+z-1)*A+1))end;function ProfNumberByName(B)for b,f in ipairs(UNIT_PROFICIENCIES)do if B==f then return b end end;return 1 end;function ProfNameByNumber(C)return UNIT_PROFICIENCIES[C]end;function RandomSleepDeficit()local D=math.random()*math.random()local E=MIN_HOURS_AWAKE+D*(MAX_HOURS_AWAKE-MIN_HOURS_AWAKE)return SLEEP_UNITS_LOST_MIN*60*E end;function CircadianTerm()local F=ScenEdit_CurrentLocalTime()local G=tonumber(string.sub(F,1,2))local H=tonumber(string.sub(F,4,5))local d=G+H/60;local I=math.cos(2*math.pi*(d-18)/24)+0.5*math.cos(4*math.pi*(d-21)/24)return I end;function EffectivenessScore(J,y)local I=y*(0.07+0.05*(SLEEP_RESERVOIR_CAPACITY-J)/SLEEP_RESERVOIR_CAPACITY)return J/SLEEP_RESERVOIR_CAPACITY+I end;function RestorativeSleep(K,J,y)local L=K/60;local M=L*-0.55*y;return M+L*(SLEEP_RESERVOIR_CAPACITY-J)*0.0026564 end;function CrashRisk(K,N,O)local L=K/3600;local P=(1-N)*100;local Q=1+P*P/39.0625;local R=ScenEdit_GetTimeOfDay({lat=O.latitude,lon=O.longitude})if R.tod>0 then if O.type=="Facility"then Q=Q*2 elseif O.type=="Ship"then Q=Q*5 end end;if O.type=="Ship"then local S=ScenEdit_GetWeather()Q=Q+Q*4*(S.seastate-9)/9 end;return math.min(0.95,Q*CRASH_INCIDENCE*L)end;function MicroNapRisk(K,N,y)local T=1-N;local U=1;if y<0 then U=U+-2*y else U=1/(1+2*y/1.2999)end;return K*U*T*T*T/600 end;function Sandman_Init()local V={}for m,W in ipairs(VP_GetSides())do for k,X in ipairs(W.units)do local Y=ScenEdit_GetUnit({guid=X.guid})if Y.type=="Aircraft"then table.insert(V,X.guid)end end end;local y=CircadianTerm()local Z={}local _={}local a0={}local a1={}local a2={}local a3={}for m,f in ipairs(V)do local a4=ScenEdit_GetUnit({guid=f})_[m]=SLEEP_RESERVOIR_CAPACITY-RandomSleepDeficit()-SLEEP_UNITS_LOST_MIN*a4.airbornetime_v/60;Z[m]=ProfNumberByName(a4.proficiency)a0[m]=EffectivenessScore(_[m],y)a1[m]=RestStateByCondition(a4.condition_v,y)a2[m]=0;a3[m]=0;local a5=ProfNameByNumber(ProfByEffectiveness(Z[m],a0[m]))if a4.proficiency~=a5 then ScenEdit_SetUnit({guid=f,proficiency=a5})end end;StoreArrayString("UNIT_TRACKER_GUIDS",V)StoreArrayNumber("UNIT_TRACKER_BASE_PROFS",Z)StoreArrayNumber("UNIT_TRACKER_SLEEPRES",_)StoreArrayNumber("UNIT_TRACKER_EFFECT",a0)StoreArrayNumber("UNIT_TRACKER_RESTSTATE",a1)StoreArrayNumber("UNIT_TRACKER_BOLTER",a2)StoreArrayNumber("UNIT_TRACKER_MICRONAP",a3)StoreBoolean("UNIT_TRACKER_INITIALIZED",true)end;function Sandman_CheckInit()if GetBoolean("UNIT_TRACKER_INITIALIZED")==false then Sandman_Init()end end;function Sandman_Display(a6)Sandman_CheckInit()local a7={"UNIT DESIGNATION","SKILL","EFFECTIVENESS"}local a8="<table cellSpacing=1 cols="..#a7 .." cellPadding=1 width=\"95%\" border=2><tbody>"a8=a8 .."<tr>"for m,a9 in ipairs(a7)do a8=a8 .."<td><b>"..a9 .."</b></td>"end;a8=a8 .."</tr>"local aa="</tbody></table>"local ab=""local V=GetArrayString("UNIT_TRACKER_GUIDS")local Z=GetArrayNumber("UNIT_TRACKER_BASE_PROFS")local a0=GetArrayNumber("UNIT_TRACKER_EFFECT")local a1=GetArrayNumber("UNIT_TRACKER_RESTSTATE")local function ac()ab=ab..a8 end;local function ad()ab=ab..aa end;local function ae()ab=ab.."<tr>"end;local function af()ab=ab.."</tr>"end;local function ag(ah)ab=ab.."<td>"..ah.."</td>"end;local ai={}local aj=ScenEdit_PlayerSide()local function ak(al)if a6 then for m,am in ipairs(a6)do if al==am then return true end end;return false end;return true end;local an=0;for m,u in ipairs(V)do local e,X=pcall(ScenEdit_GetUnit,{guid=u})if X and ak(u)then if X.side==aj and X.loadoutdbid~=4 then an=an+1;local ao=X.condition_v;local ap=ai[ao]if ap==nil then ap={}ai[ao]=ap end;local aq;if X.group~=nil then aq=X.group.name elseif X.base~=nil then aq=X.base.name else aq="Unassigned"end;local ar=ap[aq]if ar==nil then ar={}ap[aq]=ar end;local as=ar[X.classname]if as==nil then as={}ar[X.classname]=as end;as[tostring(m)]=X end end end;if an==0 then Input_OK("No valid units selected!")return end;local function at(au,av)ab=ab.."<hr><center><h2>"..string.upper(au).."</h2></center><hr>"for aw,ar in pairs(av)do ab=ab.."<center><p><h2><u>"..aw.."</u></h2></p></center>"for ax,as in pairs(ar)do if not DictionaryEmpty(as)then ab=ab.."<b>"..ax.."</b>"ac()for k,X in pairs(as)do local m=tonumber(k)ae()ag(X.name)ag(ProfNameByNumber(Z[m]))local ay=UNIT_RESTSTATES[a1[m]]ag("<center>"..Round(a0[m]*100).."% "..ay.."</center>")af()end;ad()ab=ab.."<br/>"end end end;ab=ab.."<hr><br/>"end;for az,ap in pairs(ai)do if az~="Parked"then at(az,ap)end end;if ai["Parked"]~=nil then at("Parked",ai["Parked"])end;ScenEdit_SpecialMessage("playerside",ab)local aA=ScenEdit_GetKeyValue("__SCEN_SETUPPHASE")if aA~=""then if PBEM_FlushSpecialMessages then PBEM_FlushSpecialMessages()end end end;function Sandman_DisplaySelected()Sandman_CheckInit()local aB={}local Y=ScenEdit_SelectedUnits()if Y then for m,X in ipairs(Y.units)do table.insert(aB,X.guid)end end;if#aB>0 then Sandman_Display(aB)else Input_OK("No units selected!")end end;function Sandman_Update(K)Sandman_CheckInit()local V=GetArrayString("UNIT_TRACKER_GUIDS")local Z=GetArrayNumber("UNIT_TRACKER_BASE_PROFS")local _=GetArrayNumber("UNIT_TRACKER_SLEEPRES")local a0=GetArrayNumber("UNIT_TRACKER_EFFECT")local a1=GetArrayNumber("UNIT_TRACKER_RESTSTATE")local a2=GetArrayNumber("UNIT_TRACKER_BOLTER")local a3=GetArrayNumber("UNIT_TRACKER_MICRONAP")local y=CircadianTerm()for m,u in ipairs(V)do local e,X=pcall(ScenEdit_GetUnit,{guid=u})if X then if X.loadoutdbid~=4 then local aC=0;local J=_[m]if X.condition_v=="Parked"then aC=K*PARKED_PERCENTAGE elseif string.find(X.condition_v,"Readying")~=nil then aC=K*READYING_PERCENTAGE end;local aD=K-aC;local aE=0;if aC>0 then aE=RestorativeSleep(aC,J,y)end;local aF=SLEEP_UNITS_LOST_MIN*aD/60;J=J+aE-aF;J=math.min(SLEEP_RESERVOIR_CAPACITY,math.max(0,J))_[m]=J;a1[m]=RestStateByCondition(X.condition_v,y)local aG=Z[m]local aH=EffectivenessScore(J,y)a0[m]=aH;local aI=ProfByEffectiveness(aG,aH)local aJ=ProfNameByNumber(aI)if X.proficiency~=aJ then pcall(ScenEdit_SetUnit,{guid=X.guid,proficiency=aJ})end;local function aK(Y,aL)local al=Y.guid;local aM=Y.course;local aN=not aL;if aL then local aO=World_GetPointFromBearing({latitude=Y.latitude,longitude=Y.longitude,distance=500,bearing=Y.heading})table.insert(aM,1,{latitude=aO.latitude,longitude=aO.longitude})else table.remove(aM,1)end;pcall(ScenEdit_SetUnit,{guid=al,course=aM,outofcomms=aL,AI_EvaluateTargets_enabled=aN,AI_DeterminePrimaryTarget_enabled=aN})end;if X.airbornetime_v>0 then local aP=math.random()local aQ=MicroNapRisk(K,aH,y)if a3[m]==1 then if aP*2>aQ then aK(X,false)a3[m]=0 end else if aP<=aQ then aK(X,true)a3[m]=1 end end else if a3[m]==1 then aK(X,false)a3[m]=0 end end;if a2[m]==1 then X:RTB(true)a2[m]=0 end;if X.condition=="On final approach"or X.condition=="In landing queue"then if X.base then local aR=CrashRisk(K,aH,X.base)local aP=math.random()if aP<=aR then local aS="at"if X.base.type=="Ship"then aS="on"end;local aT=X.name.." crashed while attempting to land "..aS.." "..X.base.name.."."ScenEdit_SpecialMessage(X.side,aT,{latitude=X.latitude,longitude=X.longitude})ScenEdit_KillUnit({guid=X.guid})else if aP*100<=aR then X:RTB(false)a2[m]=1 end end end end end end end;StoreArrayNumber("UNIT_TRACKER_SLEEPRES",_)StoreArrayNumber("UNIT_TRACKER_EFFECT",a0)StoreArrayNumber("UNIT_TRACKER_RESTSTATE",a1)StoreArrayNumber("UNIT_TRACKER_BOLTER",a2)StoreArrayNumber("UNIT_TRACKER_MICRONAP",a3)end;function Side_Exists(aU)for m,W in ipairs(VP_GetSides())do if W.name==aU then return true end end;return false end;function Event_Exists(aV)local aW=ScenEdit_GetEvents()for b=1,#aW do local aX=aW[b]if aX.details.description==aV then return true end end;return false end;function Event_Delete(aV,aY)aY=aY or false;if aY then ForEachDo_Break(ScenEdit_GetEvents(),function(aX)if aX.details.description==aV then ForEachDo(aX.details.triggers,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveTrigger(aV,n.Description)Trigger_Delete(n.Description)end end end)ForEachDo(aX.details.conditions,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveCondition(aV,n.Description)Condition_Delete(n.Description)end end end)ForEachDo(aX.details.actions,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveAction(aV,n.Description)Action_Delete(n.Description)end end end)return false end;return true end)end;pcall(ScenEdit_SetEvent,aV,{mode="remove"})end;function Event_Create(aV,b0)ForEachDo(ScenEdit_GetEvents(),function(aX)if aX.details.description==aV then pcall(ScenEdit_SetEvent,aV,{mode="remove"})end end)b0.mode="add"pcall(ScenEdit_SetEvent,aV,b0)return aV end;function Event_AddTrigger(b1,b2)pcall(ScenEdit_SetEventTrigger,b1,{mode='add',name=b2})end;function Event_RemoveTrigger(b1,b2)pcall(ScenEdit_SetEventTrigger,b1,{mode='remove',name=b2})end;function Event_AddCondition(b1,b3)pcall(ScenEdit_SetEventCondition,b1,{mode='add',name=b3})end;function Event_RemoveCondition(b1,b3)pcall(ScenEdit_SetEventCondition,b1,{mode='remove',name=b3})end;function Event_AddAction(b1,b4)pcall(ScenEdit_SetEventAction,b1,{mode='add',name=b4})end;function Event_RemoveAction(b1,b4)pcall(ScenEdit_SetEventAction,b1,{mode='remove',name=b4})end;function Trigger_Create(b5,b0)b0.name=b5;b0.mode="add"pcall(ScenEdit_SetTrigger,b0)return b5 end;function Trigger_Delete(b5)pcall(ScenEdit_SetTrigger,{name=b5,mode="remove"})end;function Condition_Create(b6,b0)b0.name=b6;b0.mode="add"pcall(ScenEdit_SetCondition,b0)return b6 end;function Condition_Delete(b6)pcall(ScenEdit_SetCondition,{name=b6,mode="remove"})end;function Action_Create(b7,b0)b0.name=b7;b0.mode="add"pcall(ScenEdit_SetAction,b0)return b7 end;function Action_Delete(b7)pcall(ScenEdit_SetAction,{name=b7,mode="remove"})end;function SpecialAction_Create(b7,b8,W,b9)local ba=pcall(ScenEdit_AddSpecialAction,{ActionNameOrID=b7,Description=b8,Side=W,IsActive=true,IsRepeatable=true,ScriptText=b9})if ba==true then return b7 end;return""end;function SpecialAction_Delete(b7,W)pcall(ScenEdit_SetSpecialAction,{ActionNameOrID=b7,Side=W,mode="remove"})end;SANDMAN_VERSION="0.1.0"function Sandman_Wizard()if Event_Exists("SANDMAN: Scenario Loaded")then Event_Delete("SANDMAN: Scenario Loaded",true)ForEachDo(VP_GetSides(),function(W)local bb=W.name;SpecialAction_Delete("Fatigue Avoidance Scheduling Tool (All Pilots)",bb)SpecialAction_Delete("Fatigue Avoidance Scheduling Tool (Selected Pilots)",bb)end)end;if Event_Exists("SANDMAN: Update Tick")then Event_Delete("SANDMAN: Update Tick",true)end;local bc=Event_Create("SANDMAN: Scenario Loaded",{IsRepeatable=true,IsShown=false})Event_AddTrigger(bc,Trigger_Create("PBEM_Scenario_Loaded",{type="ScenLoaded"}))Event_AddAction(bc,Action_Create("SANDMAN: Load Library",{type="LuaScript",ScriptText=SANDMAN_LOADER}))local bd=Event_Create("SANDMAN: Update Tick",{IsRepeatable=true,IsShown=false})Event_AddTrigger(bd,Trigger_Create("SANDMAN_Update_Tick",{type="RegularTime",interval=4}))Event_AddAction(bd,Action_Create("SANDMAN: Next Update",{type="LuaScript",ScriptText="Sandman_Update(60)"}))ForEachDo(VP_GetSides(),function(W)local bb=W.name;SpecialAction_Create("Fatigue Avoidance Scheduling Tool (All Pilots)","Shows the current effectiveness state for all of your pilots.",bb,"Sandman_Display()")SpecialAction_Create("Fatigue Avoidance Scheduling Tool (Selected Pilots)","Shows the current effectiveness state for the currently selected aircraft.",bb,"Sandman_DisplaySelected()")end)if Input_YesNo("Thanks for using SANDMAN, the fatigue modeling system for CMO. Do you want to use the suggested values?")then Sandman_UseDefaults()else Sandman_InputDefaults()end;Input_OK("SANDMAN v"..SANDMAN_VERSION.." has been installed into this scenario!")end;SANDMAN_LOADER="function ForEachDo(table,a)for b=1,#table do a(table[b])end end;function ForEachDo_Break(table,a)for b=1,#table do if a(table[b])==false then break end end end;function IsIn(c,d)for e,f in pairs(d)do if c==f then return true end end;return false end;function PadDigits(g)local h=tostring(g)if#h==1 then h='0'..h end;return h end;function RStrip(i)i=string.gsub(i,\"^%s*\",\"\")return string.gsub(i,\"%s*$\",\"\")end;function Format(i,j)for b=1,#j do i=string.gsub(i,\"[%%][\"..b..\"]\",j[b])end;return i end;function Round(k)return tonumber(math.floor(k+0.5))end;function DictionaryEmpty(l)for m,n in pairs(l)do return false end;return true end;function String_Split(o,p)if p==nil then p=\"%s\"end;local d={}for i in string.gmatch(o,\"([^\"..p..\"]+)\")do table.insert(d,i)end;return d end;function Input_OK(q)ScenEdit_MsgBox(q,0)end;function Input_YesNo(q)local r={['Yes']=true,['No']=false}while true do local s=ScenEdit_MsgBox(q,4)if s~='Cancel'then return r[s]end end;return false end;function Input_Number(q)while true do local n=ScenEdit_InputBox(q)if n then n=tonumber(n)if n then return n end else return nil end end end;function Input_Number_Default(q,t)local n=ScenEdit_InputBox(q)if n then n=tonumber(n)if n then return n end end;return t end;function Input_String(q)local n=ScenEdit_InputBox(q)if n then return tostring(n)end;return\"\"end;function StoreBoolean(u,n)if n then ScenEdit_SetKeyValue(u,'Yes')else ScenEdit_SetKeyValue(u,'No')end end;function GetBoolean(u)local n=ScenEdit_GetKeyValue(u)if n then if n=='Yes'then return true end end;return false end;function StoreString(u,n)ScenEdit_SetKeyValue(u,n)end;function GetString(u)return ScenEdit_GetKeyValue(u)end;function StoreNumber(u,n)ScenEdit_SetKeyValue(u,tostring(n))end;function GetNumber(u)local n=tonumber(ScenEdit_GetKeyValue(u))if n then return n end;return 0 end;function StoreArrayString(u,v)local w=\"\"for b=1,#v-1 do w=w..tostring(v[b])..\"∧\"end;w=w..tostring(v[#v])StoreString(u,w)end;function GetArrayString(u)return String_Split(GetString(u),\"∧\")end;function StoreArrayNumber(u,v)local w=\"\"for b=1,#v-1 do w=w..tostring(v[b])..\"∧\"end;w=w..tostring(v[#v])StoreString(u,w)end;function GetArrayNumber(u)local v=String_Split(GetString(u),\"∧\")for b=1,#v do v[b]=tonumber(v[b])end;return v end;DEFAULT_CRASH_INCIDENCE=3.5;DEFAULT_PARKED_PERCENTAGE=1/2;DEFAULT_READYING_PERCENTAGE=1/6;DEFAULT_MIN_HOURS_AWAKE=4;DEFAULT_MAX_HOURS_AWAKE=12;function Sandman_RefreshSettings()CRASH_INCIDENCE=GetNumber(\"SANDMAN_DEF_CRASH_INCID\")PARKED_PERCENTAGE=GetNumber(\"SANDMAN_DEF_PARKED_PERC\")READYING_PERCENTAGE=GetNumber(\"SANDMAN_DEF_READYING_PERC\")MIN_HOURS_AWAKE=GetNumber(\"SANDMAN_DEF_MIN_HRS\")MAX_HOURS_AWAKE=GetNumber(\"SANDMAN_DEF_MAX_HRS\")end;function Sandman_UseDefaults()MIN_HOURS_AWAKE=DEFAULT_MIN_HOURS_AWAKE;MAX_HOURS_AWAKE=DEFAULT_MAX_HOURS_AWAKE;CRASH_INCIDENCE=DEFAULT_CRASH_INCIDENCE;PARKED_PERCENTAGE=DEFAULT_PARKED_PERCENTAGE;READYING_PERCENTAGE=DEFAULT_READYING_PERCENTAGE;StoreNumber(\"SANDMAN_DEF_CRASH_INCID\",CRASH_INCIDENCE)StoreNumber(\"SANDMAN_DEF_PARKED_PERC\",PARKED_PERCENTAGE)StoreNumber(\"SANDMAN_DEF_READYING_PERC\",READYING_PERCENTAGE)StoreNumber(\"SANDMAN_DEF_MIN_HRS\",MIN_HOURS_AWAKE)StoreNumber(\"SANDMAN_DEF_MAX_HRS\",MAX_HOURS_AWAKE)end;function Sandman_InputDefaults()MIN_HOURS_AWAKE=-1;MAX_HOURS_AWAKE=-1;CRASH_INCIDENCE=-1;repeat MIN_HOURS_AWAKE=Input_Number_Default(\"Enter the MINIMUM number of hours a pilot may have been awake at the start of the scenario.\\n\\nDEFAULT: \"..DEFAULT_MIN_HOURS_AWAKE,DEFAULT_MIN_HOURS_AWAKE)until MIN_HOURS_AWAKE>=0;repeat MAX_HOURS_AWAKE=Input_Number_Default(\"Enter the MAXIMUM number of hours a pilot may have been awake at the start of the scenario.\\n\\nDEFAULT: \"..DEFAULT_MAX_HOURS_AWAKE,DEFAULT_MAX_HOURS_AWAKE)until MAX_HOURS_AWAKE>=0;repeat CRASH_INCIDENCE=Input_Number_Default(\"Enter the NORMAL number of crashes an airforce may experience in 100,000 flight hours.\\n\\nDEFAULT: \"..DEFAULT_CRASH_INCIDENCE,DEFAULT_CRASH_INCIDENCE)until CRASH_INCIDENCE>=0;CRASH_INCIDENCE=CRASH_INCIDENCE/100000;PARKED_PERCENTAGE=DEFAULT_PARKED_PERCENTAGE;READYING_PERCENTAGE=DEFAULT_READYING_PERCENTAGE;StoreNumber(\"SANDMAN_DEF_CRASH_INCID\",CRASH_INCIDENCE)StoreNumber(\"SANDMAN_DEF_PARKED_PERC\",PARKED_PERCENTAGE)StoreNumber(\"SANDMAN_DEF_READYING_PERC\",READYING_PERCENTAGE)StoreNumber(\"SANDMAN_DEF_MIN_HRS\",MIN_HOURS_AWAKE)StoreNumber(\"SANDMAN_DEF_MAX_HRS\",MAX_HOURS_AWAKE)end;Sandman_RefreshSettings()SLEEP_RESERVOIR_CAPACITY=2880;SLEEP_UNITS_LOST_MIN=0.5;UNIT_PROFICIENCIES={\"Novice\",\"Cadet\",\"Regular\",\"Veteran\",\"Ace\"}UNIT_RESTSTATES={\"⇓\",\"\",\"⇑\",\"⇑⇑\"}STATE_AWAKE=1;STATE_REST_NONE=2;STATE_REST_LIGHT=3;STATE_REST_HEAVY=4;function RestStateByCondition(x,y)if x==\"Parked\"then if y>-0.05 then return STATE_REST_LIGHT else return STATE_REST_HEAVY end elseif string.find(x,\"Readying\")then if y>-0.05 then return STATE_REST_NONE else return STATE_REST_LIGHT end end;return STATE_AWAKE end;function ProfByEffectiveness(z,A)return tonumber(math.floor((0.25+z-1)*A+1))end;function ProfNumberByName(B)for b,f in ipairs(UNIT_PROFICIENCIES)do if B==f then return b end end;return 1 end;function ProfNameByNumber(C)return UNIT_PROFICIENCIES[C]end;function RandomSleepDeficit()local D=math.random()*math.random()local E=MIN_HOURS_AWAKE+D*(MAX_HOURS_AWAKE-MIN_HOURS_AWAKE)return SLEEP_UNITS_LOST_MIN*60*E end;function CircadianTerm()local F=ScenEdit_CurrentLocalTime()local G=tonumber(string.sub(F,1,2))local H=tonumber(string.sub(F,4,5))local d=G+H/60;local I=math.cos(2*math.pi*(d-18)/24)+0.5*math.cos(4*math.pi*(d-21)/24)return I end;function EffectivenessScore(J,y)local I=y*(0.07+0.05*(SLEEP_RESERVOIR_CAPACITY-J)/SLEEP_RESERVOIR_CAPACITY)return J/SLEEP_RESERVOIR_CAPACITY+I end;function RestorativeSleep(K,J,y)local L=K/60;local M=L*-0.55*y;return M+L*(SLEEP_RESERVOIR_CAPACITY-J)*0.0026564 end;function CrashRisk(K,N,O)local L=K/3600;local P=(1-N)*100;local Q=1+P*P/39.0625;local R=ScenEdit_GetTimeOfDay({lat=O.latitude,lon=O.longitude})if R.tod>0 then if O.type==\"Facility\"then Q=Q*2 elseif O.type==\"Ship\"then Q=Q*5 end end;if O.type==\"Ship\"then local S=ScenEdit_GetWeather()Q=Q+Q*4*(S.seastate-9)/9 end;return math.min(0.95,Q*CRASH_INCIDENCE*L)end;function MicroNapRisk(K,N,y)local T=1-N;local U=1;if y<0 then U=U+-2*y else U=1/(1+2*y/1.2999)end;return K*U*T*T*T/600 end;function Sandman_Init()local V={}for m,W in ipairs(VP_GetSides())do for k,X in ipairs(W.units)do local Y=ScenEdit_GetUnit({guid=X.guid})if Y.type==\"Aircraft\"then table.insert(V,X.guid)end end end;local y=CircadianTerm()local Z={}local _={}local a0={}local a1={}local a2={}local a3={}for m,f in ipairs(V)do local a4=ScenEdit_GetUnit({guid=f})_[m]=SLEEP_RESERVOIR_CAPACITY-RandomSleepDeficit()-SLEEP_UNITS_LOST_MIN*a4.airbornetime_v/60;Z[m]=ProfNumberByName(a4.proficiency)a0[m]=EffectivenessScore(_[m],y)a1[m]=RestStateByCondition(a4.condition_v,y)a2[m]=0;a3[m]=0;local a5=ProfNameByNumber(ProfByEffectiveness(Z[m],a0[m]))if a4.proficiency~=a5 then ScenEdit_SetUnit({guid=f,proficiency=a5})end end;StoreArrayString(\"UNIT_TRACKER_GUIDS\",V)StoreArrayNumber(\"UNIT_TRACKER_BASE_PROFS\",Z)StoreArrayNumber(\"UNIT_TRACKER_SLEEPRES\",_)StoreArrayNumber(\"UNIT_TRACKER_EFFECT\",a0)StoreArrayNumber(\"UNIT_TRACKER_RESTSTATE\",a1)StoreArrayNumber(\"UNIT_TRACKER_BOLTER\",a2)StoreArrayNumber(\"UNIT_TRACKER_MICRONAP\",a3)StoreBoolean(\"UNIT_TRACKER_INITIALIZED\",true)end;function Sandman_CheckInit()if GetBoolean(\"UNIT_TRACKER_INITIALIZED\")==false then Sandman_Init()end end;function Sandman_Display(a6)Sandman_CheckInit()local a7={\"UNIT DESIGNATION\",\"SKILL\",\"EFFECTIVENESS\"}local a8=\"<table cellSpacing=1 cols=\"..#a7 ..\" cellPadding=1 width=\\\"95%\\\" border=2><tbody>\"a8=a8 ..\"<tr>\"for m,a9 in ipairs(a7)do a8=a8 ..\"<td><b>\"..a9 ..\"</b></td>\"end;a8=a8 ..\"</tr>\"local aa=\"</tbody></table>\"local ab=\"\"local V=GetArrayString(\"UNIT_TRACKER_GUIDS\")local Z=GetArrayNumber(\"UNIT_TRACKER_BASE_PROFS\")local a0=GetArrayNumber(\"UNIT_TRACKER_EFFECT\")local a1=GetArrayNumber(\"UNIT_TRACKER_RESTSTATE\")local function ac()ab=ab..a8 end;local function ad()ab=ab..aa end;local function ae()ab=ab..\"<tr>\"end;local function af()ab=ab..\"</tr>\"end;local function ag(ah)ab=ab..\"<td>\"..ah..\"</td>\"end;local ai={}local aj=ScenEdit_PlayerSide()local function ak(al)if a6 then for m,am in ipairs(a6)do if al==am then return true end end;return false end;return true end;local an=0;for m,u in ipairs(V)do local e,X=pcall(ScenEdit_GetUnit,{guid=u})if X and ak(u)then if X.side==aj and X.loadoutdbid~=4 then an=an+1;local ao=X.condition_v;local ap=ai[ao]if ap==nil then ap={}ai[ao]=ap end;local aq;if X.group~=nil then aq=X.group.name elseif X.base~=nil then aq=X.base.name else aq=\"Unassigned\"end;local ar=ap[aq]if ar==nil then ar={}ap[aq]=ar end;local as=ar[X.classname]if as==nil then as={}ar[X.classname]=as end;as[tostring(m)]=X end end end;if an==0 then Input_OK(\"No valid units selected!\")return end;local function at(au,av)ab=ab..\"<hr><center><h2>\"..string.upper(au)..\"</h2></center><hr>\"for aw,ar in pairs(av)do ab=ab..\"<center><p><h2><u>\"..aw..\"</u></h2></p></center>\"for ax,as in pairs(ar)do if not DictionaryEmpty(as)then ab=ab..\"<b>\"..ax..\"</b>\"ac()for k,X in pairs(as)do local m=tonumber(k)ae()ag(X.name)ag(ProfNameByNumber(Z[m]))local ay=UNIT_RESTSTATES[a1[m]]ag(\"<center>\"..Round(a0[m]*100)..\"% \"..ay..\"</center>\")af()end;ad()ab=ab..\"<br/>\"end end end;ab=ab..\"<hr><br/>\"end;for az,ap in pairs(ai)do if az~=\"Parked\"then at(az,ap)end end;if ai[\"Parked\"]~=nil then at(\"Parked\",ai[\"Parked\"])end;ScenEdit_SpecialMessage(\"playerside\",ab)local aA=ScenEdit_GetKeyValue(\"__SCEN_SETUPPHASE\")if aA~=\"\"then if PBEM_FlushSpecialMessages then PBEM_FlushSpecialMessages()end end end;function Sandman_DisplaySelected()Sandman_CheckInit()local aB={}local Y=ScenEdit_SelectedUnits()if Y then for m,X in ipairs(Y.units)do table.insert(aB,X.guid)end end;if#aB>0 then Sandman_Display(aB)else Input_OK(\"No units selected!\")end end;function Sandman_Update(K)Sandman_CheckInit()local V=GetArrayString(\"UNIT_TRACKER_GUIDS\")local Z=GetArrayNumber(\"UNIT_TRACKER_BASE_PROFS\")local _=GetArrayNumber(\"UNIT_TRACKER_SLEEPRES\")local a0=GetArrayNumber(\"UNIT_TRACKER_EFFECT\")local a1=GetArrayNumber(\"UNIT_TRACKER_RESTSTATE\")local a2=GetArrayNumber(\"UNIT_TRACKER_BOLTER\")local a3=GetArrayNumber(\"UNIT_TRACKER_MICRONAP\")local y=CircadianTerm()for m,u in ipairs(V)do local e,X=pcall(ScenEdit_GetUnit,{guid=u})if X then if X.loadoutdbid~=4 then local aC=0;local J=_[m]if X.condition_v==\"Parked\"then aC=K*PARKED_PERCENTAGE elseif string.find(X.condition_v,\"Readying\")~=nil then aC=K*READYING_PERCENTAGE end;local aD=K-aC;local aE=0;if aC>0 then aE=RestorativeSleep(aC,J,y)end;local aF=SLEEP_UNITS_LOST_MIN*aD/60;J=J+aE-aF;J=math.min(SLEEP_RESERVOIR_CAPACITY,math.max(0,J))_[m]=J;a1[m]=RestStateByCondition(X.condition_v,y)local aG=Z[m]local aH=EffectivenessScore(J,y)a0[m]=aH;local aI=ProfByEffectiveness(aG,aH)local aJ=ProfNameByNumber(aI)if X.proficiency~=aJ then pcall(ScenEdit_SetUnit,{guid=X.guid,proficiency=aJ})end;local function aK(Y,aL)local al=Y.guid;local aM=Y.course;local aN=not aL;if aL then local aO=World_GetPointFromBearing({latitude=Y.latitude,longitude=Y.longitude,distance=500,bearing=Y.heading})table.insert(aM,1,{latitude=aO.latitude,longitude=aO.longitude})else table.remove(aM,1)end;pcall(ScenEdit_SetUnit,{guid=al,course=aM,outofcomms=aL,AI_EvaluateTargets_enabled=aN,AI_DeterminePrimaryTarget_enabled=aN})end;if X.airbornetime_v>0 then local aP=math.random()local aQ=MicroNapRisk(K,aH,y)if a3[m]==1 then if aP*2>aQ then aK(X,false)a3[m]=0 end else if aP<=aQ then aK(X,true)a3[m]=1 end end else if a3[m]==1 then aK(X,false)a3[m]=0 end end;if a2[m]==1 then X:RTB(true)a2[m]=0 end;if X.condition==\"On final approach\"or X.condition==\"In landing queue\"then if X.base then local aR=CrashRisk(K,aH,X.base)local aP=math.random()if aP<=aR then local aS=\"at\"if X.base.type==\"Ship\"then aS=\"on\"end;local aT=X.name..\" crashed while attempting to land \"..aS..\" \"..X.base.name..\".\"ScenEdit_SpecialMessage(X.side,aT,{latitude=X.latitude,longitude=X.longitude})ScenEdit_KillUnit({guid=X.guid})else if aP*100<=aR then X:RTB(false)a2[m]=1 end end end end end end end;StoreArrayNumber(\"UNIT_TRACKER_SLEEPRES\",_)StoreArrayNumber(\"UNIT_TRACKER_EFFECT\",a0)StoreArrayNumber(\"UNIT_TRACKER_RESTSTATE\",a1)StoreArrayNumber(\"UNIT_TRACKER_BOLTER\",a2)StoreArrayNumber(\"UNIT_TRACKER_MICRONAP\",a3)end;function Side_Exists(aU)for m,W in ipairs(VP_GetSides())do if W.name==aU then return true end end;return false end;function Event_Exists(aV)local aW=ScenEdit_GetEvents()for b=1,#aW do local aX=aW[b]if aX.details.description==aV then return true end end;return false end;function Event_Delete(aV,aY)aY=aY or false;if aY then ForEachDo_Break(ScenEdit_GetEvents(),function(aX)if aX.details.description==aV then ForEachDo(aX.details.triggers,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveTrigger(aV,n.Description)Trigger_Delete(n.Description)end end end)ForEachDo(aX.details.conditions,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveCondition(aV,n.Description)Condition_Delete(n.Description)end end end)ForEachDo(aX.details.actions,function(aZ)for a_,n in pairs(aZ)do if n.Description~=nil then Event_RemoveAction(aV,n.Description)Action_Delete(n.Description)end end end)return false end;return true end)end;pcall(ScenEdit_SetEvent,aV,{mode=\"remove\"})end;function Event_Create(aV,b0)ForEachDo(ScenEdit_GetEvents(),function(aX)if aX.details.description==aV then pcall(ScenEdit_SetEvent,aV,{mode=\"remove\"})end end)b0.mode=\"add\"pcall(ScenEdit_SetEvent,aV,b0)return aV end;function Event_AddTrigger(b1,b2)pcall(ScenEdit_SetEventTrigger,b1,{mode='add',name=b2})end;function Event_RemoveTrigger(b1,b2)pcall(ScenEdit_SetEventTrigger,b1,{mode='remove',name=b2})end;function Event_AddCondition(b1,b3)pcall(ScenEdit_SetEventCondition,b1,{mode='add',name=b3})end;function Event_RemoveCondition(b1,b3)pcall(ScenEdit_SetEventCondition,b1,{mode='remove',name=b3})end;function Event_AddAction(b1,b4)pcall(ScenEdit_SetEventAction,b1,{mode='add',name=b4})end;function Event_RemoveAction(b1,b4)pcall(ScenEdit_SetEventAction,b1,{mode='remove',name=b4})end;function Trigger_Create(b5,b0)b0.name=b5;b0.mode=\"add\"pcall(ScenEdit_SetTrigger,b0)return b5 end;function Trigger_Delete(b5)pcall(ScenEdit_SetTrigger,{name=b5,mode=\"remove\"})end;function Condition_Create(b6,b0)b0.name=b6;b0.mode=\"add\"pcall(ScenEdit_SetCondition,b0)return b6 end;function Condition_Delete(b6)pcall(ScenEdit_SetCondition,{name=b6,mode=\"remove\"})end;function Action_Create(b7,b0)b0.name=b7;b0.mode=\"add\"pcall(ScenEdit_SetAction,b0)return b7 end;function Action_Delete(b7)pcall(ScenEdit_SetAction,{name=b7,mode=\"remove\"})end;function SpecialAction_Create(b7,b8,W,b9)local ba=pcall(ScenEdit_AddSpecialAction,{ActionNameOrID=b7,Description=b8,Side=W,IsActive=true,IsRepeatable=true,ScriptText=b9})if ba==true then return b7 end;return\"\"end;function SpecialAction_Delete(b7,W)pcall(ScenEdit_SetSpecialAction,{ActionNameOrID=b7,Side=W,mode=\"remove\"})end;SANDMAN_VERSION=\"0.1.0\"function Sandman_Wizard()if Event_Exists(\"SANDMAN: Scenario Loaded\")then Event_Delete(\"SANDMAN: Scenario Loaded\",true)ForEachDo(VP_GetSides(),function(W)local bb=W.name;SpecialAction_Delete(\"Fatigue Avoidance Scheduling Tool (All Pilots)\",bb)SpecialAction_Delete(\"Fatigue Avoidance Scheduling Tool (Selected Pilots)\",bb)end)end;if Event_Exists(\"SANDMAN: Update Tick\")then Event_Delete(\"SANDMAN: Update Tick\",true)end;local bc=Event_Create(\"SANDMAN: Scenario Loaded\",{IsRepeatable=true,IsShown=false})Event_AddTrigger(bc,Trigger_Create(\"PBEM_Scenario_Loaded\",{type=\"ScenLoaded\"}))Event_AddAction(bc,Action_Create(\"SANDMAN: Load Library\",{type=\"LuaScript\",ScriptText=SANDMAN_LOADER}))local bd=Event_Create(\"SANDMAN: Update Tick\",{IsRepeatable=true,IsShown=false})Event_AddTrigger(bd,Trigger_Create(\"SANDMAN_Update_Tick\",{type=\"RegularTime\",interval=4}))Event_AddAction(bd,Action_Create(\"SANDMAN: Next Update\",{type=\"LuaScript\",ScriptText=\"Sandman_Update(60)\"}))ForEachDo(VP_GetSides(),function(W)local bb=W.name;SpecialAction_Create(\"Fatigue Avoidance Scheduling Tool (All Pilots)\",\"Shows the current effectiveness state for all of your pilots.\",bb,\"Sandman_Display()\")SpecialAction_Create(\"Fatigue Avoidance Scheduling Tool (Selected Pilots)\",\"Shows the current effectiveness state for the currently selected aircraft.\",bb,\"Sandman_DisplaySelected()\")end)if Input_YesNo(\"Thanks for using SANDMAN, the fatigue modeling system for CMO. Do you want to use the suggested values?\")then Sandman_UseDefaults()else Sandman_InputDefaults()end;Input_OK(\"SANDMAN v\"..SANDMAN_VERSION..\" has been installed into this scenario!\")end"Sandman_Wizard()