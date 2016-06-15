
CREATE PROCEDURE updateStareSetContracte @sesiune VARCHAR(50), @parXML XML
AS

BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	IF EXISTS (SELECT *	FROM sysobjects WHERE NAME = 'updateStareSetContracteSP')
	begin
		exec updateStareSetContracteSP @sesiune=@sesiune, @parXML=@parXML
		return
	end
	
	DECLARE 
		@utilizator VARCHAR(100),  @mesaj varchar(4000), @sub varchar(13), @iDoc int,@xml xml, @rootXml varchar(50)
	
	IF OBJECT_ID('tempdb..#contr_st') is not null
		drop table #contr_st

	if @parXML.exist('(/Date)')=1 
		set @rootXml='/Date/row'
	else
		set @rootXml='/row'

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	select 
		idContract idContract, convert(varchar(20),'') tip, convert(int, 0) stareRealizat, convert(float, 0.0) deFacturat, convert(float, 0.0) facturat
	into #contr_st
	from OPENXML(@iDoc, @rootXml)
	WITH (idContract int '@idContract')
	exec sp_xml_removedocument @iDoc

	update c
		set c.tip=ct.tip
	from #contr_st c
	jOIN contracte ct on c.idContract=ct.idContract
	
	delete from #contr_st where tip in ('CS', 'CB', 'CF') -- la aceste tipuri de contracte, starea nu se schimba in functie de cantitatea facturata

	update c	
		set stareRealizat=ISNULL(s.stare,0)
	from #contr_st c
	OUTER APPLY( select max(stare) stare from StariContracte where ISNULL(inchisa,0)=1 and tipContract=c.tip) s
		
	
	select @sub = RTRIM(val_alfanumerica)
	from par 
	where Tip_parametru='GE' and Parametru='SUBPRO'
	
	declare @gestiuneRezervari varchar(20)
	EXEC luare_date_par 'GE', 'REZSTOCBK', 0, 0, @gestiuneRezervari OUTPUT
	
	-- calculez cantitatile de facturat si cat s-a facturat -> am nevoie de group by, pt. cazurile in care o pozitie din contracte are mai multe pozitii in pozdoc

	update c
		set c.deFacturat= xx.deFacturat, c.facturat=xx.facturat
	from #contr_st c
	JOIN 	
	(
		select 
			sum(x.defacturat) defacturat, sum(x.facturat) facturat, x.idContract idcontract
		from 
			(
				select max(pc.cantitate) deFacturat, SUM(pd.cantitate) facturat, max(c.idContract) idContract
				from Contracte c
				JOIN #contr_st cc on cc.idContract=c.idContract
				left join PozContracte pc on c.idContract=pc.idContract
				left join LegaturiContracte lc on lc.idPozContract=pc.idPozContract
				left join pozdoc pd on lc.idPozDoc=pd.idPozDoc and pd.Subunitate=@sub and pd.tip in ('AP', 'AS','TE','AC','RM') and (pd.gestiune_primitoare!=@gestiuneRezervari OR NULLIF(pd.gestiune_primitoare,'') IS NULL)							
				group by pc.idPozContract
			) x 
		group by x.idContract
	) xx on xx.idContract=c.idContract
	
	SELECT @xml = 
	( 
		SELECT 
			idContract idContract, GETDATE() data,stareRealizat stare, 'Realizare integrala comanda' explicatii 
		from #contr_st where ROUND(deFacturat,5)<=ROUND(facturat,5)
		FOR XML raw, root('Date') 
	)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml OUTPUT

	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (updateStareSetContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

