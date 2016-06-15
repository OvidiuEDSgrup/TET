
CREATE function fTipSumeSalarii ()
returns @tipsume table (tip_suma varchar(20), denumire varchar(50), tabela varchar(50), camp_tabela varchar(50), ordine int)
begin
	declare @den_os1 varchar(10), @den_os2 varchar(10), @den_os3 varchar(10), @den_os4 varchar(10), 
		@den_intr1 varchar(50), @den_intr2 varchar(50), @den_intr3 varchar(50), 
		@den_spspec varchar(50), @den_spsistprg varchar(50), @den_spfunctsupl varchar(50),
		@den_sp1 varchar(50), @den_sp2 varchar(50), @den_sp3 varchar(50), @den_sp4 varchar(50), 
		@den_sp5 varchar(50), @den_sp6 varchar(50), @den_sp7 varchar(50), @den_sp8 varchar(50)
	
	select @den_os1=max(case when Parametru='OSUPL1' then Val_alfanumerica else '' end),
		@den_os2=max(case when Parametru='OSUPL2' then Val_alfanumerica else '' end),
		@den_os3=max(case when Parametru='OSUPL3' then Val_alfanumerica else '' end),
		@den_os4=max(case when Parametru='OSUPL4' then Val_alfanumerica else '' end),
		@den_intr1=max(case when Parametru='PROCINT' then Val_alfanumerica else '' end),
		@den_intr2=max(case when Parametru='PROC2INT' then Val_alfanumerica else '' end),
		@den_intr3=max(case when Parametru='PROC3INT' then Val_alfanumerica else '' end),
		@den_spsistprg=max(case when Parametru='SPSISTPRG' then Val_alfanumerica else '' end),
		@den_spfunctsupl=max(case when Parametru='SPFCTSUPL' then Val_alfanumerica else '' end),
		@den_spspec=max(case when Parametru='SSPEC' then Val_alfanumerica else '' end),
		@den_sp1=max(case when Parametru='SCOND1' then Val_alfanumerica else '' end),
		@den_sp2=max(case when Parametru='SCOND2' then Val_alfanumerica else '' end),
		@den_sp3=max(case when Parametru='SCOND3' then Val_alfanumerica else '' end),
		@den_sp4=max(case when Parametru='SCOND4' then Val_alfanumerica else '' end),
		@den_sp5=max(case when Parametru='SCOND5' then Val_alfanumerica else '' end),
		@den_sp6=max(case when Parametru='SCOND6' then Val_alfanumerica else '' end),
		@den_sp7=max(case when Parametru='SCOND7' then Val_alfanumerica else '' end),
		@den_sp8=max(case when Parametru='SCOND8' then Val_alfanumerica else '' end)
	from par
	where tip_parametru='PS' and parametru in ('OSUPL1','OSUPL2','OSUPL3','OSUPL4','PROCINT','PROC2INT','PROC3INT',
		'SSPEC','SPSISTPRG','SPFCTSUPL','SCOND1','SCOND2','SCOND3','SCOND4','SCOND5','SCOND6','SCOND7','SCOND8')

	set @den_spsistprg=(case when @den_spsistprg='' then 'Spor sistematic peste program' else @den_spsistprg end)
	set @den_spfunctsupl=(case when @den_spfunctsupl='' then 'Spor functie suplimentara' else @den_spfunctsupl end)

	insert into @tipsume
