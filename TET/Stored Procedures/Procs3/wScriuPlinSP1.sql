--***
create procedure  [dbo].[wScriuPlinSP1] @sesiune varchar(50), @parXML xml OUTPUT
as
  
declare @sub varchar(9),@utilizator varchar(50),@LMutilizator varchar(50),@jurnalUtilizator varchar(3),@contUtilizator varchar(40),
	@CtAvFurn varchar(40),@ctAvBen varchar(40),@Bugetari int,@SugerareEfectUnicPeTert int,@DecontPeContMarca int, @NrDecont_Numar int,
	@detalii_antet xml,@detalii_pozitii xml, @codMeniu varchar(50)
  
  -- numerotare (RE) si explicatii
  
begin try  
	
	SET @codMeniu = @parXML.value('(/*/@codMeniu)[1]', 'varchar(50)')
	
	/*Lucian: Aici se aloca numar de document daca nu exista*/
	if exists (select 1 from #descris where isnull(numar,'')='')
	begin
		if (select count(distinct Plata_incasare) from #descris where isnull(numar,'')='')>1
			raiserror('Nu se pot trimite mai multe tipuri cu numar de document necompletat!',16,1)

		declare @fXML xml, @tipPentruNr varchar(2), @subtip varchar(20),@NrDocPrimit varchar(20),@lm varchar(20),@jurnal varchar(20),
			@NumarDocPrimit int,@idPlajaPrimit int,@nrdocumente int,@serieprimita varchar(20)

		select top 1 @tipPentruNr=tip_antet,@lm=loc_de_munca,@jurnal=jurnal,@subtip=plata_incasare
		from #datecitite where isnull(numar,'')=''

		set @lm = (case when @lm is null then '' else @LM end)
		set @jurnal = (case when @jurnal is null then '' else @jurnal end)
		set @fXML = '<row/>'
		set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
		set @fXML.modify ('insert attribute meniu {"PI_FILIALE"} into (/row)[1]')
		set @fXML.modify ('insert attribute tip {sql:variable("@tipPentruNr")} into (/row)[1]')
		set @fXML.modify ('insert attribute subtip {sql:variable("@subtip")} into (/row)[1]')
		set @fXML.modify ('insert attribute utilizator {sql:variable("@utilizator")} into (/row)[1]')
		set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')
		set @fXML.modify ('insert attribute jurnal {sql:variable("@jurnal")} into (/row)[1]')

		exec wIauNrDocFiscale @parXML=@fXML, @NrDoc=@NrDocPrimit output, @Numar=@NumarDocPrimit output, @idPlaja=@idPlajaPrimit output, @serie=@serieprimita OUTPUT

		if @NrDocPrimit is null
			raiserror('Eroare generare numar de document. Plaja de numere folosita pentru acest tip de document s-a epuizat, sau nu este configurata!',16,1)

		if (select top 1 SerieInNumar from docfiscale where id=@idPlajaPrimit)=1
			update #descris set numar=@serieprimita+ltrim(str(@NumarDocPrimit))
			where isnull(numar,'')=''
		else
			update #descris set numar=ltrim(str(convert(int,@NrDocPrimit)))
			where isnull(numar,'')=''
	end
				
end try  
begin catch  
	if EXISTS (SELECT 1 FROM sys.dm_tran_active_transactions WHERE name = 'scriupozplin')
		ROLLBACK TRAN scriupozplin

	declare @mesaj varchar(255)
	set @mesaj='wScriuPlinSP1: '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1) 
end catch
