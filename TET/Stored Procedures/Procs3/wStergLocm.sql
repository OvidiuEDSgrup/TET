--***
create procedure wStergLocm @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @mesaj varchar(200), 
	@lm char(9), @referinta int, @tabReferinta int, @mesajEroare varchar(100)

EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmllm') IS NOT NULL
	drop table #xmllm

begin try
select lm
	into #xmllm
	from OPENXML(@iDoc, '/row')
	WITH
	(
		lm char(13) '@lm'
	)
	where isnull(lm, '')<>''
	
	exec sp_xml_removedocument @iDoc 

	select @referinta=dbo.wfReflm(x.lm), 
		@lm=(case when @referinta>0 and @lm is null then x.lm else @lm end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmllm x
	if @lm is not null
	begin
		set @mesajEroare='Locul de munca ' + RTrim(@lm) + ' are ' + (case @tabReferinta when 1 then 'descendenti' when 2 then 'inregistrari' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end

	delete lm
	from lm, #xmllm x
	where lm.cod=x.lm
	
	delete s
	from speciflm s, #xmllm x
	where s.loc_de_munca=x.lm

--	stergere proprietati (pus initial pt. cazul in care se opereaza in macheta de locuri de munca proprietatea DOMENIU)
	delete p
	from proprietati p, #xmllm x
	where p.tip='LM' and p.Cod=x.lm
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmllm') IS NOT NULL
	drop table #xmllm


--select @mesaj as mesajeroare for xml raw
