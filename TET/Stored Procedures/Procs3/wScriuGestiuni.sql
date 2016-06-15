--***
create procedure wScriuGestiuni @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @Sub char(9), @mesaj varchar(200), 
	@gestiune char(9), @referinta int, @tabReferinta int, @mesajEroare varchar(100), 
	@UltGestiune int, @detalii xml, @docDetalii xml

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML


IF OBJECT_ID('tempdb..#xmlgestiuni') IS NOT NULL
	drop table #xmlgestiuni

begin try
	select isnull(ptupdate, 0) as ptupdate, upper(gestiune) as gestiune, upper(isnull(gestiune_veche, gestiune)) as gestiune_veche, 
		upper(denumire) as denumire, upper(tip_gestiune) as tip_gestiune, upper(tert) as tert, upper(cont) as cont, upper(lm) as lm,
		isnull(categpret, '') as categpret, detalii
	into #xmlgestiuni
	from OPENXML(@iDoc, '/row')
	WITH
	(
		detalii xml 'detalii/row',
		ptupdate int '@update', 
		gestiune char(9) '@gestiune', 
		gestiune_veche char(9) '@o_gestiune', 
		denumire char(30) '@dengestiune', 
		tip_gestiune char(1) '@tipgestiune', 
		tert char(13) '@tert', 
		cont varchar(40) '@cont',
		categpret varchar(20) '@categpret',
		lm varchar(13) 'detalii/row/@lm' -- lm si denlm se scriu in gestiuni.detalii
	)
	exec sp_xml_removedocument @iDoc 
	
	while exists (select 1 from #xmlgestiuni x where x.ptupdate=0 and isnull(x.gestiune, '')='')
	begin
		if @UltGestiune is null
			exec luare_date_par 'GE', 'GESTIUNE', 0, @UltGestiune output, ''
		set @UltGestiune = @UltGestiune + 1
		while exists (select 1 from gestiuni where subunitate=@Sub and cod_gestiune=RTrim(LTrim(convert(char(9), @UltGestiune))))
			set @UltGestiune = @UltGestiune + 1
		update top (1) x
		set gestiune=RTrim(LTrim(convert(char(9), @UltGestiune)))
		from #xmlgestiuni x
		where x.ptupdate=0 and isnull(x.gestiune, '')=''
	end
	if @UltGestiune is not null
		exec setare_par 'GE', 'GESTIUNE', null, null, @UltGestiune, null
	
	if exists (select 1 from #xmlgestiuni where isnull(gestiune, '')='')
		raiserror('Gestiune necompletata', 16, 1)
	
	select @gestiune=x.gestiune
	from #xmlgestiuni x, gestiuni g 
	where g.subunitate=@Sub and g.cod_gestiune=x.gestiune and (x.ptupdate=0 or x.ptupdate=1 and x.gestiune<>x.gestiune_veche)
	if @gestiune is not null
	begin
		set @mesajEroare='Gestiunea ' + RTrim(@gestiune) + ' este deja introdusa'
		raiserror(@mesajEroare, 16, 1)
	end
	
	update x
	set tip_gestiune='C'
	from #xmlgestiuni x
	where x.ptupdate=0 and tip_gestiune is null
	
	select @gestiune=x.gestiune
	from #xmlgestiuni x
	where x.ptupdate=0 and isnull(x.tip_gestiune, '')=''
	if @gestiune is not null
	begin
		set @mesajEroare='Tip gestiune necompletat pentru gestiunea ' + RTrim(@gestiune)
		raiserror(@mesajEroare, 16, 1)
	end
	
	select @referinta=dbo.wfRefGestiuni(x.gestiune_veche), 
		@gestiune=(case when @referinta>0 and @gestiune is null then x.gestiune_veche else @gestiune end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlgestiuni x
	where x.ptupdate=1 and x.gestiune<>x.gestiune_veche
	if @gestiune is not null
	begin
		set @mesajEroare='Gestiunea ' + RTrim(@gestiune) + ' apare in ' + (case @tabReferinta when 1 then 'stocuri' when 2 then 'istoric stocuri' when 3 then 'rulaje' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	insert gestiuni
	(Subunitate, Tip_gestiune, Cod_gestiune, Denumire_gestiune, Cont_contabil_specific, detalii)
	select @Sub, x.tip_gestiune, x.gestiune, isnull(x.denumire, space(30)) + isnull(x.tert, ''), isnull(x.cont, ''), x.detalii
	from #xmlgestiuni x
	where x.ptupdate=0
	
	/** daca exista tabela gestcor, se vor introduce si acolo gestiunea si locul de munca (ulterior, tabela se va elimina) */
	if exists (select 1 from sys.sysobjects where name = 'gestcor' and type = 'U')
		if isnull((select lm from #xmlgestiuni where ptupdate=0),'')<>''--daca s-a introdus locul de munca coresp gestiunii se insereaza in gestcor
			insert gestcor (Gestiune,Loc_de_munca)
			select x.gestiune,x.lm
			from #xmlgestiuni x
			where x.ptupdate=0	

	update g
	set cod_gestiune=isnull(x.gestiune, g.cod_gestiune), tip_gestiune=isnull(x.tip_gestiune, g.tip_gestiune), 
		denumire_gestiune=isnull(x.denumire, left(g.denumire_gestiune, 30)) + isnull(x.tert, substring(g.denumire_gestiune, 31, 13)), 
		cont_contabil_specific=isnull(x.cont, g.cont_contabil_specific), g.detalii=x.detalii
	from gestiuni g, #xmlgestiuni x
	where x.ptupdate=1 and g.subunitate=@Sub and g.cod_gestiune=x.gestiune_veche
	
	/** daca exista tabela gestcor, se vor introduce si acolo gestiunea si locul de munca (ulterior, tabela se va elimina) */
	if exists (select 1 from sys.sysobjects where name = 'gestcor' and type = 'U')
	begin
		if not exists (select 1 from gestcor g inner join #xmlgestiuni x on g.Gestiune=x.gestiune)
			and isnull((select lm from #xmlgestiuni where ptupdate=1),'')<>''
				
			insert gestcor (Gestiune,Loc_de_munca)
			select x.gestiune,x.lm
			from #xmlgestiuni x
			where x.ptupdate=1
		else	
			update ge ---se face update si pe locul d emunca din gestcor
			set Gestiune=isnull(x.gestiune, ge.gestiune),loc_de_munca=ISNULL(x.lm,ge.loc_de_munca)
			from gestcor ge, #xmlgestiuni x
			where x.ptupdate=1 and ge.gestiune=x.gestiune_veche
	end

	/** Inserare categpret in proprietati */
	insert into proprietati (Tip, Cod, Cod_proprietate, Valoare, Valoare_tupla)
	select 'GESTIUNE', x.gestiune, 'CATEGPRET', x.categpret, ''
	from #xmlgestiuni x
	where (x.ptupdate = 0) or (x.ptupdate = 1 and not exists (select 1 from proprietati pr where pr.Tip = 'GESTIUNE' and x.gestiune = pr.Cod
		and pr.Cod_proprietate = 'CATEGPRET'))

	/** Modificare proprietate categpret daca se da update pe gestiuni */
	update pr
	set pr.Valoare = x.categpret
	from proprietati pr
	inner join #xmlgestiuni x on pr.Tip = 'GESTIUNE' and x.gestiune = pr.Cod and pr.Cod_proprietate = 'CATEGPRET'
	where x.ptupdate = 1

end try

begin catch
	set @mesajEroare = ERROR_MESSAGE()+'(wScriuGestiuni)'
	raiserror(@mesajEroare, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlgestiuni') IS NOT NULL
	drop table #xmlgestiuni

--select @mesaj as mesajeroare for xml raw
