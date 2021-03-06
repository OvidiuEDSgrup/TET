USE [TET]
GO
/****** Object:  Trigger [dbo].[doccontr]    Script Date: 12/15/2011 09:24:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
--***
/*Pentru completare cant. realizata*/
ALTER trigger [dbo].[doccontr] on [dbo].[pozdoc] for update,insert,delete NOT FOR REPLICATION as
begin
-------------	din tabela par (parametri trimis de Magic):
declare @rezstoc int, @multicdbk int, @pozsurse int
set @rezstoc=isnull((select top 1 val_logica from par where tip_parametru='GE' and parametru='REZSTOC'),0)
set @multicdbk=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='MULTICDBK'),0)
set @pozsurse=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)
-------------
declare @realizat float
declare @csub char(9),@ccod char(20), @barcod char(8), @ctip char(2),@ccontr char(20),@ctert char(13),@cgest char(9),@semn int,@cant float,@ctipcontr char(1),@ccodi char(13),@clocatie char(20),@pret float
declare @gsub char(9),@gcod char(20),@gbarcod char(8), @gtip char(2),@gcontr char(20),@gtert char(13),@ggest char(9),@gcodi char(13), @glocatie char(20),@gid int,@gpret float,@gfetch int
declare @cGestPrim char(9), @gGestPrim char(9)

declare tmpCo cursor for
select subunitate,cod,barcod, tip,contract,tert,1,cantitate,(case when left(tip,1)='R' then 'F' else 'B' end),
(case when @rezstoc=1 then gestiune else '' end) as gest,(case when @rezstoc=1 and left(tip,1)='A' then cod_intrare else '' end) as codi,locatie,
(case when left(tip,1)='R' or valuta<>'' then pret_valuta else pret_vanzare end)
from inserted where tip in ('AC','AP','AS','RM','RS') and contract<>'' 
union all
select subunitate,cod,barcod, tip,contract,tert,-1,cantitate,(case when left(tip,1)='R' then 'F' else 'B' end),
(case when @rezstoc=1 then gestiune else '' end),(case when @rezstoc=1 and left(tip,1)='A' then cod_intrare else '' end),locatie,
(case when left(tip,1)='R' or valuta<>'' then pret_valuta else pret_vanzare end)
from deleted where tip in ('AC','AP','AS','RM','RS') and contract<>''
order by subunitate,tip,contract/*,tert*/,cod,gest,locatie

open tmpCo
fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
set @gsub=@csub
set @gtip=@ctip
set @gcontr=@ccontr
--set @gtert=@ctert
set @gcod=@ccod
set @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
set @ggest=@cgest
set @gcodi=@ccodi
set @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	set @gid=0
	set @glocatie=@clocatie
	while @gsub=@csub and @gTip=@cTip and @gcontr=@ccontr --and @gtert=@ctert 
		and @gcod=@ccod and (@rezstoc=0 or @ggest=@cgest and @gcodi=@ccodi) 
		and @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
		and @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
		and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		if @semn=1 set @glocatie=@clocatie
		fetch next from tmpCo into @csub,@ccod,@barcod,@ctip,@ccontr,@ctert,@semn,@cant,@ctipcontr,@cgest,@ccodi,@clocatie,@pret
		set @gfetch=@@fetch_status
	end
	update pozcon set cant_realizata=cant_realizata+@realizat,@gid=1
		where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr --and tert=@gtert 
		and cod=@gcod 
		and (@rezstoc=0 or @rezstoc=1 and mod_de_plata=@ggest 
			and (left(@gtip,1)='A' or factura=@glocatie) and (left(@gtip,1)='R' or valuta=@gcodi) 
			and zi_scadenta_din_luna=0 and (left(@gtip,1)='R' or contract<>@glocatie))
		and ((@ctipcontr = 'B' and tip = 'BK') or (@ctipcontr = 'F' and tip = 'FC') or (@ctipcontr = 'B' and tip = 'BP'))
		and (@multicdbk=0 or @multicdbk=1 and (@ctipcontr<>'B' or abs(pret-@gpret)<=0.001))
		and (@pozsurse=0 or @pozsurse=1 and (@ctipcontr<>'B' or mod_de_plata=@gbarcod))

	/*cu rezervari de stocuri*/
	update pozcon set cant_realizata=cant_realizata+@realizat
		where @rezstoc=1 and @gid=0 and left(@gtip,1)='A' and subunitate=@gsub and tip='BF' and
		contract=@gcontr and /*tert=@gtert and */cod=@gcod and zi_scadenta_din_luna>0

	/* Modificare stare contract*/
--	update con set stare='6' 
	--	where subunitate=@gsub and left(tip,1)=@ctipcontr and contract=@gcontr /*and tert=@gtert*/
		--and tip<>'BF'

	set @gsub=@csub
	set @gtip=@ctip
	set @gcontr=@ccontr
	--set @gtert=@ctert
	set @gcod=@ccod
	set @gbarcod=(case when @pozsurse=1 and @ctipcontr='B' then @barcod else '' end)
	set @ggest=@cgest
	set @gcodi=@ccodi
	set @gpret=(case when @multicdbk=1 and @ctipcontr='B' then @pret else 0 end)
end

close tmpCo
deallocate tmpCo

-- realizat pe TE

declare tmpCo cursor for
select subunitate, (case when tip='AE' then '' when contract<>'' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip='AE' then grupa else factura end),  1, cantitate, pret_cu_amanuntul
from inserted where (tip = 'TE' and factura <> '' or tip='AE' and grupa<>'')
union all
select subunitate, (case when tip='AE' then '' when contract<>'' then contract else gestiune_primitoare end) as gestiune_primitoare, 
cod, (case when tip='AE' then grupa else factura end), -1, cantitate, pret_cu_amanuntul
from deleted where (tip = 'TE' and factura <> '' or tip='AE' and grupa<>'')

open tmpCo
fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
set @gsub=@csub
set @gGestPrim=@cGestPrim
set @gcod=@ccod
set @gcontr=@ccontr
set @gpret=(case when @multicdbk=1 then @pret else 0 end)
set @gfetch=@@fetch_status
while @gfetch=0
begin
	set @realizat=0
	while @gsub=@csub and @gGestPrim=@cGestPrim and @gcontr=@ccontr and @gcod=@ccod 
		and @gpret=(case when @multicdbk=1 then @pret else 0 end) and @gfetch=0
	begin
		set @realizat=@realizat+@semn*@cant 
		fetch next from tmpCo into @csub, @cGestPrim, @ccod, @ccontr, @semn, @cant, @pret
		set @gfetch=@@fetch_status
	end
	update pozcon 
	set pret_promotional=p.pret_promotional+@realizat
	from pozcon p 
	left outer join gestiuni g on p.punct_livrare<>'' and p.subunitate=g.subunitate and p.punct_livrare=g.cod_gestiune
	where p.subunitate=@gsub and p.tip='BK' and p.contract=@gcontr and p.cod=@gcod
	and (@gGestPrim='' or p.punct_livrare = @gGestPrim)
	and (@multicdbk=0 or abs(round(convert(decimal(17, 5), pret*(1.00+(case when isnull(g.tip_gestiune, '') not in ('A', 'V') then p.cota_TVA else 0 end)/100.00)), 5)-@gpret)<=0.001)

	set @gsub=@csub
	set @gGestPrim=@cGestPrim
	set @gcod=@ccod
	set @gcontr=@ccontr
	set @gpret=(case when @multicdbk=1 then @pret else 0 end)
end

close tmpCo
deallocate tmpCo
end
