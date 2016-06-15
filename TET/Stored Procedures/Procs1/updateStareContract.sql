-- schimb stare contract in functie de cantitatile facturate
CREATE PROCEDURE updateStareContract @sesiune VARCHAR(50), @parXML XML
AS
if exists (select 1 from sysobjects where [type]='P' and [name]='updateStareContractSP')
begin
	exec updateStareContractSP @sesiune, @parXML
	return 0
end

BEGIN TRY
	DECLARE @utilizator VARCHAR(100), @idContract INT, @mesaj varchar(4000), @sub varchar(13), @deFacturat float, @facturat float, @stare int,
			@xml xml, @stareRealizat int, @tip varchar(2)
	
	SET @idContract = @parXML.value('(/*/@idContract)[1]', 'int')
	select top 1 @tip=tip from contracte where idContract=@idContract
	-- pana ce se gaseste o solutie mai buna, iau asa starea pentru care nu mai aduc contractele
	-- atentie -> daca nu se filtreaza / stare, nu merge bine clauza top 25
	set @stareRealizat = (select max(stare) from StariContracte where ISNULL(inchisa,0)=1 and tipContract=@tip)
	
	if ISNULL(@stareRealizat,0)=0 -- nu fac nimic daca nu este stare cu aceasta denumire 
		return 0
	
	select @sub = RTRIM(val_alfanumerica)
	from par 
	where Tip_parametru='GE' and Parametru='SUBPRO'

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT	
	
	select top 1 @stare = st.stare 
	from
		(
			select
				stare , RANK() OVER (order BY data desc, idJurnal desc) rn
			from JurnalContracte jc	where idContract=@idContract
		) st where st.rn=1
	
	
	-- calculez cantitatile de facturat si cat s-a facturat -> am nevoie de group by, pt. cazurile in care o pozitie din contracte are mai multe pozitii in pozdoc
	select @deFacturat = SUM(x.deFacturat ), @facturat = SUM(x.facturat)
	from 
	(
		select max(pc.cantitate) deFacturat, SUM(pd.cantitate) facturat
		from Contracte c
		left join PozContracte pc on c.idContract=pc.idContract
		left join LegaturiContracte lc on lc.idPozContract=pc.idPozContract
		left join pozdoc pd on lc.idPozDoc=pd.idPozDoc and pd.Subunitate='1' and pd.tip in ('AP', 'AS','TE','AC')/* de detaliat ce inseamnna 'realizare'... */
		where c.idContract=@idContract
		group by pc.idPozContract
	) x
	
	if ROUND(@deFacturat,5)<=ROUND(@facturat,5)
	begin
		if @stare<@stareRealizat -- momentan e starea hard-codata pt. realizare... 
		begin
			SELECT @xml = ( SELECT @idContract idContract, GETDATE() data, @stareRealizat stare, 'Realizare integrala comanda' explicatii FOR XML raw )
			EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml OUTPUT
		end
	end
	-- momentan nu tratez revenire din stare realizat...
	--else -- @deFacturat<>@facturat
	--if @stare=@stareRealizat
	--begin
	--	SELECT @xml = ( SELECT @idContract idContract, GETDATE() data, 1 stare, 'Revenire' explicatii FOR XML raw )
	--	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @xml OUTPUT
	--end
	
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (updateStareContract)'

	RAISERROR (@mesaj, 11, 1)
END CATCH

-- exec updateStareContract '', '<row idContract="220" />'
