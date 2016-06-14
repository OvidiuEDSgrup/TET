create table tempdb..tmpdocy10832    (tip char(2), numar char(8), data datetime, gestiune char(9), cod char(20), codi char(13))

create table #tmpgestcodi (gest char(9), codi char(13))
declare @nNr int, @nOldNr int
declare @cGest char(9), @cCod char(20), @cCodI char(13), @nPret float

declare tmpy cursor for
	select (case when tip='TE' then gestiune_primitoare else gestiune end), cod
	, (case when tip='TE' and grupa<>'' then grupa else cod_intrare end), pret_de_stoc from pozdoc 
	where subunitate='1        ' and tip='RM' and numar='1/08    ' and data='01/10/2012'

open tmpy
fetch next from tmpy into @cGest, @cCod, @cCodI, @nPret

while @@fetch_status=0
begin
	truncate table #tmpgestcodi 
	insert into #tmpgestcodi values (@cGest, @cCodI)
	set @nOldNr = 0
	set @nNr = 1
	while @nOldNr <> @nNr
	begin
		set @nOldNr = @nNr

		insert into #tmpgestcodi 
		select gestiune_primitoare, (case when grupa<>'' then grupa else cod_intrare end) 
		from pozdoc where subunitate='1        ' and tip='TE' and data>='01/01/2012' and cod=@cCod /*and pret_de_stoc<>@nPret */
		and exists (select 1 from #tmpgestcodi where gest=gestiune and codi=cod_intrare) 
		and not exists (select 1 from #tmpgestcodi where gest=gestiune_primitoare and codi=(case when grupa<>'' then grupa else cod_intrare end)) 
		
		set @nNr = (select count(*) from #tmpgestcodi) 
	end
	
	insert into tempdb..tmpdocy10832    
	select tip, numar, data, gestiune, cod, cod_intrare from pozdoc 
	where subunitate='1        ' and cod=@cCod and data>='01/01/2012' and (1=0 or tip_miscare='E') and pret_de_stoc<>@nPret 
	and exists (select 1 from #tmpgestcodi where gest=gestiune and codi=cod_intrare) 
	
	update p
	set pret_de_stoc=@nPret, 
		adaos=(case when p.tip in ('AP', 'AC') or p.tip='TE' and isnull(g.tip_gestiune, '') in ('A', 'V') then round(convert(decimal(15,5), 100*((case when p.tip='TE' then p.pret_cu_amanuntul/(1.00+p.tva_neexigibil/100.00) else p.pret_vanzare end)/@nPret - 1)), 2) else p.adaos end)
	from pozdoc p 
	left outer join gestiuni g on p.tip='TE' and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune_primitoare
	where p.subunitate='1        ' and p.cod=@cCod and p.data>='01/01/2012' and (1=0 or p.tip_miscare='E') and p.pret_de_stoc<>@nPret 
	and exists (select 1 from #tmpgestcodi where gest=p.gestiune and codi=p.cod_intrare) 
	
	fetch next from tmpy into @cGest, @cCod, @cCodI, @nPret
end

close tmpy
deallocate tmpy

drop table #tmpgestcodi
GO

create table tempdb..tmpdocy:7 (tip char(2), numar char(8), data datetime, gestiune char(9), cod char(20), codi char(13))

create table #tmpgestcodi (gest char(9), codi char(13))
declare @nNr int, @nOldNr int
declare @cGest char(9), @cCod char(20), @cCodI char(13), @nPret float

declare tmpy cursor for
	select gestiune, cod, cod_intrare, pret_de_stoc from pozdoc 
	where subunitate=':1' and tip=':2' and numar=':3' and data=':4'

open tmpy
fetch next from tmpy into @cGest, @cCod, @cCodI, @nPret

while @@fetch_status=0
begin
	truncate table #tmpgestcodi 
	insert into #tmpgestcodi values (@cGest, @cCodI)
	set @nOldNr = 0
	set @nNr = 1
	while @nOldNr <> @nNr
	begin
		set @nOldNr = @nNr

		insert into #tmpgestcodi 
		select gestiune_primitoare, (case when grupa<>'' then grupa else cod_intrare end) 
		from pozdoc where subunitate=':1' and tip='TE' and data>=':5' and cod=@cCod and pret_de_stoc<>@nPret 
		and exists (select 1 from #tmpgestcodi where gest=gestiune and codi=cod_intrare) 
		and not exists (select 1 from #tmpgestcodi where gest=gestiune_primitoare and codi=(case when grupa<>'' then grupa else cod_intrare end)) 
		
		set @nNr = (select count(*) from #tmpgestcodi) 
	end
	
	insert into tempdb..tmpdocy:7 
	select tip, numar, data, gestiune, cod, cod_intrare from pozdoc 
	where subunitate=':1' and cod=@cCod and data>=':5' and (:6=0 or tip_miscare='E') and pret_de_stoc<>@nPret 
	and exists (select 1 from #tmpgestcodi where gest=gestiune and codi=cod_intrare) 
	
	update p
	set pret_de_stoc=@nPret, 
		adaos=(case when p.tip in ('AP', 'AC') or p.tip='TE' and isnull(g.tip_gestiune, '') in ('A', 'V') then round(convert(decimal(15,5), 100*((case when p.tip='TE' then p.pret_cu_amanuntul/(1.00+p.tva_neexigibil/100.00) else p.pret_vanzare end)/@nPret - 1)), 2) else p.adaos end)
	from pozdoc p 
	left outer join gestiuni g on p.tip='TE' and g.subunitate=p.subunitate and g.cod_gestiune=p.gestiune_primitoare
	where p.subunitate=':1' and p.cod=@cCod and p.data>=':5' and (:6=0 or p.tip_miscare='E') and p.pret_de_stoc<>@nPret 
	and exists (select 1 from #tmpgestcodi where gest=p.gestiune and codi=p.cod_intrare) 
	
	fetch next from tmpy into @cGest, @cCod, @cCodI, @nPret
end

close tmpy
deallocate tmpy

drop table #tmpgestcodi

go


(case when isnull((select max(te.grupa) from pozdoc te, pozdoc ap where
ap.tip='AP' and te.tip='TE' and te.cod=ap.cod and ap.cod_intrare=te.grupa
and p.contract=ap.Contract),'')='' then

(select SUM(cm.cantitate) from pozdoc pp,pozdoc cm,pozdoc ap where
ap.tip='AP' and pp.cod=ap.Cod and pp.Cod_intrare=ap.Cod_intrare and
pp.tip='PP' and cm.Tip='CM' and pp.Numar=cm.Numar and pp.Data=cm.data and
p.contract=ap.Contract)

else (select SUM(cm.cantitate) from pozdoc pp,pozdoc cm, pozdoc te,pozdoc ap
where ap.tip='AP' and te.tip='TE' and pp.cod=ap.Cod and ap.cod=te.Cod and
ap.Cod_intrare=te.grupa and pp.Cod_intrare=te.Cod_intrare and pp.tip='PP'
and cm.Tip='CM' and pp.Numar=cm.Numar and pp.Data=cm.data and
p.contract=ap.Contract)

end)