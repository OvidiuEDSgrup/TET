
CREATE PROCEDURE wPrelucrareComenziRezervari @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	
	/* Actualizam #documente cu diverse informatii */
	update d
		set cod_intrare=r.cod_intrare, colet=r.colet, idIntrare=r.idIntrare,
		gestiune_primitoare=(case when d.gestiune!=r.Gestiune then d.gestiune else d.gestiune_primitoare end),
		gestiune=r.Gestiune, d.detalii= r.detalii
	from #documente d
	JOIN PozDoc r on d.idPozDocRezervare=r.idPozDoc

	delete #documente where abs(cantitate)<0.05

	create table #docDeSters(subunitate varchar(20),tip varchar(20),numar varchar(20),data datetime)

	delete p
	OUTPUT DELETED.subunitate,deleted.tip,deleted.numar,deleted.data
	into #docDeSters
	from PozDoc p
	JOIN #documente r on p.idPozDoc=r.idPozDocRezervare

	delete d
	from #DocDeSters ds
	inner join doc d on d.Subunitate=ds.subunitate and d.tip=ds.tip and d.numar=ds.numar and d.data=ds.data
	left join pozdoc p on d.Subunitate=p.subunitate and d.tip=p.tip and d.numar=p.numar and d.data=p.data
	where p.subunitate is null
	
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
