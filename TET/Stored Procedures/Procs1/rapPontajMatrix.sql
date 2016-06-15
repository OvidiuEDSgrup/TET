/*
	grupare = 0 -> Marci, data
	grupare = 1 -> Locuri de munca
	grupare = 2 -> Comenzi
	grupare = 3 -> Locuri de munca si comenzi
*/
Create procedure rapPontajMatrix 
	(@dataJos datetime, @dataSus datetime, @locm varchar(9)=null, @marca varchar(6)=null, @comanda varchar(20)=null, @colrand char(2)=14, @grupare char(1)=0, @ordonare char(1)=0)
as
begin try
	set transaction isolation level read uncommitted
	IF OBJECT_ID('tempdb..#final') IS NOT NULL drop table #final
	IF OBJECT_ID('tempdb..#pontaj') IS NOT NULL drop table #pontaj
	IF OBJECT_ID('tempdb..#pontaj_matrix') IS NOT NULL drop table #pontaj_matrix
	
	declare @culm int, @cucomenzi int, @indiciPontajLM int, 
		@pden_os1 varchar(30), @pden_os2 varchar(30), @pden_os3 varchar(30), @pden_os4 varchar(30), @den_intr_tehn varchar(30), 
		@proc_os1 float,@proc_os2 float,@proc_os3 float,@proc_os4 float
	set @indiciPontajLM=dbo.iauParL('PS','INDICIPLM')
	Exec Luare_date_par 'PS','OSUPL1',0,@proc_os1 output,@pden_os1 output
	Exec Luare_date_par 'PS','OSUPL2',0,@proc_os2 output,@pden_os2 output
	Exec Luare_date_par 'PS','OSUPL3',0,@proc_os3 output,@pden_os3 output
	Exec Luare_date_par 'PS','OSUPL4',0,@proc_os4 output,@pden_os4 output
	Exec Luare_date_par 'PS','PROCINT',0,0,@den_intr_tehn output

	
	select @culm=(case when @grupare=1 or @grupare=3 then 1 else 0 end),
          @cucomenzi=(case when @grupare=2 or @grupare=3 then 1 else 0 end)

	declare @q_datajos datetime, @q_datasus datetime, @q_lm varchar(9), @q_marca varchar(6), @q_comanda varchar(20), @q_colrand int, @q_ordonare int
	select @q_datajos=@datajos, @q_datasus=@datasus, @q_lm=@locm, @q_marca=@marca, @q_comanda=@comanda, @q_colrand=@colrand, 
		@q_ordonare=( case when @culm=1 then @ordonare else 0 end)

	declare @q_epsilon float
	set @q_epsilon=0.0001
	declare @utilizator varchar(20)
	set @utilizator = dbo.fIaUtilizator('')
	IF @utilizator IS NULL
		RETURN -1

	select 
	s.marca,s.nume,s.cod_functie,f.denumire,s.salar_de_incadrare,s.salar_de_baza	--antet salariat
	,isnull(r.loc_de_munca,p.loc_de_munca) as loc_de_munca,lm.denumire as nume_lm	-- locuri de munca
	,isnull(r.comanda,'') as comanda,c.descriere,									--antet comenzi
	p.data,p.Grupa_de_munca,														-- detalii
	/*,Ore_lucrate*/
		convert(float, Ore_regie) Ore_regie, convert(float, Ore_acord) Ore_acord, convert(float, Ore_suplimentare_1) Ore_sup1, 
		convert(float, Ore_suplimentare_2) Ore_sup2, convert(float, Ore_suplimentare_3) Ore_sup3, 
		convert(float, Ore_suplimentare_4) Ore_sup4, convert(float, Ore_spor_100) Ore_spor_100, convert(float, Ore_de_noapte) Ore_noapte,
		convert(float, Ore_intrerupere_tehnologica) Ore_intr_tehn, convert(float, Ore_concediu_de_odihna) Ore_conc_odih, 
		convert(float, Ore_concediu_medical) Ore_conc_med, convert(float, Ore_invoiri) Ore_invoiri, convert(float, Ore_nemotivate) Ore_nemotivate, 
		convert(float, Ore_obligatii_cetatenesti) Ore_oblig_cet, convert(float, Ore_concediu_fara_salar) Ore_conc_f_sal, 
		convert(float, Ore_donare_sange) Ore_don_sang, 
		convert(float,(case when @indiciPontajLM=1 and Coeficient_acord=0 and Ore_lucrate<>0 then 1 else Coeficient_acord end)) Coef_acord, convert(float,Coeficient_de_timp) Coef_timp,
		convert(float, Ore_realizate_acord) Ore_real_acord, convert(float,Ore_sistematic_peste_program) Ore_sist_p_prg, 
		convert(float,Ore__cond_1) Ore_cond_1, convert(float, Ore__cond_2) Ore_cond_2, convert(float, Ore__cond_3) Ore_cond_3, 
		convert(float, Ore__cond_4) Ore_cond_4, convert(float, Ore__cond_5) Ore_cond_5, convert(float, Ore__cond_6) Ore_cond_6, 
	--convert(float,p.Grupa_de_munca), 
		convert(float, Ore) Ore,convert(float,p.Spor_cond_10) Ore_deleg--pontaj
	into #pontaj
	from 
	pontaj p
		left join realcom r on p.marca=r.marca and p.loc_de_munca=r.loc_de_munca and p.data=r.data and 'PS'+rtrim(convert(char(3),p.numar_curent))=isnull(r.numar_document,'')
		inner join personal s on s.marca=p.marca
		left join functii f on f.cod_functie=s.cod_functie
		left join lm on lm.cod=isnull(r.loc_de_munca,p.loc_de_munca)
		left join comenzi c on c.comanda=r.comanda and '1'=c.subunitate
	where --r.marca is not null and 
		p.data between @q_datajos and @q_datasus
		and (@q_lm is null or p.loc_de_munca like @q_lm+'%')
		and (@q_marca is null or p.marca=@q_marca)
		and (@q_comanda is null or r.comanda like rtrim(@q_comanda))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
	order by f.cod_functie,r.marca,r.data

