--***
create procedure wScriuCfgFormulare (@sesiune varchar(50), @parXML xml)
as
begin
declare @eroare varchar(2000)
begin try
	declare @utilizator varchar(20)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	if object_id('tempdb..#tmp') is not null drop table #tmp
--	citire parametri
	declare @formular varchar(20), @denumire varchar(50), @procedura varchar(1000), @tip varchar(1), @transformare varchar(200), @exml bit,
			@o_formular varchar(20), @tipformular varchar(20), @caleraport varchar(150),
			@update bit

	select	@formular=rtrim(isnull(@parXML.value('(row/@formular)[1]','varchar(20)'),'')),
			@denumire=@parXML.value('(row/@denumire)[1]','varchar(50)'),
			@procedura=rtrim(isnull(@parXML.value('(row/@procedura)[1]','varchar(1000)'),'')),
			@exml=isnull(@parXML.value('(row/@exml)[1]','bit'),''),
			@transformare=rtrim(isnull(@parXML.value('(row/@sablon)[1]','varchar(200)'),'')),
			@tip=isnull(@parXML.value('(row/@o_tip)[1]','varchar(200)'),''),
			@update=isnull(@parXML.value('(row/@update)[1]','varchar(200)'),0),
			@o_formular=rtrim(isnull(@parXML.value('(row/@o_formular)[1]','varchar(20)'),'')),
			@tipformular=isnull(@parXML.value('(row/@tipformular)[1]','varchar(20)'),''),
			@caleraport=rtrim(isnull(@parXML.value('(row/@cale_raport)[1]','varchar(150)'),''))

		-->tipul nu prea conteaza, pentru compatibilitate in urma il iau din BD
	select @tip=Tip_formular from antform a where a.Numar_formular=@o_formular
	select @tip=isnull(@tip,'')

--	erori
	if (@tipformular='Altele')
		raiserror('Acest tip de formular se configureaza din ASiSplus!',16,1)
	if (@formular='') raiserror ('Completati cu un numar de formular!',16,1)
	if (@tipformular='Raport') and (@caleraport='')
		raiserror ('Completati calea raportului!',16,1)
	if (@tipformular='Procedura') and (@procedura='') 
		raiserror ('Completati procedura!',16,1)
	if (@tipformular='Raport') and (@procedura <> '')
		raiserror('Procedura nu se completeaza pentru tipul Raport!',16,1)
	if (@tipformular='Procedura') and (@caleraport <> '')
		raiserror('Calea raportului nu se completeaza pentru tipul Procedura!',16,1)
	if not exists(select 1 from sysobjects where type='P' and name=@procedura) and (@tipformular='Procedura')
			raiserror('Procedura nu exista in baza de date!',16,1)
	if (@update=1) 
	begin
		if (@o_formular='') raiserror ('Nu s-a identificat formularul care trebuie modificat!',16,1)
		if (@o_formular<>@formular) and exists (select 1 from antform a where a.Numar_formular=@formular)
			raiserror('Numar de formular existent! Schimbati-l!',16,1)
		if not exists (select 1 from antform a where a.Numar_formular=@o_formular)
			raiserror('Formularul de modificat nu exista in baza de date!',16,1)
		--if not exists (select 1 from antform a where a.Numar_formular=@o_formular and a.CLFrom='PROCEDURA')
			--raiserror('Formularul de modificat nu e cu procedura! Nu e permisa modificarea!',16,1)
	end

--	Modificare/Adaugare propriu-zisa
	--	Incarcarea fisierului xml:
	declare @cale varchar(2000), @cmd varchar(4000)
	create table #tmp(continut varchar(max))
	if @exml=1 and not exists (select 1 from xmlformular x where x.numar_formular=@o_formular and len(isnull(x.continut,''))>0) and
		@transformare='' raiserror('Alegeti sablonul cu xml al formularului!',16,1)	--> daca avea sablon in BD nu e necesar sa se reincarce
	if (@exml=1 and @transformare<>'')
	begin
		select @cale=val_alfanumerica from par where tip_parametru='ar' and parametru='CALEFORM'
		if (@cale is null) raiserror ('Calea pentru formulare nu este configurata! Incarcarea fisierului XML a esuat!',16,1)
		select @transformare=rtrim(@cale)+'\uploads\'+@transformare
		select @cmd=
'		insert into #tmp(continut)
		SELECT x.a as continut
			FROM OPENROWSET(BULK '''+@transformare+''', single_clob) as x(a)'
			exec (@cmd)
	end

	if (@exml=1 and @transformare='') 
		set @transformare=(select top 1 a.transformare from antform a where a.Numar_formular=@o_formular)

	-- scrierea datelor in tabele:
	if (@update=0)
	begin
		insert into antform(Numar_formular, Denumire_formular, Linii_in_pozitii, Linii_pe_pagina, CLFrom,
					CLWhere, CLOrder, Tip_formular, eXML, Transformare)
		select @formular, @denumire, 0, 0, @tipformular,
					(case when @tipformular='Procedura' then @procedura
					else @caleraport end), '', '', (case when @transformare='' then 0 else 1 end), @transformare
		insert into XMLFormular(Numar_formular, Versiune, Continut, Nume_fisier, Last_modified_date)
		select @formular, 0, null, null, null
	end
	else
	begin
		update a set a.CLFrom=@tipformular, a.Numar_formular=@formular, a.Denumire_formular=@denumire,
					a.CLWhere=(case when @tipformular='Procedura' then @procedura else @caleraport end),
					a.Transformare=@transformare,
					a.eXML=(case when @transformare='' then 0 else 1 end)
		from antform a where a.Numar_formular=@o_formular

		if not exists(select 1 from xmlformular x where x.Numar_formular=@o_formular)
		insert into XMLFormular(Numar_formular, Versiune, Continut, Nume_fisier, Last_modified_date)
			select @o_formular, 0, null, null, null

		update x set x.Numar_formular=@formular
			from xmlformular x where x.Numar_formular=@o_formular

		update w set w.cod_formular=@formular
			from WebConfigFormulare w where w.cod_formular=@o_formular
	end

	if (select count(1) from #tmp)>0
	update x set x.Continut=t.continut
		from xmlformular x, #tmp t where rtrim(x.Numar_formular)=@formular
	if object_id('tempdb..#tmp') is not null drop table #tmp
end try
begin catch
	set @eroare=ERROR_MESSAGE()+' (wScriuCfgFormulare '+convert(varchar(20),ERROR_LINE())+')'
end catch
if len(@eroare)>0 raiserror(@eroare, 16,1)
end
