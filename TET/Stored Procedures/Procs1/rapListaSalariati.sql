--***
Create procedure rapListaSalariati 
	(@dataJos datetime, @dataSus datetime, @marca varchar(6)=null, @locm varchar(9)=null, @strict int=0, @codfunctie varchar(6)=null, @tippersonal char(1)=null, 
	@comanda varchar(20)=null, @sex int=null, @tipstat varchar(30)=null, @localitate varchar(30)=null, @judet varchar(20)=null, 
	@varstaJos int=null, @varstaSus int=null, @nascutilunacrt int=0, @cucarnetmunca char(10)=null,
	@dataangJos datetime, @dataangSus datetime, @datalichJos datetime, @datalichSus datetime, @ordonare int, @alfabetic int)
as
begin try
	set transaction isolation level read uncommitted

	declare @dreptConducere int, @areDreptCond int, @lista_drept char(1), @sub varchar(9), @utilizator varchar(20)  -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @sub=dbo.iauParA('GE','SUBPRO')
	set @dreptConducere=dbo.iauParL('PS','DREPTCOND')	
	SET @utilizator = dbo.fIaUtilizator(null) 
	
--	verific daca utilizatorul are/nu are dreptul de Salarii conducere (SALCOND)
	set @lista_drept='T'
	set @areDreptCond=0
	if  @dreptConducere=1 
	begin
		set @areDreptCond=isnull((select dbo.verificDreptUtilizator(@utilizator,'SALCOND')),0)
		if @areDreptCond=0
			set @lista_drept='S'
	end 
	
	declare @persvarsta table (marca char(6), varsta char(25))
	insert into @persvarsta
	select Marca, dbo.fCalculVarsta(Data_nasterii,@dataSus) from personal

	select p.marca, p.nume, p.loc_de_munca as lm, lm.denumire as den_lm, p.cod_functie as functie, f.denumire as den_functie, 
		isnull(ip.Centru_de_cost_exceptie,'') as comanda, isnull(z.Descriere,'') as den_comanda, 
		isnull(i.Salar_de_incadrare,p.Salar_de_incadrare) as salar_de_incadrare, 
		(case when isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza)=0 then 8 else isnull(i.Salar_lunar_de_baza,p.Salar_lunar_de_baza) end) as regim_de_lucru, 
		ip.Nr_contract, dc.Data_inf as data_contract,
		convert(char(10),p.data_angajarii_in_unitate,103) as data_angajarii, p.cod_numeric_personal as cnp, p.data_nasterii, 
		'Strada '+rtrim(p.strada)+' nr. ' +rtrim(p.numar)+(case when p.bloc<>'' then ' bloc '+rtrim(p.bloc) else '' end)+(case when p.scara<>'' then ' scara '+rtrim(p.scara) else '' end) 
			+(case when p.apartament<>'' then ' ap. '+rtrim(p.apartament) else '' end)+(case when p.sector<>0 then ' sector '+rtrim(convert(char(1),p.sector)) else '' end) as adresa, 
		p.localitate, p.judet, 
		v.varsta as varsta, convert(int,left(v.varsta,CHARINDEX('a',v.varsta)-1)) as varsta_ani, 
		p.copii as buletin, isnull(rtrim(x.val_inf),'') as carnet_munca, p.data_angajarii_in_unitate, 
		(case when p.Loc_ramas_vacant=1 then convert(char(10),p.data_plec,103) else '' end) as data_plec, 
		(case when @ordonare=2 then p.loc_de_munca when @ordonare=3 then p.localitate when @ordonare=4 then right(convert(char(4),year(@dataSus-p.data_nasterii)),2) 
			when @ordonare=6 then isnull(ip.Centru_de_cost_exceptie,'') else '' end) as grupare, 
		(case when @ordonare=2 then p.loc_de_munca when @ordonare=3 then p.localitate when @ordonare=6 then isnull(ip.Centru_de_cost_exceptie,'') else '' end) as ordonare, 
		(case when @ordonare=4 then convert(int,right(convert(char(4),year(@dataSus-p.data_nasterii)),2)) else 0 end) as ordonare1 
	from personal p
		left outer join infopers ip on p.marca=ip.marca 
		left outer join @persvarsta v on v.marca=p.Marca
		left outer join istPers i on p.marca=i.marca and i.Data=@dataSus
		left outer join lm on p.loc_de_munca=lm.cod
		left outer join functii f on p.cod_functie=f.cod_functie
		left outer join comenzi z on z.Subunitate=@sub and z.Comanda=ip.Centru_de_cost_exceptie
		left outer join extinfop x on x.marca = p.marca and x.cod_inf='NRSCARNET'
		left outer join extinfop dc on dc.marca = p.marca and dc.cod_inf='DATAINCH'
	where (@marca is null or p.Marca=@marca) and (@locm is null or p.Loc_de_munca like rtrim(@locm)+(case when @strict=0 then '%' else '' end)) 
		and ((@dataangJos is not null or @datalichJos is not null) or p.marca in (select i.marca from istpers i where i.data=@dataSus) or p.data_angajarii_in_unitate<=@dataSus 
		and (convert(char(1),p.loc_ramas_vacant)='0' or (convert(char(1),p.loc_ramas_vacant)='1' and p.Data_plec>@dataJos))) 
		and (@sex is null or p.sex=@sex) and (@tipstat is null or ip.religia=@tipstat) 
		and (@tippersonal is null or (@tippersonal='T' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('1','2')) or (@tipPersonal='M' and isnull(i.tip_salarizare,p.Tip_salarizare) in ('3','4','5','6','7')))
		and (@localitate is null or p.localitate=@localitate) and (@judet is null or p.judet=@judet) 
		and (@varstaJos is null or convert(int,right(convert(char(4),year(@dataSus-data_nasterii)),2))+(case when month(@dataSus-p.data_nasterii)=12 then 1 else 0 end) between @varstaJos and @varstaSus) 
		and (@nascutilunacrt=0 or month(p.data_nasterii)=month(@dataSus)) 
		and (@cucarnetmunca is null or @cucarnetmunca='Necompletat' and isnull(rtrim(x.val_inf),'')='' or @cucarnetmunca='Completat' and isnull(rtrim(x.val_inf),'')<>'') 
		and (@dataangJos is null or p.data_angajarii_in_unitate between @dataangJos and @dataangSus) and (@datalichJos is null or p.Loc_ramas_vacant=1 and p.data_plec between @datalichJos and @datalichSus) 
		and (@codfunctie is null or p.cod_functie=@codfunctie) and (@comanda is null or ip.Centru_de_cost_exceptie=@comanda)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=p.Loc_de_munca))
		and (@dreptConducere=0 or (@dreptConducere=1 and @areDreptCond=1 and (@lista_drept='T' or @lista_drept='C' and p.pensie_suplimentara=1 or @lista_drept='S' and p.pensie_suplimentara<>1)) 
			or (@dreptConducere=1 and @areDreptCond=0 and @lista_drept='S' and p.pensie_suplimentara<>1))
	order by ordonare, /*ordonare1,*/ (case when @ordonare=4 then @dataSus-p.data_nasterii else '' end) desc, (case when @alfabetic=1 then p.nume else p.marca end)
	
end try

begin catch
	declare @eroare varchar(2000)
	set @eroare='Procedura rapListaSalariati (linia '+convert(varchar(20),ERROR_LINE())+') :'+char(10)+rtrim(error_message())
	raiserror(@eroare,16,1)
end catch
	
