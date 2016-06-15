--***
create procedure inlocuirePretsauContpePozDoc @subunitate varchar(20),@tip varchar(2),@numar varchar(20),@data datetime,@numar_pozitie int
as

begin
/*
--Pentru teste doar

declare @subunitate varchar(20),@tip varchar(2),@numar varchar(20),@data datetime,@numar_pozitie int
set @subunitate='1'
set @tip='RM'
set @numar='CR1'
set @data='08/15/2011'
set @numar_pozitie=49566
*/
declare @cGest varchar(20), @cCod varchar(20), @cCodI varchar(20), @nPret float,@cContDeStoc varchar(40), @nPretAm float, @tipGestiuneIntrare char(1)

select	@cGest = p.Gestiune, @cCod = p.Cod,@cCodI = (case when tip = 'TE' and grupa<>'' then grupa else Cod_intrare end),
		@nPret = Pret_de_stoc, @cContDeStoc = Cont_de_stoc,-- ?la propagare trebuie inlocuit doc confirmat(cont_corespondent=cont_De_stoc la confirmare)  
		@nPretAm = p.pret_cu_amanuntul, @tipGestiuneIntrare=g.tip_gestiune
from pozdoc p
	left outer join gestiuni g on g.Subunitate=p.Subunitate and (p.tip<>'TE' and g.cod_gestiune=p.gestiune or p.tip='TE' and g.cod_gestiune=p.gestiune_primitoare)
where p.Subunitate=@subunitate and p.Tip=@tip and p.Numar=@numar and p.data=@data and p.Numar_pozitie=@numar_pozitie

-- Inlocuire pret in Nomenclator
if isnull((select val_logica from par where tip_parametru='GE' and parametru='ACTNOMINT'),0)=1
	update nomencl set Pret_stoc = @nPret where cod=@cCod and pret_stoc<>@nPret

--Contul se inlocuieste doar la primul nivel (nu e nevoie de parcurgere in bucla) fiindca se poate schimba dintr-o gestiune in alta 
update p
set  p.Cont_de_stoc = @cContDeStoc,
	pret_cu_amanuntul = (case when @tipGestiuneIntrare='A' then @nPretAm else pret_cu_amanuntul end)	-- tratat sa se propage pretul cu amanuntul doar la primul nivel, ca si contul de stoc
from pozdoc p
where p.Subunitate=@subunitate and p.Gestiune=@cGest 
	and cod=@cCod and Cod_intrare=@cCodI
	and (p.Tip_miscare='E' or p.Tip_miscare='I' and p.cantitate<0)
	and p.Cont_de_stoc!=@cContDeStoc 

/*TI-uri*/		
update p
set p.Cont_corespondent = @cContDeStoc,
	Pret_amanunt_predator = @nPretAm
from pozdoc p 
where	p.Subunitate=@subunitate and Gestiune_primitoare=@cGest and p.tip='TE'
		and cod=@cCod and (case when grupa<>'' then grupa else Cod_intrare end)=@cCodI
		and p.Tip_miscare='E'
		and (p.Cont_corespondent!=@cContDeStoc or p.Pret_amanunt_predator<>@nPretAm)

--Inlocuire pret in "bucla" de TE-uri
declare @nOldNr int,@nNr int
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
/*
 * tratare TI-uri
*/
/*
update pozdoc 
set Pret_amanunt_predator = @nPretAm--, 
	--Cont_corespondent = @cContDeStoc
from pozdoc p
inner join #tmpgestcodi ti on ti.gest=p.gestiune_primitoare  and ti.codi=( case when grupa<>'' then grupa else p.cod_intrare end )
left outer join gestiuni g on p.tip='TE' and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune_primitoare
where p.subunitate=@subunitate and p.cod=@cCod 
		and p.tip_miscare='E' and p.tip='TE'
		and p.Pret_amanunt_predator<>@nPretAm
*/
/*--*/		
update p
set Pret_de_stoc = @nPret, 
	--Pret_amanunt_predator = (case when tip='TE' then @nPretAm else pret_amanunt_predator end),
	--pret_cu_amanuntul = (case when @tipGestiuneIntrare='A' then @nPretAm else pret_cu_amanuntul end),	tratat sa se propage pretul cu amanuntul doar sus la primul nivel, ca si contul de stoc
	Adaos=(case when p.tip in ('AP', 'AC') or p.tip='TE' and isnull(g.tip_gestiune, '') in ('A', 'V') 
		then round(convert(decimal(15,5), 100*((case when p.tip='TE' then p.pret_cu_amanuntul/(1.00+p.tva_neexigibil/100.00) else p.pret_vanzare end)/@nPret - 1)), 2) 
		else p.adaos end)
from pozdoc p
inner join #tmpgestcodi ti on ti.gest=p.gestiune and ti.codi=p.cod_intrare
left outer join gestiuni g on p.tip='TE' and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune_primitoare
where p.subunitate=@subunitate and p.cod=@cCod
and p.tip_miscare='E' 
and (p.pret_de_stoc<>@nPret /*or (case when tip='TE' then p.Pret_amanunt_predator else p.Pret_cu_amanuntul end)<>@nPretAm*/)

drop table #tmpgestcodi

end
