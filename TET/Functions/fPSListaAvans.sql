--***
/**	functie pentru lista avans salarii	*/
Create
function  [dbo].[fPSListaAvans] (@DataJ datetime, @DataS datetime, @MarcaJ char(6), @MarcaS char(6), @LocmJ char(9), 
@LocmS char(9), @ManadatarJ char(6), @lGrupaMunca int, @cGrupaMunca char(1), @TipOrdonare char(1), 
@LimitaAvans int, @LimitaPremii int, @lCard int, @cCard char(30), @lTipSalarizare int, @cTipSalarizare char(1), 
@AreDreptCond int, @ListaDreptCond char(1),@lLocmStatie int, @cLocmStatie char(9), @lTipStat int, @cTipStat char(30), 
@NumaiOreAvMM0 int, @LocmExcep char(9), @AparecorM int, @OrdonareAlfa int)
returns @AvansSalarii table
(Data datetime, Marca char(6), Loc_de_munca char(9), Avans decimal(10), Premiu decimal(10), Retinere_afisata decimal(10,2), 
Gasit_avans_exceptie int, Avans_exceptie_Dafora decimal(10), Ore_lucrate_avans_exceptie int, Zile_lucratoare_CM int,
Suma_corectie_M decimal(10), Suma_corectie_N decimal(10), Suma_corectie_O decimal(10), Avans_de_afisat decimal(10,2), 
Suma_corectieC_Salubris decimal(10), Rest_de_plata_avans decimal(10,2), Cod_parinte char(9), Denumire_lm char(30), 
Nume char(50), Cod_functie char(6), Banca char(25), Categoria_salarizare char(4), Salar_de_baza decimal(10), 
Grupa_de_munca char(1), Denumire_functie char(30), Mandatar char(6), Denumire_mandatar char(50), Ordonare char(100))
as
begin
declare @userASiS char(10), @DreptCond int, @DetTipCorectii int, @RetineriAvans int, @lMandatari int, @Dafora int, @Salubris int
-- pt filtrare pe proprietatea LOCMUNCA a utilizatorului (daca e definita)
set @userASiS=dbo.fIaUtilizator(null)
set @DreptCond=dbo.iauParL('PS','DREPTCOND')
set @DetTipCorectii=dbo.iauParL('PS','SUBTIPCOR')
set @RetineriAvans=dbo.iauParL('PS','RETAVANS')
set @lMandatari=dbo.iauParL('PS','MANDATARI')
set @Dafora=dbo.iauParL('SP','DAFORA')
set @Salubris=dbo.iauParL('SP','SALUBRIS')

insert into @AvansSalarii
select a.data, a.marca, max(a.loc_de_munca), max(a.avans), max(a.premiu_la_avans), max(isnull(r.Retinut_la_avans,0)), 
(case when isnull(max(d.marca),'X')<>'X' then 1 else 0 end), 
(case when @Dafora=1 then isnull(max(d.suma_avans),0) else 0 end), isnull(max(d.ore_lucrate_la_avans),0), max(e.zile_lucratoare), isnull(max(f.suma_corectie),0), isnull(max(f1.suma_corectie),0), isnull(max(f2.suma_corectie),0), 
max(a.avans)-(case when @Dafora=1 then isnull(max(d.suma_avans),0) else 0 end), max(isnull(s.Suma_corectie,0)), 
max(a.avans)+max(a.premiu_la_avans)+(case when @AparecorM=1 then isnull(max(f.suma_corectie),0) else 0 end)- max(isnull(r.Retinut_la_avans,0)), 
max(l.cod_parinte), max(l.denumire), max(b.nume), isnull(max(g.cod_functie), max(b.cod_functie)), max(b.banca), max(b.categoria_salarizare), isnull(max(g.salar_de_baza), max(b.salar_de_baza)), isnull(max(g.grupa_de_munca),max(b.grupa_de_munca)), max(h.denumire), 
(case when @TipOrdonare=3 then max(isnull(m.mandatar,'')) else '' end), max(isnull(p.Nume,'')), 
(case when @TipOrdonare=3 then max(isnull(m.mandatar,'')) else '' end)+(case when @TipOrdonare=2 then '' else max(a.loc_de_munca) end)+(case when @OrdonareAlfa=1 then max(b.nume) else a.marca end) as ordonare 
from net a 
left outer join personal b on a.marca=b.marca
left outer join infopers c on a.marca=c.marca
left outer join avexcep d on a.data=d.data and a.marca=d.marca
left outer join (select data, marca, sum(zile_lucratoare) as zile_lucratoare from conmed where data between @DataJ and @DataS group by data, marca) e on a.data=e.data and a.marca=e.marca
left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'M-', '', '', 0) f on @AparecorM=1 and a.data=f.data and a.marca=f.marca
left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'N-', '', '', 0) f1 on @AparecorM=1 and a.data=f1.data and a.marca=f1.marca
left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'O-', '', '', 0) f2 on @AparecorM=1 and a.data=f2.data and a.marca=f2.marca
left outer join istpers g on a.data=g.data and a.marca=g.marca
left outer join lm l on a.loc_de_munca=l.cod
left outer join functii h on h.cod_functie=b.cod_functie
left outer join mandatar m on @lMandatari=1 and m.loc_munca=a.Loc_de_munca
left outer join personal p on @lMandatari=1 and p.marca=m.Mandatar
left outer join (select data as data, marca, sum(Retinut_la_avans) as Retinut_la_avans from resal 
where data between @DataJ and @DataS and Retinut_la_avans<>0 group by data, marca) r on @RetineriAvans=1 and a.data=r.data 
and a.marca=r.marca
left outer join dbo.fSumeCorectie (@DataJ, @DataS, 'C-', '', '', 0) s on @Salubris=1 and a.data=s.data and a.marca=s.marca
left outer join LMFiltrare lu on lu.utilizator=@userASiS and lu.cod=a.Loc_de_munca
where a.data = @DataS and a.marca between @MarcaJ and @MarcaS 
and a.loc_de_munca between @LocmJ and @LocmS 
and (@LimitaAvans=0 or a.avans>0)  and (@LimitaPremii<>1 or a.premiu_la_avans>0) 
and (@lGrupaMunca=0 or b.grupa_de_munca=@cGrupaMunca) 
and (@ManadatarJ='' or a.loc_de_munca in (select loc_munca from mandatar where mandatar=@ManadatarJ)) 
and (@lCard=0 or b.banca=@cCard) and (@lTipSalarizare=0 or b.tip_salarizare=@cTipSalarizare) 
and (@DreptCond=0 or (@AreDreptCond=1 and (@ListaDreptCond='T' or @ListaDreptCond='C' and b.pensie_suplimentara=1 or @ListaDreptCond='S' and b.pensie_suplimentara<>1)) or (@AreDreptCond=0 and b.pensie_suplimentara<>1)) 
and (@lLocmStatie=0 or a.loc_de_munca like rtrim(@cLocmStatie)+'%') and (@lTipStat=0 or c.religia=@cTipStat) 
and (@NumaiOreAvMM0=0 or d.ore_lucrate_la_avans>0) and (@LocmExcep='' or a.loc_de_munca not like @LocmExcep+'%')
and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
group by a.Data, a.Marca 
order by ordonare
return
end
