
/**
	Procedura pentru luare date in formularul web 'Predare'.
**/

create procedure rapFormPredare @sesiune varchar(50), @numar varchar(20), @data datetime
as
begin try 
set transaction isolation level read uncommitted
	declare 
		@mesaj varchar(500), @subunitate varchar(10), @locm varchar(50),
		@gestiune varchar(20), @utilizator varchar(50), @detalii xml
	
	exec wIaUtilizator @sesiune = @sesiune, @utilizator = @utilizator output
	
	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output

	if object_id('tempdb..#PozDocFiltr') is not null
		drop table #PozDocFiltr

	/** Pregatire prefiltrare din tabela PozDoc pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre **/
	create table [dbo].[#PozDocFiltr] ([Numar] [varchar](20) NOT NULL, [Cod] [varchar](20) NOT NULL, [Data] [datetime] NOT NULL, 
		[Gestiune] [varchar](9) NOT NULL, [Cantitate] [float] NOT NULL, [Pret_de_stoc] [float] NOT NULL, [Cod_intrare] [varchar](13) NOT NULL,
		[Loc_de_munca] [varchar](9) NOT NULL, [numar_pozitie] [int], [Utilizator] [varchar](200), comanda varchar(20)
		)

	insert into #PozDocFiltr (
		Numar, Cod, Data, Gestiune, Cantitate, Pret_de_stoc,
		Cod_intrare, Loc_de_munca, numar_pozitie, Utilizator, comanda
		)
	select rtrim(Numar), rtrim(Cod), Data data, rtrim(Gestiune), Cantitate, Pret_de_stoc, 
		rtrim(Cod_intrare), Loc_de_munca, Numar_pozitie, rtrim(Utilizator), pz.Comanda
	from pozdoc pz
	where pz.subunitate = @subunitate
		AND pz.tip = 'PP'
		AND pz.data = @data
		and pz.numar = @numar

	create index IX1 on #pozdocfiltr(numar,cod,cod_intrare)

	select top 1 @detalii = detalii, @locm = RTRIM(Loc_munca) from doc where tip = 'PP' and numar = @numar and data = @data
	
	/** Datele despre firma se vor stoca de acuma incolo in tabela #dateFirma */
	IF OBJECT_ID('tempdb.dbo.#dateFirma') IS NOT NULL DROP TABLE #dateFirma
	
	CREATE TABLE #dateFirma(locm varchar(50))
	exec wDateFirma_tabela
	
	EXEC wDateFirma @locm = @locm
	
	/** Selectul principal	**/
	select
		d.firma as UNITATE,
		ltrim(pz.numar) as DOC,
		ltrim(lm.Denumire) as LM,
		convert(char(12), pz.data, 103) as DATA,
		row_number() over (order by pz.numar_pozitie) as NR,
		rtrim(g.denumire_gestiune) as GEST,
		rtrim(pz.cod_intrare) as CODI,
		rtrim(pz.cod) as COD,
		rtrim(n.denumire) as DENUMIRE,
		rtrim(n.um) as UM,
		round(pz.cantitate, 2) as CANT,
		pz.pret_de_stoc as PRET,
		round(pz.pret_de_stoc * pz.cantitate, 2) as VALOARE,
		isnull(@detalii.value('(/row/@denPersPredatoare)[1]', 'varchar(200)'), '') as PREDATOR,
		isnull(@detalii.value('(/row/@denPersPrimitoare)[1]', 'varchar(200)'), '') as PRIMITOR,
		isnull(@detalii.value('(/row/@observatii)[1]', 'varchar(300)'), '') as OBSERVATII,
		'Operat: ' + rtrim (pz.utilizator) + '. Tiparit la ' + convert(varchar(10), getdate(), 103) + ' ' + convert(varchar(5), getdate(), 108)
			+ ', de catre ' + @utilizator as date_tiparire,
		pz.numar_pozitie as ordine,
		pz.comanda
	into #date
	from #PozDocFiltr pz
	left join nomencl n on n.Cod = pz.Cod
	left join gestiuni g on g.cod_gestiune = pz.gestiune and g.subunitate = @subunitate
	left join lm on pz.Loc_de_munca = lm.Cod
	left join #dateFirma d ON 1 = 1

	if exists (select 1 from sys.sysobjects where name = 'rapFormPredareSP')
		exec rapFormPredareSP @sesiune = @sesiune, @numar = @numar, @data = @data

	select * from #date order by ordine

end try
begin catch
	set @mesaj = ERROR_MESSAGE() + ' (rapFormPredare)'
	raiserror(@mesaj, 11, 1)
end catch
