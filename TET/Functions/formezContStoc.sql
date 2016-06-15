--***
create function formezContStoc (@Gestiune char(9), @Cod char(20), @LM char(9)) returns varchar(40)
as begin

declare @ContStoc varchar(40), @TipNomencl char(1), @ContNomencl varchar(40), @Grupa char(13)

set @TipNomencl=''
set @ContNomencl=''
set @Grupa=''

select @TipNomencl=tip, @ContNomencl=cont, @Grupa=grupa 
from nomencl 
where cod=@Cod

if @TipNomencl in ('R', 'S')
begin
	declare @AnLMServ int, @NrCarAnLMServ int
	select @AnLMServ=convert(int, val_logica), @NrCarAnLMServ=val_numerica from par where tip_parametru='GE' and parametru='CONTS'+(case when @TipNomencl='R' then 'F' else 'P' end)
	if @AnLMServ is null set @AnLMServ=0
	if isnull(@NrCarAnLMServ, 0)=0 set @NrCarAnLMServ=9
	set @ContStoc=RTrim(@ContNomencl)+(case when @AnLMServ=1 and @LM<>'' then '.'+RTrim(Left(@LM, @NrCarAnLMServ)) else '' end)
end

if @ContStoc is null
begin
	declare @ContGestiune varchar(40), @TipGestiune char(1)
	select @ContGestiune=cont_contabil_specific, @TipGestiune=tip_gestiune
	from gestiuni
	where cod_gestiune=@Gestiune
	
	if @TipGestiune in ('A', 'V') and left(@ContGestiune, 3)<>'371' and left(@ContNomencl, 3)<>'371'
		set @ContNomencl='371'
	
	if @ContGestiune<>'' set @ContStoc=@ContGestiune
end

if @ContStoc is null and left(@ContNomencl, 2)='30'
begin
	declare @AnGest30 int, @NrCarAnGest30 int
	select @AnGest30=convert(int, val_logica), @NrCarAnGest30=val_numerica from par where tip_parametru='GE' and parametru='CONTS'
	if @AnGest30 is null set @AnGest30=0
	if isnull(@NrCarAnGest30, 0)=0 set @NrCarAnGest30=9
	set @ContStoc=RTrim(@ContNomencl)+(case when @AnGest30=1 then '.'+RTrim(Left(@Gestiune, @NrCarAnGest30)) else '' end)
end

if @ContStoc is null and left(@ContNomencl, 2)='37'
begin
	declare @AnGest37 int, @AnGrupa37 int

	select @AnGest37=convert(int, val_logica), @AnGrupa37=val_numerica from par where tip_parametru='GE' and parametru='CONTM'
	if @AnGest37 is null set @AnGest37=0
	if @AnGrupa37 is null set @AnGrupa37=0
	set @ContStoc=RTrim(@ContNomencl)+(case when @AnGest37=1 then '.'+RTrim(@Gestiune) else '' end)+(case when @AnGrupa37=1 then '.'+RTrim(@Grupa) else '' end)
end

if @ContStoc is null and left(@ContNomencl, 2)='34'
begin
	declare @AnGest34 int, @NrCarAnGest34 int
	select @AnGest34=convert(int, val_logica), @NrCarAnGest34=val_numerica from par where tip_parametru='GE' and parametru='CONTPF'
	if @AnGest34 is null set @AnGest34=0
	if isnull(@NrCarAnGest34, 0)=0 set @NrCarAnGest34=9
	set @ContStoc=RTrim(@ContNomencl)+(case when @AnGest34=1 then '.'+RTrim(Left(@Gestiune, @NrCarAnGest34)) else '' end)
end

if @ContStoc is null
begin
	declare @AnGest3Alte int, @NrCarAnGest3Alte int
	select @AnGest3Alte=convert(int, val_logica), @NrCarAnGest3Alte=val_numerica from par where tip_parametru='GE' and parametru='CONT3'
	if @AnGest3Alte is null set @AnGest3Alte=0
	if isnull(@NrCarAnGest3Alte, 0)=0 set @NrCarAnGest3Alte=9
	set @ContStoc=RTrim(@ContNomencl)+(case when @AnGest3Alte=1 then '.'+RTrim(Left(@Gestiune, @NrCarAnGest3Alte)) else '' end)
end

return @ContStoc
end
