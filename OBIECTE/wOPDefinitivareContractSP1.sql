IF EXISTS (SELECT * FROM sysobjects	WHERE NAME = 'wOPDefinitivareContractSP1')
	DROP PROCEDURE wOPDefinitivareContractSP1
GO

CREATE PROCEDURE wOPDefinitivareContractSP1 @sesiune VARCHAR(50), @parXML XML 
AS
BEGIN TRY
--/*sp
	declare @procid int=@@procid, @objname sysname
	set @objname=object_name(@procid)
	EXEC wJurnalizareOperatie @sesiune=@sesiune, @parXML=@parXML, @obiectSql=@objname
--sp*/
	DECLARE 
		@idContract INT, @stare INT, @mesaj VARCHAR(500), @docJurnal XML, @tipContract varchar(2), @stareDefinitiva int 
		,@utilizator varchar(20)

	EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT-->identIFicare utilizator pe baza sesiunii
	
	select 
		@idContract = @parXML.value('(/*/@idContract)[1]', 'int'),
		@tipContract = @parXML.value('(/*/@tip)[1]', 'varchar(2)'),
		@stare = @parXML.value('(/*/@stare)[1]', 'int')
	
	if @tipContract='RN'
	begin
		--select top 1 @stareDefinitiva=stare from StariContracte where tipContract=@tipContract and modificabil=0 order by stare
	
		IF @idContract IS NULL
			RAISERROR ('Nu s-a putut identificare comanda/contractul ', 11, 1)
		
		delete n
		from necesaraprov n join Contracte c on c.tip=@tipContract and c.numar=n.Numar and c.data=n.Data join PozContracte p on p.idPozContract=n.Numar_pozitie
		where c.idContract=@idContract and n.Stare='0'
		
		insert necesaraprov (Numar,Data,Numar_pozitie,Gestiune,Cod,Cantitate,Stare,Loc_de_munca,Comanda,Numar_fisa,Utilizator,Data_operarii,Ora_operarii,detalii)
		select c.Numar,c.Data,p.idPozContract,c.Gestiune,p.Cod,p.Cantitate,0,c.Loc_de_munca,Comanda='',Numar_fisa='',isnull(s.Utilizator,@utilizator),GETDATE(),Ora_operarii='',p.detalii
		from PozContracte p join Contracte c on c.idContract=p.idContract
			left join necesaraprov n on n.Numar=c.numar and n.Data=c.data and n.Numar_pozitie=p.idPozContract
			outer apply (select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.modificabil, j.utilizator 
				from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc,j.idJurnal desc) s
		where c.idContract=@idContract and n.Numar_pozitie is null
	end

	--SET @docJurnal = (SELECT @idContract idContract, 1 stare, GETDATE() AS data, 'Definitivat' AS explicatii FOR XML raw )

	--EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal
END TRY

begin catch
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror(@mesaj, 16,1)
end catch