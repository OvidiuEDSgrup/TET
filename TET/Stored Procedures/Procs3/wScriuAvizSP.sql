
--***
CREATE PROCEDURE wScriuAvizSP @parXmlScriereIesiri XML 
OUTPUT AS

BEGIN TRY
	DECLARE @Tip CHAR(2), @Numar CHAR(8), @Data DATETIME, @Tert CHAR(13), @PctLiv CHAR(5), @CtFact CHAR(13), @Fact CHAR(20), @DataFact 
		DATETIME, @DataScad DATETIME, @Gest CHAR(9), @Cod CHAR(20), @CodIntrare CHAR(13), @Cantitate FLOAT, @PretValuta FLOAT, 
		@Valuta CHAR(3), @Curs FLOAT, @Discount FLOAT, @PretVanz FLOAT, @CotaTVA FLOAT, @SumaTVA FLOAT, @PretAm FLOAT, @CategPret INT, 
		@LM CHAR(9), @Comanda_bugetari CHAR(40), @Comanda CHAR(20), @ComLivr CHAR(20), @Jurnal CHAR(3), @Stare INT, @Barcod CHAR(30), @TipTVAsauSchimb INT, 
		@Suprataxe FLOAT, @Serie CHAR(20), @Utilizator CHAR(10), @CtStoc CHAR(13), @ValFact FLOAT, @ValTVA FLOAT, @ValValuta FLOAT, 
		@NrPozitie INT, @PozitieNoua INT, @update BIT, @subtip VARCHAR(2), @mesaj VARCHAR(200), @docInserate XML, @adaos float,
		@dataOperarii datetime, @oraOperarii varchar(50), @tipMiscare char(1), @docDetalii XML, @detalii xml, @areDetalii bit,
		@areIdPozDoc bit, @comandaSql nvarchar(max), @explicatii varchar(50), 
		@Sb CHAR(9), @TPreturi INT, @DiscInv INT, @TLit INT, @Accize INT, @CtAccDB CHAR(13), @CtAccCR CHAR(13), @DifPProd INT, @Ct378 CHAR(13), 
		@AnGest378 INT, @AnGr378 INT, @Ct4428 CHAR(13), @AnGest4428 INT, @Ct4427 CHAR(13), @Ct4428AV CHAR(13), @TipNom CHAR(1), 
		@CtNom CHAR(13), @PStocNom FLOAT, @GrNom CHAR(13), @StLimNom FLOAT, @CoefC2Nom FLOAT, @CategNom INT, @TipGest CHAR(1), 
		@CtGest CHAR(13), @CategMFix INT, @ValAmMFix FLOAT, @CtAmMFix CHAR(13), @PretSt FLOAT, @TVAnx FLOAT, @PretAmPred FLOAT, 
		@LocatieStoc CHAR(30), @DataExpStoc DATETIME, @DiscAplic FLOAT, @CtCoresp CHAR(13), @CtInterm CHAR(13), @CtVenit CHAR(13), 
		@CtAdPred CHAR(13), @CtTVAnxPred CHAR(13), @CtTVA CHAR(13), @AccCump FLOAT, @AccDat FLOAT, @StersPoz INT, @Bugetar INT, @serii INT,
		@rotunjpretvanz INT, @sumarotpretvanz decimal(17,3),
		@Ct4428LaPlati varchar(20) --Pentru TVA la Incasare
		
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune='', @parXML=@parXmlScriereIesiri, @obiectSql=@objname
	
	--SET @Gest = @parXmlScriereIesiri.value('(/row/@gestiune)[1]','varchar(9)')
	--SET @Tip = @parXmlScriereIesiri.value('(/row/@tip)[1]','varchar(2)')
	--if @Tip='AS' and isnull(@Gest,'')<>''
	--	set @parXmlScriereIesiri.modify('delete /row/@gestiune')
--sp*/

END TRY

BEGIN CATCH
	--ROLLBACK TRAN
	SET @mesaj = ERROR_MESSAGE()+' (wScriuAvizSP)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