/**	pana aici select "cinstit", cu conversie la float pe toate datele pentru a nu intampina probleme la "unpivot" */
--	calculez coeficient acord ca si medie ponderata si impart la nr. de pozitii cu coeficient<>0, astfel incat la final sa se poata insuma
	update #pontaj set Coef_acord=(select round(sum((p.Ore_lucrate*(case when p.Coeficient_acord=0 then 1 else p.Coeficient_acord end)))/sum(p.Ore_lucrate),4)/COUNT(1)
	from pontaj p where p.Marca=#pontaj.Marca and month(p.Data)=MONTH(#pontaj.data) and YEAR(p.Data)=YEAR(#pontaj.data) and Ore_lucrate<>0)
	where Ore_regie+Ore_acord<>0 and @grupare=0

	create table #pontaj_matrix(grupare1 varchar(20),grupare2 varchar(20),grupare3 varchar(20),grupare4 varchar(20),
				et1 varchar(200), et2 varchar(200), et3 varchar(200), et4 varchar(200), camp varchar(20), valoare float,
				ordonare varchar(200),nr int,feliere varchar(2))
	insert into #pontaj_matrix(grupare1,grupare2,grupare3,grupare4,et1,et2,et3,et4,camp,valoare,ordonare,nr,feliere)
	select	(case when @culm=1 then rtrim(loc_de_munca) else '' end) grupare1, rtrim(marca) grupare2, 
		(case when @cucomenzi=1 then rtrim(comanda) else '' end) grupare3, rtrim(convert(varchar(20),data,102)) grupare4,
			'LM='+rtrim(loc_de_munca)+' | '+rtrim(isnull(nume_lm,''))+'' as et1,
			rtrim(marca)+' | '+rtrim(isnull(nume,''))+' | F='+rtrim(isnull(cod_functie,''))+' ('+rtrim(denumire)+')'+
			' | SI='+convert(varchar(20),round(salar_de_incadrare,4))+
			' | SB='+convert(varchar(20),round(salar_de_baza,4)) as et2, 
			rtrim(Comanda)+' | "'+rtrim(isnull(descriere,''))+'"' as et3,
			convert(varchar(20),data,103)+' | Gr. m.="'+rtrim(isnull(Grupa_de_munca,'')+'"') as et4,
		(case when camp='Ore_cond_6' then 'Nr tichete' else replace(camp,'_',' ') end) camp, valoare,
		'' as ordonare,
		row_number() over(order by (select 1 as unu)) as nr,
		'  ' feliere
	from (select marca,nume,cod_functie,denumire,salar_de_incadrare,salar_de_baza,
		comanda,loc_de_munca,nume_lm,descriere,data,Grupa_de_munca,
		Ore_regie, Ore_acord, Ore_sup1, Ore_sup2, Ore_sup3, Ore_sup4, Ore_spor_100, Ore_noapte, Ore_deleg, Ore_intr_tehn, Ore_conc_odih, 
		Ore_conc_med, Ore_invoiri, Ore_nemotivate, Ore_oblig_cet, Ore_conc_f_sal, Ore_don_sang, Coef_acord, Coef_timp, Ore_real_acord, 
		Ore_sist_p_prg, Ore_cond_1, Ore_cond_2, Ore_cond_3, Ore_cond_4, Ore_cond_5, Ore_cond_6, Ore from #pontaj) p
	unpivot
	(valoare
		for camp in
		(	Ore_regie, Ore_acord, Ore_sup1, Ore_sup2, Ore_sup3, Ore_sup4, Ore_spor_100, Ore_noapte, Ore_deleg, Ore_intr_tehn, Ore_conc_odih, 
			Ore_conc_med, Ore_invoiri, Ore_nemotivate, Ore_oblig_cet, Ore_conc_f_sal, Ore_don_sang, Coef_acord, Coef_timp, Ore_real_acord, 
			Ore_sist_p_prg, Ore_cond_1, Ore_cond_2, Ore_cond_3, Ore_cond_4, Ore_cond_5, Ore_cond_6, Ore
		)) as unpvt;		/** folosind operatorul unpivot se aduc toate valorile intr-o singura coloana, pentru pontaj matrix*/

	declare @q_nrcol int
	select @q_nrcol=count(distinct camp) from #pontaj_matrix

	update p set p.nr=((pp.nr-1) %@q_colrand)+1,
		p.feliere=replicate('0',2-len(convert(varchar(3),(pp.nr-1)/@q_colrand+1)))+convert(varchar(2),(pp.nr-1)/@q_colrand+1)
	from #pontaj_matrix p,		
	(select camp,row_number() over (order by nr) nr from
	(select camp,sum(abs(valoare)) valoare, min(nr) nr
			from #pontaj_matrix
			group by camp
	) p where valoare>=@q_epsilon
	)pp where p.camp=pp.camp /** update pentru pastrarea ordinii coloanelor indiferent de existenta valorilor si ordinea marcilor*/

	delete from #pontaj_matrix where abs(valoare)<@q_epsilon	/** eliminam datele fara valoare */

	if (@q_ordonare=1) /** inversare loc de munca cu marca*/
		update #pontaj_matrix set grupare1=grupare2,grupare2=grupare1,et1=et2,et2=et1

	insert into #pontaj_matrix(grupare1,grupare2,grupare3,grupare4,et1,et2,et3,et4,camp,valoare,ordonare,nr,feliere)
	select grupare1,grupare2,grupare3,grupare4,max(et1),max(et2),max(et3),max(et4),
		'' camp, 0 valoare, '' ordonare, max(pp.nr), pp.feliere 
	from #pontaj_matrix p,(select feliere,max(nr) nr from #pontaj_matrix pp group by feliere) pp
	group by grupare1,grupare2,grupare3,grupare4, pp.feliere

	/** Adaug denumirile pentru sporuri: */
--	Lucian: scriu in camp denumirea sporului fara caracterul '.' daca il contine, pentru a nu pune eronat formatul in reporting
	update p set camp='Ore '+rtrim(REPLACE(par.Val_alfanumerica,'.',' '))
	from #pontaj_matrix p,par where par.tip_parametru='PS' and (--parametru='SSPEC' and r.coloana='Spor_specific' or 
			parametru like 'SCOND%' and len(rtrim(parametru))=6 and right(rtrim(parametru),1)=right(p.camp,1) and Val_alfanumerica<>''
		and camp like 'Ore_cond_%')

	declare @maxfeliere varchar(2)
	select @maxfeliere=max(feliere) from #pontaj_matrix		/**	pentru a ordona corect datele am nevoie de variabila aceasta - vezi mai jos*/

	create table #final (feliere int, coloana int, ordonare varchar(200), parinte varchar(200), etgrupare varchar(200), valoare varchar(30), nivel int)
	insert into #final (feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel)
	select 1 feliere, 1 nr, 
		' | 11' ordonare, 
		'' parinte, (case when @q_ordonare=0 then 'Loc de munca | Denumire loc de munca' 
					else 'Marca | Nume | F="Functie" | SI="Salar de incadrare" | SB="Salar de baza"' end),'',1	where @culm=1
	union all
	select 1 feliere, 1 nr, 
		' | 12' ordonare, 
		'' parinte, (case when @q_ordonare=1 then 'Loc de munca | Denumire loc de munca' 
					else 'Marca | Nume | F="Functie" | SI="Salar de incadrare" | SB="Salar de baza"' end),'',2-(1-@culm)
	union all
	select 1 feliere, 1 nr, 
		' | 13' ordonare, 
		'' parinte, 'Comanda | Descriere','',3-(1-@culm) where @cucomenzi=1
	union all
	select 1 feliere, 1 nr, 
		' | 14' ordonare, 
		'' parinte, 'Data | Gr. m.="Grupa de munca"','',4-(1-@culm)-(1-@cucomenzi)	/** antetul raportului - e mai usor aici decat direct in raport*/
	union all
	select feliere, nr, 
		' |A'+max(feliere) ordonare, 
		'' parinte, '',max(camp),0
	from #pontaj_matrix group by feliere,nr
	union all
	select feliere, nr, ' |A'+@maxfeliere+
		+' |B'+max(feliere) ordonare, 
		' |A'+@maxfeliere parinte, 'Total',convert(varchar(20),round(sum(valoare),4)),0
	from #pontaj_matrix where camp<>'Coef acord'
	group by feliere,nr

