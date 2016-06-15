--***
/**	functie pt. returnare date privind sporurile pt. registru electronic */
Create function fRevisalSporuri 
	(@dataJos datetime, @dataSus datetime, @Marca char(6)) 
returns @Sporuri table 
	(Data datetime, Marca char(6), IsProcent char(5), TipSpor char(50), CodSpor char(50), ValoareSpor decimal(10), Versiune int)
as
Begin
	if exists (select 1 from sysobjects where [type]='TF' and [name]='fRevisalSporuriSP')
		insert into @sporuri
		select * from fRevisalSporuriSP (@dataJos, @dataSus, @Marca)
	else 
	Begin
		declare @utilizator varchar(20), @lista_lm int, @OreLuna float, @OreMLuna float, 
		@Spsp_suma int, @Sp1_suma int, @Sp2_suma int, @Sp3_suma int, @Sp4_suma int, @Sp5_suma int, @Sp6_suma int, @Indc_suma int, @Spfs_suma int, 
		@DataSNext datetime

		set @utilizator = dbo.fIaUtilizator(null)
		set @lista_lm=dbo.f_areLMFiltru(@utilizator)

		set @OreLuna=dbo.iauParLN(@dataSus,'PS','ORE_LUNA')
		set @OreMLuna=dbo.iauParLN(@dataSus,'PS','NRMEDOL')
		set @Spsp_suma=dbo.iauParL('PS','SSP-SUMA')
		set @Sp1_suma=dbo.iauParL('PS','SC1-SUMA')
		set @Sp2_suma=dbo.iauParL('PS','SC2-SUMA')
		set @Sp3_suma=dbo.iauParL('PS','SC3-SUMA')
		set @Sp4_suma=dbo.iauParL('PS','SC4-SUMA')
		set @Sp5_suma=dbo.iauParL('PS','SC5-SUMA')
		set @Sp6_suma=dbo.iauParL('PS','SC6-SUMA')
		set @Indc_suma=dbo.iauParL('PS','INDC-SUMA')
		set @Spfs_suma=dbo.iauParL('PS','SPFS-SUMA')

		set @DataSNext=dbo.eom(DateAdd(day,1,@dataSus))

		insert @Sporuri
		select i.Data, i.Marca, 
		(case when r.Parametru='RSPVECH' then 'true' 
			when r.Parametru='RSPNOAPTE' and isnull(e.Val_inf,'') in ('OreDeNoapte','Inegal') then 'true' 
			when r.Parametru='RSFCTSPL' then (case when @Spfs_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSSISTPRG' then 'true'
			when r.Parametru='RINDCOND' then (case when @Indc_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSSPEC' then (case when @Spsp_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND1' then (case when @Sp1_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND2' then (case when @Sp2_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND3' then (case when @Sp3_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND4' then (case when @Sp4_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND5' then (case when @Sp5_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND6' then (case when @Sp6_suma=1 then 'false' else 'true' end)
			when r.Parametru='RSCOND7' then 'true' end) as IsProcent, 
		(case when r.Val_alfanumerica in (select Cod from CatalogRevisal where TipCatalog='TipSporPredefinit') 
			then 'TipSporPredefinit' else 'TipSporAngajator' end) as TipSpor,
		r.Val_alfanumerica as CodSpor,
		round((case when r.Parametru='RSPVECH' then i.Spor_vechime
			when r.Parametru='RSPNOAPTE' and isnull(e.Val_inf,'') in ('OreDeNoapte','Inegal') then i.Spor_de_noapte
			when r.Parametru='RSFCTSPL' then i.Spor_de_functie_suplimentara 
			when r.Parametru='RSSISTPRG' then i.Spor_sistematic_peste_program
			when r.Parametru='RINDCOND' then i.Indemnizatia_de_conducere 
			when r.Parametru='RSSPEC' then i.Spor_specific 
			when r.Parametru='RSCOND1' then i.Spor_conditii_1 
			when r.Parametru='RSCOND2' then i.Spor_conditii_2 
			when r.Parametru='RSCOND3' then i.Spor_conditii_3 
			when r.Parametru='RSCOND4' then i.Spor_conditii_4 
			when r.Parametru='RSCOND5' then i.Spor_conditii_5 
			when r.Parametru='RSCOND6' then i.Spor_conditii_6 
			when r.Parametru='RSCOND7' then p1.Spor_cond_7 else 0 end),0) as Valoare, 
		1 as Versiune
		from istPers i  
			left outer join personal p on p.Marca=i.Marca
			left outer join infoPers p1 on p1.Marca=i.Marca
			left outer join lm l on l.Cod=p.Loc_de_munca
			left outer join LMFiltrare lu on lu.utilizator=@utilizator and lu.cod=i.loc_de_munca
			left outer join extinfop e on e.Cod_inf='REPTIMPMUNCA' and e.Marca=i.Marca and e.Val_inf in ('OreDeNoapte','Inegal')
			left outer join par r on r.Tip_parametru='PS' 
			and r.Parametru in ('RSPVECH','RSPNOAPTE','RSFCTSPL','RSSISTPRG','RINDCOND','RSSPEC','RSCOND1','RSCOND2','RSCOND3','RSCOND4','RSCOND5','RSCOND6','RSCOND7')
		where ((i.Data=@dataSus  or i.Data=@DataSNext and p.Data_angajarii_in_unitate>@dataSus) 
				or convert(char(1),p.loc_ramas_vacant)='1' and i.Data<@dataJos and i.Data>'08/01/2011' and MONTH(i.Data)=MONTH(p.Data_plec) and year(i.Data)=year(p.Data_plec))
			and (@Marca='' or i.Marca=@Marca) and i.grupa_de_munca not in ('O','P','') 
			and (@lista_lm=0 or lu.cod is not null) 
			and r.Val_alfanumerica<>''

		delete from @Sporuri where ValoareSpor=0
	end

	return
end

/*
	select * from dbo.fRevisalSporuri ('09/01/2011', '09/30/2011', '') order by marca
		insert @Sporuri
	select i.Data, i.Marca, (case when r.Parametru='RSPVECH' then 'true' 
	when r.Parametru='RSPNOAPTE' and isnull(e.Val_inf,'') in ('OreDeNoapte','Inegal') then 'true' 
	when r.Parametru='RSFCTSPL' then (case when @Spfs_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSSISTPRG' then 'true'
	when r.Parametru='RINDCOND' then (case when @Indc_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSSPEC' then (case when @Spsp_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND1' then (case when @Sp1_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND2' then (case when @Sp2_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND3' then (case when @Sp3_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND4' then (case when @Sp4_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND5' then (case when @Sp5_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND6' then (case when @Sp6_suma=1 then 'false' else 'true' end)
	when r.Parametru='RSCOND7' then 'true' end) as IsProcent, 
	(case when r.Val_alfanumerica<>'' then 'TipSporPredefinit' else 'TipSporAngajator' end) as TipSpor,
	(case when r.Val_alfanumerica='' then r.Denumire_parametru else r.Val_alfanumerica end) as CodSpor,
	round((case when r.Parametru='RSPVECH' then i.Salar_de_baza*i.Spor_vechime/100 
	when r.Parametru='RSPNOAPTE' and isnull(e.Val_inf,'') in ('OreDeNoapte','Inegal') then i.Salar_de_baza*i.Spor_de_noapte/100 
	when r.Parametru='RSFCTSPL' then (case when @Spfs_suma=1 then i.Spor_de_functie_suplimentara else i.Salar_de_baza*i.Spor_de_functie_suplimentara/100 end)
	when r.Parametru='RSSISTPRG' then i.Salar_de_baza*i.Spor_sistematic_peste_program/100
	when r.Parametru='RINDCOND' then (case when @Indc_suma=1 then i.Indemnizatia_de_conducere else i.Salar_de_baza*i.Indemnizatia_de_conducere/100 end)
	when r.Parametru='RSSPEC' then (case when @Spsp_suma=1 then i.Spor_specific else i.Salar_de_baza*i.Spor_specific/100 end)
	when r.Parametru='RSCOND1' then (case when @Sp1_suma=1 then i.Spor_conditii_1 else i.Salar_de_baza*i.Spor_conditii_1/100 end)
	when r.Parametru='RSCOND2' then (case when @Sp2_suma=1 then i.Spor_conditii_2 else i.Salar_de_baza*i.Spor_conditii_2/100 end)
	when r.Parametru='RSCOND3' then (case when @Sp3_suma=1 then i.Spor_conditii_3 else i.Salar_de_baza*i.Spor_conditii_3/100 end)
	when r.Parametru='RSCOND4' then (case when @Sp4_suma=1 then i.Spor_conditii_4 else i.Salar_de_baza*i.Spor_conditii_4/100 end)
	when r.Parametru='RSCOND5' then (case when @Sp5_suma=1 then i.Spor_conditii_5 else i.Salar_de_baza*i.Spor_conditii_5/100 end)
	when r.Parametru='RSCOND6' then (case when @Sp6_suma=1 then i.Spor_conditii_6 else i.Salar_de_baza*i.Spor_conditii_6/100 end)
	when r.Parametru='RSCOND7' then i.Salar_de_baza*p1.Spor_cond_7/100 else 0 end),0) as Valoare, 
	1 as Versiune
	from istPers i  
		left outer join personal p on p.Marca=i.Marca
		left outer join infoPers p1 on p1.Marca=i.Marca
		left outer join lm l on l.Cod=p.Loc_de_munca
		left outer join extinfop e on e.Cod_inf='REPTIMPMUNCA' and e.Marca=i.Marca and e.Val_inf in ('OreDeNoapte','Inegal')
		left outer join par r on r.Tip_parametru='PS' 
		and r.Parametru in ('RSPVECH','RSPNOAPTE','RSFCTSPL','RSSISTPRG','RINDCOND',
		'RSSPEC','RSCOND1','RSCOND2','RSCOND3','RSCOND4','RSCOND5','RSCOND6','RSCOND7')
	where i.Data=@dataSus and (@Marca='' or i.Marca=@Marca) and i.grupa_de_munca not in ('O','P','') 

*/
