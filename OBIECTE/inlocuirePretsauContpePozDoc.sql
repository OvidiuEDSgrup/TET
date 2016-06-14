
--***
ALTER procedure [yso].[inlocuirePretsauContpePozDoc] @subunitate varchar(20),@cGest varchar(20), @cCod varchar(20), @cCodI varchar(20), @data datetime, @nPret float,@cContDeStoc varchar(20) as

begin

--Pentru teste doar

--declare @subunitate varchar(20),@tip varchar(2),@numar varchar(20),@data datetime,@numar_pozitie int
--set @subunitate='1'
--set @tip='RM'
--set @numar='CR1'
--set @data='08/15/2011'
--set @numar_pozitie=49566

--print 'si aici'
--declare @cGest varchar(20), @cCod varchar(20), @cCodI varchar(20), @nPret float,@cContDeStoc varchar(20)

--select @cGest='101',@cCod='02012050',@cCodI='IMPL1',@nPret=31.87,@cContDeStoc='371.1'
--from pozdoc p
--where p.Subunitate=@subunitate and p.Tip=@tip and p.Numar=@numar and p.data=@data and p.Numar_pozitie=@numar_pozitie

--exec dbo.RefacereStocuri @cGest, @cCod, null,null,null,null

--Contul se inlocuieste doar la primul nivel (nu e nevoie de parcurgere in bucla) fiindca se poate schimba dintr-o gestiune in alta 
--update p set p.cont_de_stoc=@cContDeStoc
--from pozdoc p
--where p.Subunitate=@subunitate and p.Gestiune=@cGest and cod=@cCod and p.Cod_intrare=@cCodI 
----and p.Data>=@data Oare trebuie acest filtru suplimentar?
--and p.Tip_miscare='E'
--and p.Cont_de_stoc!=@cContDeStoc

--Inlocuire pret in "bucla" de TE-uri
declare @nOldNr int,@nNr int

if OBJECT_ID('tempdb..#tmpgestcodi') is not null 
	drop table #tmpgestcodi
create table #tmpgestcodi (gest char(9), codi char(13))
insert into #tmpgestcodi values(@cGest,@cCodI)

set @nOldNr = 0
set @nNr = 1
while @nOldNr <> @nNr
begin
	set @nOldNr = @nNr

	insert into #tmpgestcodi 
	select gestiune_primitoare, (case when grupa<>'' then grupa else cod_intrare end) 
	from pozdoc where subunitate='1' and tip='TE' and data>=@data and cod=@cCod
	and exists (select 1 from #tmpgestcodi where gest=gestiune and codi=cod_intrare) 
	and not exists (select 1 from #tmpgestcodi where gest=gestiune_primitoare and codi=(case when grupa<>'' then grupa else cod_intrare end)) 
	
	set @nNr = (select count(*) from #tmpgestcodi) 
end

alter table pozdoc disable trigger docdefinitiv
alter table pozdoc disable trigger tr_PropagPretContPozdoc

update p
set pret_de_stoc=@nPret, 
	adaos=(case when p.tip in ('AP', 'AC') or p.tip='TE' and isnull(g.tip_gestiune, '') in ('A', 'V') then round(convert(decimal(15,5), 100*((case when p.tip='TE' then p.pret_cu_amanuntul/(1.00+p.tva_neexigibil/100.00) else p.pret_vanzare end)/@nPret - 1)), 2) else p.adaos end)
from pozdoc p 
inner join #tmpgestcodi ti on ti.gest=p.gestiune and ti.codi=p.cod_intrare
left outer join gestiuni g on p.tip='TE' and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune_primitoare
where p.subunitate='1' and p.cod=@cCod 
--and data >= @data Oare trebuie acest filtru sumplimentar?
and p.tip_miscare='E' 
and p.pret_de_stoc<>@nPret

alter table pozdoc enable trigger docdefinitiv
alter table pozdoc enable trigger tr_PropagPretContPozdoc

drop table #tmpgestcodi
end
