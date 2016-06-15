/**
	Procedura este folosita pentru a lista Adeverinte pentru somaj. 
**/
create procedure rapAdeverintaSomaj (@sesiune varchar(50), @marca varchar(6), @datajos datetime, @datasus datetime, @dataset char(2), @parXML xml='<row/>', @nrluni int=12)
AS
/*
	exec rapAdeverintaSomaj '', '1', '01/01/2012', '12/31/2012', 'P', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	
	DECLARE @denunit VARCHAR(100), @adrunit VARCHAR(100), @codfisc VARCHAR(100), @ordreg VARCHAR(100), @caen VARCHAR(100), @judet VARCHAR(100), @localit varchar(100), @contbanca VARCHAR(100), 
		@banca varchar(100), @dirgen varchar(100), @direc varchar(100), @sefpers varchar(100), @telefon varchar(100), @email varchar(100), 
		@compartiment varchar(100), @functierepr varchar(100), @numerepr varchar(100), @numec varchar(100), @functc varchar(100), 
		@tip varchar(2), @mesaj varchar(1000), @cTextSelect nvarchar(max), @debug bit, 
		@utilizator varchar(50), @lista_lm int
	
	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	
	if @nrluni<>12
		set @datajos=dbo.EOM(DateADD(month,-@nrluni,@datasus))

	/**
		Informatiile din PAR sau similare se iau o singura data, nu in selectul principal care ar cauza rularea instructiunilor de multe ori
	*/
	select	@denunit=(case when parametru='NUME' then rtrim(val_alfanumerica) else @denunit end),
			@codfisc=(case when parametru='CODFISC' then rtrim(val_alfanumerica) else @codfisc end),
			@ordreg=(case when parametru='ORDREG' then rtrim(val_alfanumerica) else @ordreg end),
			@caen=(case when parametru='CAEN' then rtrim(val_alfanumerica) else @ordreg end),
			@judet=(case when parametru='JUDET' then rtrim(val_alfanumerica) else @judet end),
			@localit=(case when parametru='SEDIU' then rtrim(val_alfanumerica) else @localit end),
			@adrunit=(case when parametru='ADRESA' then rtrim(val_alfanumerica) else @adrunit end),
			@contBanca=(case when parametru='CONTBC' then rtrim(val_alfanumerica) else @contBanca end),
			@banca=(case when parametru='BANCA' then rtrim(val_alfanumerica) else @banca end),
			@dirgen=(case when parametru='DIRGEN' then rtrim(val_alfanumerica) else @dirgen end),
			@direc=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @direc end),
			@sefpers=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @sefpers end),
			@telefon=(case when parametru='TELFAX' then rtrim(val_alfanumerica) else @telefon end),
			@email=(case when parametru='EMAIL' then rtrim(val_alfanumerica) else @email end),
			@compartiment=(case when parametru='COMP' then rtrim(val_alfanumerica) else @compartiment end),
			@functierepr=(case when parametru='FDIRGEN' then rtrim(val_alfanumerica) else @functierepr end),
			@numerepr=(case when parametru='DIRGEN' then rtrim(val_alfanumerica) else @numerepr end),
			@numec=(case when parametru='DIREC' then rtrim(val_alfanumerica) else @numec end),
			@functc=(case when parametru='FDIREC' then rtrim(val_alfanumerica) else @functc end)
	from par
	where Tip_parametru='GE' and Parametru in ('NUME','CODFISC','ORDREG','ADRESA','JUDET','SEDIU','CONTBC','BANCA','FDIRGEN','DIRGEN','FDIREC','DIREC','SEFPERS','TELFAX','EMAIL') 
		or Tip_parametru='PS' and Parametru in ('CAEN','COMP')

