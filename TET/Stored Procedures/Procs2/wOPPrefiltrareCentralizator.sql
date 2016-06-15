CREATE PROCEDURE  wOPPrefiltrareCentralizator @sesiune VARCHAR(50), @parXML XML
AS
	if exists (select 1 from sysobjects where [type]='P' and [name]='wOPPrefiltrareCentralizatorSP')
	begin 
		declare @returnValue int -- variabila salveaza return value de la procedura specifica
		exec @returnValue = wOPPrefiltrareCentralizatorSP @sesiune, @parXML output
		return @returnValue
	end

	SET NOCOUNT ON
	declare
		@client varchar(20), @furnizor varchar(20), @comanda varchar(20), @articol varchar(20),@utilizator varchar(100), @subunitate varchar(9),
		@gestiuneRezervari varchar(20), @cuRezervari bit, @grupa varchar(20), @siComenziLivrare bit, @siReferate bit,
		@tipaprov varchar(20) /*Valori permise S=Stoc,C=Comenzi*/

	/* Filtre*/
	SELECT
		@client=@parXML.value(' (/*/@client)[1]','varchar(20)'),
		@furnizor=@parXML.value(' (/*/@furnizor)[1]','varchar(20)'),
		@comanda=@parXML.value(' (/*/@comanda)[1]','varchar(20)'),
		@articol=@parXML.value(' (/*/@articol)[1]','varchar(20)'),
		@grupa=@parXML.value(' (/*/@grupa)[1]','varchar(20)'),
		@siComenziLivrare=@parXML.value(' (/*/@comenzilivrare)[1]','bit'),
		@siReferate=@parXML.value(' (/*/@referate)[1]','bit'),
		@tipaprov=@parXML.value(' (/*/@tipaprov)[1]','varchar(20)')

	EXEC wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator OUTPUT
	EXEC luare_date_par 'GE', 'REZSTOCBK', @cuRezervari OUTPUT, 0, @gestiuneRezervari OUTPUT

	
	delete tmpArticoleCentralizator where utilizator=@utilizator
	delete tmpPozArticoleCentralizator where utilizator=@utilizator
	
	/** Filtrare din Comenzi pe "Comanda" si "Client" pentru optiunea "Comenzi" **/
	SELECT 
		c.Comanda comanda, c.Beneficiar tert
	into #tmpComenziFiltr
	from comenzi c
	where 
		c.Starea_comenzii='L' and 
		(isnull(@client,'')='' or c.Beneficiar=@client) and
		(isnull(@comanda,'')=''OR c.Comanda= @comanda) and
		@tipAprov='C'

	
	/** 
		Selectia principala a datelor
			Pentru comenzi: Porning de la #tmpComenziFiltr cu comenzi in starea lansata si tehnologia produselor (pozLansari)
			Pentru stoc: Prin JOIN cu StocLim, articolele care au completate valorile de stocmin si/sau stocmaxim
			Pentru stoc, si cu bifa de comenzi livrare: Pentru stoc + articolele din comenzile de livrare deschise
	**/	
	if @tipAprov='C'
			insert INTO tmpPozArticoleCentralizator (utilizator,idPozLansare , cod ,cantitate )
			select
				@utilizator,poz.id idPozLansare,poz.cod cod, poz.cantitate cantitate
			from pozLansari pl
				inner JOIN #tmpComenziFiltr c on pl.tip='L' and pl.cod=c.comanda
				inner JOIN pozLansari poz on poz.parinteTop=pl.id 
				inner JOIN nomencl n ON n.cod=poz.cod and (isnull(@articol,'')='' OR n.cod=@articol)
				where (ISNULL(@grupa,'')='' OR n.Grupa=@grupa) and n.Cont not like '341%'
	else 
	/** TipAprov='S' -> se iau toate articolele in functie de STOC MINIM si filtrele selectate**/
	BEGIN
							
		insert INTO tmpPozArticoleCentralizator (cod ,cantitate, utilizator)
		select
			n.cod cod, sum(ISNULL(sl.Stoc_min,0)) cantitate, @utilizator
		from  nomencl n
		JOIN stoclim sl on sl.Cod=n.cod and sl.Cod_gestiune=''
		and (ISNULL(@grupa,'')='' OR n.Grupa=@grupa) and (ISNULL(@articol ,'')='' or n.cod=@articol)
		group by n.cod

		IF ISNULL(@siComenziLivrare,0) = 1
		BEGIN
					
			insert INTO tmpPozArticoleCentralizator (cod ,cantitate, utilizator, idPozContract)
			select
				pc.cod, pc.cantitate, @utilizator, pc.idPozContract
			from Contracte c
			JOIN PozContracte pc on c.idContract=pc.idContract and c.tip='CL'
			CROSS APPLY 
			(
				select top 1 j.stare stare, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc
			) st
			OUTER APPLY
			(
				select top 1 idPozContract from LegaturiContracte l where l.idPozContractCorespondent=pc.idPozContract
			) cc
			where 
				ISNULL(st.inchisa,0)=0 and isnull(cc.idPozContract,0)=0 and
				(ISNULL(@client,'')='' or c.tert=@client) and
				(ISNULL(@articol,'')='' or pc.cod=@articol)
		END

		IF ISNULL(@siReferate,0) = 1
		BEGIN
					
			insert INTO tmpPozArticoleCentralizator (cod ,cantitate, utilizator, idPozContract)
			select
				pc.cod, pc.cantitate, @utilizator, pc.idPozContract
			from Contracte c
			JOIN PozContracte pc on c.idContract=pc.idContract and c.tip='RN'
			CROSS APPLY 
			(
				select top 1 j.stare stare, s.modificabil, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=c.tip and j.idContract=c.idContract order by j.data desc
			) st
			OUTER APPLY
			(
				select top 1 idPozContract from LegaturiContracte l where l.idPozContractCorespondent=pc.idPozContract
			) cc
			where 
				ISNULL(st.inchisa,0)=0 and ISNULL(st.modificabil,0)=0 and isnull(cc.idPozContract,0)=0 and
				(ISNULL(@articol,'')='' or pc.cod=@articol)
		END
	END

	/* Selectul din pozitii in antet grupat*/	
	insert into tmpArticoleCentralizator (utilizator, cod ,cantitate, tip)
	select @utilizator,cod, sum(ISNULL(cantitate,0)), @tipaprov
	from tmpPozArticoleCentralizator where utilizator=@utilizator
	group by cod
	
	/** Punem furnizor si pret la articolele la care gasim Contracte furnzizor **/
	update a
		set a.furnizor=furn.furnizor, a.pret=furn.pret, a.curs=furn.curs, a.valuta=furn.valuta, a.cod_specific=furn.cod_specific
	FROM tmpArticoleCentralizator a 
	LEFT JOIN
	(
		select
			c.tert furnizor, pc.pret pret,pc.cod ,c.curs, c.valuta,pc.cod_specific ,
			row_number() over (partition BY pc.cod order BY c.data DESC) rn 
		from Contracte c
		JOIN PozContracte pc on c.idContract=pc.idContract and c.tip='CF'
		where (ISNULL(@furnizor,'')='' OR c.tert=@furnizor)
	) furn ON furn.rn=1  and furn.cod=a.cod 
	where a.utilizator=@utilizator

	/** Articolele care nu au pret rezultat din Contract furnizor primesc un pret din FurnizorPeCoduri (ppreturi) **/
	update a
		set a.furnizor=furn.tert, a.pret=furn.pret,a.cod_specific=furn.cod_specific
	FROM tmpArticoleCentralizator a 
	LEFT JOIN 
		(
			select 
				fc.cod, fc.tert, fc.pret , fc.cod_specific
			from
				(
					select 
						rtrim(p.Cod_resursa) cod, rtrim(p.Tert) tert,p.pret pret,rtrim(p.codfurn) cod_specific,
						row_number() over (partition BY p.Cod_resursa order BY ISNULL(p.prioritate,0), p.data_pretului DESC) rn
					from ppreturi p
					where (ISNULL(@furnizor,'')='' OR p.tert=@furnizor)					
				) fc
			where fc.rn=1
		) furn ON furn.cod=a.cod	
	where isnull(a.pret,0)=0 and a.furnizor is null and a.utilizator=@utilizator

	/** Articolele care nu au pret din FurnizorPeCoduri (ppreturi) sa ia din Nomenclator **/
	update a
		set a.pret=n.Pret_stoc 
	FROM tmpArticoleCentralizator a 
	JOIN nomencl n on n.cod=a.cod
	where isnull(a.pret,0)=0 and a.utilizator=@utilizator

	/** Se face si filtru pe furnizor, daca este cazul**/
	if isnull(@furnizor,'')!=''
		delete from tmpArticoleCentralizator where isnull(furnizor,'')!=@furnizor and utilizator=@utilizator

	/** 
		Pe articolele selectate facem update la "Cantitate rezervata" si "Cantitate in curs de aprovizionare" 
		Aceasta operatie se face doar la cele pe Comanda
		La cele pe stoc se ia altfel
	**/
	IF OBJECT_ID('tempdb.dbo.#inCurs') IS NOT NULL
		drop table #inCurs

	create table #inCurs(cod varchar(20), cantitate float)

	if @tipaprov='C'
	begin
			update ais
				SET ais.cant_aprovizionare= isnull(clc.cantitate,0)
			from tmpPozArticoleCentralizator ais
			JOIN
				(
					select 
						pz.idPozLansare, SUM(pz.cantitate) cantitate
					FROM PozContracte pz 
					CROSS APPLY 
					(
						select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract='CA' and j.idContract=pz.idContract order by j.data desc
					) st
					JOIN tmpPozArticoleCentralizator tt on tt.idPozLansare=pz.idPozLansare and tt.utilizator=@utilizator
					where  ISNULL(st.inchisa,0)=0
					group by pz.idPozLansare
				) clc on clc.idPozLansare=ais.idPozLansare and ais.utilizator=@utilizator  

			insert into #inCurs (cod, cantitate)
			select t.cod, sum(t.cant_aprovizionare) 
			from tmpPozArticoleCentralizator t where t.utilizator=@utilizator
			group by t.cod
	end
	else
	begin

		insert into #inCurs (cod, cantitate)
		select 		
			pz.cod,SUM(pz.cantitate-isnull(pd.cantitate,0)) cantitate		
		FROM PozContracte pz 
		JOIN Contracte con on pz.idContract=con.idContract
		CROSS APPLY 
		(
			select top 1 j.stare stare, s.denumire denstare, s.culoare culoare, s.inchisa from JurnalContracte j JOIN StariContracte s on j.stare=s.stare and s.tipContract=con.tip and j.idContract=con.idContract order by j.data desc
		) st
		JOIN (select cod from tmpArticoleCentralizator where utilizator=@utilizator group by cod) tt on tt.cod=pz.cod
		LEFT JOIN LegaturiContracte lc on lc.idPozContract=pz.idPozContract
		LEFT JOIN PozDoc pd ON pd.idPozDoc=lc.idPozDoc and pd.tip='RM'
		where con.tip='CA' and ISNULL(st.inchisa,0)=0
		group by pz.cod

	end


	update clc
		SET clc.cant_aprovizionare= ais.cantitate
	from tmpArticoleCentralizator clc
	inner join #incurs ais on clc.cod=ais.cod and clc.utilizator=@utilizator

	/** Calculez stocul. Daca se lucreaza cu rezervari, stocul din acea gestiune nu va fi luat in calcul **/
	select 
		s.cod, SUM(s.stoc) stoc
	INTO #stoc
	from stocuri s
	JOIN tmpArticoleCentralizator a on a.cod=s.cod and a.utilizator=@utilizator
	where (@cuRezervari=1 and s.Cod_gestiune<>@gestiuneRezervari) OR @cuRezervari=0
	GROUP BY s.cod

	update tmpArticoleCentralizator set
			decomandat =(case 
				/**Exista stoc maxim completat*/
				when @tipaprov='S' and isnull(sl.stoc_max,0)>0 
					then isnull(sl.stoc_max,0)-isnull(s.stoc,0)-ISNULL(t.cant_aprovizionare,0)
				/**Nu exista stoc maxim, doar eventual minim (dar nu obligatoriu)*/
				when @tipaprov='S' and isnull(sl.stoc_max,0)=0 
					then ISNULL(tp.cantitate,0)-isnull(cant_rezervata,0)-ISNULL(t.cant_aprovizionare,0)-isnull(s.stoc,0)
				/*Pentru comenzi productie*/
				else ISNULL(t.cantitate,0)-ISNULL(t.cant_aprovizionare,0)-ISNULL(s.stoc,0) end) ,
		stoc=s.stoc
	from tmpArticoleCentralizator t
	LEFT JOIN tmpPozArticoleCentralizator tp on t.cod=tp.cod and tp.idPozContract is null and tp.utilizator =t.utilizator 
	LEFT JOIN stoclim sl on sl.cod=t.cod and sl.cod_gestiune=''
	LEFT JOIN #stoc s on s.cod=t.cod
	where t.utilizator=@utilizator

	/* Cele care ar avea cantitati negative le facem 0*/
	update tmpArticoleCentralizator set
		decomandat = 0
	where ISNULL(decomandat,0)<0.0 and utilizator=@utilizator

	/*Adaugam cantitatea din comenzi de livrare la tipul de aprovizonare PT STOC*/
	update t
		set decomandat=(ISNULL(t.cantitate,0)-ISNULL(tp.cantitate,0))+ISNULL(decomandat,0)
	from tmpArticoleCentralizator t
	LEFT JOIN tmpPozArticoleCentralizator tp on t.cod=tp.cod and tp.idPozContract is null and tp.utilizator=t.utilizator 
	where @tipaprov='S' and t.utilizator=@utilizator

	/* In caz de stoclim, actualizam cantitatea de aprovizionat PT STOC dupa calcul*/
	update tp
		set cantitate=t.decomandat-(t.cantitate-ISNULL(tp.cantitate,0))
	from tmpPozArticoleCentralizator tp
	JOIN tmpArticoleCentralizator t on t.cod=tp.cod and tp.idPozContract is null and tp.utilizator=t.utilizator and t.utilizator=@utilizator and @tipaprov='S'
		
	/* Stergem cele fara cantitati de comandat si fara cantitati in curs (daca decomandat=0 dar cant_aprovizionare<>0 inseamna ca am in curs comenzi de aprovizionare*/
	delete tmpArticoleCentralizator where decomandat=0 and cant_aprovizionare<=0 and utilizator=@utilizator

	/** Apelam  luare datelor pt. macheta, de data aceasta refresh="1"-> avem date de aratat **/
	declare 
		@docXML xml
	set @docXML=(select '1' as refresh for xml raw)

	exec wIaDateCentralizatorAprovizionare @sesiune=@sesiune, @parXML=@docXML
