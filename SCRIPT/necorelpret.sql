declare @dDataJos datetime, @dDataSus datetime, @cCod char(20), @cGestiune char(20), @nInPretAm int, @nZecPret int

set @dDataJos='10/01/2015'
set @dDataSus='12/31/2015'
if 0=1 set @cCod='                    '
if 0=1 set @cGestiune='         '
set @nInPretAm=0
set @nZecPret= 5 

declare @lPM int, @nExcepPM int, @cGestExcepPM char(1000)

exec luare_date_par 'GE', 'MEDIUP', @lPM output, @nExcepPM output, @cGestExcepPM output
set @cGestExcepPM=','+LTrim(RTrim(@cGestExcepPM))+','

declare @docstoc table (subunitate char(9), gestiune char(20), cont char(20), cod char(20), data datetime, cod_intrare char(20), pret float, tip_document char(2), numar_document char(9), cantitate float, tip_miscare char(1), in_out char(1), predator char(20), jurnal char(3), tert char(13), serie char(20), pret_cu_amanuntul float, tip_gestiune char(1), locatie char(30), data_expirarii datetime, TVA_neexigibil int, pret_vanzare float, accize_cump float, loc_de_munca char(13), comanda char(40), numar_pozitie int, 
 grp varchar(100), ordine varchar(30), 
 dataStoc datetime, pretStoc float, contStoc char(20), dataExpStoc datetime, pretAmStoc float, locatieStoc char(30), 
 pretDocCorel float, pretStocCorel float)

	declare @p xml
	select @p=(select @dDataJos dDataJos, @dDataSus dDataSus, @cCod cCod, @cGestiune cGestiune, 0 Corelatii
	for xml raw)

	if object_id('tempdb..#docstoc') is not null drop table #docstoc
		create table #docstoc(subunitate varchar(9))
		exec pStocuri_tabela
	 
	exec pstoc @sesiune='', @parxml=@p
		
insert @docstoc
select subunitate, gestiune, cont, cod, data, cod_intrare, pret, tip_document, numar_document, cantitate, tip_miscare, in_out, predator, jurnal, tert, serie, pret_cu_amanuntul, tip_gestiune, locatie, data_expirarii, TVA_neexigibil, pret_vanzare, accize_cump, loc_de_munca, comanda, numar_pozitie, 
subunitate+tip_gestiune+gestiune+cod+cod_intrare, 
(case when tip_document = 'SI' then '0' else '1' end)+(case when tip_miscare='I' and tip_document<>'AI' or tip_miscare='E' and cantitate<0 then '0' when tip_document='AI' then '1' else '2' end)+convert(char(8), data, 112)+str(numar_pozitie), 
'01/01/2999', 0, '', '01/01/2999', 0, '', 0, 0
from --dbo.fStocuri(@dDataJos, @dDataSus, @cCod, @cGestiune, null, null, null, null, 0, '', '', '', '', '', '', null)
	#docstoc
where tip_gestiune not in ('T')
and (@nInPretAm=0 or @nInPretAm=1 and tip_gestiune='A')
and (@lPM=0 or sign(charindex(','+rtrim(gestiune)+',',@cGestExcepPM))<>sign(@nExcepPM) or tip_gestiune in ('A', 'F', 'T'))

update @docstoc
set 
dataStoc=data, pretStoc=pret, contStoc=cont, dataExpStoc=data_expirarii, pretAmStoc=pret_cu_amanuntul, locatieStoc=locatie
from @docstoc d, (select d2.grp, min(d2.ordine) as ordine from @docstoc d2 group by d2.grp) d1
where d.grp=d1.grp and d.ordine=d1.ordine

update @docstoc
set 
dataStoc=d1.dataStoc, pretStoc=d1.pretStoc, contStoc=d1.contStoc, dataExpStoc=d1.dataExpStoc, pretAmStoc=d1.pretAmStoc, locatieStoc=d1.locatieStoc, 
pretDocCorel=(case when @nInPretAm=1 then d.pret_cu_amanuntul else d.pret end), 
pretStocCorel=(case when @nInPretAm=1 then d1.pretAmStoc else d1.pretStoc end)
from @docstoc d, (select d2.grp, min(dataStoc) as dataStoc, max(pretStoc) as pretStoc, max(contStoc) as contStoc, 
 min(dataExpStoc) as dataExpStoc, max(pretAmStoc) as pretAmStoc, max(locatieStoc) as locatieStoc from @docstoc d2 group by d2.grp) d1
where d.grp=d1.grp

drop table necorelp 

select gestiune, tip_document as tip, numar_document as numar, data, tip_miscare, cod, cod_intrare, 
pretDocCorel as pret_de_stoc, 
pretStocCorel as pret
,numar_pozitie as numar_pozitie
into necorelp 
from @docstoc
where data between @dDataJos and @dDataSus and tip_document<>'SI'
and abs(pretStocCorel-pretDocCorel)>=1.00/power(10, @nZecPret)

if object_id('tempdb..#docstoc') is not null drop table #docstoc
begin try
alter table pozdoc disable trigger all
--/*
select * --*/ update p set pret_de_stoc=c.pret
from necorelp c join pozdoc p on p.Subunitate='1' and p.Tip=c.tip and p.Data=c.data and p.Numar=c.numar and p.Numar_pozitie=c.numar_pozitie
alter table pozdoc enable trigger all
end try
begin catch
	alter table pozdoc enable trigger all
	
end catch