--	Date pozitii contributii somaj
	if @dataset='P'
	begin
		IF OBJECT_ID('tempdb..#AdSomajFiltr') is not null drop table #AdSomajFiltr
		
		/** Prefiltrare din tabela Net pentru a nu lucra cu toata, decat ceea ce este de interes dupa filtre**/
		CREATE TABLE dbo.#AdSomajFiltr (Marca varchar(6) not null, Data datetime not null, Loc_de_munca varchar(9),  Luna varchar(15) not null, An int not null, 
			Baza_somaj decimal(10) not null, Somaj_individual decimal(10) not null, Somaj_unitate decimal(10,2) not null, 
			Doc_plata_somajI varchar(10) not null, Doc_plata_somajU varchar(20) not null, Nr_declaratie varchar(20) not null, CNP varchar(13))

		INSERT INTO #AdSomajFiltr (Marca, Data, Loc_de_munca, Luna, An, Baza_somaj, Somaj_individual, Somaj_unitate, Doc_plata_somajI, Doc_plata_somajU, Nr_declaratie, CNP)
		SELECT n.Marca, n.Data, n.Loc_de_munca, dbo.fDenumireLuna (n.Data), year(n.Data), n.Asig_sanatate_din_CAS, n.Somaj_1, n.Somaj_5, '', '', '', p.Cod_numeric_personal
		FROM net n
			left outer join personal p on p.Marca=n.marca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=n.loc_de_munca
		WHERE n.Marca=@marca
			--exists (select 1 from personal p1 where p1.Cod_numeric_personal=p.Cod_numeric_personal and p1.Marca=@marca)
			and n.Data=dbo.EOM(n.Data) and n.Data between @datajos and @datasus
			and (@lista_lm=0 or lu.cod is not null) 

		create index IX1 on #AdSomajFiltr (marca,data)

		SELECT
			rtrim(n.Luna) as luna, 
			rtrim(convert(char(4),n.An)) as an, 
			row_number() OVER(ORDER BY n.Data desc) as nr_crt,
			left(convert(char(15),convert(money,round(sum(n.Baza_somaj),0)),0),15) as baza_somaj,
			left(convert(char(15),convert(money,round(sum(n.Somaj_individual),0)),0),15) as somaj_ind,
			left(convert(char(15),convert(money,round(sum(n.Somaj_unitate),2)),0),15) as somaj_unit,
			(case when dbo.iauParLA(n.data,'PS','OPCS')<>'' then dbo.iauParLA(n.data,'PS','OPCS')+' - '+CONVERT(CHAR(10),dbo.iauParLD(n.data,'PS','OPCS'),103) else '' end) as docpl_somaj_ind, 
			(case when dbo.iauParLA(n.data,'PS','OPCS')<>'' then dbo.iauParLA(n.data,'PS','OPCS')+' - '+CONVERT(CHAR(10),dbo.iauParLD(n.data,'PS','OPCS'),103) else '' end) as docpl_somaj_unit, 
			(case when dbo.iauParLA(n.data,'PS','D112')<>'' then dbo.iauParLA(n.data,'PS','D112')+' - '+CONVERT(CHAR(10),dbo.iauParLD(n.data,'PS','D112'),103) else '' end) as nr_inreg_decl,
			@utilizator AS intocmit, 'Venituri salariale' as tip_venit,
			convert(char(15),convert(money,round((select sum(Baza_somaj) from #AdSomajFiltr),2)),1) as tot_baza_somaj,
			convert(char(15),convert(money,round((select sum(Somaj_individual) from #AdSomajFiltr),2)),1) as tot_somaj_ind,
			convert(char(15),convert(money,round((select sum(Somaj_unitate) from #AdSomajFiltr),2)),1) as tot_somaj_unit
		FROM #AdSomajFiltr n
		GROUP BY n.Data, n.An, n.Luna, n.CNP
		ORDER BY n.Data desc
	end

--	Date antet
	if @dataset='A'
	begin
		SELECT top 1
			@denunit as DENUNIT, @codfisc as CODFISC, @ordreg as ORDREG, @judet as JUDETA, @localit as LOCALIT, @adrunit as ADRUNIT, @caen as CAEN, @banca as BANCA, @contbanca as CONTBANCA,
			@dirgen as DIRGEN, @direc as DIREC, @sefpers as SEFPERS, @telefon as TELEFON, @email as EMAIL, 
			@compartiment as COMP, @functierepr as FUNCTIEREPR, @numerepr as NUMEREPR, @numec as NUMEC, @functc AS FUNCTC, 
			rtrim(p.Nume) as NUME, rtrim(p.localitate) as LOCALITATE, rtrim(p.judet) as JUDET, rtrim(p.Numar) as NUMAR,
			rtrim(p.Bloc) as BLOC, rtrim(p.Apartament) as APART, p.adresa as ADRESA,
			p.tip_act as TIPACT, p.serie_bul as SERIEBUL, p.nr_bul as NRBUL,
			p.elib as ELIB, CONVERT(CHAR(10),p.data_elib,103) as DATAELIB, rtrim(p.cnp) as CNP,
			CONVERT(CHAR(10),p.data_angajarii,103) as DATAANG, 
			(case when plecat=1 and CONVERT(CHAR(10),p.data_plec,103)<>'01/01/1901' then CONVERT(CHAR(10),p.data_plec,103) else '' end) as DATAPL,
			p.mod_angajare as DURATACNT,
			CONVERT(CHAR(10),p.data_nasterii,103) as DATAN,
			p.den_functie as FUNCTIE, p.den_lm as DENLM,
			rtrim(p.nr_contract) as NRCONTR, 
			(case when (select rtrim(val_inf) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM')<>'' then (select rtrim(val_inf) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM') 
				else rtrim(p.nr_contract) end) as NRCONTRACT, 
			(case when (select rtrim(val_inf) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM')<>'' 
				then (select CONVERT(CHAR(10),(data_inf),103) from extinfop e where e.marca=p.marca and e.cod_inf='CNTRITM') 
				else (select CONVERT(CHAR(10),data_inf,103) from extinfop e where e.marca=p.marca and e.cod_inf='DATAINCH') end) as DATACONTRACT,
			dbo.iauExtinfopVal(p.Marca,'RTEMEIINCET') as TEMEIINCET
		FROM dbo.fDateSalariati(@marca, null) p 
	end

	if @dataset='S'
	begin
		select CONVERT(CHAR(10),c.data_inceput,103) as data_inc_susp, 
			CONVERT(CHAR(10),c.data_sfarsit,103) as data_sf_susp, 
			(case when tip_suspendare='CM' then rtrim(convert(char(3),c.zile_lucratoare))+' zile CM' else c.Motiv_suspendare end) as motiv_susp,
			convert(char(3),c.Zile_calendaristice) as zile_cal_susp
		FROM fPerSuspCntrMunca (@datajos, @datasus, @marca, Null, 1) c
	end

	if @dataset='N'
	begin
		select (case when CONVERT(CHAR(10),n.data_inceput,111)<'2011/01/01' then '01/01/2011' else CONVERT(CHAR(10),n.data_inceput,103) end) as data_inc_norma, 
			CONVERT(CHAR(10),n.data_sfarsit,103) as data_sf_norma, 
			rtrim(convert(char(3),n.Norma_zi)) as nr_ore_zi,
			rtrim(convert(char(3),n.Norma_saptamina)) as nr_ore_sapt
		FROM fEvolutieNormaCM (@datajos, @datasus, @marca) n
	end

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapAdeverintaSomaj)'
	raiserror(@mesaj, 11, 1)
end catch
