--***
Create procedure wOPModificareD112 @sesiune varchar(50), @parXML xml
as

declare @subtip varchar(2), @datalunii datetime, @luna int, @an int, @userASiS varchar(20), @lmUtilizator varchar(9), @iDoc int, @multiFirma int

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
select @multiFirma=0
if exists (select * from sysobjects where name ='par' and xtype='V')
	set @multiFirma=1

if @multiFirma=1 
	select @lmUtilizator=isnull(min(Cod),'') from LMfiltrare where utilizator=@userASiS and cod in (select cod from lm where Nivel=1)

set @subtip = ISNULL(@parXML.value('(/parametri/@subtip)[1]', 'varchar(2)'), '')
set @luna = ISNULL(@parXML.value('(/parametri/@luna)[1]', 'int'), 0)
set @an = ISNULL(@parXML.value('(/parametri/@an)[1]', 'int'), 0)
set @datalunii=dbo.eom(convert(datetime,str(@luna,2)+'/01/'+str(@an,4)))

begin try  
	--BEGIN TRAN

	if @subtip in ('AA')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AngajatorA (contributii pe coduri bugetare)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AngajatorA') IS NOT NULL DROP TABLE #D112AngajatorA

		SELECT @datalunii as data, A_codOblig, A_codBugetar, A_datorat, A_deductibil, A_plata
		INTO #D112AngajatorA
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '../@data'
			,A_codOblig varchar(20) '@A_codOblig'
			,A_codBugetar varchar(20) '@A_codBugetar'
			,A_datorat varchar(15) '@A_datorat'
			,A_deductibil varchar(15) '@A_deductibil'
			,A_plata varchar(15) '@A_plata'
		)
		EXEC sp_xml_removedocument @iDoc 
		
