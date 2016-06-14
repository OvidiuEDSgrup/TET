IF EXISTS (SELECT * FROM sysobjects WHERE NAME = 'updateStareSetContracteSP')
	DROP PROCEDURE updateStareSetContracteSP
GO

CREATE PROCEDURE updateStareSetContracteSP @sesiune VARCHAR(50), @parXML XML
AS

BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED /*SP
	IF EXISTS (SELECT *	FROM sysobjects WHERE NAME = 'updateStareSetContracteSP')
	begin
		exec updateStareSetContracteSP @sesiune=@sesiune, @parXML=@parXML
		return
	end --SP*/
	
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
		, convert(int, 0) stare1, convert(varchar(20),'') numar, convert(datetime,'') data, convert(int, 0) stare
	into #contr_st
	from OPENXML(@iDoc, @rootXml)
	WITH (idContract int '@idContract')
	exec sp_xml_removedocument @iDoc

	update c
		set c.tip=ct.tip
			, numar=ct.numar, data=ct.data, stare=j.stare
	from #contr_st c
	jOIN contracte ct on c.idContract=ct.idContract
	cross apply (select top 1 stare 
					FROM JurnalContracte j
					WHERE j.idContract = c.idContract
					ORDER BY data DESC, idjurnal desc) j
	
	delete from #contr_st where tip not in ('RN') 

	update c	
		set stareRealizat=ISNULL(s.stare,0)
	from #contr_st c
	OUTER APPLY( select max(stare) stare from StariContracte where ISNULL(inchisa,0)=1 and tipContract=c.tip) s
		
	select @sub = RTRIM(val_alfanumerica)
	from par 
	where Tip_parametru='GE' and Parametru='SUBPRO'
	
	declare @gestiuneRezervari varchar(20)
	EXEC luare_date_par 'GE', 'REZSTOCBK', 0, 0, @gestiuneRezervari OUTPUT
	
	update p set starePoz=coalesce(n.stare*10-(case when n.cantitate<p.cantitate then 5 else 0 end),(case p.starePoz when -10 then -10 end),-15)
	from PozContracte p join #contr_st c on c.idContract=p.idContract
		left join necesaraprov n on n.Numar_pozitie=p.idPozContract and n.Numar=c.numar and n.Data=c.data
	where isnumeric(coalesce(n.stare,0))=1
		and isnull(p.starePoz,-15)<>coalesce(n.stare*10-(case when n.cantitate<p.cantitate then 5 else 0 end),(case p.starePoz when -10 then -10 end),-15)
	
	update c set stare1=s.stare
	from #contr_st c join (
		select c.numar, c.data, c.idContract, 
			stare=max(p.starePoz)-(case when COUNT(distinct isnull(p.starePoz,-15))>1 then 5 else 0 end) 
		from PozContracte p join #contr_st c on c.idContract=p.idContract
			--left join necesaraprov n on n.Numar_pozitie=p.idPozContract and n.Numar=c.numar and n.Data=c.data
		--where isnumeric(coalesce(n.stare,0))=1
		group by c.numar, c.data, c.idContract
		) s on s.idContract=c.idContract
	
	SELECT @xml = 
	( 
		SELECT 
			idContract idContract, GETDATE() data,stare1 stare, RTRIM(s.denumire) explicatii 
		from #contr_st c join StariContracte s on s.tipContract=c.tip
		where c.stare1<>c.stare
		FOR XML raw, root('Date') 
	)
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml OUTPUT

END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (updateStareSetContracteSP)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

