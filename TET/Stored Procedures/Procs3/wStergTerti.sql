--***
create procedure wStergTerti @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @Sub char(9), @mesaj varchar(200), 
	@tert char(13), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
IF OBJECT_ID('tempdb..#xmlterti') IS NOT NULL
	drop table #xmlterti

begin try
	select tert
		into #xmlterti
		from OPENXML(@iDoc, '/row')
		WITH
		(
			tert char(13) '@tert'
		)
		where isnull(tert, '')<>''
	
	exec sp_xml_removedocument @iDoc 

	select @referinta=dbo.wfRefTerti(x.tert), 
		@tert=(case when @referinta>0 and @tert is null then x.tert else @tert end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlterti x
	if @tert is not null
	begin
		set @mesajEroare='Tertul ' + RTrim(@tert) + ' are ' + (case @tabReferinta when 1 then 'bonuri in PV sau facturi' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete t
	from terti t, #xmlterti x
	where t.subunitate=@Sub and t.tert=x.tert
	
	delete i
	from infotert i, #xmlterti x
	where i.subunitate=@Sub and i.tert=x.tert
	
end try
begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlterti') IS NOT NULL
	drop table #xmlterti
	
--select @mesaj as mesajeroare for xml raw
