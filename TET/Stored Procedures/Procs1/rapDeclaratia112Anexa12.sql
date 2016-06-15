/**
	Procedura este folosita pentru a lista Anexa 12 (nominala) la declaratia 112. 
**/
Create procedure rapDeclaratia112Anexa12 (@sesiune varchar(50), @datalunii datetime, @marca varchar(6)=null, @cnp varchar(13)=null, @dataset varchar(20), @parXML xml='<row/>')
AS
/*
	exec rapDeclaratia112Anexa12 @sesiune='', @datajos='10/01/2013', @datasus='10/31/2013', @dataset='Asigurat', @parXML='<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @lista_lm int, @lm varchar(9), @alfabetic int, @doarCM int, @mesaj varchar(1000)
	
	select @alfabetic=isnull(@parXML.value('(/row/@alfabetic)[1]','int'),0)
		,@doarCM=isnull(@parXML.value('(/row/@doarcm)[1]','int'),0)
		,@datalunii=dbo.EOM(@datalunii)
	
	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)

	if @marca is not null
		select @cnp=cod_numeric_personal from personal where marca=@marca

--	Date asigurati
	if @dataset='Asigurat'
		select a.Data, a.cnpAsig, a.idAsig, a.numeAsig, a.prenAsig, a.cnpAnt, a.numeAnt, a.prenAnt, a.dataAng, a.dataSf, a.casaSn, a.asigCI, a.asigSO
		from D112Asigurat a
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.loc_de_munca
		where a.data=@datalunii and (@doarCM=0 or a.cnpAsig in (select cnpAsig from D112AsiguratD where data=@datalunii))
			and (@cnp is null or a.cnpAsig=@cnp)
			and (@lista_lm=0 or lu.cod is not null)
		order by (case when @alfabetic=1 then a.numeAsig else a.cnpAsig end)

--	Date coasigurati
	if @dataset='CoAsigurati'
		select Data, cnpAsig, (case when tip='S' then 'Sot/sotie' else 'Parinte' end) as tipAsigurat, cnp, nume, prenume 
		from D112coasigurati c
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=c.loc_de_munca
		where Data=@datalunii and cnpAsig=@cnp
			and (@lista_lm=0 or lu.cod is not null)

--	Sectiuni
	if @dataset='Sectiuni'
	begin
		if OBJECT_ID('tempdb..#sectiuni') is not null drop table #sectiuni
		create table #sectiuni (sectiune varchar(20), den_sectiune varchar(200), data datetime, cnpAsig varchar(13), coloana varchar(20), den_suma varchar(1000), suma varchar(15))
		insert into #sectiuni 
		select 'SECTIUNEA A', '', Data, CNPAsig, coloana, '' as den_suma, suma
		from 
		(select Data, cnpAsig, convert(varchar(15),A_1) as A_1, convert(varchar(15),A_2) as A_2, convert(varchar(15),A_3) as A_3, convert(varchar(15),A_4) as A_4, 
			convert(varchar(15),A_5) as A_5, convert(varchar(15),A_6) as A_6, convert(varchar(15),A_7) as A_7, convert(varchar(15),A_8) as A_8, convert(varchar(15),A_9) as A_9, 
			convert(varchar(15),A_10) as A_10, convert(varchar(15),A_11) as A_11, convert(varchar(15),A_12) as A_12, convert(varchar(15),A_13) as A_13, 
			convert(varchar(15),A_14) as A_14, convert(varchar(15),A_20) as A_20
		from D112AsiguratA a
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=a.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp 
			and (@lista_lm=0 or lu.cod is not null)) a 
		unpivot (suma for coloana in (A_1, A_2, A_3, A_4, A_5, A_6, A_7, A_8, A_9, A_10, A_11, A_12, A_13, A_14, A_20)) r

		insert into #sectiuni
		select 'B.1.','Contract / Contracte de munca sau/si somaj tehnic beneficiar de scutire', Data, CNPAsig, coloana, '' as den_suma, suma
		from 
		(select Data, cnpAsig, convert(varchar(15),B1_1) as B1_1, convert(varchar(15),B1_2) as B1_2, convert(varchar(15),B1_3) as B1_3, convert(varchar(15),B1_4) as B1_4, 
			convert(varchar(15),B1_5) as B1_5, convert(varchar(15),B1_6) as B1_6, convert(varchar(15),B1_7) as B1_7, convert(varchar(15),B1_8) as B1_8, 
			convert(varchar(15),B1_9) as B1_9, convert(varchar(15),B1_10) as B1_10, convert(varchar(15),B1_15) as B1_15
		from D112AsiguratB1 b1
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=b1.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp 
			and (@lista_lm=0 or lu.cod is not null)) a 
		unpivot (suma for coloana in (B1_1, B1_2, B1_3, B1_4, B1_5, B1_6, B1_7, B1_8, B1_9, B1_10, B1_15)) r

		insert into #sectiuni
		select 'B.1.1.', 'Scutiri la plata', Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, convert(varchar(15),B11_1) as B11_1, convert(varchar(15),B11_2) as B11_2, convert(varchar(15),B11_3) as B11_3, convert(varchar(15),B11_41) as B11_41, 
			convert(varchar(15),B11_42) as B11_42, convert(varchar(15),B11_43) as B11_43, convert(varchar(15),B11_5) as B11_5, 
			convert(varchar(15),B11_6) as B11_6, convert(varchar(15),B11_71) as B11_71, convert(varchar(15),B11_72) as B11_72, convert(varchar(15),B11_73) as B11_73
		from D112AsiguratB11 b11
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=b11.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp
			and (@lista_lm=0 or lu.cod is not null)) a
		unpivot (suma for coloana in (B11_1, B11_2, B11_3, B11_41, B11_42, B11_43, B11_5, B11_6, B11_71, B11_72, B11_73)) r

		insert into #sectiuni
		select 'AsiguratB234', '', Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, convert(varchar(15),B2_1) as B2_1, convert(varchar(15),B2_2) as B2_2, convert(varchar(15),B2_3) as B2_3, convert(varchar(15),B2_4) as B2_4, 
			convert(varchar(15),B2_5) as B2_5, convert(varchar(15),B2_6) as B2_6, convert(varchar(15),B2_7) as B2_7, 
			convert(varchar(15),B3_1) as B3_1, convert(varchar(15),B3_2) as B3_2, convert(varchar(15),B3_3) as B3_3, convert(varchar(15),B3_4) as B3_4, 
			convert(varchar(15),B3_5) as B3_5, convert(varchar(15),B3_6) as B3_6, convert(varchar(15),B3_7) as B3_7, convert(varchar(15),B3_8) as B3_8, 
			convert(varchar(15),B3_9) as B3_9, convert(varchar(15),B3_10) as B3_10, convert(varchar(15),B3_11) as B3_11, convert(varchar(15),B3_12) as B3_12, 
			convert(varchar(15),B3_13) as B3_13, convert(varchar(15),B4_1) as B4_1, convert(varchar(15),B4_2) as B4_2, convert(varchar(15),B4_3) as B4_3, 
			convert(varchar(15),B4_4) as B4_4, convert(varchar(15),B4_5) as B4_5, convert(varchar(15),B4_6) as B4_6, convert(varchar(15),B4_7) as B4_7, 
			convert(varchar(15),B4_8) as B4_8, convert(varchar(15),B4_14) as B4_14
		from D112AsiguratB234 b2
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=b2.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp
			and (@lista_lm=0 or lu.cod is not null)) a
		unpivot (suma for coloana in (B2_1, B2_2, B2_3, B2_4, B2_5, B2_6, B2_7, B3_1, B3_2, B3_3, B3_4, B3_5, B3_6, B3_7, B3_8, B3_9, B3_10, B3_11, B3_12, B3_13, 
			B4_1, B4_2, B4_3, B4_4, B4_5, B4_6, B4_7, B4_8, B4_14)) r

		update #sectiuni set 
				den_sectiune=(case when left(coloana,2)='B2' then 'C.N.P.A.S. - Conditii de munca' 
					when left(coloana,2)='B3' then 'Ind. Asigurari Sociale conf. OUG 158/2005, cu  modif. si complet. ulterioare sau Prestatii conf. Legii nr.346/2002.' 
					when left(coloana,2)='B4' then 'Centralizator' 
					end), 
				sectiune=left(coloana,1)+'.'+substring(coloana,2,1)+'.'
		where sectiune='AsiguratB234'

		insert into #sectiuni
		select 'SECTIUNEA D'+convert(char(1),id), '-Concedii medicale conform O.U.G. nr.158/2005, cu  modificarile si completarile ulterioare', 
			Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, ROW_NUMBER() over (order by D_1) as id, 
			convert(varchar(15),D_1) as D_1, convert(varchar(15),D_2) as D_2, convert(varchar(15),isnull(D_3,'')) as D_3, convert(varchar(15),isnull(D_4,'')) as D_4, 
			convert(varchar(15),D_5) as D_5, convert(varchar(15),D_6) as D_6, convert(varchar(15),D_7) as D_7, convert(varchar(15),isnull(D_8,'')) as D_8, 
			convert(varchar(15),D_9) as D_9, convert(varchar(15),D_10) as D_10,	convert(varchar(15),isnull(D_11,'')) as D_11, convert(varchar(15),isnull(D_12,'')) as D_12, 
			convert(varchar(15),isnull(D_13,'')) as D_13, convert(varchar(15),D_14) as D_14, convert(varchar(15),D_15) as D_15, convert(varchar(15),D_16) as D_16, 
			convert(varchar(15),D_17) as D_17, convert(varchar(15),D_18) as D_18, convert(varchar(15),D_19) as D_19, convert(varchar(15),D_20) as D_20, convert(varchar(15),D_21) as D_21 
		from D112AsiguratD d
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=d.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp
			and (@lista_lm=0 or lu.cod is not null)) a
		unpivot (suma for coloana in (D_1, D_2, D_3, D_4, D_5, D_6, D_7, D_8, D_9, D_10, D_11, D_12, D_13, D_14, D_15, D_16, D_17, D_18, D_19, D_20, D_21)) r

		insert into #sectiuni
		select 'SECTIUNEA E1', ' - Venituri din salarii obtinute la functia de baza', 
		Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_8)))) as E1_1, rtrim(convert(char(15),sum(convert(decimal(10),E3_9)))) as E1_2, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_11)))) as E1_3, rtrim(convert(char(15),sum(convert(decimal(10),E3_12)))) as E1_4, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_13)))) as E1_5, rtrim(convert(char(15),sum(convert(decimal(10),E3_14)))) as E1_6, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_15)))) as E1_7 
		from D112AsiguratE3 
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=loc_de_munca
		where Data=@datalunii and cnpAsig=@cnp and E3_3='1' 
			and (@lista_lm=0 or lu.cod is not null)
		group by Data, Loc_de_munca, cnpAsig) a
		unpivot (suma for coloana in (E1_1, E1_2, E1_3, E1_4, E1_5, E1_6, E1_7)) r

		insert into #sectiuni
		select 'SECTIUNEA E2', ' - Alte venituri din salarii', 
		Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_8)))) as E2_1, rtrim(convert(char(15),sum(convert(decimal(10),E3_9)))) as E2_2, 
			rtrim(convert(char(15),sum(convert(decimal(10),E3_14)))) as E2_3, rtrim(convert(char(15),sum(convert(decimal(10),E3_15)))) as E2_4 
		from D112AsiguratE3 
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=loc_de_munca
		where Data=@datalunii and cnpAsig=@cnp and E3_3<>'1' 
			and (@lista_lm=0 or lu.cod is not null)
		group by Data, Loc_de_munca, cnpAsig) a
		unpivot (suma for coloana in (E2_1, E2_2, E2_3, E2_4)) r

		insert into #sectiuni
		select 'SECTIUNEA E3.'+convert(char(1),id), ' - Date detaliate privind impozitul pe venit', 
			Data, CNPAsig, coloana, '' as den_suma, suma
		from
		(select Data, cnpAsig, ROW_NUMBER() over (order by E3_1, E3_2, E3_3, E3_4) as id, 
			convert(varchar(15),E3_1) as E3_1, convert(varchar(15),E3_2) as E3_2, convert(varchar(15),isnull(E3_3,'')) as E3_3, convert(varchar(15),isnull(E3_4,'')) as E3_4, 
			convert(varchar(15),E3_5) as E3_5, convert(varchar(15),E3_6) as E3_6, convert(varchar(15),E3_7) as E3_7, convert(varchar(15),isnull(E3_8,'')) as E3_8, 
			convert(varchar(15),E3_9) as E3_9, convert(varchar(15),E3_10) as E3_10,	convert(varchar(15),isnull(E3_11,'')) as E3_11, convert(varchar(15),isnull(E3_12,'')) as E3_12, 
			convert(varchar(15),isnull(E3_13,'')) as E3_13, convert(varchar(15),E3_14) as E3_14, convert(varchar(15),E3_15) as E3_15, convert(varchar(15),E3_16) as E3_16
		from D112AsiguratE3 d
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=d.loc_de_munca
		where data=@datalunii and cnpAsig=@cnp
			and (@lista_lm=0 or lu.cod is not null)) a
		unpivot (suma for coloana in (E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16)) r

		select ts.ordine, s.sectiune, s.den_sectiune, s.data, s.cnpAsig, s.coloana, ts.den_suma, ltrim(rtrim(s.suma)) as suma
		from #sectiuni s
			left outer join dbo.fTipSumeD112(@datalunii) ts on ts.cod=s.coloana
		order by sectiune, ordine
	end

end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapDeclaratia112Anexa12)'
	raiserror(@mesaj, 11, 1)
end catch
