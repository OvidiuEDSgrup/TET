/**
	Procedura este folosita pentru a lista Anexa 11 la declaratia 112. 
**/
create procedure rapDeclaratia112Anexa11 (@sesiune varchar(50), @datajos datetime, @datasus datetime, @dataset char(2), @parXML xml='<row/>')
AS
/*
	exec rapDeclaratia112Anexa11 '', '02/01/2013', '02/28/2013', 'I', '<row />'
*/
begin try 
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
	DECLARE @utilizator varchar(50), @lista_lm int, @lm varchar(9), @multiFirma int, @mesaj varchar(1000)
	
	if @sesiune<>''
		exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output
	else 
		set @utilizator=dbo.fIaUtilizator(null)

	set @lista_lm=dbo.f_areLMFiltru(@utilizator)
	set @multiFirma=0
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

--	Date contributii
	if @dataset='C'
		select convert(int,B_cnp) as nr_asig_somaj, rtrim(B_sanatate) as B_sanatate, rtrim(B_pensie) as B_pensie, rtrim(B_brutSalarii) as B_brutSalarii, rtrim(B_sal) as B_sal, 
			rtrim(C1_11) as C1_11, rtrim(C1_12) as C1_12, rtrim(C1_13) as C1_13, rtrim(C1_21) as C1_21, rtrim(C1_22) as C1_22, rtrim(C1_23) as C1_23, 
			rtrim(C1_31) as C1_31, rtrim(C1_32) as C1_32, rtrim(C1_33) as C1_33, 
			rtrim(C1_T1) as C1_T1, rtrim(C1_T2) as C1_T2, rtrim(C1_T) as C1_T, rtrim(C1_T3) as C1_T3, rtrim(C1_5) as C1_5, rtrim(C1_6) as C1_6, rtrim(C1_7) as C1_7, 
			rtrim(C2_11) as C2_11, rtrim(C2_12) as C2_12, rtrim(C2_13) as C2_13, rtrim(C2_14) as C2_14, rtrim(C2_15) as C2_15, rtrim(C2_16) as C2_16, 
			rtrim(C2_21) as C2_21, rtrim(C2_22) as C2_22, rtrim(C2_24) as C2_24, rtrim(C2_26) as C2_26, rtrim(C2_31) as C2_31, rtrim(C2_32) as C2_32, rtrim(C2_34) as C2_34, rtrim(C2_36) as C2_36, 
			rtrim(C2_41) as C2_41, rtrim(C2_42) as C2_42, rtrim(C2_44) as C2_44, rtrim(C2_46) as C2_46, 
			rtrim(C2_51) as C2_51, rtrim(C2_52) as C2_52, rtrim(C2_54) as C2_54, rtrim(C2_56) as C2_56, 
			rtrim(C2_T6) as C2_T6, rtrim(C2_7) as C2_7, rtrim(C2_8) as C2_8, rtrim(C2_9) as C2_9, rtrim(C2_10) as C2_10, 
			rtrim(C2_110) as C2_110, rtrim(C2_120) as C2_120, rtrim(C2_130) as C2_130, rtrim(C3_11) as C3_11, rtrim(C3_12) as C3_12, rtrim(C3_13) as C3_13, rtrim(C3_14) as C3_14, 
			rtrim(C3_21) as C3_21, rtrim(C3_22) as C3_22, rtrim(C3_23) as C3_23, rtrim(C3_24) as C3_24, 
			rtrim(C3_31) as C3_31, rtrim(C3_32) as C3_32, rtrim(C3_33) as C3_33, rtrim(C3_34) as C3_34, rtrim(C3_41) as C3_41, rtrim(C3_42) as C3_42, rtrim(C3_43) as C3_43, rtrim(C3_44) as C3_44, 
			rtrim(C3_total) as C3_total, rtrim(C3_suma) as C3_suma, rtrim(C3_aj_nr) as C3_aj_nr, rtrim(C3_aj_suma) as C3_aj_suma, 
			rtrim(C4_scutitaSo) as C4_scutitaSo, rtrim(C6_baza) as C6_baza, rtrim(C6_ct) as C6_ct, rtrim(C7_baza) as C7_baza, rtrim(C7_ct) as C7_ct, 
			rtrim(D1) as D1, rtrim(E1_venit) as E1_venit, rtrim(F1_suma) as F1_suma 
		from D112AngajatorB ab
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=ab.loc_de_munca
		where data between @datajos and @datasus
			and (@multiFirma=0 or lu.cod is not null) 

--	Date subventii
	if @dataset='S'
		select rtrim(C5_subv)+' - '+rtrim(case when C5_subv='1' then 'Subventii cf.art.80 din Legea 76/ 2002.' 
			when C5_subv='2' then 'Scutire de la plata contributiei datorate de angajator cf.art.80 din Legea 76/ 2002.' 
			when C5_subv='3' then 'Subventii cf.art.85 din Legea 76/ 2002.' 
			when C5_subv='4' then 'Scutire de la plata contributiei datorate de angajator cf.art.85 alin.(1) din Legea 76/ 2002.' 
			when C5_subv='6' then 'Subventii conform art.934 si art.936 din Legea nr.76/2002, cu modificarile si completarile ulterioare 
				(sau subventii conform art.8 din Legea nr.116/2002, cu modificarile si completarile ulterioare, pentru angajatorii care mai pot beneficia, in conditiile legii, de aceste subventii).' 
			when C5_subv='7' then 'Reduceri ale contributiei datorate de angajator conform art.93 din Legea nr.76/2002, cu modificarile si completarile ulterioare.' 
			when C5_subv='10' then 'Subventii cf.art.1 din Legea 72/ 2007.' 
			else '' end) as C5_subv, 
			rtrim(C5_recuperat) as C5_recuperat, rtrim(C5_restituit) as C5_restituit  
		from D112AngajatorC5 c5 
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=c5.loc_de_munca
		where data between @datajos and @datasus
			and (@multiFirma=0 or lu.cod is not null) 

--	Date impozit
	if @dataset='I'
		select F2_id, F2_cif, rtrim(F2_suma) as F2_suma
		from D112AngajatorF2 f2
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=f2.loc_de_munca
		where data between @datajos and @datasus 
			and (@multiFirma=0 or lu.cod is not null) 
		order by convert(int,f2_id)
end try
begin catch
	set @mesaj=ERROR_MESSAGE()+ ' (rapDeclaratia112Anexa11)'
	raiserror(@mesaj, 11, 1)
end catch
