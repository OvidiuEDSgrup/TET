--***
Create procedure wIaSalariati @sesiune varchar(50), @parXML xml
as
declare @sub varchar(9), @LunaInch int, @AnulInch int, @DataInch datetime, @DataAnAnt datetime, @DataLunii datetime, --	data lunii pentru calcul zile CO cuvenite
	@tip varchar(2), @marca varchar(6), @userASiS varchar(10), @filtruSalariat varchar(50), @filtruNume varchar(50), @filtruMarca varchar(6), @filtruFunctie varchar(20), @filtruLm varchar(20),
	@filtruCNP varchar(13), @filtruCuPlecati varchar(20), @filtruNrContract varchar(20), @codMeniu char(2), @dataCrt datetime

set @sub=dbo.iauParA('GE','SUBPRO')
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 1901)
set @DataInch=dbo.Eom(convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4)))
set @DataAnAnt=(case when @DataInch=dbo.EOY(@DataInch) then @DataInch else DateADD(day,-1,dbo.BOY(@DataInch)) end)
set @DataLunii=dbo.EOM(DateADD(day,1,@DataInch))

exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output
set @tip=isnull(@parXML.value('(/row/@tip)[1]','varchar(2)'),'')
set @marca=isnull(@parXML.value('(/row/@marca)[1]','varchar(6)'),'')
set @filtruSalariat=isnull(@parXML.value('(/row/@f_salariat)[1]','varchar(50)'),'')
set @filtruMarca=isnull(@parXML.value('(/row/@f_marca)[1]','varchar(6)'),'')
set @filtruNume=isnull(@parXML.value('(/row/@f_nume)[1]','varchar(50)'),'')
set @filtruFunctie=isnull(@parXML.value('(/row/@f_functie)[1]','varchar(50)'),'')
set @filtruLm=isnull(@parXML.value('(/row/@f_lm)[1]','varchar(50)'),'')
set @filtruCNP=isnull(@parXML.value('(/row/@f_cnp)[1]','varchar(13)'),'')
set @filtruCuPlecati=isnull(@parXML.value('(/row/@f_cuplecati)[1]','varchar(20)'),'')
set @filtruNrContract=isnull(@parXML.value('(/row/@f_nrcontract)[1]','varchar(20)'),'')
set @filtruNume=Replace(@filtruNume,' ','%')
set @codMeniu=isnull(@parXML.value('(/row/@codMeniu)[1]','varchar(2)'),'')
set @dataCrt=convert(datetime,convert(char(10),GETDATE(),101),101)

if OBJECT_ID('tempdb..#personal100') is not null
	drop table #personal100
if OBJECT_ID('tempdb..#marci') is not null
	drop table #marci
if OBJECT_ID('tempdb..#zileCOcuv') is not null
	drop table #zileCOcuv
if OBJECT_ID('tempdb..#zileCOcuvAn') is not null
	drop table #zileCOcuvAn
if OBJECT_ID('tempdb..#zileCOcuvLuna') is not null
	drop table #zileCOcuvLuna

create table #personal100 (marca varchar(6) primary key)

insert #personal100
select top 100 rtrim(p.marca) as personal
from personal p
	left join functii f on p.cod_functie=f.cod_functie
	left join lm on p.loc_de_munca=lm.cod
	left join infopers i on i.marca=p.marca
	left outer join LMFiltrare lu on lu.utilizator=@userASiS and p.Loc_de_munca=lu.cod
where (@filtruMarca='' or p.marca like @filtruMarca+'%')
	and (@filtruNume='' or p.nume like '%'+@filtruNume+'%')
	and (@filtruSalariat='' or p.marca like @filtruSalariat+'%' or p.nume like '%'+@filtruSalariat+'%')
	and (@filtruFunctie='' or p.Cod_functie like @filtruFunctie+'%' or f.Denumire like '%'+@filtruFunctie+'%') 
	and (@filtruLm='' or p.Loc_de_munca like @filtruLm+'%' or lm.Denumire like '%'+@filtruLm+'%')
	and (dbo.f_areLMFiltru(@userASiS)=0 or lu.cod is not null)
	and (@filtruCNP='' or p.Cod_numeric_personal like '%'+@filtruCNP+'%')
	and (@filtruNrContract='' or i.Nr_contract like @filtruNrContract+'%')
	and (p.loc_ramas_vacant=0 and upper(@filtruCuPlecati)<>'DOAR'	--	doar activi
		or upper(@filtruCuPlecati)='DA' and p.loc_ramas_vacant=1	--	si salariatii plecati
		or upper(@filtruCuPlecati)='DOAR' and p.loc_ramas_vacant=1)	--	doar salariatii plecati
	and (@marca='' or p.Marca=@marca)
order by p.marca,p.cod_functie

/*	Populam tabela #marci si pe baza ei se va face calculul zilelor de CO cuvenite doar pentru aceste marci. */
select marca into #marci from #personal100

