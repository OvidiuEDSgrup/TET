
CREATE PROCEDURE wIaPreturiIntrare @sesiune VARCHAR(50), @parXML XML
AS
BEGIN TRY
	declare 
		@data datetime, @tert varchar(20), @idContract int, @valuta varchar(20)

	select 
		@Data = isnull(@parXML.value('(/*/@data)[1]', 'datetime'), getdate()),
		@Tert = isnull(@parXML.value('(/*/@tert)[1]', 'varchar(13)'), ''),	
		@idContract = isnull(@parXML.value('(/*/@idContract)[1]', 'int'), 0),	
		@valuta = isnull(@parXML.value('(/*/@valuta)[1]', 'varchar(20)'), '')

	/* PASUL 1: daca se cere exact de pe 1 contract (cu ID)	*/
	update #preturiintrare
		set pret_stoc=con.pret, valuta=con.valuta, calculat=1
	from 
	(
		select 
			pc.cod,max(pc.pret) as pret,max(c.valuta) as valuta
		from Contracte c
		inner join PozContracte pc on c.idContract=pc.idContract
		where c.idContract=@idContract
		group by pc.cod
	) con
	where #preturiintrare.cod=con.cod and isnull(calculat,0)=0
	
	/* PASUL 2: Contract furnizor in perioada de valabilitate	*/
	update #preturiintrare
	set pret_stoc=c1.pret, valuta=c1.valuta, calculat=1
	from
		(	select 
				pc.cod,pc.pret as pret,pc.discount as discount,c.valuta as valuta
			from contracte c 
			INNER JOIN pozcontracte pc on c.idContract=pc.idContract
			INNER JOIN #preturiintrare p on p.cod=pc.cod
			where c.tip='CF' and c.tert=@tert and @data between c.data and ISNULL(c.valabilitate, '01/01/2999')
		) c1
		where 
		#preturiintrare.cod=c1.cod and 
		isnull(calculat,0)=0 

	/* PASUL 3: Tabela PPRETURI	*/
	update p
		set p.pret_stoc=pp.pret, calculat=1
	from #preturiintrare p
	JOIN PPreturi pp on p.cod=pp.cod_resursa and pp.tip_resursa='C' and pp.tert=@tert
	where isnull(calculat,0)=0 

	/* PASUL 4, legacy: pret de stoc din nomenclator */
	update p
		set pret_stoc=isnull(n.Pret_stoc,0), calculat=1, valuta=n.valuta
	from #preturiintrare p
	inner join nomencl n on p.cod=n.cod 
	where isnull(calculat,0)=0 


	/* Apel procedura SP	*/
	if exists(select * from sysobjects where name='wIaPreturiIntrareSP2' and type='P')
		exec wIaPreturiIntrareSP2 @sesiune=@sesiune, @parXML=@parXML 

	/* Tratari valuta si alte chestii-	*/
	------------------------------------------------------------------------------------------
	if @valuta='' and exists(select valuta from #preturiintrare where valuta!='') /*Cautam cursuri*/
	begin
		select p.valuta,c.curs
		into #valute
			from #preturiintrare p
			cross apply (select top 1 curs from curs where valuta=p.valuta and data<=@data order by data desc) c

		update #preturiintrare
			set curs=isnull(#valute.curs,1)
			from #valute where #preturiintrare.valuta!='' and #preturiintrare.valuta=#valute.valuta
	end

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
