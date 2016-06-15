
create procedure wOPDetaliiPozitieTehn @sesiune varchar(50), @parXML XML  
as
begin try
	declare 
		@idPozTehnologie int
		
	select
		@idPozTehnologie = @parXML.value('(/*/@idPozTehnologie)[1]','int')

	IF OBJECT_ID('tempdb.dbo.#sdv') IS NOT NULL
		drop table #sdv

	select 
		D.cod.value('(@idDetaliu)[1]', 'int') idDetaliu,
		D.cod.value('(@ordine)[1]', 'int') ordine,
		D.cod.value('(@descriere)[1]', 'varchar(1000)') descriere,
		D.cod.value('(@scule)[1]', 'varchar(200)') scule,
		D.cod.value('(@dispozitive)[1]', 'varchar(200)') dispozitive,
		D.cod.value('(@verificatoare)[1]', 'varchar(200)') verificatoare
	into #sdv
	FROM @parXML.nodes('*/DateGrid/row') D(cod)	
	where ISNULL(D.cod.value('(@ordine)[1]', 'int'),0)>0
	
	begin tran

		delete DetaliiPozTehnologii where idPozTehnologii=@idPozTehnologie

		insert into DetaliiPozTehnologii (idPozTehnologii, ordine, descriere, scule, dispozitive, verificatoare)
		select @idPozTehnologie, ordine, descriere, scule, dispozitive, verificatoare
		from #sdv
	commit tran

end try
begin catch
	declare @mesaj varchar(2000)
	IF @@TRANCOUNT>0
		ROLLBACK TRAN
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