--	sume din brut
	select 'TOL', 'Total ore lucrate', 'brut', 'Total_ore_lucrate', 1
	union all
	select 'ORG', 'Ore regie', 'brut', 'Ore_lucrate__regie', 2
	union all
	select 'RG', 'Realizat regie', 'brut', 'Realizat__regie', 3
	union all
	select 'OAC', 'Ore acord', 'brut', 'Ore_lucrate_acord', 4
	union all
	select 'AC', 'Realizat acord', 'brut', 'Realizat_acord', 5
	union all
	select 'OS1', @den_os1, 'brut', 'Ore_suplimentare_1', 6 where @den_os1<>''
	union all
	select 'IOS1', 'Indemnizatie '+@den_os1, 'brut', 'Indemnizatie_ore_supl_1', 7 where @den_os1<>''
	union all
	select 'OS2', @den_os2, 'brut', 'Ore_suplimentare_2', 8 where @den_os2<>''
	union all
	select 'IOS2', 'Indemnizatie '+@den_os2, 'brut', 'Indemnizatie_ore_supl_2', 9 where @den_os2<>''
	union all
	select 'OS3', @den_os3, 'brut', 'Ore_suplimentare_3', 10 where @den_os3<>''
	union all
	select 'IOS3', 'Indemnizatie '+@den_os3, 'brut', 'Indemnizatie_ore_supl_3', 11 where @den_os3<>''
	union all
	select 'OS4', @den_os4, 'brut', 'Ore_suplimentare_4', 12 where @den_os4<>''
	union all
	select 'IOS4', 'Indemnizatie '+@den_os4, 'brut', 'Indemnizatie_ore_supl_4', 13 where @den_os4<>''
	union all
	select 'OS100', 'Ore spor 100%', 'brut', 'Ore_spor_100', 14
	union all
	select 'IOS100', 'Indemnizatie ore spor 100%', 'brut', 'Indemnizatie_ore_spor_100', 15
	union all
	select 'ONO', 'Ore de noapte', 'brut', 'Ore_de_noapte', 16
	union all
	select 'IONO', 'Indemnizatie ore de noapte', 'brut', 'Ind_ore_de_noapte', 17
	union all
	select 'ORN', 'Ore regim normal', 'brut', 'Ore_lucrate_regim_normal', 18
	union all
	select 'IORN', 'Indemnizatie ore regim normal', 'brut', 'Ind_regim_normal', 19
	union all 
	select 'OIT1', 'Ore '+@den_intr1, 'brut', 'Ore_intrerupere_tehnologica', 20 where @den_intr1<>''
	union all 
	select 'IT1', 'Indemnizatie '+@den_intr1, 'brut', 'Ind_intrerupere_tehnologica', 21 where @den_intr1<>''
	union all
	select 'IT2', 'Indemnizatie '+@den_intr2, 'brut', 'Ind_invoiri', 22 where @den_intr2<>''
	union all 
	select 'OBL', 'Ore obligatii cetatenesti', 'brut', 'Ore_obligatii_cetatenesti', 23
	union all 
	select 'IOBL', 'Indemnizatie ore obligatii cetatenesti', 'brut', 'Ind_obligatii_cetatenesti', 24
	union all 
	select 'CFS', 'Ore concediu fara salar', 'brut', 'Ore_concediu_fara_salar', 25
	union all 
	select 'IDS', 'Ind donare sange', 'brut', 'Ind_concediu_fara_salar', 26
	union all
	select 'OCO', 'Ore concediu de odihna', 'brut', 'Ore_concediu_de_odihna', 27
	union all
	select 'ICO', 'Indemnizatie concediu de odihna', 'brut', 'Ind_concediu_de_odihna', 28
	union all
	select 'OCM', 'Ore concediu medical', 'brut', 'Ore_concediu_medical', 29
	union all
	select 'ICMUnitate', 'Indemnizatie CM unitate', 'brut', 'Ind_c_medical_unitate', 30
	union all
	select 'ICMFnuass', 'Indemnizatie CM Fnuass', 'brut', 'Ind_c_medical_CAS', 31
	union all
	select 'ICMFaambp', 'Indemnizatie CM Faambp', 'brut', 'Spor_cond_9', 32
	union all
	select 'OIV', 'Ore invoiri', 'brut', 'Ore_invoiri', 33
	union all
	select 'ONE', 'Ore nemotivate', 'brut', 'Ore_nemotivate', 34
	union all
	select 'INDC', 'Indemnizatie conducere', 'brut', 'Ind_nemotivate', 35
	union all
	select 'SALCATL', 'Salar categoria lucrarii', 'brut', 'Salar_categoria_lucrarii', 36
/*
	union all
	select 'CMCAS', 'Corectie CM Fnuass/Faambp', 'brut', 'CMCAS', 37
	union all
	select 'CMUnitate', 'Corectie CM unitate', 'brut', 'CMUnitate', 38
*/	
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'CO', 39 from tipcor where Tip_corectie_venit='D-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Restituiri', 40 from tipcor where Tip_corectie_venit='F-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Diminuari', 41 from tipcor where Tip_corectie_venit='G-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Suma_impozabila', 42 from tipcor where Tip_corectie_venit='H-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Premiu', 43 from tipcor where Tip_corectie_venit='I-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Diurna', 44 from tipcor where Tip_corectie_venit='J-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Cons_admin', 45 from tipcor where Tip_corectie_venit='K-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Sp_salar_realizat', 46 from tipcor where Tip_corectie_venit='L-'
	union all
	select Tip_corectie_venit, Denumire, 'brut', 'Suma_imp_separat', 47 from tipcor where Tip_corectie_venit='O-'
	union all
	select 'SPV', 'Spor vechime', 'brut', 'Spor_vechime', 48
	union all
	select 'SSISTPRG', @den_spsistprg, 'brut', 'Spor_sistematic_peste_program', 49
	union all
	select 'SFCTSPL', @den_spfunctsupl, 'brut', 'Spor_de_functie_suplimentara', 50
	union all
	select 'SSPEC', @den_spspec, 'brut', 'Spor_specific', 51
	union all
	select 'SC1', @den_sp1, 'brut', 'Spor_cond_1', 52 where @den_sp1<>''
	union all
	select 'SC2', @den_sp2, 'brut', 'Spor_cond_2', 53 where @den_sp2<>''
	union all
	select 'SC3', @den_sp3, 'brut', 'Spor_cond_3', 54 where @den_sp3<>''
	union all
	select 'SC4', @den_sp4, 'brut', 'Spor_cond_4', 55 where @den_sp4<>''
	union all
	select 'SC5', @den_sp5, 'brut', 'Spor_cond_5', 56 where @den_sp5<>''
	union all
	select 'SC6', @den_sp6, 'brut', 'Spor_cond_6', 57 where @den_sp6<>''
	union all
	select 'SC7', @den_sp7, 'brut', 'Spor_cond_7', 58 where @den_sp7<>''
	union all
	select 'SC8', @den_sp8, 'brut', 'Spor_cond_8', 59 where @den_sp8<>''
	union all
	select 'COMP', 'Ajutor deces', 'brut', 'Compensatie', 60
	union all
	select 'VTB', 'Venit total din BRUT', 'brut', 'Venit_total', 61
	union all
	select 'VCN', 'Venit conditii normale', 'brut', 'Venit_cond_normale', 62
	union all
	select 'VCD', 'Venit conditii deosebite', 'brut', 'Venit_cond_deosebite', 63
	union all
	select 'VCS', 'Venit conditii speciale', 'brut', 'Venit_cond_speciale', 64
	union all
	select 'SALOR', 'Salar orar', 'brut', 'Salar_orar', 65

