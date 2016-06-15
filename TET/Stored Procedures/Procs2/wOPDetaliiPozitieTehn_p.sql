
create procedure wOPDetaliiPozitieTehn_p @sesiune varchar(50), @parXML XML  
as
begin try
	declare 
		@idPozTehnologie int, @linii int

	IF @parXML.exist('(/row/row)[1]')=0
		raiserror('Operatia se utilizeaza in contextul componentelor tehnologiei (pozitii), nu in antet',16,1)

	select
		@idPozTehnologie = @parXML.value('(/*/row/@id)[1]','int')

	IF OBJECT_ID('tempdb.dbo.#populare_detalii') IS NOT NULL
		DROP TABLE #populare_detalii
	
	create table #populare_detalii (idDetaliu int, ordine int, descriere varchar(1000), scule varchar(200), dispozitive varchar(200), verificatoare varchar(200))
	
	insert into #populare_detalii (idDetaliu, ordine, descriere, scule, dispozitive, verificatoare)
	select
		idDetaliu, ordine, descriere, scule, dispozitive, verificatoare	
	from DetaliiPozTehnologii where idPozTehnologii=@idPozTehnologie

	select @linii=@@ROWCOUNT

	insert into #populare_detalii (idDetaliu, ordine, descriere, scule, dispozitive, verificatoare)
	select
		'','','','','',''	
	from Tally where N>@linii and n<16

	select @idPozTehnologie idPozTehnologie for xml raw, root('Date')
	select
	(
		select * from #populare_detalii
		order by (case when ordine>0 then ordine else 1000 end)
		for xml raw,type
	)
	FOR XML path('DateGrid'), root('Mesaje')

end try
begin catch
	select '1' as inchideFereastra for xml raw, root('Mesaje')
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
