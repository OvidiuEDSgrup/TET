
CREATE PROCEDURE wStergRezervariComenzi @sesiune VARCHAR(50), @parXML XML
AS

	declare 
		@gestiuneRezervari varchar(20), @cuRezervari bit, @docJurnal xml,@subunitate varchar(20),@dataMinExp datetime,@zile_rezervare int

	/* Daca nu se lucreaza cu rezervari, nu facem nimic*/
	EXEC luare_date_par 'GE', 'REZSTOCBK', 0, 0, @gestiuneRezervari OUTPUT
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output
	EXEC luare_date_par 'UC','EXPREZ',0,@zile_rezervare OUTPUT,''
	
	IF @gestiuneRezervari IS NULL
		RETURN
	
	set @dataMinExp=dateadd(day,-2-@zile_rezervare,convert(char(10),getdate(),101))
	/* Daca primim explicit #contracte, stergem rezervarile acelor contracte, altfel contruim #contracte si stergem doar cele expirate*/
	IF OBJECT_ID('tempdb..#contracte') IS NULL	
	begin
		create table #contracte (idContract int)
		insert into #contracte (idContract)
		select pc.idContract
		from PozDoc p
		JOIN LegaturiContracte lc on p.idPozDoc=lc.idPozDoc
		JOIN PozContracte pc on pc.idPozContract=lc.idPozContract
		where p.subunitate=@subunitate and p.data>=@dataMinExp and p.Gestiune_primitoare=@gestiuneRezervari and p.tip='TE' and p.data_expirarii>convert(char(10),getdate())
		group by pc.idContract
	end

	/* Daca nu se avem nici o rezervare expirata sau trimisa explicit, nu facem nimic*/
	IF NOT EXISTS (select 1 from #contracte)
		RETURN

	/*Stergem PozDoc astfel se sterg si legaturiContracte-> va ramane jurnalul "martor"*/
	delete p
	from PozDoc p
	JOIN LegaturiContracte lc on p.idPozDoc=lc.idPozDoc
	JOIN PozContracte pc on pc.idPozContract=lc.idPozContract
	JOIN #contracte c on c.idContract=pc.idContract
	where p.Gestiune_primitoare=@gestiuneRezervari and p.tip='TE' 

	/* Pentru o urmarire mai buna, jurnalizam faptul ca s-a sters rezervarea in dreptul fiecarui contract*/
	SELECT @docJurnal = (SELECT idContract idContract, 'Stergere rezervare' explicatii, GETDATE() data from #contracte FOR XML raw,root('Date'))
	EXEC wScriuJurnalContracte @sesiune = @sesiune, @parXML = @docJurnal OUTPUT
