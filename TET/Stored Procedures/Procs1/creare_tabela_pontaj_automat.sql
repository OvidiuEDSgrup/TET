--***
/**	proc.creare tab.pontaj automat	*/
Create
	procedure [dbo].[creare_tabela_pontaj_automat]
As
Begin
	Create table dbo.##pontaj_automat (HostID char(8), Data datetime not null, Marca char(6) not null, Numar_curent smallint not null,	Loc_de_munca char(9) not null, Loc_munca_pentru_stat_de_plata bit not null, Tip_salarizare char(1) not null, Regim_de_lucru float not null,
		Salar_orar float not null, Ore_lucrate smallint not null, Ore_regie smallint not null, Ore_acord smallint not null, 
		Ore_suplimentare_1 smallint not null, Ore_suplimentare_2 smallint not null, Ore_suplimentare_3 smallint not null, 
		Ore_suplimentare_4 smallint not null, Ore_spor_100 smallint not null, Ore_de_noapte smallint not null, 
		Ore_intrerupere_tehnologica smallint not null, Ore_concediu_de_odihna smallint not null, Ore_concediu_medical smallint not null, 
		Ore_invoiri smallint not null, Ore_nemotivate smallint not null, Ore_obligatii_cetatenesti smallint not null, 
		Ore_concediu_fara_salar smallint not null, Ore_donare_sange smallint not null, Salar_categoria_lucrarii real not null, 
		Coeficient_acord float not null, Realizat float not null, Coeficient_de_timp float not null, Ore_realizate_acord real not null,
		Sistematic_peste_program real not null, Ore_sistematic_peste_program smallint not null, Spor_specific float not null, 
		Spor_conditii_1 float not null, Spor_conditii_2 float not null, Spor_conditii_3 float not null, Spor_conditii_4 float not null, 
		Spor_conditii_5 float not null, Spor_conditii_6 float not null, Ore__cond_1 smallint not null, Ore__cond_2 smallint not null,
		Ore__cond_3 smallint not null,Ore__cond_4 smallint not null, Ore__cond_5 smallint not null, Ore__cond_6 real not null, 
		Grupa_de_munca char(1) not null, Ore smallint not null, Spor_cond_7 float not null DEFAULT (0), Spor_cond_8 float not null DEFAULT (0), 
		Spor_cond_9 float not null DEFAULT (0), Spor_cond_10 float not null DEFAULT (0)) ON [PRIMARY]

	Create Unique Clustered Index [Principal] ON dbo.##pontaj_automat (HostID Asc, Data Asc, Marca Asc, Numar_curent Asc)
End