--	actualizez datele din tabela D112AngajatorA cu valorile din grid (daca s-au modificat)
		update a set a.A_datorat=x.A_datorat, a.A_deductibil=x.A_deductibil, a.A_plata=x.A_plata
		from D112AngajatorA a 
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
			, #D112AngajatorA x
		where (@multifirma=0 or lu.Cod is not null) 
			and a.Data=@datalunii and a.A_codOblig=x.A_codOblig 
	End

	if @subtip in ('AB')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AngajatorB (contributii sociale si baze de calcul)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AngajatorB') IS NOT NULL DROP TABLE #D112AngajatorB

		SELECT @datalunii as data, B_cnp, B_sanatate, B_pensie, B_brutSalarii, totalPlata_A, C1_11, C1_12, C1_13, C1_21, C1_22, C1_23, C1_31, C1_32, C1_33, C1_T1, C1_T2, C1_T, C1_T3, C1_5, C1_6, C1_7, 
		C2_11, C2_12, C2_13, C2_14, C2_15, C2_16, C2_21, C2_22, C2_24, C2_26, C2_31, C2_32, C2_34, C2_36, C2_41, C2_42, C2_44, C2_46, C2_51, C2_52, C2_54, C2_56, C2_T6, C2_7, C2_8, C2_9, C2_10, 
		C2_110, C2_120, C2_130, C3_11, C3_12, C3_13, C3_14, C3_21, C3_22, C3_23, C3_24, C3_31, C3_32, C3_33, C3_34, C3_41, C3_42, C3_43, C3_44, 
		C3_total, C3_suma, C3_aj_nr, C3_aj_suma, C4_scutitaSo, C6_baza, C6_ct, C7_baza, C7_ct, D1, E1_venit, F1_suma
		INTO #D112AngajatorB
		FROM OPENXML(@iDoc, '/parametri')
		WITH
		(
			data datetime '@data'
			,B_cnp varchar(15) '@B_cnp'
			,B_sanatate varchar(15) '@B_sanatate'
			,B_pensie varchar(15) '@B_pensie'
			,B_brutSalarii varchar(15) '@B_brutSalarii'
			,totalPlata_A varchar(15) '@totalPlata_A'
			,C1_11 varchar(15) '@C1_11'
			,C1_12 varchar(15) '@C1_12'
			,C1_13 varchar(15) '@C1_13'
			,C1_21 varchar(15) '@C1_21'
			,C1_22 varchar(15) '@C1_22'
			,C1_23 varchar(15) '@C1_23'
			,C1_31 varchar(15) '@C1_31'
			,C1_32 varchar(15) '@C1_32'
			,C1_33 varchar(15) '@C1_33'
			,C1_T1 varchar(15) '@C1_T1'
			,C1_T2 varchar(15) '@C1_T2'
			,C1_T varchar(15) '@C1_T'
			,C1_T3 varchar(15) '@C1_T3'
			,C1_5 varchar(15) '@C1_5'
			,C1_6 varchar(15) '@C1_6'
			,C1_7 varchar(15) '@C1_7'
			,C2_11 varchar(15) '@C2_11'
			,C2_12 varchar(15) '@C2_12'
			,C2_13 varchar(15) '@C2_13'
			,C2_14 varchar(15) '@C2_14'
			,C2_15 varchar(15) '@C2_15'
			,C2_16 varchar(15) '@C2_16'
			,C2_21 varchar(15) '@C2_21'
			,C2_22 varchar(15) '@C2_22'
			,C2_24 varchar(15) '@C2_24'
			,C2_26 varchar(15) '@C2_26'
			,C2_31 varchar(15) '@C2_31'
			,C2_32 varchar(15) '@C2_32'
			,C2_34 varchar(15) '@C2_34'
			,C2_36 varchar(15) '@C2_36'
			,C2_41 varchar(15) '@C2_41'
			,C2_42 varchar(15) '@C2_42'
			,C2_44 varchar(15) '@C2_44'
			,C2_46 varchar(15) '@C2_46'
			,C2_51 varchar(15) '@C2_51'
			,C2_52 varchar(15) '@C2_52'
			,C2_54 varchar(15) '@C2_54'
			,C2_56 varchar(15) '@C2_56'
			,C2_T6 varchar(15) '@C2_T6'
			,C2_7 varchar(15) '@C2_7'
			,C2_8 varchar(15) '@C2_8'
			,C2_9 varchar(15) '@C2_9'
			,C2_10 varchar(15) '@C2_10'
			,C2_110 varchar(15) '@C2_110'
			,C2_120 varchar(15) '@C2_120'
			,C2_130 varchar(15) '@C2_130'
			,C3_11 varchar(15) '@C3_11'
			,C3_12 varchar(15) '@C3_12'
			,C3_13 varchar(15) '@C3_13'
			,C3_14 varchar(15) '@C3_14'
			,C3_21 varchar(15) '@C3_21'
			,C3_22 varchar(15) '@C3_22'
			,C3_23 varchar(15) '@C3_23'
			,C3_24 varchar(15) '@C3_24'
			,C3_31 varchar(15) '@C3_31'
			,C3_32 varchar(15) '@C3_32'
			,C3_33 varchar(15) '@C3_33'
			,C3_34 varchar(15) '@C3_34'
			,C3_41 varchar(15) '@C3_41'
			,C3_42 varchar(15) '@C3_42'
			,C3_43 varchar(15) '@C3_43'
			,C3_44 varchar(15) '@C3_44'
			,C3_total varchar(15) '@C3_total'
			,C3_suma varchar(15) '@C3_suma'
			,C3_aj_nr varchar(15) '@C3_aj_nr'
			,C3_aj_suma varchar(15) '@C3_aj_suma'
			,C4_scutitaSo varchar(15) '@C4_scutitaSo'
			,C6_baza varchar(15) '@C6_baza'
			,C6_ct varchar(15) '@C6_ct'
			,C7_baza varchar(15) '@C7_baza'
			,C7_ct varchar(15) '@C7_ct'
			,D1 varchar(15) '@D1'
			,E1_venit varchar(15) '@E1_venit'
			,F1_suma varchar(15) '@F1_suma'
		)
		EXEC sp_xml_removedocument @iDoc 
		select * from #D112AngajatorB
