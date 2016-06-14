--/*
IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'wScriuDocSP')
	DROP PROCEDURE wScriuDocSP
GO
--*/
CREATE PROCEDURE wScriuDocSP @sesiune varchar(50), @parXML xml OUTPUT --am inlocuit cu ALTER va da eroare in cazul in care nu exista
AS
begin try
	declare @subunitate varchar(13),@userASiS varchar(20), @gestProprietate varchar(20), @clientProprietate varchar(13), @lmProprietate varchar(20), @jurnalProprietate varchar(3),
			@returneaza_inserate bit, @rootDoc varchar(20),@multiDoc int, @rootDocAntet varchar(20),@StocuriNoi int
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	exec luare_date_par 'AR', 'NSTOC', @StocuriNoi output, 0, ''

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS OUTPUT
	
	if OBJECT_ID('tempdb..#documente') is null
		create table #documente(tip varchar(2),numar varchar(20),data datetime,gestiune varchar(13),gestiune_primitoare varchar(20),tert varchar(13),factura varchar(20),
		data_facturii datetime,data_scadentei datetime,loc_de_munca varchar(13),numar_pozitie int,cod varchar(20),barcod varchar(20),codcodi varchar(50),cantitate float,pret_valuta float,pret_vanzare float,
		tip_tva int,zilescadenta int,facturanesosita int,aviznefacturat int,cod_intrare varchar(20),codiPrim varchar(20),pret_cu_amanuntul float,cota_tva int,tva_deductibil decimal(12,2),
		tva_valuta float,comanda varchar(20),indbug varchar(20),pret_de_stoc float,pret_amanunt_predator float,valuta varchar(3),curs float,locatie varchar(20),[contract] varchar(20),
		lot varchar(20),data_expirarii datetime,discount decimal(12,3),punctlivrare varchar(13),numar_dvi varchar(20),categ_pret int,
		cont_de_stoc varchar(20),cont_corespondent varchar(20),cont_intermediar varchar(20),cont_factura varchar(20),cont_venituri varchar(20),
		tva_neexigibil decimal(5,2),idJurnalContract int,idPozContract int,stare int,jurnal varchar(20),detalii xml,detalii_antet xml,subtip varchar(2),tip_miscare varchar(1),
		cumulat float,nrordmin int,nrordmax int,tvaunit float,nrpe int,nrpozmax int,updatabile int,cerecumulare int,idlinie int,idIntrareFirma int,idIntrare int,ptUpdate int,idpozdoc int,pid int,tva_deductibil_i decimal(12,2), idPtAntet int,colet varchar(20),
		codgs1 varchar(1000),nrp int identity)

	--begin transaction wScriuDocSP
	/*Aici se aloca numar de document daca nu exista*/
	if (select count(distinct tip) from #documente where isnull(numar,'')='')>1
			raiserror('Nu se pot trimite mai multe tipuri cu numar de document necompletat!',16,1)

	if exists (select top (1) 1 from #documente where isnull(numar,'')='' )
	begin 
		declare @fXML xml, @tipPentruNr varchar(2), @NrDocPrimit varchar(20),@lm varchar(20),@jurnal varchar(20),@NumarDocPrimit int,@idPlajaPrimit int,@nrdocumente int,@serieprimita varchar(20)
			,@NrAvizeUnitar int

		exec luare_date_par 'GE','NRAVIZEUN', @NrAvizeUnitar output, 0,''

		select top 1 @tipPentruNr=(case when @NrAvizeUnitar=1 and tip='AS' then 'AP' else (case when isnull(aviznefacturat,0)=1 and tip='AP' then 'AN' else (tip) end) end)
			,@lm=(loc_de_munca),@jurnal=(jurnal),@nrdocumente=(pid)
		from #documente where isnull(numar,'')=''

		if @NrAvizeUnitar=1 and @tipPentruNr='AS' 
			set @tipPentruNr='AP' 
		
		set @fXML = '<row/>'set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
		set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')
		set @fXML.modify ('insert attribute documente {sql:variable("@nrdocumente")} into (/row)[1]')
			
		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output,@Numar=@NumarDocPrimit output,@idPlaja=@idPlajaPrimit output,@serie=@serieprimita OUTPUT
			
		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)
			
		if (select top 1 SerieInNumar from docfiscale where id=@idPlajaPrimit)=1
			update #documente set numar=@serieprimita+ltrim(str(@NumarDocPrimit+pid-1))
				where isnull(numar,'')=''
		else
			update #documente set numar=ltrim(str(convert(int,@NrDocPrimit)+pid-1))
				where isnull(numar,'')=''
		
		if @parXML.value('(/row/@numar)[1]', 'varchar(9)') is not null                          
			set @parXML.modify('replace value of (/row/@numar)[1] with sql:variable("@NrDocPrimit")') 
		else
			set @parXML.modify ('insert attribute numar{sql:variable("@NrDocPrimit")} into (/row)[1]') 
	end
	
	if exists (select top (1) 1 from #documente d left join comenzi c on c.Subunitate=@subunitate and c.Comanda=d.comanda
				where d.tip='TE' and isnull(d.comanda,'')<>'' and c.Comanda is null)
		insert comenzi (Subunitate,Tip_comanda,Comanda,Descriere,Beneficiar,Art_calc_benef,Comanda_beneficiar,Loc_de_munca_beneficiar
			,Data_inchiderii,Data_lansarii,Grup_de_comenzi,Loc_de_munca,Starea_comenzii,Numar_de_inventar,detalii)
		select top 1 t.Subunitate,'P',isnull(t.Tert,d.comanda),isnull(t.Denumire,d.comanda),isnull(t.Tert,''),'','',''
			,GETDATE(),GETDATE(),0,d.loc_de_munca,'L','',null 
		from #documente d 
			left join comenzi c on c.Subunitate=@subunitate and c.Comanda=d.comanda
			left join terti t on t.Subunitate=@subunitate and t.Tert=d.comanda
		where d.tip='TE' and isnull(d.comanda,'')<>'' and c.Comanda is null
	--commit tran wscriudoc
END TRY

BEGIN CATCH
	if @@trancount>0 and EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'wScriuDocSP')
			ROLLBACK TRAN wScriuDocSP
	
	declare @mesaj varchar(1000)
	SET @mesaj = ERROR_MESSAGE()+' (wScriuDocSP)'

	RAISERROR (@mesaj, 11, 1)
END CATCH