--***
/**	functie pt. totalizare sume pe luna, marca, corectie/luna, marca, corectie si loc de munca */
Create function fSumeCorectie
	(@dataJos datetime, @dataSus datetime, @TipCorectie char(2), @marca char(6), @Lm char(9), @PeLm int) 
returns @SumeCorectie table 
	(Data datetime, Marca char(6), Loc_de_munca char(9), Tip_corectie_venit varchar(2), Suma_corectie decimal(10,2), Suma_neta decimal(10,2))
as
begin
--	@TipCorectie poate functiona si ca subtipcorectie.
	declare @userASiS char(10), @lista_lm int, @multiFirma int, @SubtipCor int
	set @userASiS=dbo.fIaUtilizator(null)
	set @lista_lm=dbo.f_areLMFiltru(@userASiS)
	set @multiFirma=0
--	daca tabela par este view inseamna ca se lucreaza cu parametrii pe locuri de munca (in aceeasi BD sunt mai multe unitati)	
	if exists (select * from sysobjects where name ='par' and xtype='V')
		set @multiFirma=1

	set @SubtipCor=dbo.iauParL('PS','SUBTIPCOR')

	insert into @SumeCorectie
	select dbo.eom(c.data) as Data, c.marca, (case when @PeLm=1 then c.Loc_de_munca else '' end) as Loc_de_munca, 
		isnull(nullif(s.Tip_corectie_venit,''),c.Tip_corectie_venit) as tip_corectie, 
		round(round(sum(c.Suma_corectie),2),10,2) as Suma_corectie, round(round(sum(c.Suma_neta),2),10,2) as Suma_neta
	from corectii c 
		left outer join infopers i on c.marca=i.marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=c.loc_de_munca
		left outer join subtipcor s on s.subtip=c.Tip_corectie_venit
	where c.data between @dataJos and @dataSus and (isnull(@marca,'')='' or c.Marca=@marca) 
		and (@multiFirma=0 or @lista_lm=0 or lu.cod is not null)
		and (isnull(@TipCorectie,'')='' or @Subtipcor=0 and c.tip_corectie_venit=@TipCorectie 
			or @Subtipcor=1 and (c.Tip_corectie_venit in (select s.Subtip from Subtipcor s where s.tip_corectie_venit=@TipCorectie) or c.Tip_corectie_venit=@TipCorectie))
	group by dbo.eom(c.data), c.Marca, (case when @PeLm=1 then c.Loc_de_munca else '' end), isnull(nullif(s.Tip_corectie_venit,''),c.Tip_corectie_venit)
	order by dbo.eom(c.data), c.Marca, (case when @PeLm=1 then c.Loc_de_munca else '' end), isnull(nullif(s.Tip_corectie_venit,''),c.Tip_corectie_venit)

	return
end
