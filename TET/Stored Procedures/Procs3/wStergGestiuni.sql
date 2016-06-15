--***
CREATE procedure wStergGestiuni @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @Sub char(9), @mesaj varchar(200), 
	@gestiune char(9), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

begin try
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlgestiuni') IS NOT NULL
	drop table #xmlgestiuni

	select gestiune
	into #xmlgestiuni
	from OPENXML(@iDoc, '/row')
	WITH
	(
		gestiune char(9) '@gestiune'
	)
	where isnull(gestiune, '')<>''
	
	exec sp_xml_removedocument @iDoc 

	select @referinta=dbo.wfRefGestiuni(x.gestiune), 
		@gestiune=(case when @referinta>0 and @gestiune is null then x.gestiune else @gestiune end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlgestiuni x
	if @gestiune is not null
	begin
		set @mesajEroare='Gestiunea ' + RTrim(@gestiune) + ' apare in ' + (case @tabReferinta when 1 then 'stocuri' when 2 then 'istoric stocuri' when 3 then 'rulaje' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete g
	from gestiuni g, #xmlgestiuni x
	where g.subunitate=@Sub and g.cod_gestiune=x.gestiune
	
	/** Stergem toate proprietatile gestiunii, daca gestiunea a fost stearsa */
	delete pr from proprietati pr
	inner join #xmlgestiuni x on pr.Tip = 'GESTIUNE' and pr.Cod = x.gestiune

	set @mesaj=''
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj,11,1)
end catch

IF OBJECT_ID('tempdb..#xmlgestiuni') IS NOT NULL
	drop table #xmlgestiuni