/**	in tabela #final se introduc datele organizate astfel incat sa se poata afisa conform cu gruparile dorite si cu organizarea pe linii si coloane*/
	insert into #final (feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel)
	select feliere, nr, ' |A'+@maxfeliere+' |B'+@maxfeliere+
					' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+max(feliere) ordonare, 
					' |A'+@maxfeliere+' |B'+@maxfeliere parinte, 
			max(et1) ,convert(varchar(20),round(sum(valoare),4)),1
	from #pontaj_matrix where @culm=1 and camp<>'Coef acord'
	group by feliere,nr,grupare1

	insert into #final (feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel)
	select feliere, nr, ' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)+
					' |D'+replicate('0',20-len(grupare2))+grupare2+' |'+max(feliere)
		ordonare, 
					' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)
		parinte, max(et2) ,convert(varchar(20),round(sum(valoare),4)),2-(1-@culm)
	from #pontaj_matrix 
	where camp<>'Coef acord'
	group by feliere,nr,grupare1,grupare2

	insert into #final (feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel)
	select feliere, nr, ' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)+
					' |D'+replicate('0',20-len(grupare2))+grupare2+' |'+@maxfeliere+
					' |E'+replicate('0',20-len(grupare3))+grupare3+' |'+max(feliere)
		ordonare, 
					' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)+
					' |D'+replicate('0',20-len(grupare2))+grupare2+' |'+@maxfeliere
		 parinte, max(et3) , convert(varchar(20),round(sum(valoare),4)),3-(1-@culm)
	from #pontaj_matrix where @cucomenzi=1 and camp<>'Coef acord'
	group by feliere,nr,grupare1,grupare2,grupare3

	insert into #final (feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel)
	select feliere, nr, ' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)+
					' |D'+replicate('0',20-len(grupare2))+grupare2+' |'+@maxfeliere+
					(case when @cucomenzi=1 then ' |E'+replicate('0',20-len(grupare3))+grupare3+' |'+@maxfeliere else '' end)+
					' |F'+replicate('0',20-len(grupare4))+grupare4+' |'+max(feliere)
		ordonare, 
					' |A'+@maxfeliere+' |B'+@maxfeliere+
					(case when @culm=1 then ' |C'+replicate('0',20-len(grupare1))+grupare1+' |'+@maxfeliere else '' end)+
					' |D'+replicate('0',20-len(grupare2))+grupare2+' |'+@maxfeliere+
					(case when @cucomenzi=1 then ' |E'+replicate('0',20-len(grupare3))+grupare3+' |'+@maxfeliere else '' end)
		 parinte, max(et4) , convert(varchar(20),round(sum(valoare),4)),4-(1-@culm)-(1-@cucomenzi)
	from #pontaj_matrix 
	group by feliere,nr,grupare1,grupare2,grupare3,grupare4
	
	update #final set valoare=REPLACE((case when Valoare='Ore sup1' then @pden_os1 when Valoare='Ore sup2' then @pden_os2 
									when Valoare='Ore sup3' then @pden_os3 when Valoare='Ore sup4' then @pden_os4 
									when Valoare='Ore intr tehn' then @den_intr_tehn else valoare end),'.','')
	where valoare in ('Ore sup1','Ore sup2','Ore sup3','Ore sup4','Ore intr tehn')

	select feliere, coloana, ordonare, parinte, etgrupare, valoare, nivel 
	from #final 
	order by --len(ordonare),
		rtrim(ordonare), coloana
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapPontajMatrix (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch

IF OBJECT_ID('tempdb..#final') IS NOT NULL drop table #final
IF OBJECT_ID('tempdb..#pontaj') IS NOT NULL drop table #pontaj
IF OBJECT_ID('tempdb..#pontaj_matrix') IS NOT NULL drop table #pontaj_matrix

/*
	exec rapPontajMatrix '08/01/2012', '08/31/2012', null, null, null, 14, 3, 0
*/
