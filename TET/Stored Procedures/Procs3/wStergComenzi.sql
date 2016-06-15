--***
create procedure wStergComenzi @sesiune varchar(50), @parXML xml
as

declare @iDoc int, @Sub char(9), @mesaj varchar(200), 
	@comanda char(20), @referinta int, @tabReferinta int, @mesajEroare varchar(100)
exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sub output  
EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML

IF OBJECT_ID('tempdb..#xmlcomenzi') IS NOT NULL
	drop table #xmlcomenzi

begin try
select comanda
	into #xmlcomenzi
	from OPENXML(@iDoc, '/row')
	WITH
	(
		comanda char(20) '@comanda'
	)
	where isnull(comanda, '')<>''
	
	exec sp_xml_removedocument @iDoc 
	
	select @referinta=dbo.wfRefComenzi(x.comanda), 
		@comanda=(case when @referinta>0 and @comanda is null then x.comanda else @comanda end), 
		@tabReferinta=(case when @referinta>0 and @tabReferinta is null then @referinta else @tabReferinta end)
	from #xmlcomenzi x
	where x.comanda<>x.comanda
	if @comanda is not null
	begin
		set @mesajEroare='Comanda ' + RTrim(@comanda) + ' are ' + (case @tabReferinta when 1 then 'inregistrari' when 2 then 'lansari' else 'documente' end)
		raiserror(@mesajEroare, 16, 1)
	end
	
	delete c
	from comenzi c, #xmlcomenzi x
	where c.subunitate=@Sub and c.comanda=x.comanda
	
	delete p
	from pozcom p, #xmlcomenzi x
	where p.subunitate in (@Sub, 'GR') and p.comanda=x.comanda
	
end try

begin catch
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch

IF OBJECT_ID('tempdb..#xmlcomenzi') IS NOT NULL
	drop table #xmlcomenzi

--select @mesaj as mesajeroare for xml raw
