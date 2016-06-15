--
CREATE PROCEDURE wScriuLegaturiContracte @sesiune VARCHAR(50), @parXML XML OUTPUT AS

DECLARE @idContract INT, @data DATETIME, @explicatii VARCHAR(60), @stare VARCHAR(2), @mesaj VARCHAR(500), @detalii XML, @utilizator VARCHAR(100), @rootXml varchar(50),
		@iDoc int
declare @contracte table (idJurnal int, idContract int, data datetime, explicatii varchar(max), stare int, detalii xml)
declare @pozitii table (idJurnalContract int, idPozContract int, idPozDoc int, idPozContractCorespondent int, idContract int, data datetime, explicatii varchar(max), stare int, detalii xml)

BEGIN TRY
	set @rootXml='/Date/row/pozitii/row'
	
	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT

	EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
	
	-- citesc pozitiile
	insert into @pozitii(idJurnalContract, idPozContract, idPozDoc, idPozContractCorespondent, idContract, data, explicatii, stare, detalii)
	select idJurnalContract, idPozContract, idPozDoc, idPozContractCorespondent, idContract, isnull(data, getdate()), explicatii, stare, detalii
	from OPENXML(@iDoc, @rootXml) 
		WITH 
		(
			idPozContract int '@idPozContract', 
			idPozDoc int '@idPozDoc', 
			idPozContractCorespondent int '@idPozContractCorespondent', 
			idJurnalContract int '../../@idJurnalContract', 
			idContract int '../../@idContract',
			data datetime '../../@data',
			explicatii varchar(max) '../../@explicatii',
			stare int '../../@stare',
			detalii xml '../../detalii/row'
		)
		
	exec sp_xml_removedocument @iDoc
	
	-- iau idContract din idPozContract
	update p
		set idContract = pc.idContract
	from @pozitii p, PozContracte pc
	where p.idPozContract=pc.idPozContract
	and p.idContract is NULL
	
	-- inserez aici o linie pt. fiecare contract
	insert into @contracte(idJurnal, idContract, data, explicatii, stare, detalii)
	select max(p.idJurnalContract), idContract, max(data), max(explicatii), max(stare), max(convert(varchar(max),detalii))
	from @pozitii p
	group by p.idContract
	
	/** Daca nu se trimite starea va ramane in starea anterioara **/
	update c
		set stare = stari.stare
	from @contracte c
	cross apply (select top 1 stare 
					FROM JurnalContracte j
					WHERE j.idContract = c.idContract
					ORDER BY data DESC) stari
	where c.stare is null
	
	declare @jurnalIntrodus TABLE(idJurnal INT, idContract int)
	
	-- jurnalizez operatia(pt. contractele care nu au trimis idJurnal)
	INSERT INTO JurnalContracte (idContract, data, stare, explicatii, detalii, utilizator)
		OUTPUT inserted.idJurnal, inserted.idContract
		INTO @jurnalIntrodus(idJurnal, idContract)
	select idContract, data, stare, explicatii, detalii, @utilizator
	from @contracte
	where idJurnal is null
	
	-- updatez idJurnal
	update c
		SET c.idJurnal=j.idJurnal
	from @contracte c, @jurnalIntrodus j
	where c.idContract=j.idContract
	
	insert into LegaturiContracte(idJurnal, idPozContract, idPozDoc, idPozContractCorespondent)
	SELECT c.idJurnal, p.idPozContract, p.idPozDoc, p.idPozContractCorespondent
	from @pozitii p, @contracte c
	where p.idContract=c.idContract
	
	--	momentan nu trimit nimic inapoi in parXML - daca va fi nevoie, am putea trimite idLegatura...
END TRY

BEGIN CATCH
	SET @mesaj = ERROR_MESSAGE() + ' (wScriuLegaturiContracte)'

	RAISERROR (@mesaj, 11, 1)
END CATCH