--	sume din net - pozitiile cu prima / ultima zi din luna
	insert into @tipsume
	select 'VTN', 'Venit total din NET', 'net', 'VENIT_TOTAL', 70
	union all
	select 'BCASI', 'Baza CAS individual', 'net', 'Baza_CAS', 71
	union all
	select 'CASI', 'Cas individual', 'net', 'Pensie_suplimentara_3', 72
	union all
	select 'BSOMAJ', 'Baza somaj', 'net', 'Asig_sanatate_din_CAS', 73
	union all
	select 'SOMAJI', 'Somaj individual', 'net', 'Somaj_1', 74
	union all
	select 'BCASSI', 'Baza sanatate individual', 'net1', 'Asig_sanatate_din_net', 75
	union all
	select 'CASSI', 'Sanatate individual', 'net', 'Asig_sanatate_din_net', 76
	union all
	select 'VNETIMP', 'Venit net inaintea impozitarii ', 'net', 'VEN_NET_IN_IMP', 77
	union all
	select 'BIMP', 'Baza de calcul impozit', 'net', 'Venit_baza', 78
	union all
	select 'IMPOZIT', 'Impozit', 'net', 'Impozit', 79
	union all
	select 'VNET', 'Venit net', 'net', 'VENIT_NET', 80
	union all
	select 'RESTPL', 'Rest de plata', 'net', 'Rest_de_plata', 81
	union all
	select 'BCASCN', 'Baza CAS conditii normale', 'net', 'Baza_CAS_cond_norm', 82
	union all
	select 'BCASCD', 'Baza CAS conditii deosebite', 'net', 'Baza_CAS_cond_deoseb', 83
	union all
	select 'BCASCS', 'Baza CAS conditii speciale', 'net', 'Baza_CAS_cond_spec', 84
	union all
	select 'CASU', 'CAS unitate', 'net', 'CAS', 85
	union all
	select 'BCASCMCN', 'Baza CAS CM conditii normale', 'net1', 'Baza_CAS_cond_norm', 86
	union all
	select 'BCASCMCD', 'Baza CAS CM conditii deosebite', 'net1', 'Baza_CAS_cond_deoseb', 87
	union all
	select 'BCASCMCS', 'Baza CAS CM conditii speciale', 'net1', 'Baza_CAS_cond_spec', 88
	union all
	select 'CASCMU', 'CAS CM unitate', 'net1', 'CAS', 89
	union all
	select 'SOMAJU', 'Somaj unitate', 'net', 'Somaj_5', 90
	union all
	select 'BFAAMBPCM', 'Baza acc. de munca aferent CM', 'net1', 'Asig_sanatate_din_CAS', 91
	union all
	select 'FAAMBP', 'Fond acc. de munca', 'net', 'Fond_de_risc_1', 92
	union all
	select 'CCM', 'Comision carti de munca', 'net', 'Camera_de_munca_1', 93
	union all
	select 'CASSU', 'Sanatate unitate', 'net', 'Asig_sanatate_pl_unitate', 94
	union all
	select 'BCCI', 'Baza CCI', 'net1', 'Baza_CAS', 95
	union all
	select 'CCI', 'Concedii si indemnizatii', 'net', 'Ded_suplim', 96
	union all
	select 'CCIFAAMBP', 'Concedii si indemnizatii pt. FAAMBP', 'net1', 'Ded_suplim', 97
	union all
	select 'BFGAR', 'Baza fond de garantare', 'net1', 'CM_incasat', 98
	union all
	select 'FGAR', 'Fond de garantare', 'net1', 'Somaj_5', 99
	union all
	select 'CASSFAAMBP', 'Sanatate aferent CM din FAAMBP - angajat', 'net1', 'Asig_sanatate_din_impozit', 100
	union all
	select 'DEXT', 'Debite externe', 'net', 'Debite_externe', 101
	union all
	select 'DINT', 'Debite interne', 'net', 'Debite_interne', 102
	union all
	select 'RATE', 'Rate', 'net', 'Rate', 103
	union all
	select 'CTCRT', 'Cont curent', 'net', 'Cont_curent', 104
	union all
	select 'DEDBAZA', 'Deducere personala', 'net', 'Ded_baza', 105

	return
end
