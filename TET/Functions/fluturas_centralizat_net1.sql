--***
/**	fluturas centralizat pe net 1	*/
Create
function [dbo].[fluturas_centralizat_net1](@DataJ datetime,@DataS datetime,@MarcaJ char(6),@MarcaS char(6),@LocmJ char(9), 
@LocmS char(9),@lGrupaM int,@cGrupaM char(1),@lTipSalarizare int,@cTipSalJos char(1),@cTipSalSus char(1),@lTipPers int, 
@cTipPers char(1),@lFunctie int,@cFunctie char(6),@lMandatar int,@cMandatar char(6),@lCard int,@cCard char(30),@lUnSex int,
@Sex int, @lTipStat int,@cTipStat char(200), @AreDreptCond int,@cListaCond char(1),@lTipAngajare int,@cTipAngajare char(1), @lSirMarci int, @cSirMarci char(200), @LmExcep char(9),@StrictLmExcep int,@lGrupaMExcep int,@Grupare char(20)) 
returns @fluturas_centralizat_net1 table
(Data datetime,Marca char(6),Avans float,Premiu_av float,Ajutor_ridicat_dafora float,Ajutor_cuvenit_dafora float,Prime_avans_dafora float, Avans_CO_dafora float,Ore_ingr_copil int,Ingrij_copil int,Nr_tichete float,Val_tichete float,NrTichSupl float,ValTichSupl float,
SPNedet int,SPDet int,Ocazional int,Ocaz_P int,Cm_t_part int,Handicap int,Angajat int,Plecat int,Plecat_01 int,scut_80 float,Scut_85 float, Cotiz_hand float,Nrms_cnph float)
as
begin
declare @Dafora int,@lOPTICHINM int,@lNC_tichete int, @lTichete_personalizate int, @nTabela int, @cTabela char(1), @Val_tichet float, @nVal_tichet float, @ImpozitTichete int, @DataTicJ datetime, @DataTicS datetime, @NCCnph int 
Set @Dafora = dbo.iauParL('SP','DAFORA')
Set @lOPTICHINM = dbo.iauParL('PS','OPTICHINM')
Set @lNC_tichete = dbo.iauParL('PS','NC-TICHM')
Set @lTichete_personalizate = dbo.iauParL('PS','TICHPERS')
Set @nTabela = dbo.iauParN('PS','NC-TICHM')
Set @cTabela = (case when convert(char(2),@nTabela)>1 then right(rtrim(convert(char(2),@nTabela)),1) else '' end)
Set @nVal_tichet = dbo.iauParN('PS','VALTICHET')
Set @ImpozitTichete=dbo.iauParLL(@DataS,'PS','DJIMPZTIC')
Set @DataTicJ=dbo.iauParLD(@DataS,'PS','DJIMPZTIC')
Set @DataTicS=dbo.iauParLD(@DataS,'PS','DSIMPZTIC')
Set @DataTicJ=(case when @DataTicJ='01/01/1901' then @DataJ else @DataTicJ end)
Set @DataTicS=(case when @DataTicS='01/01/1901' then @DataS else @DataTicS end)
Set @NCCnph=dbo.iauParL('PS','NC-CPHAND') 
insert @fluturas_centralizat_net1
select a.data,a.marca,
sum(a.Avans-(case when a.Premiu_la_avans<>0 then 0 else isnull(x.Premiu_la_avans,0) end)),
sum((case when a.Premiu_la_avans<>0 then a.Premiu_la_avans else isnull(x.Premiu_la_avans,0) end)),
isnull((select sum(co.suma_corectie) from corectii co where @Dafora=1 and year(co.data)=year(a.Data) and month(co.data)=month(a.Data) and co.Marca=a.Marca and co.tip_corectie_venit='S-'),0),
isnull((select sum(co.suma_corectie) from corectii co where @Dafora=1 and year(co.data)=year(a.Data) and month(co.data)=month(a.Data) and co.Marca=a.Marca and co.tip_corectie_venit in ('S-','F-')),0), 
isnull((select sum(r.retinut_la_avans+r.retinut_la_lichidare) from resal r where @Dafora=1 and r.Data=a.Data and r.marca=a.marca and r.cod_beneficiar='11'),0),
isnull((select sum(r.retinut_la_avans+r.retinut_la_lichidare) from resal r where @Dafora=1 and r.Data=a.Data and r.marca=a.marca and r.cod_beneficiar='10'),0),
isnull((select sum(zile_lucratoare*8) from conmed cm where cm.Data=a.Data and cm.Tip_diagnostic='0-' and cm.Marca=a.Marca),0), 
(case when isnull((select sum(zile_lucratoare*8) from conmed cm where cm.Data=a.Data and cm.Tip_diagnostic='0-' and cm.Marca=a.Marca),0)=0 then 0 else 1 end), 
(case when not(@lOPTICHINM=1 or @lNC_tichete=1 and @cTabela='2') then isnull((select sum(j.ore__cond_6) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0) else sum(isnull(t.Nr_tichete,0)) end), 
round((case when not(@lOPTICHINM=1 or @lNC_tichete=1 and @cTabela='2') then isnull((select sum(j.ore__cond_6) from pontaj j where year(j.data)=year(a.data) and month(j.data)=month(a.data) and j.marca=a.marca),0)*(case when isnull(max(l.Val_numerica),0)=0 then @nVal_tichet else isnull(max(l.Val_numerica),0) end) else sum(isnull(t.Val_tichete,0)) end),2), sum(isnull(ts.NrTichSupl,0)),sum(isnull(ts.ValTichSupl,0)),
(case when (max(i.mod_angajare)='N' or max(i.mod_angajare)='') and max(i.grupa_de_munca)<>'O' then 1 else 0 end),(case when (max(i.mod_angajare) in ('D','R')) and max(i.grupa_de_munca)<>'O' then 1 else 0 end), 
(case when max(i.grupa_de_munca)='O' then 1 else 0 end),(case when max(i.grupa_de_munca)='P' then 1 else 0 end),(case when max(i.grupa_de_munca)='C' then 1 else 0 end),(case when max(p.grad_invalid) in ('1','2') and max(i.grupa_de_munca)<>'O' then 1 else 0 end), 
(case when year(max(p.Data_angajarii_in_unitate))=year(a.Data) and month(max(p.Data_angajarii_in_unitate))=month(a.Data) and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
(case when max(convert(char(1),p.Loc_ramas_vacant))='1' and year(max(p.Data_plec))=year(a.Data) and month(max(p.Data_plec))=month(a.Data) and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
(case when max(convert(char(1),p.Loc_ramas_vacant))='1' and year(max(p.Data_plec))=year(a.Data) and month(max(p.Data_plec))=month(a.Data) and day(max(p.Data_plec))=1 and max(i.grupa_de_munca)<>'O' then 1 else 0 end),
/*isnull((select count(1) from istpers i1 where i1.data between @DataJ and @DataS 
and (@MarcaJ='' or i1.marca between @MarcaJ and @MarcaS) and (@LocmJ='' or i1.loc_de_munca between @LocmJ and @LocmS)
and year(i1.Data_plec)=year(a.Data) and month(i1.Data_plec)=month(a.Data) and day(i1.Data_plec)=1 and i1.grupa_de_munca<>'O'),0), */
sum(isnull(ss.Scutire_art80,0)), sum(isnull(ss.Scutire_art85,0)), 
(case when @NCCnph=1 and @LocmJ<>'' and dbo.eom(@DataJ)=@DataS then isnull((select Suma_cnph from dbo.fCalcul_cnph (@DataJ,@DataS,'',@LocmJ,@LocmS,'')),0) else 
isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'CPH'+'%'
and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
and (@Grupare in ('AN','LUNA','MARCA') and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=a.data or @Grupare='' and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @DataJ and @DataS)),0) end), 
(case when @NCCnph=1 and @LocmJ<>'' and dbo.eom(@DataJ)=@DataS then isnull((select Numar_mediu_cnph from dbo.fCalcul_cnph (@DataJ,@DataS,'',@LocmJ,@LocmS,'')),0) else 
isnull((select sum(c.Val_numerica) from par c where c.tip_parametru='PS' and c.parametru like 'NRM'+'%'
and (substring(c.parametru,6,4)+substring(c.parametru,4,2) between '200101' and '205012') 
and (@Grupare in ('AN','LUNA','MARCA') and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102))=a.data or @Grupare='' and dbo.eom(convert(datetime,substring(c.parametru,4,2)+'/01/'+substring(c.parametru,6,4),102)) between @DataJ and @DataS)),0) end)
from net a
left outer join (select data, marca, sum(ind_c_medical_unitate) as ind_c_medical_unitate from brut where data between @DataJ and @DataS group by data, marca) b on a.data=b.data and a.marca=b.marca
left outer join extinfop e on e.marca=a.marca and e.cod_inf='DEXPSOMAJ'
left outer join extinfop f on f.marca=a.marca and f.cod_inf='DCONVSOMAJ'
left outer join personal p on p.marca=a.marca
left outer join infopers c on c.marca=a.marca
left outer join avexcep x on x.data=a.data and x.marca=a.marca   
inner join istpers i on i.data=a.data and i.marca=a.marca   
left outer join (select Data_lunii, Marca, sum((case when tip_operatie='R' then -1 else 1 end)*nr_tichete) as nr_tichete, 
sum((case when tip_operatie='R' then -1 else 1 end)*nr_tichete*valoare_tichet) as Val_tichete from tichete 
where Data_lunii between @DataJ and @DataS 
and (@lTichete_personalizate=1 and tip_operatie in ('C','S','R') or @lTichete_personalizate=0 and (tip_operatie in ('P','S') or tip_operatie='R' and valoare_tichet<>0)) group by Data_lunii, Marca) t on t.Data_lunii=a.Data and t.Marca=a.Marca
left outer join (select Data_lunii, Marca, sum(nr_tichete) as NrTichSupl, 
sum(nr_tichete*valoare_tichet) as ValTichSupl from tichete 
where Data_lunii between @DataJ and @DataS and tip_operatie='S' group by Data_lunii, Marca) ts on ts.Data_lunii=a.Data 
and ts.Marca=a.Marca
left outer join par_lunari l on l.data=a.data and l.tip='PS' and l.parametru='VALTICHET'   
left outer join dbo.fScutiriSomaj (@DataJ, @DataS, @MarcaJ, @MarcaS, @LocmJ, @LocmS) ss on ss.data=a.data and ss.marca=a.marca
where a.data between @DataJ and @DataS and a.data=dbo.eom(a.data)
and (@MarcaJ='' or a.marca between @MarcaJ and @MarcaS) 
and (@LocmJ='' or a.loc_de_munca between @LocmJ and @LocmS)
and (@lTipPers=0 or @cTipPers='N' and c.Actionar=1 or @cTipPers='C' and c.Actionar=0) 
group by a.Data,a.Marca
return
end
