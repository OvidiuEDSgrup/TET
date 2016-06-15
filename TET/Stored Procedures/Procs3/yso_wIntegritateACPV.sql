--***
create procedure yso_wIntegritateACPV @sesiune varchar(50), @parXML xml          
as        
-- exec yso_wIntegritateACPV '', '<row dataj="2012-08-23" datas="2012-08-23"/>'
declare @dataj datetime, @datas datetime,@userASiS varchar(20),@sub varchar(20),@gestiune varchar(20),@curefacere int
	/*sp*/,@listaGestiuni VARCHAR(max) /*sp*/
EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT

exec wJurnalizareOperatie @sesiune,@parXML,'yso_wIntegritateACPV'

select	@dataj = ISNULL(@parXML.value('(/*/@dataj)[1]', 'datetime'), ''),       
		@datas = ISNULL(@parXML.value('(/*/@datas)[1]', 'datetime'), ''),
		@gestiune= ISNULL(@parXML.value('(/*/@gestiune)[1]', 'varchar(20)'), ''),
		@curefacere= ISNULL(@parXML.value('(/*/@curefacere)[1]', 'int'), 0)
--/*sp
declare @DetaliereBonuri bit
select @DetaliereBonuri=0
select @DetaliereBonuri=isnull((select val_logica from par where tip_parametru='PO' and Parametru='DETBON'),0)
--select @listaGestiuni = isnull(@listaGestiuni,'')
--	+isnull(';' + (SELECT TOP 1 rtrim(val_alfanumerica) FROM par WHERE Tip_parametru = 'GE' AND Parametru='REZSTOCBK' 
--		and Val_logica = 1) + ';','')
--sp*/
/* 
	calculam sume pentru bonuri(fara facturi) din tabela bp, si le scriem in tabela temporara #bp.
	* cand se va face pentru facturi nu se face TE si trebuie vazut cum facem cu gestiunile...
 */
select a.Gestiune as gestiune,data,sum(Total) as bp,convert(float,0.00) as ac, SUM(cantitate) as cantBp, CONVERT(float,0) as cantpozdoc
/*sp*/,bp.Casa_de_marcat,bp.Numar_bon,bp.Vinzator
,nrPozdoc=left((case when @DetaliereBonuri=1 then RTrim(CONVERT(varchar(4),bp.Casa_de_marcat))+right(replace(str(bp.Numar_bon),' ','0'),4) 
	else '' end),8)  /*sp*/
into #bp
from bonuri bp
left join antetBonuri a on a.IdAntetBon=bp.IdAntetBon
where Factura_chitanta=1 and tip='21'
and data between @dataj and @datas
and (@gestiune='' or a.Gestiune=@gestiune)
group by a.Gestiune,data
/*sp*/,bp.Casa_de_marcat,bp.Numar_bon,bp.Vinzator /*sp*/

/* 
	calculam sume pentru bonuri din tabela pozdoc. 
*/
select gestiune,data,SUM(round(round(cantitate*Pret_vanzare,2) + TVA_deductibil,2)) as val, SUM(cantitate) as cantitate
/*sp*/,pozdoc.Numar/*sp*/
into #ac
from pozdoc
where Subunitate='1' and tip='AC' 
and data between @dataj and @datas
and (@gestiune='' or gestiune=@gestiune /*sp or charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0 sp*/)
group by gestiune,data
/*sp*/,pozdoc.Numar/*sp*/

/*
	actualizam in tabela #bp, informatiile din pozdoc
*/
update #bp set ac=val, cantpozdoc=#ac.cantitate 
	from #ac 
	where #bp.gestiune=#ac.gestiune and #bp.Data=#ac.Data
		/*sp*/and #bp.nrPozdoc=#ac.Numar/*sp*/

if @curefacere=1
begin
	/*
		daca se trimite atributul @curefacere, procedura apeleaza procedura de refacere, pentru fieacare zi la care
		sunt diferente.
	*/
	declare tmpRefac cursor for
	select distinct gestiune,data/*sp*/,#bp.Casa_de_marcat,#bp.Numar_bon,#bp.Vinzator /*sp*/
	from #bp 
	where abs(bp-ac)>=0.01 or abs(cantbp-cantpozdoc)>=0.001
	order by gestiune,data/*sp*/,#bp.Casa_de_marcat,#bp.Numar_bon,#bp.Vinzator /*sp*/

	declare @gestiuner varchar(20),@datar datetime,@nFetch int,@p2 xml 
/*sp*/	, @casam varchar(10), @numar int, @vanzator varchar(10) /*sp*/
	open tmpRefac
	fetch next from tmpRefac into @gestiuner,@datar /*sp*/, @casam, @numar, @vanzator /*sp*/
	set @nFetch=@@FETCH_STATUS
	while @nFetch=0
	begin
		print 'Refac pentru '+@gestiuner+','+convert(varchar(10),@datar,103)

		set @p2=(select @gestiuner as '@gestiune',1 as '@stergere',1 as '@generare',
		@datar as '@datajos',@datar as '@datasus','O' as '@tipMacheta',		
/*sp	'RF' as '@codMeniu' sp*/ @casam as '@casam', @numar as '@numar', @vanzator as '@vanzator' /*sp*/
		for xml path('parametri'),type)
		
		exec yso_wOPRefacACTE @sesiune=@sesiune,@parXML=@p2
		
		fetch next from tmpRefac into @gestiuner,@datar /*sp*/, @casam, @numar, @vanzator /*sp*/
		set @nFetch=@@FETCH_STATUS
	end
	close tmpRefac
	deallocate tmpRefac
end
else -- afisez rezultatul.
	select *, convert(decimal(20,3),bp-ac) as dif_val, cantbp-cantpozdoc as dif_cant 
	--into yso_wIntegritateACPVRezTblStrNoi
	from #bp
	order by ABS(bp-ac) desc

--Gata cu bonrile
/* Verificam pentru transferuri*/

select loc_de_munca as gestiune,data,numar_bon,sum(cantitate) as cantbp,convert(float,0) as cantte,convert(float,0) as dif
into #bpte
from bp where data between @dataj and @datas and tip='11'
group by loc_de_munca,data,numar_bon

select gestiune,data,numar,sum(cantitate) as cantte
into #te
from pozdoc where data between @dataj and @datas and tip='TE' and stare='5'
group by gestiune,data,numar

update #bpte set cantte=#te.cantte,dif=cantbp-#te.cantte from #te where #te.data=#bpte.data and #bpte.numar_bon=#te.numar and #te.gestiune=#bpte.gestiune

select * from #bpte order by abs(dif) desc
drop table #te
drop table #bpte
