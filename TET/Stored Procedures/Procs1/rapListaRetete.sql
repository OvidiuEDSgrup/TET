
create procedure rapListaRetete @sesiune varchar(50), @cod varchar(20)=NULL, @grupa varchar(20)=NULL, @categoriepret varchar(20)='1'
as 
/*
	exec rapListaRetete @sesiune='57A59227C2B21',@cod='12'
*/

begin try

	declare @utilizator varchar(100)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	IF OBJECT_ID('tempdb..#ret_filtr') IS NOT NULL
		drop table #ret_filtr

	/* Punem toate produsele conform filtrarii pentru a le determina reteta si retelele semif. lor*/
	DELETE FROM tmpprodsisemif WHERE utilizator = @utilizator
	INSERT INTO tmpprodsisemif (id, utilizator, tip, codNomencl, idp, codp, nivel, cantitate)
	SELECT 
		pt.id , @utilizator, 'P', t.cod,0 , '' , 0, 1
	from tehnologii t
	JOIN pozTehnologii pt on pt.tip='T' and pt.cod=t.cod
	JOIN nomencl n on n.cod=t.codNomencl
	where 
		(@cod IS NULL or t.codNomencl=@cod) and
		(@grupa IS NULL or n.grupa=@grupa)

	EXEC FaSemifabricateDinProduse @sesiune = @sesiune, @parXML = ''
	
	select 
		id, codNomencl cod, nivel, cantitate, convert(decimal(15,5),0) as pret_amanunt
	into #ret_filtr
	from tmpprodsisemif where utilizator=@utilizator
	
	/* Luam o singura data componentele din retete*/
	select 
		distinct mat.id idMat, mat.cod cod, convert(decimal(17,5), 0.0) pret_stoc
	into #pret_coduri
	from PozTehnologii p
	JOIN #ret_filtr r on p.cod=r.cod and p.tip='T'
	JOIN PozTehnologii mat on mat.parinteTop=p.id and mat.tip='M'



	/* UPDATE DE PRET PENTRU MATERIILE PRIME DIN RECEPTII*/
	update pr
		set pret_stoc=ISNULL(preturi.pret_de_stoc,0)
	from #pret_coduri pr
	JOIN
	(
		select
			p.cod, p.pret_de_stoc, rank() over (partition by p.cod  order by p.data desc, p.idPozDoc) rk
		from PozDoc p
		JOIN #pret_coduri pr on pr.cod=p.cod and p.tip='RM' and data>DATEADD(MONTH,-6,GETDATE())
	) preturi 
	ON preturi.rk=1 and preturi.cod=pr.cod

	declare @nivel int
	select @nivel=max(nivel) from #ret_filtr

	/* CALCULAM DE JOS IN SUS PRETUL FIECARUI SEMIF. PT A PUTEA AJUNGE LA PRETUL PRODUSULUI*/
	while @nivel>0
	begin
		
		update pc
			set pc.pret_stoc=pr.pret
		from  #ret_filtr rf
		JOIN pozTehnologii t on t.cod=rf.cod and t.tip='T'
		JOIN #pret_coduri pc on pc.cod=t.cod
		CROSS APPLY
		(
			select
				sum(mat.cantitate*pc.pret_stoc) pret
			from pozTehnologii mat 
			JOIN #pret_coduri pc on pc.idMat=mat.id
			where mat.parinteTop=t.id and mat.tip='M'
		) pr
		where rf.nivel=@nivel and ISNULL(pc.pret_stoc,0)=0

		select @nivel=@nivel-1
	end

	/* Stergem ce a fost necesar pt. calculul pretului la semifabricate*/
	delete #ret_filtr where nivel>0
	
	--> pret vanzare:
	declare @xmlPret xml
	select @xmlPret= (select @categoriepret categoriePret, @cod cod for xml raw )
	create table #preturi(cod varchar(20),nestlevel int)
	insert into #preturi
	select cod,@@NESTLEVEL from #ret_filtr

	exec CreazaDiezPreturi
	--update #preturi set umprodus=@umprodus
	exec wIaPreturi @sesiune=@sesiune,@parXML=@xmlPret
	
	update r set r.pret_amanunt=p.pret_amanunt
	from #ret_filtr r inner join #preturi p on r.cod=p.cod
	
	/* SELECTUL FINAL CU PRODUSELE + RETETELE LOR DE PRIMUL NIVEL: pentru detaliere*/
	select
		rtrim(t.codNomencl) codProdus, rtrim(n.denumire) denProdus, rtrim(n.um) umProdus, convert(decimal(17,5), pr.pretProdus) pretProdus,
		rtrim(mat.cod) codArticol, rtrim(mat.Denumire) denArticol, convert(decimal(17,5), pret.pret_stoc) pretArticol,
		rtrim(mat.um) umArticol, convert(decimal(17,5), ISNULL(pret.pret_stoc,0)* ISNULL(poz.cantitate,0)) valArticol,
		convert(decimal(17,5), poz.cantitate) cantitateArticol, rtrim(g.denumire) denGrupaProdus,
		--(case when row_number() over (partition by rf.cod order by rf.cod)=1 then isnull(rf.pret_amanunt,0) else 0 end)
		rf.pret_amanunt
	from Tehnologii t
	JOIN pozTehnologii pt on t.cod=pt.cod
	JOIN Nomencl n on n.cod=t.codNomencl
	LEFT JOIN grupe g on g.grupa=n.Grupa
	JOIN #ret_filtr rf on rf.cod=t.codNomencl
	JOIN pozTehnologii poz on poz.parinteTop=pt.id and poz.tip='M'
	JOIN nomencl mat on mat.cod=poz.cod
	JOIN #pret_coduri pret on pret.idMat=poz.id
	--join #preturi pr on pr.cod=rf.cod_nomenclator
	OUTER APPLY
	(
		select
			sum(ISNULL(p.cantitate,0)*ISNULL(pr.pret_stoc,0)) pretProdus
		from Poztehnologii p
		JOIN #pret_coduri pr on pr.idMat=p.id
		where p.parinteTop=pt.id and p.tip='M'
	)pr
	order by pr.pretProdus
end try
begin catch
	declare @mesaj varchar(2000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
