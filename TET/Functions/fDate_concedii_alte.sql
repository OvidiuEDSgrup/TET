--***
/**	functie Concedii alte	*/
Create 
function [dbo].[fDate_concedii_alte] 
	(@Datajos datetime, @Datasus datetime, @pMarcajos char(6), @pMarcasus char(6), @pLocmjos char(9), @pLocmsus char(9), 
	@lCod_functie int, @pCod_functie char(6), @lTip_CO int, @pTip_CO char(1), @lTipstat int, @pTipstat char(10), 
	@Ordonare char(1), @Alfabetic bit, @Tip_Raport char (1), @DoarSalCuZileDep int, @ZileDepasire int)
returns @fDate_concedii_alte table
	(Data datetime, Marca char(6), Nume char(50), Loc_de_munca char(9), Denumire_lm char(30), 
	Tip_concediu char(30), Data_inceput datetime, Data_sfarsit datetime, Zile int, Zile_delegatie int, 
	Zile_proba int, Zile_preaviz int, Zile_CFS int, Zile_Nemotivate int, Ore_Nemotivate int, 
	Zile_CD int, Zile_recuperare int, Zile_formare_prof int, Ordonare char(50))
as
begin
	declare @userASiS char(10) -- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
	set @userASiS=dbo.fIaUtilizator(null)

	insert into @fDate_concedii_alte
	select max(a.Data), a.Marca, max(isnull(i.Nume,p.Nume)), max(isnull(i.Loc_de_munca, p.Loc_de_munca)), max(l.denumire), 
	(case when @Tip_Raport='2' then '' when max(a.Tip_concediu)='1' then 'Concediu fara salar' when max(a.Tip_concediu)='2' then 'Nemotivate' 
	when max(a.Tip_concediu)='4' then 'Delegatie' when max(a.Tip_concediu)='5' then 'Perioada de proba' 
	when max(a.Tip_concediu)='6' then 'Preaviz' when max(a.Tip_concediu)='9' then 'Cercetare disciplinara'
	when max(a.Tip_concediu)='R' then 'Recuperare' when max(a.Tip_concediu)='F' then 'Formare profesionala' else '' end), 
	max(a.Data_inceput), max( a.Data_sfarsit), sum((case when a.tip_concediu='2' and a.Indemnizatie<>0 then 0 else a.Zile end)), 
	(case when max(a.Tip_concediu)='4' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='5' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='6' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='1' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='2' then sum(isnull((case when a.Indemnizatie=0 then a.zile else 0 end),0)) else 0 end), 
	(case when max(a.Tip_concediu)='2' then sum(isnull((case when a.Indemnizatie<>0 then a.Indemnizatie else 0 end),0)) else 0 end), 
	(case when max(a.Tip_concediu)='9' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='R' then sum(isnull(a.zile,0)) else 0 end),
	(case when max(a.Tip_concediu)='F' then sum(isnull(a.zile,0)) else 0 end),
	(case when @Ordonare='1' then '' else max(isnull(i.Loc_de_munca,p.Loc_de_munca)) end) as Ordonare1
	from conalte a
		left outer join personal p on p.marca = a.marca
		left outer join infopers b on b.marca = a.marca
		left outer join lm l on p.Loc_de_munca=l.cod 
		left outer join istpers i on a.Data=i.Data and a.Marca=i.Marca
		left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=isnull(i.Loc_de_munca, p.Loc_de_munca)
	where a.Data between @Datajos and @Datasus and (@pMarcajos='' or a.Marca between @pMarcajos and @pMarcasus) 
		and (@pLocmjos='' or isnull(i.Loc_de_munca, p.Loc_de_munca) between @pLocmjos and @pLocmsus) 
		and (@lCod_functie=0 or isnull(i.Cod_functie, p.Cod_functie)=@pCod_functie) 
		and a.Tip_concediu in ('1','2','4','5','6','9','R','F') and (@lTip_CO=0 or a.Tip_concediu=@pTip_CO) 
		and (@lTipstat=0 or b.religia=@pTipstat)
		and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
		and (@DoarSalCuZileDep=0 
		or a.Marca in (select ca.marca from conalte ca where year(ca.Data)=year(@Datasus) 
		and (@lTip_CO=0 or ca.Tip_concediu=@pTip_CO) group by ca.Marca having SUM(DateDiff(day,ca.Data_inceput,ca.Data_sfarsit)+1)>@ZileDepasire))
	group by a.marca, (case when @Tip_Raport='1' then a.Data_inceput else '01/01/1901' end)
	order by Ordonare1 Asc, (case when @Alfabetic=1 then max(p.Nume)+a.Marca else a.Marca end), max(a.Data)
	return
end