--	actualizez datele din tabela D112AngajatorB cu valorile din grid (daca s-au modificat)
		update a set a.B_cnp=x.B_cnp, a.B_sanatate=x.B_sanatate, a.B_pensie=x.B_pensie, 
			a.B_brutSalarii=x.B_brutSalarii, a.totalPlata_A=x.totalPlata_A, a.C1_11=x.C1_11, a.C1_12=x.C1_12, a.C1_13=x.C1_13, a.C1_21=x.C1_21, a.C1_22=x.C1_22, a.C1_23=x.C1_23, 
			a.C1_31=x.C1_31, a.C1_32=x.C1_32, a.C1_33=x.C1_33, a.C1_T1=x.C1_T1, a.C1_T2=x.C1_T2, a.C1_T=x.C1_T, a.C1_T3=x.C1_T3, a.C1_5=x.C1_5, a.C1_6=x.C1_6, a.C1_7=x.C1_7, 
			a.C2_11=x.C2_11, a.C2_12=x.C2_12, a.C2_13=x.C2_13, a.C2_14=x.C2_14, a.C2_15=x.C2_15, a.C2_16=x.C2_16, a.C2_21=x.C2_21, a.C2_22=x.C2_22, a.C2_24=x.C2_24, a.C2_26=x.C2_26, 
			a.C2_31=x.C2_31, a.C2_32=x.C2_32, a.C2_34=x.C2_34, a.C2_36=x.C2_36, a.C2_41=x.C2_41, a.C2_42=x.C2_42, a.C2_44=x.C2_44, a.C2_46=x.C2_46, 
			a.C2_51=x.C2_51, a.C2_52=x.C2_52, a.C2_54=x.C2_54, a.C2_56=x.C2_56, a.C2_T6=x.C2_T6, a.C2_7=x.C2_7, a.C2_8=x.C2_8, a.C2_9=x.C2_9, a.C2_10=x.C2_10, 
			a.C2_110=x.C2_110, a.C2_120=x.C2_120, a.C2_130=x.C2_130, a.C3_11=x.C3_11, a.C3_12=x.C3_12, a.C3_13=x.C3_13, a.C3_14=x.C3_14, a.C3_21=x.C3_21, 
			a.C3_22=x.C3_22, a.C3_23=x.C3_23, a.C3_24=x.C3_24, a.C3_31=x.C3_31, a.C3_32=x.C3_32, a.C3_33=x.C3_33, a.C3_34=x.C3_34, 
			a.C3_41=x.C3_41, a.C3_42=x.C3_42, a.C3_43=x.C3_43, a.C3_44=x.C3_44, 
			a.C3_total=x.C3_total, a.C3_suma=x.C3_suma, a.C3_aj_nr=x.C3_aj_nr, a.C3_aj_suma=x.C3_aj_suma, 
			a.C4_scutitaSo=x.C4_scutitaSo, a.C6_baza=x.C6_baza, a.C6_ct=x.C6_ct, a.C7_baza=x.C7_baza, a.C7_ct=x.C7_ct, a.D1=x.D1, a.E1_venit=x.E1_venit, a.F1_suma=x.F1_suma
		from D112AngajatorB a 
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
			, #D112AngajatorB x
		where (@multifirma=0 or lu.Cod is not null) and a.Data=@datalunii 
	End

	if @subtip in ('C5')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AngajatorC5 (subventii / scutiri somaj)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AngajatorC5') IS NOT NULL DROP TABLE #D112AngajatorC5

		SELECT @datalunii as data, C5_subv, C5_recuperat, C5_restituit
		INTO #D112AngajatorC5
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '../../@data'
			,C5_subv varchar(20) '@C5_subv'
			,C5_recuperat varchar(20) '@C5_recuperat'
			,C5_restituit varchar(15) '@C5_restituit'
		)
		EXEC sp_xml_removedocument @iDoc 

--	actualizez datele din tabela D112AngajatorC5 cu valorile din grid (daca s-au modificat)
		update a set a.C5_recuperat=x.C5_recuperat, a.C5_restituit=x.C5_restituit
		from D112AngajatorC5 a 
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
			, #D112AngajatorC5 x
		where (@multifirma=0 or lu.Cod is not null) 
			and a.Data=@datalunii and a.C5_subv=x.C5_subv 
	End

	if @subtip in ('F2')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AngajatorF2 (impozit pe puncte de lucru)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AngajatorF2') IS NOT NULL DROP TABLE #D112AngajatorF2

		SELECT @datalunii as data, F2_cif, F2_id, F2_suma
		INTO #D112AngajatorF2
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '../@data'
			,F2_cif varchar(20) '@F2_cif'
			,F2_id varchar(10) '@F2_id'
			,F2_suma varchar(15) '@F2_suma'
		)
		EXEC sp_xml_removedocument @iDoc 
		
--	actualizez datele din tabela D112AngajatorC5 cu valorile din grid (daca s-au modificat)
		update a set a.F2_suma=x.F2_suma
		from D112AngajatorF2 a 
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
			, #D112AngajatorF2 x
		where (@multifirma=0 or lu.Cod is not null) 
			and a.Data=@datalunii and a.F2_id=x.F2_id and a.F2_cif=x.F2_cif
	End

	if @subtip in ('AD')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AsiguratD (Concedii medicale)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AsiguratD') IS NOT NULL DROP TABLE #D112AsiguratD

		SELECT cnpasig, D_1, D_2, D_3, D_4, D_5, D_6, D_7, D_8, D_9, D_10, D_11, D_12, D_13, D_14, D_15, D_16, D_17, D_18, D_19, D_20, D_21
		INTO #D112AsiguratD
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '../@data'
			,cnpasig varchar(13) '@cnpasig'
			,D_1 varchar(10) '@D_1'
			,D_2 varchar(10) '@D_2'
			,D_3 varchar(10) '@D_3'
			,D_4 varchar(10) '@D_4'
			,D_5 varchar(10) '@D_5'
			,D_6 varchar(10) '@D_6'
			,D_7 varchar(10) '@D_7'
			,D_8 varchar(10) '@D_8'
			,D_9 varchar(10) '@D_9'
			,D_10 varchar(10) '@D_10'
			,D_11 varchar(10) '@D_11'
			,D_12 varchar(10) '@D_12'
			,D_13 varchar(10) '@D_13'
			,D_14 varchar(10) '@D_14'
			,D_15 varchar(10) '@D_15'
			,D_16 varchar(10) '@D_16'
			,D_17 varchar(10) '@D_17'
			,D_18 varchar(10) '@D_18'
			,D_19 varchar(15) '@D_19'
			,D_20 varchar(15) '@D_20'
			,D_21 varchar(15) '@D_21'
		)
		EXEC sp_xml_removedocument @iDoc 
		
