--***
create procedure refPretMediu @dDataSus datetime, @cCod char(20), @InlocPret int, @cGrupa char(13), @nGrup int, @nOrd int
as
declare @dDataJos datetime,@cGrup char(1000),@gGrup char(1000),
	@lPM int,@nExcepPM int, @cGestExcepPM char(1000),@lPrestTE int,
	@ramase int,@ramaseant int,@nFetch int,@pas int,
	@ComDsTr varchar(300),@ComEnTr varchar(300),@ComSQL varchar(300), @versiuneSql varchar(10)

exec luare_date_par 'GE', 'MEDIUP', @lPM output, @nExcepPM output, @cGestExcepPM output
set @cGestExcepPM=','+LTrim(RTrim(@cGestExcepPM))+','
set @lPrestTE=isnull((select max(cast(val_logica as int)) from par where tip_parametru='GE' and parametru='PRESTTE'),0)
set @versiuneSql=substring(convert(varchar(128),SERVERPROPERTY('ProductVersion')),1,CHARINDEX('.',convert(varchar(128),SERVERPROPERTY('ProductVersion')))-1)

set @dDataJos=null
if @dDataSus is null set @dDataSus = '12/31/2999'
if @InlocPret is null set @InlocPret = 0
if @nGrup is null set @nGrup = 0
if @nOrd is null set @nOrd = 0

create table #miscari (subunitate char(9),tip_gestiune char(1),gestiune char(20),cont char(20),cod char(20),data datetime,
	cod_intrare char(20),pret float,pstoc_doc float,tip_document char(2),numar_document char(9),cantitate float,tip_miscare char(1),
	jurnal char(3),tert char(13),pret_cu_amanuntul float,locatie char(30),data_expirarii datetime,loc_de_munca char(13),
	comanda char(40),numar_pozitie int,pas int,pretmed float,cantmed float,grpmed varchar(700),criteriujos varchar(100),criteriusus varchar(100),identitate int identity(1,1))
create index stocdoc on #miscari (subunitate, tip_document, numar_document, data, numar_pozitie, tip_miscare)
create index stocgrpas on #miscari (grpmed, pas, criteriujos, tip_miscare)
create index stocstoc on #miscari (subunitate, tip_gestiune, gestiune, cod, cod_intrare)

	declare @p xml
	select @p=(select @dDataJos dDataJos, @dDataSus dDataSus, @cCod cCod, @cGrupa cGrupa, 0 Corelatii
	for xml raw)

		if object_id('tempdb..#docstoc') is not null drop table #docstoc
			create table #docstoc(subunitate varchar(9))
			exec pStocuri_tabela
		 
		exec pstoc @sesiune='', @parxml=@p
		
insert into #miscari
select subunitate, tip_gestiune,gestiune, cont, cod, data, cod_intrare, pret, pret, tip_document, numar_document, 
	cantitate*(case when tip_miscare='E' and cantitate<0 then -1 else 1 end), 
	(case when cantitate<0 then 'I' else tip_miscare end) as tip_miscare,
	jurnal, tert, pret_cu_amanuntul, locatie, data_expirarii, loc_de_munca, comanda, numar_pozitie, 
	0,0,0,dbo.fGrpMed(@nGrup, gestiune, cod, cont) as grpmed,
	(case @nOrd 
	 when 1 then convert(char(8),data,112)+str(numar_pozitie) 
	 when 2 then (case when tip_document in ('TI','TE') and cantitate>0 then '2' when tip_miscare='I' or cantitate<0 then '1' else '3' end)+convert(char(8),data,112)+str(numar_pozitie)
	 else convert(char(8),data,112)+(case when tip_document in ('TI','TE') and cantitate>0 then '2' when tip_miscare='I' or cantitate<0 then '1' else '3' end)+str(numar_pozitie) 
	end) as criteriujos,
	(case @nOrd 
	 when 1 then '29990101'
	 when 2 then '4'
	 else '29990101' 
	end) as criteriusus
from --dbo.fStocuri(@dDataJos, @dDataSus, @cCod, null, null, @cGrupa, '', '', 0, '', '', '', '', '', '', null)
	#docstoc
where sign(charindex(','+rtrim(gestiune)+',',@cGestExcepPM))=sign(@nExcepPM)
	and abs(cantitate)>=0.001 and tip_gestiune not in ('A', 'T', 'F')
order by grpmed,criteriujos,tip_miscare,tip_document,numar_document

