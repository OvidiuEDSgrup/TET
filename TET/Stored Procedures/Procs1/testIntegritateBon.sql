/*
	procedura destinata testarii PVria - se apeleaza din teste pt. a verifica corectitudinea descarcarii de gestiune.
	Se face cu procedura separata pt. a nu dubla codul comun.
*/
create procedure testIntegritateBon @sesiune varchar(50), @idAntetbon int, @verificaTeAutomat bit=0 
as

declare @msgEroare varchar(5000), @numarInPozdoc varchar(50), @dataBon Datetime, @tipDoc varchar(50), @gestpv varchar(50)
set nocount on

begin try
	select	@numarInPozdoc = bon.value('(/date/document/@numar_in_pozdoc)[1]', 'varchar(50)'),
			@tipDoc = bon.value('(/date/document/@tipdoc)[1]', 'varchar(50)'),
			@dataBon = a.Data_bon,
			@gestpv = a.gestiune
	from antetBonuri a where idantetbon=@idantetbon

	declare @bonuri table(idantetbon int)

	-- pun toate bonurile cu acelasi numar de document aici. (pt. cand setarea pt. cumulare documente e activa)
	insert into @bonuri(idantetbon)
	select idantetbon
	from antetBonuri a 
	where a.data_bon=@dataBon
	and bon.value('(/date/document/@numar_in_pozdoc)[1]', 'varchar(50)')=@numarInPozdoc

	if object_id('tempdb..#liniiPv') is not null
		drop table #liniiPv

	if object_id('tempdb..#liniiPozdoc') is not null
		drop table #liniiPozdoc

	if object_id('tempdb..#pozdoctmp') is not null
		drop table #pozdoctmp

	select cod_produs cod, sum(convert(decimal(15,3),cantitate)) cantitate, sum(convert(decimal(15,2),total)) total, sum(convert(decimal(15,2),tva)) tva
		into #liniiPv
	from bp, @bonuri b
	where b.idAntetBon=bp.idAntetBon
	group by cod_produs

	select *
		into #pozdoctmp
	from pozdoc p
	where subunitate='1' and data=@dataBon  and tip in ('AP','AC', 'TE') and numar=@numarInPozdoc 
	
	select cod, tip, sum(convert(decimal(15,3),cantitate)) cantitate, 
		sum(convert(decimal(15,2),round(round(cantitate*pret_vanzare,2)+tva_deductibil,2))) total, 
		sum(convert(decimal(15,2),tva_deductibil)) tva
		into #liniiPozdoc
	from #pozdoctmp p
	group by cod, tip

	--select * from #liniipv
	--select * from #liniiPozdoc

	--select * 
	--from pozdoc 
	--where subunitate='1' and data=@dataBon  and tip in ('AP','AC', 'TE')
	--and numar=@numarInPozdoc
	
	--select *
	--from bp
	--where idAntetBon=@idAntetBon
	
	if not exists (select * from #liniiPv)
		EXEC tSQLt.Fail N'Nu exista linii in tabela bp pt documentul generat.'

	if not exists (select * from #liniiPozdoc)
		EXEC tSQLt.Fail N'Nu exista linii in tabela pozdoc pt documentul generat.'

	if exists (select * from #liniiPv lpv, #liniipozdoc lpd where lpv.cod=lpd.cod and lpd.tip = @tipDoc and lpv.cantitate<>lpd.cantitate)
		EXEC tSQLt.Fail N'Cantitatea vanduta in PV difera de cantitatea descarcata in pozdoc.'

	if exists (select * from #liniiPv lpv, #liniipozdoc lpd where lpv.cod=lpd.cod and lpd.tip = @tipDoc and lpv.tva<>lpd.tva)
	begin
		select * from #liniiPv lpv, #liniipozdoc lpd where lpv.cod=lpd.cod and lpd.tip = @tipDoc and round(lpv.tva,2)<>round(lpd.tva,2)
		EXEC tSQLt.Fail N'TVA din PV difera de TVA descarcata in pozdoc.'
	end

	if exists (	select * 
				from #liniiPv lpv, #liniipozdoc lpd 
				where lpv.cod=lpd.cod and lpd.tip = @tipDoc and round(lpv.total,2)<>round(lpd.total,2))
		EXEC tSQLt.Fail N'Exista diferente intre totalul pozitiilor din PV si cele din pozdoc.'

	if @verificaTeAutomat=1
	begin
		-- aici ar trebui luate (cel putin) date din pozdoc pentru a verifica daca gestiunile de TE automat sunt cele din lista,
		-- sa verificam daca pret amanunt primitor/predator e corect, si daca toate cantitatile sunt ok
		declare @gestiuniTe varchar(500)
		set @gestiuniTe = ';'+(select rtrim(val_alfanumerica) from par where tip_parametru='PG' and parametru=@gestpv)+';'
		
		if exists (	select * from #pozdoctmp p where p.tip='TE')
			EXEC tSQLt.Fail N'Nu s-a generat niciun transfer aferent acestuni bon.'

		if exists (	select * 
					from #pozdoctmp p
					where p.tip='TE' and charindex(';'+RTrim(p.gestiune)+';',@gestiuniTe)=0)
			EXEC tSQLt.Fail N'Exista transferuri din gestiuni care nu au fost atasate gestiunii GESTPV.'

		if exists (	select * 
				from #liniipozdoc lpt, #liniipozdoc lpd 
				where lpt.cod=lpd.cod and lpd.tip = @tipDoc and lpt.tip='TE' and lpt.cantitate<>lpd.cantitate)
			EXEC tSQLt.Fail N'Exista diferente de cantitate TE/AC'
	end
	
end try
begin catch
	set @msgEroare = ERROR_MESSAGE()+' (testIntegritateBon)'
end catch

if object_id('tempdb..#liniiPv') is not null
	drop table #liniiPv

if object_id('tempdb..#liniiPozdoc') is not null
	drop table #liniiPozdoc

if object_id('tempdb..#pozdoctmp') is not null
	drop table #pozdoctmp

if len(@msgEroare)>0
	raiserror(@msgeroare,11,1)
