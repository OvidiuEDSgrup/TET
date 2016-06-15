create procedure wpopModificareD112 (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @subtip varchar(2), @multiFirma int, @subunitate varchar(20), @data datetime, @utilizatorASiS varchar(50)

	set @subtip = isnull(@parXML.value('(/row/@subtip)[1]', 'varchar(2)'), '')	
	select @data = isnull(@parXML.value('(/row/@datalunii)[1]','datetime'),isnull(@parXML.value('(/row/@data)[1]','datetime'),''))

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	select convert(char(10),@data,101) datalunii for xml raw

--	pentru editare sectiune D112AngajatorD (contributii sociale pe coduri bugetare)
	if @subtip in ('AA')
		SELECT (    
			select a.A_codOblig, rtrim(o.denumire) as denoblig, a.A_codBugetar, a.A_datorat, a.A_deductibil, a.A_plata
			from D112AngajatorA a
				left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=a.Loc_de_munca
				left outer join fCodObligatiiBugetare (@parXML) o on o.Cod_obligatie=a.A_codOblig
			where a.data between dbo.BOM(@data) and dbo.EOM(@data)
				and (@multiFirma=0 or lu.cod is not null)
			FOR XML raw, type  
			) 
		FOR XML path('DateGrid'), root('Mesaje')

--	pentru editare sectiune D112AngajatorB (contributii sociale si baze de calcul)
	if @subtip in ('AB')
		select b.data, b.B_cnp, b.B_sanatate, B_pensie, B_brutSalarii, totalPlata_A, 
			C1_11, C1_12, C1_13, C1_21, C1_22, C1_23, C1_31, C1_32, C1_33, 
			C1_T1, C1_T2, C1_T, C1_T3, C1_5, C1_6, C1_7, C2_11, C2_12, C2_13, C2_14, C2_15, C2_16, C2_21, C2_22, C2_24, C2_26, 
			C2_31, C2_32, C2_34, C2_36, C2_41, C2_42, C2_44, C2_46, C2_51, C2_52, C2_54, C2_56, C2_T6, C2_7, C2_8, C2_9, C2_10, C2_110, C2_120, C2_130, 
			C3_11, C3_12, C3_13, C3_14, C3_21, C3_22, C3_23, C3_24, C3_31, C3_32, C3_33, C3_34, C3_41, C3_42, C3_43, C3_44, 
			C3_total, C3_suma, C3_aj_nr, C3_aj_suma, C4_scutitaSo, C6_baza, C6_ct, C7_baza, C7_ct, D1, E1_venit, F1_suma
		from D112AngajatorB b
			left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=b.Loc_de_munca
		where b.data between dbo.BOM(@data) and dbo.EOM(@data)
			and (@multiFirma=0 or lu.cod is not null)
		FOR XML raw

--	pentru editare sectiune D112AngajatorC5 (subventii / scutiri de la somaj)
	if @subtip in ('C5')
		SELECT (    
			select a.C5_subv, 
			(case when a.C5_subv=1 then 'Subventii conform art. 80, legea 76/2002' when a.C5_subv=2 then 'Scutire conform art. 80, legea 76/2002' 
				when a.C5_subv=3 then 'Subventii conform art. 85, legea 76/2002' when a.C5_subv=4 then 'Scutire conform art. 85, legea 76/2002' 
				when a.C5_subv=6 then 'Subventie conform art. 8, legea 116/2002' when a.C5_subv=10 then 'Subventie conform art. 1, legea 72/2007' else '' end) as denC5_subv, 
			a.C5_recuperat as C5_recuperat, C5_restituit as C5_restituit
			from D112AngajatorC5 a
				left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=a.Loc_de_munca
			where a.data between dbo.BOM(@data) and dbo.EOM(@data)
				and (@multiFirma=0 or lu.cod is not null)
			FOR XML raw, type  
			) 
		FOR XML path('DateGrid'), root('Mesaje')

--	pentru editare sectiune D112AngajatorF2 (Impozit pe puncte de lucru)
	if @subtip in ('F2')
		SELECT (    
			select a.F2_cif, a.F2_id, F2_suma
			from D112AngajatorF2 a
				left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=a.Loc_de_munca
			where a.data between dbo.BOM(@data) and dbo.EOM(@data)
				and (@multiFirma=0 or lu.cod is not null)
			FOR XML raw, type  
			) 
		FOR XML path('DateGrid'), root('Mesaje')

--	pentru editare sectiune D112AsiguratD (date concedii medicale)
	if @subtip in ('AD')
		SELECT (    
			select d.cnpasig, rtrim(a.numeAsig)+' '+rtrim(a.prenAsig) as nume, 
				d.D_1, d.D_2, d.D_3, d.D_4, d.D_5, d.D_6, d.D_7, d.D_8, d.D_9, d.D_10, 
				d.D_11, d.D_12, d.D_13, d.D_14, d.D_15, d.D_16, d.D_17, d.D_18, d.D_19, d.D_20, d.D_21
			from D112asiguratD d 
				left outer join D112asigurat a on a.Data=d.Data and a.cnpAsig=d.cnpAsig
				left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=d.Loc_de_munca
			where d.data between dbo.BOM(@data) and dbo.EOM(@data)
				and (@multiFirma=0 or lu.cod is not null)
			FOR XML raw, type  
			) 
		FOR XML path('DateGrid'), root('Mesaje')

--	pentru editare sectiune D112AsiguratE3 (date detaliate privind impozitul pe venit)
	if @subtip in ('AE')
		SELECT (    
			select e.cnpasig, rtrim(a.numeAsig)+' '+rtrim(a.prenAsig) as nume, 
				e.E3_1, e.E3_2, e.E3_3, e.E3_4, e.E3_5, e.E3_6, e.E3_7, e.E3_8, e.E3_9, e.E3_10, 
				e.E3_11, e.E3_12, e.E3_13, e.E3_14, e.E3_15, e.E3_16, e.idPozitie
			from D112asiguratE3 e 
				left outer join D112asigurat a on a.Data=e.Data and a.cnpAsig=e.cnpAsig
				left outer join LMFiltrare lu on lu.utilizator=@utilizatorASiS and lu.cod=e.Loc_de_munca
			where e.data between dbo.BOM(@data) and dbo.EOM(@data)
				and (@multiFirma=0 or lu.cod is not null)
			FOR XML raw, type  
			) 
		FOR XML path('DateGrid'), root('Mesaje')

end
