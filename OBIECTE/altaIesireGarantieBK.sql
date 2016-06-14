DROP PROCEDURE yso_altaIesireGarantieBK
go
CREATE PROCEDURE yso_altaIesireGarantieBK @Subunitate CHAR(9), @Tip CHAR(2), @Contract VARCHAR(20), @Data DATE, @Tert CHAR(13) AS

--DECLARE @Subunitate CHAR(9), @Tip CHAR(2), @Contract VARCHAR(20), @Data DATE, @Tert CHAR(13)
--SELECT TOP 1 --*
--@Subunitate='1'
--,@Tip='BK'
--,@Contract=Contract
--,@Tert=Tert
--,@Data=data
--FROM con where con.responsabil_tert='1' and Subunitate='1' and tip='bk' and Contract='1124' 

--numar="TEST" 

DECLARE @Numar char(8)--, @data datetime
, @TipIesire char(2)
, @SubTipIesire char(2)
, @Gestiune varchar(9)
, @Cod varchar(20)
, @CodIntrare char(13)
, @Cantitate float
, @Cant_aprob float
, @Cant_desc float
, @CtCoresp char(13)
, @LM varchar(9)
, @Comanda char(40)
, @ComLivr char(20)
, @Explicatii varchar(16)
, @Serie char(20)
, @Utilizator char(10)
, @Schimb int
, @Jurnal char(3)
, @Stare int
, @NrPozitie int
, @PozitieNoua int
, @PretStoc float
, @dataCurenta date
,@numarpozitii int

declare @parXmlScriereIesiri xml, @RC xml
--set @parXmlScriereIesiri=convert(xml,N'<row tip="AE" data="03/13/2012">
--<row cod="237D0138" cantitate="1" pstoc="0" codintrare="IMPL1" subtip="AE" data="03/13/2012" gestiune="101" comanda="56NTEUR" lm="1" explicatii="EXX"/>
--</row>')


DECLARE pozComLivr CURSOR FOR
SELECT pozcon.Factura, pozcon.Cod, pozcon.Cant_aprobata, con.Loc_de_munca
from pozcon inner join con on con.Subunitate=pozcon.subunitate and con.Tip=pozcon.Tip and con.Contract=pozcon.Contract 
	and con.Data=pozcon.Data and pozcon.Tert=con.Tert
where pozcon.Subunitate=@Subunitate and pozcon.Tip=@Tip and pozcon.Contract=@Contract and pozcon.Data=@Data and pozcon.Tert=@Tert 
	and con.responsabil_tert='1'

OPEN pozComLivr
FETCH NEXT FROM pozComLivr INTO @gestiune,@cod,@Cant_aprob,@LM

WHILE @@FETCH_STATUS=0 
BEGIN
	set @dataCurenta=CONVERT(DATE,GETDATE())
	
	select @TipIesire=isnull(max(p.tip),'AE'), @Numar=isnull(max(p.numar),@numar), @dataCurenta=isnull(max(p.Data),@dataCurenta)
		, @numarpozitii=COUNT(*)
	from pozdoc p where p.Subunitate=@Subunitate and p.Tip='AE' and isnull(nullif(p.Grupa,''),p.[Contract])=@Contract
	
	select @Cantitate=isnull(SUM(p.Cantitate),0) 
	from pozdoc p where p.Subunitate=@Subunitate and p.Tip='AE' and isnull(nullif(p.Grupa,''),p.[Contract])=@Contract and p.Cod=@Cod
	
	set @SubTipIesire=@TipIesire
	set @parXmlScriereIesiri = '<row><row/></row>'
	set @parXmlScriereIesiri.modify ('insert 
						(
						attribute tip {sql:variable("@TipIesire")},
						attribute numar {sql:variable("@numar")},
						attribute data {sql:variable("@dataCurenta")},
						attribute numarpozitii {sql:variable("@numarpozitii")}
						)					
						into (/row)[1]')
	IF @Cant_aprob>@Cantitate
	BEGIN
		set @Cant_desc=@Cant_aprob-@Cantitate
		set @parXmlScriereIesiri.modify ('insert 
		(
		attribute subtip {sql:variable("@SubTipIesire")},
		attribute data {sql:variable("@dataCurenta")},					
		attribute gestiune {sql:variable("@gestiune")},
		attribute cod {sql:variable("@cod")},
		attribute cantitate {sql:variable("@cant_desc")},
		attribute lm {sql:variable("@lm")},
		attribute contract {sql:variable("@contract")},
		attribute explicatii {sql:variable("@explicatii")}
		)					
		into (/row/row)[1]')

		exec wScriuPozdoc @sesiune=null,@parXML=@parXmlScriereIesiri
	END
	FETCH NEXT FROM pozComLivr INTO @gestiune,@cod,@Cant_aprob,@LM
END

CLOSE pozComLivr
DEALLOCATE pozComLivr

GO