--***
CREATE procedure wStergConturi @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @Sub char(9), @mesaj varchar(200), 
	@cont varchar(40), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmlconturi') IS NOT NULL
	drop table #xmlconturi

begin try
select cont
	into #xmlconturi
	from OPENXML(@iDoc, '/row')
	WITH
	(
		cont varchar(40) '@cont'
	)
	where isnull(cont, '')<>''
	
	exec sp_xml_removedocument @iDoc 

	select @referinta=dbo.wfRefConturi(x.cont), 
		@cont=(case when @referinta>0 and @cont is null then x.cont else @cont end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlconturi x
	if @cont is not null
	begin
		set @mesajEroare='Contul ' + RTrim(@cont) + ' are ' + (case @tabReferinta when 1 then 'analitice' when 2 then 'rulaje' when 3 then 'inregistrari' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete c
	from conturi c, #xmlconturi x
	where c.subunitate=@Sub and c.cont=x.cont
	
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlconturi') IS NOT NULL
	drop table #xmlconturi

--select @mesaj as mesajeroare for xml raw