/*	Calculam prin procedura pZileCOcuvenite, numarul de zile de CO cuvenite pe An. */
create table #zileCOcuv (marca varchar(6), zile int)
exec pZileCOcuvenite @marca=null, @data=@DataLunii, @Calcul_pana_la_luna_curenta=0
select marca, zile into #zileCOcuvAn
from #zileCOcuv

/*	Calculam prin procedura pZileCOcuvenite, numarul de zile de CO cuvenite pana la luna de lucru (luna urmatoare lunii inchise)*/
delete from #zileCOcuv
exec pZileCOcuvenite @marca=null, @data=@DataLunii, @Calcul_pana_la_luna_curenta=1
select marca, zile into #zileCOcuvLuna
from #zileCOcuv

/*	Selectul final */
select 
	@tip tip, 
	rtrim(p.marca) as marca,rtrim(p.nume) as nume,rtrim(p.nume) as densalariat,
	rtrim(p.cod_functie) as functie,rtrim(f.denumire) as denfunctie,rtrim(p.Categoria_salarizare) as categs,rtrim(csal.Descriere) as dencategs,
	rtrim(p.loc_de_munca) as lm,rtrim(lm.denumire) as denlm,convert(decimal(10),p.salar_de_incadrare) as salinc,convert(decimal(10),p.salar_de_baza) as salbaza,
	convert(decimal(10),p.salar_lunar_de_baza) as reglucr,
	rtrim(p.tip_salarizare) as tipsal,rtrim(ts.denumire) as dentipsal,rtrim(p.grupa_de_munca) as grupamunca,convert(char(1),p.somaj_1) as somaj,rtrim(p.tip_impozitare) as tipimp,
	rtrim(p.grad_invalid) as gradinv,rtrim((case when p.Grupa_de_munca in ('P','O') then 'FDP' when p.tip_colab='' then 'CDP' else p.tip_colab end)) as dedpers,
	rtrim((case when p.Grupa_de_munca in ('P','O') then p.tip_colab else '' end)) as tipcolab, convert(int,p.Pensie_suplimentara) as pensiesupl, 
	convert(char(1),p.alte_surse) as altesurse,convert(char(1),sindicalist) as sindicat,
	convert(decimal(5,2),p.As_sanatate/10.00) as cassind, convert(decimal(8,2),p.spor_vechime) as spvech,convert(decimal(8,2),p.spor_de_noapte) as spnoapte,
	convert(decimal(8,2),p.spor_sistematic_peste_program) as spprogr,convert(decimal(8,2),p.spor_de_functie_suplimentara) as spsupl,convert(decimal(8,2),p.spor_specific) as spspec,
	convert(decimal(8,2),p.spor_conditii_1) as sp1,convert(decimal(8,2),p.spor_conditii_2) as sp2,convert(decimal(8,2),p.spor_conditii_3) as sp3,
	convert(decimal(8,2),p.spor_conditii_4) as sp4,convert(decimal(8,2),p.spor_conditii_5) as sp5,convert(decimal(8,2),p.spor_conditii_6) as sp6,
	convert(decimal(8,2),i.spor_cond_7) as sp7, convert(decimal(8,2),i.spor_cond_8) as sp8, convert(decimal(8,2),i.spor_cond_9) as sp9, convert(decimal(8,2),i.spor_cond_10) as sp10, 
	convert(decimal(8,2),p.indemnizatia_de_conducere) as spindc,
	rtrim(p.banca) as banca,rtrim(p.cont_in_banca) as contbanca,convert(decimal(10),p.zile_concediu_de_odihna_an) as zileco,convert(decimal(10),p.zile_concediu_efectuat_an) as zilecosupl,
	rtrim(p.mod_angajare) as modangaj,convert(decimal(10),p.zile_absente_an) as luniproba,convert(char(1),convert(int,p.coef_invalid)) as dedsomaj,
	convert(varchar(10),p.Data_angajarii_in_unitate,101) as dataangajarii,
	convert(int,(case when year(p.vechime_totala)=1899 then 1900 else year(p.vechime_totala)+(case when month(p.vechime_totala)=12 then 1 else 0 end) end)-1900) as vechimean,
	convert(int,(case when month(p.vechime_totala)=12 then 0 else month(p.vechime_totala) end)) as vechimeluna,
	convert(int,day(p.vechime_totala)) as vechimezi,
	(case when (case when year(p.vechime_totala)=1899 then 1900 else year(p.vechime_totala)+(case when month(p.vechime_totala)=12 then 1 else 0 end) end)-1900<10 then '0' else '' end)
		+rtrim(convert(char(2),(case when year(p.vechime_totala)=1899 then 1900 else year(p.vechime_totala)+(case when month(p.vechime_totala)=12 then 1 else 0 end) end)-1900))
		+'/'+(case when month(p.vechime_totala)=12 or month(p.vechime_totala)<10 then '0' else '' end)+rtrim(CONVERT(char(2),(case when month(p.vechime_totala)=12 then 0 else month(p.vechime_totala) end)))
		+'/'+(case when day(p.vechime_totala)<10 then '0' else '' end)+rtrim(convert(char(2),day(p.vechime_totala))) as vechimemunca,
	rtrim(v.Vechime_totala_car) as vechimemuncalazi,
	rtrim(i.Vechime_la_intrare) as vechimeintrare,
	rtrim(v.Vechime_la_intrare) as vechimeintrarelazi,
	rtrim(i.Vechime_in_meserie) as vechimemeserie,
	rtrim(v.Vechime_in_meserie) as vechimemeserielazi, 
	(case when p.Grupa_de_munca in ('N','D','S','C') then (case when v.gradatia=0 then 'Debutant' else convert(varchar(10),v.gradatia) end) else '' end) as gradatia, 
	convert(char(1),p.loc_ramas_vacant) as plecat,convert(varchar(10),p.data_plec,101) as dataplec,
	rtrim(p.Cod_numeric_personal) as cnp,rtrim(p.copii) as buletin,
	rtrim(p.localitate) as localitate,
	rtrim((case when charindex(',',p.Judet)=0 then p.Judet else left(p.Judet,charindex(',',p.Judet)-1) end)) as judet,
	rtrim((case when charindex(',',p.Judet)=0 then p.Judet else left(p.Judet,charindex(',',p.Judet)-1) end)) as denjudet,
	rtrim(p.strada) as strada,rtrim(p.numar) as numar,rtrim(p.bloc) as bloc,
	rtrim(p.scara) as scara,rtrim(p.etaj) as etaj,rtrim(p.apartament) as apart,rtrim(convert(decimal(10),p.cod_postal)) as codpostal,
	rtrim(p.adresa) as casasan,rtrim(isnull(cs.val_inf,'')) as dencasasan,rtrim(p.Activitate) as activitate, 
	rtrim(i.nr_contract) as nrcontract,convert(char(1),i.actionar) as actionar,rtrim(i.telefon) as telefon,rtrim(i.email) as email,rtrim(i.permis_auto_categoria) as permis,rtrim(i.religia) as religia,
	rtrim(i.nationalitatea) as nationalitatea,rtrim(i.cetatenia) as cetatenia,
	rtrim(i.starea_civila) as stareacivila,rtrim(i.evidenta_militara) as stagiumilitar,rtrim(i.limbi_straine) as limba,rtrim(i.observatii) as observatii,
	convert(char(1),Loc_de_munca_din_pontaj) as tichete,
	ltrim(rtrim((case when charindex(',',p.Judet)=0 then '' else substring(p.Judet,charindex(',',p.Judet)+1,10) end))) as anplimp, 
	rtrim(i.Centru_de_cost_exceptie) as comanda, rtrim(c.Descriere) as dencomanda, 
	isnull(rtrim(dp.pasaport),'') as pasaport,
	(case when isnull(p.fictiv,0)=0 then 0 else 1 end) as fictiv, (case when isnull(p.fictiv,0)=0 then 'Nu' else 'Da' end) as denfictiv, 
	convert(int,isnull(ip.Coef_invalid,0)) as zilecoram, isnull(zca.zile,0) as zilecocuvan, isnull(zcl.zile,0) as zilecocuvluna, 
	(case when loc_ramas_vacant=1 then '#808080' when isnull(p.fictiv,0)=1 then '#FF8040' else '#000000' end) as culoare,
	p.detalii detalii
