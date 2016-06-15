--***
Create procedure rapModificariDateSalariati 
	(@dataJos datetime, @dataSus datetime, @marca varchar(6)=null, @locm varchar(9)=null, @strict int=0, @functie varchar(6)=null, 
	@tippersonal char(1)=null, @tipstat varchar(30)=null, @localitate varchar(30)=null, @judet varchar(20)=null, @tipmodificare char(1)=null, @ordonare int, @alfabetic int)
as
begin try
	set transaction isolation level read uncommitted

	declare @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	SET @utilizator = dbo.fIaUtilizator(null) 

	select p.marca, rtrim(isnull(i.nume,p.nume)) as nume, rtrim(isnull(i.Loc_de_munca,p.loc_de_munca)) as lm, rtrim(lm.denumire) as den_lm, 
		isnull(i.Cod_functie,p.Cod_functie) as cod_functie, rtrim(f.denumire) as den_functie, p.Cod_numeric_personal as cnp, 
		isnull(e1.Val_inf,(case when i.Mod_angajare<>i1.Mod_angajare then i.Mod_angajare else '' end)) as durata, 
		isnull(e1.data_inf,(case when i.Mod_angajare<>i1.Mod_angajare then dbo.bom(i.Data) else '01/01/1901' end)) as datamdurata, 
		isnull(e2.Val_inf,(case when i.Cod_functie<>i1.Cod_functie then i.Cod_functie else '' end)) as functie, 
		isnull(e2.data_inf,(case when i.Cod_functie<>i1.Cod_functie then dbo.bom(i.Data) else '01/01/1901' end)) as datamfunctie, 
		isnull(e3.Procent,(case when i.Salar_lunar_de_baza<>i1.Salar_lunar_de_baza then i.Salar_lunar_de_baza else 0 end)) as regimlucru, 
		isnull(e3.data_inf,(case when i.Salar_lunar_de_baza<>i1.Salar_lunar_de_baza then dbo.bom(i.Data) else '01/01/1901' end)) as datamregim, 
		isnull(e4.Val_inf,(case when i.Loc_de_munca<>i1.Loc_de_munca then i.Loc_de_munca else '' end)) as locm, 
		isnull(e4.Data_inf,(case when i.Loc_de_munca<>i1.Loc_de_munca then dbo.bom(i.Data) else '01/01/1901' end)) as datamlocm, 
		isnull(e5.Procent,(case when i.Salar_de_incadrare<>i1.Salar_de_incadrare then i.Salar_de_incadrare else 0 end)) as salar, 
		isnull(e5.data_inf,(case when i.Salar_de_incadrare<>i1.Salar_de_incadrare then dbo.bom(i.Data) else '01/01/1901' end)) as datamsalar, 
		isnull(e6.Procent,(case when i.Spor_conditii_4<>i1.Spor_conditii_4 then i.Spor_conditii_4 else 0 end)) as sporcond4, 
		isnull(e6.data_inf,(case when i.Spor_conditii_4<>i1.Spor_conditii_4 then dbo.bom(i.Data) else '01/01/1901' end)) as datamsp4, 
		(case when @ordonare=2 then rtrim(isnull(i.Loc_de_munca,p.loc_de_munca)) else '' end) as ordonare
	from personal p 
		left outer join infopers ip on p.marca=ip.marca 
		left outer join istpers i on i.data=@dataSus and i.marca=p.Marca
		left outer join istpers i1 on i1.data=dbo.eom(DateADD(month,-1,@dataSus)) and i1.marca=p.Marca
		left outer join lm on lm.cod=isnull(i.Loc_de_munca,p.loc_de_munca)
		left outer join functii f on f.cod_functie=isnull(i.Cod_functie,p.Cod_functie)
		left outer join extinfop e1 on e1.marca = p.marca and e1.cod_inf='DATAMDCTR' and e1.data_inf between @dataJos and @dataSus
		left outer join extinfop e2 on e2.marca = p.marca and e2.cod_inf='DATAMFCT' and e2.data_inf between @dataJos and @dataSus
		left outer join extinfop e3 on e3.marca = p.marca and e3.cod_inf='DATAMRL' and e3.data_inf between @dataJos and @dataSus
		left outer join extinfop e4 on e4.marca = p.marca and e4.cod_inf='DATAMLM' and e4.data_inf between @dataJos and @dataSus and e4.Val_inf<>''
		left outer join extinfop e5 on e5.marca = p.marca and e5.cod_inf='SALAR' and e5.data_inf between @dataJos and @dataSus and e5.Procent<>0
		left outer join extinfop e6 on e6.marca = p.marca and e6.cod_inf='SPORCOND4' and e6.data_inf between @dataJos and @dataSus and e6.Procent<>0
	where (@marca is null or p.Marca=@marca) 
		and (@locm is null or isnull(i.Loc_de_munca,p.loc_de_munca) like rtrim(@locm)+(case when @strict=0 then '%'else '' end)) 
		and (@tipstat is null or ip.religia=@tipstat) 
		and (@localitate is null or p.localitate=@localitate) and (@judet is null or p.judet=@judet) 
		and (@functie is null or isnull(i.Cod_functie,p.Cod_functie)=@functie) 
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.Loc_de_munca,p.loc_de_munca)))
		and (isnull(e1.Val_inf,'')<>'' or i.Mod_angajare<>i1.Mod_angajare 
			or isnull(e2.Val_inf,'')<>'' or i.Cod_functie<>i1.Cod_functie 
			or isnull(e3.Procent,0)<>0 or i.Salar_lunar_de_baza<>i1.Salar_lunar_de_baza
			or isnull(e4.Val_inf,'')<>'' or i.Loc_de_munca<>i1.Loc_de_munca
			or isnull(e5.Procent,0)<>0 or i.Salar_de_incadrare<>i1.Salar_de_incadrare
			or isnull(e6.Procent,0)<>0 or i.Spor_conditii_4<>i1.Spor_conditii_4)
		and (@tipmodificare is null or @tipmodificare='1' and (isnull(e1.Val_inf,'')<>'' or i.Mod_angajare<>i1.Mod_angajare)
			or @tipmodificare='2' and (isnull(e2.Val_inf,'')<>'' or i.Cod_functie<>i1.Cod_functie)
			or @tipmodificare='3' and (isnull(e3.Procent,0)<>0 or i.Salar_lunar_de_baza<>i1.Salar_lunar_de_baza)
			or @tipmodificare='4' and (isnull(e4.Val_inf,'')<>'' or i.Loc_de_munca<>i1.Loc_de_munca)
			or @tipmodificare='5' and (isnull(e5.Procent,0)<>0 or i.Salar_de_incadrare<>i1.Salar_de_incadrare))
	order by ordonare, (case when @alfabetic=1 then isnull(i.nume,p.nume) else p.marca end)
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapModificariDateSalariati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
/*
	exec rapModificariDateSalariati '04/01/2012', '04/30/2012', null, null, 0, null, null, null, null, null, null, 1, 0
*/
