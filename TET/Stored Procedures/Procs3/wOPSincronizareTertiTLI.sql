create  procedure wOPSincronizareTertiTLI @sesiune varchar(50), @parXML xml
as
begin try
	declare @mesaj varchar(max)
	
	SELECT	
		T.cf.value('(@codfiscal)[1]', 'varchar(100)') codfiscal,
		T.cf.value('(@tert)[1]', 'varchar(100)') tert,
		T.cf.value('(@dela)[1]', 'datetime') dela,		
		ta.tiptva tiptva
	INTO #tertiDePrelucrat
	FROM @parXML.nodes('*/DateGrid/row') T(cf)
	JOIN TvaPeTertiASW ta on ta.tert=T.cf.value('(@tert)[1]', 'varchar(100)')
	where T.cf.value('(@actualizeaza)[1]', 'varchar(1)')='1'
	
	/* Acest SP va putea alter datele din tabelul tmp. #tertiDePrelucrat	*/
	IF EXISTS (SELECT *	FROM sysobjects	WHERE NAME = 'wOPSincronizareTertiTLISP')
		exec wOPSincronizareTertiTLISP @sesiune = @sesiune, @parXML = @parXML

	insert into TvaPeTerti(Tert, dela,tip_tva,tipf )
	select distinct 
		t.Tert, t.dela, t.tiptva,'F'
	from #tertiDePrelucrat t	
	where not exists(select 1 from tvapeterti where tert=t.tert and dela=t.dela and tipf='F' and factura is null )

	select 
		'Tertii au fost actualizati!' as textMesaj, 'Notificari' as titluMesaj
	for XML raw, root('Mesaje')

	truncate table TvaPeTertiASW
end try

begin catch
	set @mesaj= ERROR_MESSAGE()+ ' (wOPSincronizareTertiTLI)'
	raiserror(@mesaj, 11,1 )
end catch