from personal p
	inner join #personal100 p1 on p1.Marca=p.Marca
	left join functii f on p.cod_functie=f.cod_functie
	left join lm on p.loc_de_munca=lm.cod
	left join infopers i on i.marca=p.marca
	left join istPers ip on ip.Data=@DataAnAnt and ip.marca=p.marca
	left join categs csal on csal.Categoria_salarizare=p.Categoria_salarizare
	left join extinfop cs on cs.marca=p.adresa and cs.cod_inf='#CASSAN'
	outer apply (select Val_inf as pasaport from extinfop dp where dp.marca=p.marca and dp.cod_inf='PASAPORT' and dp.Val_inf<>'' and dp.Data_inf='01/01/1901') dp 
	left join dbo.fTip_salarizare() ts on ts.Tip_salarizare=p.tip_salarizare
	left join comenzi c on c.Subunitate=@sub and c.Comanda=i.Centru_de_cost_exceptie
	left outer join fCalculVechimeSporuri (@dataCrt, @dataCrt, '', 0, 0, '1', '', 1) v on v.Marca=p.Marca
	left outer join #zileCOcuvAn zca on zca.marca=p.marca
	left outer join #zileCOcuvLuna zcl on zcl.marca=p.marca
order by p.marca,p.cod_functie
for xml raw,root ('Date')

select '1' as areDetaliiXml
for xml raw, root('Mesaje')