update #miscari set criteriujos=criteriujos+str(identitate)

update #miscari 
set tip_document='TT' 
where tip_document='TI' and (cantitate<0 or not exists (select 1 from #miscari m2 where #miscari.numar_document=m2.numar_document and #miscari.data=m2.data and #miscari.numar_pozitie=m2.numar_pozitie and m2.tip_document='TE'))

set @pas=1
set @ramaseant=0
set @ramase=(select count(*) from #miscari where pas=0)
while @ramase>0 and @ramase<>@ramaseant
begin
	while @ramase>0 and @ramase<>@ramaseant
	begin
		-- Prima intrare 
		update #miscari set pas=@pas
		from #miscari, 
			(select grpmed, min(criteriujos) as criteriujos
			from #miscari where tip_miscare='I' and pas=0
			group by grpmed) m2
		where #miscari.pas=0 and #miscari.tip_document<>'TI' and #miscari.grpmed=m2.grpmed and #miscari.criteriujos=m2.criteriujos

		-- A doua intrare 
		update #miscari set pas=@pas+1
		from #miscari,
			(select grpmed, min(criteriujos) as criteriujos
			from #miscari where tip_miscare='I' and pas=0
			group by grpmed) m2
		where #miscari.pas=0 and #miscari.tip_miscare='I' and #miscari.grpmed=m2.grpmed and #miscari.criteriujos=m2.criteriujos

		update #miscari set criteriusus=m2.criteriujos
		from #miscari,#miscari m2
		where #miscari.grpmed=m2.grpmed and #miscari.pas=@pas and m2.pas=@pas+1

		update #miscari 
		set cantmed=isnull((select sum((case when tip_miscare='I' then cantmed else -cantitate end)) from #miscari m1 where #miscari.grpmed=m1.grpmed and m1.pas=isnull(m5.pas,-1) and m1.pas>0),0)+cantitate,
			pretmed=(case when isnull((select sum((case when tip_miscare='I' then cantmed else -cantitate end)) from #miscari m1 where #miscari.grpmed=m1.grpmed and m1.pas=isnull(m5.pas,-1) and m1.pas>0),0)+cantitate=0 then 0 else
			(isnull((select sum((case when tip_miscare='I' then cantmed else -cantitate end)*pretmed) from #miscari m1 where #miscari.grpmed=m1.grpmed and m1.pas=isnull(m5.pas,-1) and m1.pas>0),0)+cantitate*pret)/
			(isnull((select sum((case when tip_miscare='I' then cantmed else -cantitate end)) from #miscari m1 where #miscari.grpmed=m1.grpmed and m1.pas=isnull(m5.pas,-1) and m1.pas>0),0)+cantitate) end)
		from #miscari left outer join (select grpmed, max(pas) as pas from #miscari where pas>0 and pas<@pas group by grpmed) m5 on #miscari.grpmed=m5.grpmed
		where #miscari.pas=@pas and #miscari.tip_miscare='I'

		update #miscari set pas=0 where pas=@pas+1

		--iesiri daca exista stoc disponibil
		update #miscari set pretmed=m2.pretmed,pas=@pas,cantmed=m2.cantmed
		from #miscari,#miscari m2
		where
			#miscari.grpmed=m2.grpmed and #miscari.tip_miscare='E' and m2.tip_miscare='I' and m2.pas=@pas and #miscari.pas=0
			and #miscari.criteriujos <= m2.criteriusus
			--si exista cantitate suficienta pe stoc
			and #miscari.grpmed in 
			(select mm.grpmed from #miscari mm 
			where #miscari.grpmed=mm.grpmed and mm.tip_miscare='E' and mm.pas=0
			and mm.criteriujos <= m2.criteriusus
		group by mm.grpmed having sum(cantitate)<=m2.cantmed)

		-- TI din TE
		update #miscari set pret=m2.pretmed+(case when @lPrestTE=1 then #miscari.pstoc_doc-m2.pstoc_doc else 0 end),
			tip_document='TT',cantmed=#miscari.cantitate
		from #miscari,#miscari m2 where
			#miscari.pas=0 and #miscari.numar_document=m2.numar_document and
			#miscari.data=m2.data and #miscari.numar_pozitie=m2.numar_pozitie and 
			#miscari.tip_document='TI' and m2.tip_document='TE' and m2.pas=@pas

		set @pas=@pas+1
		set @ramaseant=@ramase
		set @ramase=(select count(*) from #miscari where pas=0)
	end

	-- rezolvare erori
	update #miscari set pretmed=m2.pretmed,pas=@pas,cantmed=m2.cantmed
	from #miscari,
		(select pretmed, cantmed, grpmed from #miscari mm where mm.tip_miscare='I' and mm.pas>0
		and mm.pas=(select max(pas) from #miscari m1 where m1.grpmed=mm.grpmed group by grpmed) 
		) m2
	where #miscari.pas=0 and #miscari.grpmed=m2.grpmed and #miscari.tip_miscare='E'

	-- TI din TE
	update #miscari set pret=m2.pretmed+(case when @lPrestTE=1 then #miscari.pstoc_doc-m2.pstoc_doc else 0 end),
		tip_document='TT',cantmed=#miscari.cantitate
	from #miscari,#miscari m2 where
		#miscari.numar_document=m2.numar_document and
		#miscari.data=m2.data and #miscari.numar_pozitie=m2.numar_pozitie and 
		#miscari.tip_document='TI' and m2.tip_document='TE' and 
		#miscari.pas=0 and m2.pas=@pas

	set @ramaseant=@ramase
	set @ramase=(select count(*) from #miscari where pas=0)
end

if @InlocPret=1 begin
set @ComDsTr=(case when @versiuneSql>=9 then 'disable' else 'drop' end)+' trigger XXX'+(case when @versiuneSql>=9 then ' on pozdoc' else '' end)
set @ComEnTr=(case when @versiuneSql>=9 then 'enable trigger XXX on pozdoc' else '' end)

if exists (select 1 from sysobjects where type='TR' and name='docStocM')
begin
	set @ComSQL=replace(@ComDsTr,'XXX','docStocM')
	if @ComSQL<>'' exec(@ComSQL)
end
if exists (select 1 from sysobjects where type='TR' and name='docXStocM')
begin
	set @ComSQL=replace(@ComDsTr,'XXX','docXStocM')
	if @ComSQL<>'' exec(@ComSQL)
end

update pozdoc set pret_de_stoc=#miscari.pretmed 
from #miscari 
where #miscari.tip_miscare='E' and pozdoc.subunitate=#miscari.subunitate and pozdoc.tip=#miscari.tip_document and pozdoc.numar=#miscari.numar_document and
	pozdoc.data=#miscari.data and pozdoc.numar_pozitie=#miscari.numar_pozitie

if @lPrestTE=1
update pozdoc set accize_datorate=#miscari.pret
from #miscari 
where #miscari.tip_document='TT' and pozdoc.subunitate=#miscari.subunitate and pozdoc.tip='TE' and pozdoc.numar=#miscari.numar_document and
	pozdoc.data=#miscari.data and pozdoc.numar_pozitie=#miscari.numar_pozitie

if exists (select 1 from sysobjects where type='TR' and name='docStocM')
begin
set @ComSQL=replace(@ComEnTr,'XXX','docStocM')
if @ComSQL<>'' exec(@ComSQL)
end
if exists (select 1 from sysobjects where type='TR' and name='docXStocM')
begin
set @ComSQL=replace(@ComEnTr,'XXX','docXStocM')
if @ComSQL<>'' exec(@ComSQL)
end
end

if @nOrd = 2 -- pentru pret mediu neinstantaneu trebuie actualizat pretul pentru gestiunile si codurile de intrare pe care nu avem iesiri
begin
	update #miscari
	set pretmed=a.pretmed
	from 
		(select grpmed, max(pretmed) as pretmed from #miscari m1
		where exists (select 1 from #miscari m2 where m1.grpmed=m2.grpmed group by m2.grpmed having m1.pas=max(m2.pas))
		group by grpmed) a
	where #miscari.grpmed=a.grpmed
end

update stocuri 
set pret=m.pretmed
from stocuri s, (select grpmed, max(pas) as pas from #miscari group by grpmed) m1, #miscari m
where sign(charindex(','+rtrim(s.cod_gestiune)+',',@cGestExcepPM))=sign(@nExcepPM) and s.tip_gestiune not in ('A', 'T', 'F') 
	and m1.grpmed=dbo.fGrpMed(@nGrup, s.cod_gestiune, s.cod, s.cont)
	and m.grpmed=m1.grpmed and m.pas=m1.pas

drop table #miscari
if object_id('tempdb..#docstoc') is not null drop table #docstoc
