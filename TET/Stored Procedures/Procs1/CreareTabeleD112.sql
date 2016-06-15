--***
Create procedure CreareTabeleD112
as  
Begin
--drop table D112angajatorA
	if not exists (select * from sysobjects where name ='D112angajatorA')
		Create table D112angajatorA (Data datetime, A_codOblig char(3), A_codBugetar char(10), A_datorat char(15), A_deductibil char(15), A_plata char(15))
	if dbo.VerificCampTabela ('D112angajatorA', 'Data')=0
		Alter table D112angajatorA add Data datetime not null default ''
--drop table D112angajatorB
	if not exists (select * from sysobjects where name ='D112angajatorB')
		Create table D112angajatorB (Data datetime, B_cnp char(6), B_sanatate char(6), B_pensie char(5), B_brutSalarii char(15), totalPlata_A char(15), 
		C1_11 char(15), C1_12  char(15), C1_13 char(15), C1_21 char(15), C1_22 char(15), C1_23 char(15), 
		C1_31 char(15), C1_32 char(15), C1_33 char(15), C1_T1 char(15), C1_T2 char(15), C1_T char(15), 
		C1_T3 char(15), C1_5 char(15), C1_6 char(15), C1_7 char(15), 
		C2_11 char(6), C2_12 char(5), C2_13 char(5), C2_14 char(5), C2_15 char(15), C2_16 char(15), 
		C2_21 char(6), C2_22 char(5), C2_24 char(5), C2_26 char(15), C2_31 char(6), C2_32 char(5), C2_34 char(5), C2_36 char(15), 
		C2_41 char(6), C2_42 char(5), C2_44 char(5), C2_46 char(15), 
		C2_51 char(6), C2_52 char(5), C2_54 char(5), C2_56 char(15), C2_T6 char(15), 
		C2_7 char(15), C2_8 char(15), C2_9 char(15), C2_10 char(15), C2_110 char(15), C2_120 char(15), C2_130 char(15), 
		C3_11 char(6), C3_12 char(5), C3_13 char(15), C3_14 char(15),
		C3_21 char(6), C3_22 char(5), C3_23 char(15), C3_24 char(15),
		C3_31 char(6), C3_32 char(5), C3_33 char(15), C3_34 char(15),
		C3_41 char(6), C3_42 char(5), C3_43 char(15), C3_44 char(15),
		C3_total char(15), C3_suma char(15), C3_aj_nr char(15), C3_aj_suma char(15),C4_scutitaSo char(15), 
		C6_baza char(15), C6_ct char(15), C7_baza char(15), C7_ct char(15), D1 char(6), E1_venit char(15), F1_suma char(15))
	if dbo.VerificCampTabela ('D112angajatorB', 'Data')=0
		Alter table D112angajatorB add Data datetime not null default ''
--drop table D112angajatorC5
	if not exists (select * from sysobjects where name ='D112angajatorC5')
		Create table D112angajatorC5 (Data datetime, C5_subv char(2), C5_recuperat char(15), C5_restituit char(15)) 
	if dbo.VerificCampTabela ('D112angajatorC5', 'Data')=0
		Alter table D112angajatorC5 add Data datetime not null default ''
--drop table D112angajatorF2
	if not exists (select * from sysobjects where name ='D112angajatorF2')
		Create table D112angajatorF2 (Data datetime, F2_cif char(10), F2_id char(5), F2_suma char(15)) 
	if dbo.VerificCampTabela ('D112angajatorF2', 'Data')=0
		Alter table D112angajatorF2 add Data datetime not null default ''
--drop table D112Asigurat
	if not exists (select * from sysobjects where name ='D112Asigurat')
		Create table D112Asigurat (Data datetime, cnpAsig char(13), idAsig char(6), numeAsig char(75), prenAsig char(75), 
		cnpAnt char(13), numeAnt char(75), prenAnt char(75), dataAng char(10), dataSf char(10), 
		casaSn char(2), asigCI char(1), asigSO char(1))
	if dbo.VerificCampTabela ('D112Asigurat', 'Data')=0
		Alter table D112Asigurat add Data datetime not null default ''
--drop table D112coAsigurati
	if not exists (select * from sysobjects where name ='D112coAsigurati')
		create table D112coAsigurati (Data datetime, cnpAsig char(13), tip char(1), cnp char(13), nume char(75), prenume  char(75))
	if dbo.VerificCampTabela ('D112coAsigurati', 'Data')=0
		Alter table D112coAsigurati add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112coAsigurati', 'idAsig')=6
		Alter table D112coAsigurati drop column idAsig 
