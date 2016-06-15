--***
create procedure wStergPuncteLivrare @sesiune varchar(50), @parXML xml
as

declare @DouaNivele int, @RowPattern varchar(20), @PrefixAtrTert varchar(3), @AtrTert varchar(20), 
	@iDoc int, @Sub char(9), 
	@mesaj varchar(200), @tert char(13), @punct_livrare char(5), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output 

select @DouaNivele = @parXML.exist('/row/row'), 
	@RowPattern = '/row' + (case when @DouaNivele=1 then '/row' else '' end), 
	@PrefixAtrTert = (case when @DouaNivele=1 then '../' else '' end), 
	@AtrTert = @PrefixAtrTert + '@tert'

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmlpctliv') IS NOT NULL
	drop table #xmlpctliv

begin try
select tert, punct_livrare
		into #xmlpctliv
	from OPENXML(@iDoc, @RowPattern)
	WITH
	(
		tert char(13) @AtrTert, 
		punct_livrare char(5) '@punctlivrare'
	)
	where isnull(tert, '')<>'' and isnull(punct_livrare, '')<>''
	
	exec sp_xml_removedocument @iDoc 
	
	select @referinta=dbo.wfRefPuncteLivrare(x.tert, x.punct_livrare), 
		@tert=(case when @referinta>0 and @tert is null then x.tert else @tert end), 
		@punct_livrare=(case when @referinta>0 and @punct_livrare is null then x.punct_livrare else @punct_livrare end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlpctliv x
	if @punct_livrare is not null
	begin
		set @mesajEroare='Punctul de livrare ' + RTrim(@punct_livrare) + ' al tertului ' + RTrim(@tert) + ' apare in ' + (case @tabReferinta when 1 then 'documente' else 'alte documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete i
	from infotert i, #xmlpctliv x
	where i.subunitate=@Sub and i.tert=x.tert and i.identificator=x.punct_livrare
	
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlpctliv') IS NOT NULL
	drop table #xmlpctliv

--select @mesaj as mesajeroare for xml raw