--	actualizez datele din tabela D112AsiguratD cu valorile din grid (daca s-au modificat)
		update d set d.D_3=x.D_3, d.D_4=x.D_4, d.D_5=x.D_5, d.D_6=x.D_6, d.D_7=x.D_7, d.D_8=x.D_8, d.D_9=x.D_9, d.D_10=x.D_10, 
			d.D_11=x.D_11, d.D_12=x.D_12, d.D_13=x.D_13, d.D_14=x.D_14, d.D_15=x.D_15, d.D_16=x.D_16, 
			d.D_17=x.D_17, d.D_18=x.D_18, d.D_19=x.D_19, d.D_20=x.D_20, d.D_21=x.D_21
		from D112AsiguratD d 
			left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=d.Loc_de_munca
			, #D112AsiguratD x
		where (@multifirma=0 or lu.Cod is not null) 
			and d.Data=@datalunii and d.cnpAsig=x.cnpAsig and d.D_1=x.D_1 and d.D_2=x.D_2
	End

	if @subtip in ('AE')
	Begin
--	citire date din gridul de operatii pt. editare sectiune AsiguratE (date detaliate privind impozitul pe venit)
		EXEC sp_xml_preparedocument @iDoc OUTPUT, @parXML
		IF OBJECT_ID('tempdb..#D112AsiguratE3') IS NOT NULL DROP TABLE #D112AsiguratE3

		SELECT cnpasig, E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16, _update
		INTO #D112AsiguratE3
		FROM OPENXML(@iDoc, '/parametri/DateGrid/row')
		WITH
		(
			data datetime '../@data'
			,_update int '../../@update'
			,cnpasig varchar(13) '@cnpasig'
			,E3_1 varchar(10) '@E3_1'
			,E3_2 varchar(10) '@E3_2'
			,E3_3 varchar(10) '@E3_3'
			,E3_4 varchar(10) '@E3_4'
			,E3_5 varchar(10) '@E3_5'
			,E3_6 varchar(10) '@E3_6'
			,E3_7 varchar(10) '@E3_7'
			,E3_8 varchar(10) '@E3_8'
			,E3_9 varchar(10) '@E3_9'
			,E3_10 varchar(10) '@E3_10'
			,E3_11 varchar(10) '@E3_11'
			,E3_12 varchar(10) '@E3_12'
			,E3_13 varchar(10) '@E3_13'
			,E3_14 varchar(10) '@E3_14'
			,E3_15 varchar(10) '@E3_15'
			,E3_16 varchar(10) '@E3_16'
			,idPozitie int '@idPozitie'
		)
		EXEC sp_xml_removedocument @iDoc 

--	actualizez datele din tabela D112AsiguratE3 cu valorile din grid (daca s-au modificat)
		if exists (select 1 from #D112AsiguratE3 where _update=1)
			update e set e.E3_5=x.E3_5, e.E3_6=x.E3_6, e.E3_7=x.E3_7, e.E3_8=x.E3_8, e.E3_9=x.E3_9, e.E3_10=x.E3_10, 
				e.E3_11=x.E3_11, e.E3_12=x.E3_12, e.E3_13=x.E3_13, e.E3_14=x.E3_14, e.E3_15=x.E3_15, e.E3_16=x.E3_16
			from D112AsiguratE3 e 
				left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=e.Loc_de_munca
				, #D112AsiguratE3 x
			where (@multifirma=0 or lu.Cod is not null) 
				and e.Data=@datalunii and e.cnpAsig=x.cnpAsig and e.idPozitie=x.idPozitie
		else
			insert into D112AsiguratE3 (Data, Loc_de_munca, cnpAsig, E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16)
			select @datalunii, @lmUtilizator, cnpAsig, 
				E3_1, E3_2, E3_3, E3_4, E3_5, E3_6, E3_7, E3_8, E3_9, E3_10, E3_11, E3_12, E3_13, E3_14, E3_15, E3_16
			from #D112AsiguratE3 a
	End

	--COMMIT TRAN
end try  

begin catch  
	--ROLLBACK TRAN
	declare @eroare varchar(254) 
	set @eroare='Procedura wOPModificareD112 (linia '+convert(varchar(20),ERROR_LINE())+'): '+ERROR_MESSAGE()
	raiserror(@eroare, 16, 1) 
end catch
