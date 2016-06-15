--***
create procedure wStergPersoaneContact @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrTert varchar(3), @AtrTert varchar(20), 
	@iDoc int, @Sub char(9), @tip varchar(2),
	@mesaj varchar(200), @tert char(13), @identificator char(5), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 
select @tip = isnull(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 

select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrTert = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrTert = @PrefixAtrTert + '@tert'
	
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML


IF OBJECT_ID('tempdb..#xmlpersct') IS NOT NULL
	drop table #xmlpersct

begin try
select tert, identificator
		into #xmlpersct
	from OPENXML(@iDoc, @RowPattern)
	WITH
	(
		tert char(13) @AtrTert, 
		identificator char(5) '@identificator' 
	)
	where isnull(tert, '')<>'' and isnull(identificator, '')<>''
	
	exec sp_xml_removedocument @iDoc 
	
	select @referinta=dbo.wfRefPersoaneContact(x.tert, x.identificator), 
		@tert=(case when @referinta>0 and @tert is null then x.tert else @tert end), 
		@identificator=(case when @referinta>0 and @identificator is null then x.identificator else @identificator end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlpersct x
	if @identificator is not null
	begin
		set @mesajEroare='Persoana de contact ' + RTrim(@identificator) + ' a tertului ' + RTrim(@tert) + ' apare in ' + (case @tabReferinta when 1 then 'documente' else 'alte documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete i
	from infotert i, #xmlpersct x
	where i.subunitate='C'+@Sub and i.tert=x.tert and i.identificator=x.identificator
	
	--refresh pozitii in cazul in care tipul este 'SA','EV'-> tab de tip pozdoc
	if @tip in ('SA','EV')
	begin
		declare @docXMLIaPersoaneContact xml
		set @tert= (select top 1 x.tert from #xmlpersct x)
		set @docXMLIaPersoaneContact='<row tert="'+rtrim(@tert)+ '" tip="'+@tip +'"/>'
		exec wIaPersoaneContact @sesiune=@sesiune, @parXML=@docXMLIaPersoaneContact
	end
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlpersct') IS NOT NULL
	drop table #xmlpersct

--select @mesaj as mesajeroare for xml raw
