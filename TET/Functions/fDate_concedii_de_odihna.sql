--***
/**	functie date concedii odihna	*/
Create 
function [dbo].[fDate_concedii_de_odihna] 
	(@Datajos datetime, @Datasus datetime, @pMarcajos char(6), @pMarcasus char(6), @pLocmjos char(9), @pLocmsus char(9), 
	@lCodFunctie int, @pCodFunctie char(6), @Ordonare char(1), @Alfabetic bit, @lTipCO int, @pTipCO char(1), 
	@lLocmStatie int, @pLocmStatie char(9), @lSirTipCO int, @pSirTipCO char(20), @lTipstat int, @pTipstat char(10))
returns @fDate_concedii_de_odihna table
	(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_lm char(30), Vechime_totala datetime, Salar_de_incadrare float, Tip_salarizare char(1), Grupa_de_munca char(1), Somaj int, Cass int, Tip_colaborator char(3), 
	Suma_corectie_O float, Are_prima_CO_data_inceput int, Tip_concediu char(1), Data_inceput datetime, Data_sfarsit datetime, Zile_CO int, Indemnizatie_CO float, Zile_prima_vacanta int, Prima_vacanta float, Indemnizatie_CO_net float, Grupare char(50), Ordonare char(50))
as
begin
	declare @utilizator varchar(20)
	SET @utilizator = dbo.fIaUtilizator('')

	insert into @fDate_concedii_de_odihna
	select a.Data as Data, a.Marca as Marca, isnull(i.Nume,p.Nume) as Nume, isnull(i.Loc_de_munca, p.Loc_de_munca) as LM, l.denumire as DenLM, 
	p.Vechime_totala as VechimeTotala, isnull(i.Salar_de_incadrare, p.Salar_de_incadrare) as SalarIncadrare, isnull(i.Tip_salarizare, p.Tip_salarizare) as TipSalarizare, 
	isnull(i.Grupa_de_munca, p.Grupa_de_munca) as GrupaMunca, p.Somaj_1 as SomajPersonal, p.As_sanatate as ProcCASS, p.Tip_colab as Tip_colab, 
	(case when a.Tip_concediu in ('1','3','4','6','7') then (case when isnull((select sum(c.suma_corectie) from corectii c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca and c.Data=h.Data_inceput and c.Tip_corectie_venit='O-'),0)<>0 then 
	isnull((select sum(c.suma_corectie) from corectii c where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and c.Data=a.Data_inceput and c.Tip_corectie_venit='O-'),0) else 
	isnull((select sum(c.suma_corectie) from corectii c where dbo.eom(c.Data)=dbo.eom(a.Data) and c.Marca=a.Marca and c.Tip_corectie_venit='O-'),0) end) else 0 end) as SumaCorectieO, 
	(case when isnull((select sum(c.suma_corectie) from corectii c, concodih h where dbo.eom(c.Data)=a.Data and c.Marca=a.Marca and dbo.eom(c.Data)=h.Data and c.marca=h.marca and c.Data=h.Data_inceput and c.Tip_corectie_venit='O-'),0)<>0 then 1 else 0 end) as ArePrimaCODataInceput,
	a.Tip_concediu as Tip_concediu, a.Data_inceput as Data_inceput, a.Data_sfarsit as Data_sfarsit, a.Zile_CO as Zile_CO, a.Indemnizatie_CO as Indemnizatie_CO, a.Zile_prima_vacanta as Zile_prima_vacanta, a.Prima_vacanta, 
	(case when a.Tip_concediu<>'5' then isnull(d.indemnizatie_CO,0) else 0 end) as IndemnizatieNeta, 
	(case when @Ordonare='1' then a.Marca else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Grupare, 
	(case when @Ordonare='1' then '' else isnull(i.Loc_de_munca,p.Loc_de_munca) end) as Ordonare1 
	from concodih a
		left outer join personal p on p.marca = a.marca
		left outer join infopers b on b.marca = a.marca
		left outer join lm l on p.Loc_de_munca=l.cod 
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join concodih d on a.Data=d.Data and a.Marca=d.Marca and a.Data_inceput=d.Data_inceput and d.tip_concediu='9' 
	where a.Data between @Datajos and @Datasus and (@pMarcajos='' or a.Marca between @pMarcajos and @pMarcasus) 
		and (@pLocmjos='' or isnull(i.Loc_de_munca, p.Loc_de_munca) between @pLocmjos and @pLocmsus) 
		and (@lLocmStatie=0 or isnull(i.Loc_de_munca, p.Loc_de_munca) like rtrim(@pLocmStatie)+'%') 
		and (@lCodFunctie=0 or isnull(i.Cod_functie, p.Cod_functie)=@pCodFunctie) 
		and a.Tip_concediu in ('1','2','3','6','5','4','7','8') and (@lTipCO=0 or a.Tip_concediu=@pTipCO) 
		and (@lSirTipCO=0 or charindex(','+rtrim(ltrim(a.Tip_concediu))+',',@pSirTipCO)>0) 
		and (@lTipstat=0 or b.religia=@pTipstat)
		and (dbo.f_areLMFiltru(@utilizator)=0 or exists (select 1 from lmfiltrare l where l.utilizator=@utilizator and l.cod=isnull(i.Loc_de_munca, p.Loc_de_munca)))
	order by Ordonare1 Asc, (case when @Alfabetic=1 then p.Nume+a.Marca else a.Marca end), a.Data

	return
end