--drop table D112AsiguratA
	if not exists (select * from sysobjects where name ='D112AsiguratA')
		Create table D112AsiguratA (Data datetime, cnpAsig char(13), A_1 char(2), A_2 char(1), A_3 char(2), A_4 char(1), A_5 char(15), 
		A_6 char(3), A_7 char(3), A_8 char(5), A_9 char(15), A_10 char(15), A_11 char(15), A_12 char(15), 
		A_13 char(15), A_14 char(15), A_20 char(15))
	if dbo.VerificCampTabela ('D112AsiguratA', 'Data')=0
		Alter table D112AsiguratA add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratA', 'idAsig')=6
		Alter table D112AsiguratA drop column idAsig 
--drop table D112AsiguratB1
	if not exists (select * from sysobjects where name ='D112AsiguratB1')
		Create table D112AsiguratB1 (Data datetime, cnpAsig char(13), B1_1 char(2), B1_2 char(1), B1_3 char(2), B1_4 char(1), 
		B1_5 char(15), B1_6 char(3), B1_7 char(3), B1_8 char(3), B1_9 char(5), B1_10 char(15), B1_15 char(2))
	if dbo.VerificCampTabela ('D112AsiguratB1', 'Data')=0
		Alter table D112AsiguratB1 add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratB1', 'idAsig')=6
		Alter table D112AsiguratB1 drop column idAsig 
--drop table D112AsiguratB11
	if not exists (select * from sysobjects where name ='D112AsiguratB11')
		Create table D112AsiguratB11 (Data datetime, cnpAsig char(13), B11_1 char(2), B11_2 char(15), B11_3 char(15), B11_41 char(15), B11_42 char(15), 
		B11_43 char(15), B11_5 char(15), B11_6 char(15), B11_71 char(15), B11_72 char(15), B11_73 char(15))
	if dbo.VerificCampTabela ('D112AsiguratB11', 'Data')=0
		Alter table D112AsiguratB11 add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratB11', 'idAsig')=6
		Alter table D112AsiguratB11 drop column idAsig 
--drop table D112AsiguratB234
	if not exists (select * from sysobjects where name ='D112AsiguratB234')
		Create table D112AsiguratB234 (Data datetime, cnpAsig char(13), B2_1 char(1), B2_2 char(2), B2_3 char(2), B2_4 char(2), B2_5 char(15), B2_6 char(15), B2_7 char(15), 
		B3_1 char(2), B3_2 char(2), B3_3 char(2), B3_4 char(2), B3_5 char(2), B3_6 char(2), B3_7 char(15), B3_8 char(2), 
		B3_9 char(15), B3_10 char(15), B3_11 char(15), B3_12 char(15), B3_13 char(15), B4_1 char(2), B4_2 char(2), 
		B4_3 char(15), B4_4 char(15), B4_5 char(15), B4_6 char(15), B4_7 char(15), B4_8 char(15), B4_14 char(15))
	if dbo.VerificCampTabela ('D112AsiguratB234', 'Data')=0
		Alter table D112AsiguratB234 add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratB234', 'idAsig')=6
		Alter table D112AsiguratB234 drop column idAsig 
--drop table D112AsiguratC
	if not exists (select * from sysobjects where name ='D112AsiguratC')
		Create table D112AsiguratC (Data datetime, cnpAsig char(13), C_1 char(2), C_2 char(2), C_3 char(2), C_4 char(15), C_5 char(2), C_6 char(15), 
		C_7 char(15), C_8 char(15), C_9 char(15), C_10 char(15), C_11 char(15), C_17 char(2), C_18 char(15), C_19 char(15))
	if dbo.VerificCampTabela ('D112AsiguratC', 'Data')=0
		Alter table D112AsiguratC add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratC', 'idAsig')=6
		Alter table D112AsiguratC drop column idAsig 
--drop table D112AsiguratD
	if not exists (select * from sysobjects where name ='D112AsiguratD')
		Create table D112AsiguratD (Data datetime, cnpAsig char(13), D_1 char(5), D_2 char(10), D_3 char(5), D_4 char(10), D_5 char(10), D_6 char(10), 
		D_7 char(10), D_8 char(13), D_9 char(2), D_10 char(2), D_11 char(3), D_12 char(2), D_13 char(10), D_14 char(2), 
		D_15 char(2), D_16 char(2), D_17 char(6), D_18 char(3), D_19 char(11), D_20 char(15), D_21 char(15))
	if dbo.VerificCampTabela ('D112AsiguratD', 'Data')=0
		Alter table D112AsiguratD add Data datetime not null default ''
	if dbo.VerificCampTabela ('D112AsiguratD', 'idAsig')=6
		Alter table D112AsiguratD drop column idAsig 
End
