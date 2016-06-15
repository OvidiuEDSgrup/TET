
CREATE PROCEDURE wOPConfirmareTransfer @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare 
		@numar varchar(20), @data datetime, @lm_destinatar varchar(20), @sub varchar(9), @gest_detinatar varchar(20),
		@teConfirmat xml, @detalii_doc xml, @utilizator varchar(100), @detalii_poz xml

	select
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data=@parXML.value('(/*/@data)[1]','datetime'),
		@lm_destinatar=@parXML.value('(//@lmdest)[1]','varchar(20)')

	exec luare_date_par 'GE','SUBPRO',0,0,@sub output
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF ISNULL(@numar,'')=''
		raiserror('Completati numarul documentului de transfer pentru confirmare!',16,1)

	IF NOT EXISTS (select 1 from pozdoc where subunitate=@sub and tip='TE' and numar=@numar and data=@data)
		raiserror('Nu exista document de transfer cu datele (numar, data) introduse!',16,1)

	/* Se salveaza datele transferului, antet + pozitii */
	IF OBJECT_ID('tempdb.dbo.#tmp_pconfirm') IS NOT NULL
		drop table #tmp_pconfirm
	IF OBJECT_ID('tempdb.dbo.#tmp_confirm') IS NOT NULL
		drop table #tmp_confirm
		
	select * into #tmp_pconfirm from PozDoc where Subunitate=@sub and numar=@numar and data=@data and tip='TE'
	select top 1 * into #tmp_confirm from doc where Subunitate=@sub and numar=@numar and data=@data and tip='TE'

	IF NOT EXISTS (select 1 from #tmp_confirm where ISNULL(detalii.value('(/*/@gestdest)[1]','varchar(20)'),'')<>'')
		raiserror('Transferul indicat pentru confirmare nu contine informatii referitoare la gestiunea destinatara!',15,1)

	select @gest_detinatar=detalii.value('(/*/@gestdest)[1]','varchar(20)') from #tmp_confirm

	/*Se determina locul de munca destinatar, daca nu a fost completat */
	/* Pas 1- locul de munca asociat gestiunii */
	if ISNULL(@lm_destinatar,'')=''	
		select top 1 @lm_destinatar=g.Loc_de_munca from gestcor g where g.Gestiune=@gest_detinatar and g.loc_de_munca<>''

	/* Pas 2 locul de munca al documentulu initial */
	if ISNULL(@lm_destinatar,'')=''	
		select top 1 @lm_destinatar= Loc_munca from #tmp_confirm where subunitate=@sub and tip='TE' and Numar=@numar and data=@data

	/* Ultim pas- validare daca nu poate fi alocat din drepturi locul de munca determinat pana acuma se pune altul pe care are drept */
	if exists (select 1 from lmfiltrare where utilizator=@utilizator) and not exists (select 1 from lmfiltrare where utilizator=@utilizator and cod=@lm_destinatar) 
		select top 1 @lm_destinatar=cod from lmfiltrare l where l.utilizator=@utilizator

	update #tmp_confirm set Loc_munca=@lm_destinatar
	update #tmp_pconfirm set Loc_de_munca=@lm_destinatar

	set @detalii_doc=(select 'Transfer confirmat' explicatii for xml raw)	

	set @teConfirmat=
	(
		select 
			'TE' as tip, @data data, @numar numar,  Cod_gestiune gestiune, @gest_detinatar gestprim, @detalii_doc detalii, rtrim(loc_munca) lm, rtrim(comanda) comanda,
			convert(int, discount_suma) as categpret, 
			(
				select
					rtrim(cod) cod, convert(decimal(17,5), cantitate) cantitate, rtrim(cod_intrare) codintrare, NULLIF(cont_corespondent,'') contintermediar,
					RTRIM(Cont_de_stoc) contstoc, convert(decimal(17,5),pret_de_stoc) pstoc, rtrim(loc_de_munca) lm, rtrim(comanda) comanda, @detalii_poz detalii, gestiune gestiune,
					convert(int, accize_cumparare) as categpret
				from #tmp_pconfirm
				for xml raw, type
			)
		from #tmp_confirm
		for xml raw, type
	)

	begin tran
		delete PozDoc where Subunitate='1' and tip='TE' and numar=@numar and data=@data
		delete Doc where Subunitate='1' and tip='TE' and numar=@numar and data=@data
		
		exec wScriuPozDoc @sesiune=@sesiune, @parXML=@teConfirmat
	commit tran

END TRY
begin catch
	declare @mesaj varchar(4000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'

	IF @@TRANCOUNT>0
		rollback tran

	raiserror (@mesaj, 15, 1)
end catch
