--***
Create procedure wIaIstoricPersonal @sesiune varchar(50), @parXML XML    
as    
set transaction isolation level READ UNCOMMITTED

Declare @tip varchar(2), @gestiune varchar(20), @gestutiliz varchar(20), @cSub char(9), @userASiS varchar(20),
@filtruAn varchar (100),@marca varchar(6), @LunaImpl int, @AnulImpl int, @DataImpl datetime, @LunaInch int, @AnulInch int, @DataInch datetime

set @LunaImpl=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNAIMPL'), 1)
set @AnulImpl=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANULIMPL'), 2010)
set @DataImpl=dbo.Eom(convert(datetime,str(@LunaImpl,2)+'/01/'+str(@AnulImpl,4)))
set @LunaInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='LUNA-INCH'), 1)
set @AnulInch=isnull((select max(val_numerica) from par where tip_parametru='PS' and parametru='ANUL-INCH'), 2009)
set @DataInch=dbo.Eom(DateAdd(month,1,convert(datetime,str(@LunaInch,2)+'/01/'+str(@AnulInch,4))))

set @marca=ISNULL( @parXML.value('(/row/@marca)[1]','varchar(6)'),'')
set @tip=ISNULL( @parXML.value('(/row/@tip)[1]','varchar(2)'),'')
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@userASiS output

if object_id('tempdb..#istoricPersonal') is not null drop table #istoricPersonal

select top 100 *
into #istoricPersonal  
from istPers i 
where i.marca=@marca
order by i.Data desc
  
select @tip as tip, 'IP' as subtip, 
	convert(varchar(10),i.Data,101) as data,RTRIM(i.marca) as marca,RTRIM(i.nume)as nume,RTRIM(i.cod_functie)as cod_functie,RTRIM(i.loc_de_munca)as lm,
	RTRIM(i.categoria_salarizare) as categoria_salarizare,RTRIM(i.grupa_de_munca) as grupa_de_munca,i.tip_salarizare,i.tip_impozitare,
	convert(decimal(10),i.salar_de_incadrare)as salar_de_incadrare,convert(decimal(10),i.salar_de_baza)as salar_de_baza,
	convert(decimal(10),i.indemnizatia_de_conducere)as indemnizatia_de_conducere,convert(decimal(10),i.spor_vechime)as spor_vechime,
	convert(decimal(10),i.spor_de_noapte)as spor_de_noapte,convert(decimal(10),i.spor_sistematic_peste_program)as spor_sistematic_peste_program,
	convert(decimal(10),i.spor_de_functie_suplimentara)as spor_de_functie_suplimentara,convert(decimal(10),i.spor_specific)as spor_specific,
	convert(decimal(10),i.spor_conditii_1)as spor_conditii_1,convert(decimal(10),i.spor_conditii_2)as spor_conditii_2,
	convert(decimal(10),i.spor_conditii_3)as spor_conditii_3,convert(decimal(10),i.spor_conditii_4)as spor_conditii_4,
	convert(decimal(10),i.spor_conditii_5)as spor_conditii_5,convert(decimal(10),i.spor_conditii_6)as spor_conditii_6,
	convert(decimal(10),i.salar_lunar_de_baza)as salar_lunar_de_baza,RTRIM(i.localitate)as localitate,RTRIM(i.judet)as judet,
	RTRIM(i.strada)as strada,RTRIM(i.numar) as numar,i.cod_postal,RTRIM(i.bloc)as bloc,RTRIM(i.scara)as scara,rtrim(l.Denumire) as denlm,
	RTRIM(i.etaj)as etaj,RTRIM(i.apartament)as apartament,i.sector,(case when i.mod_angajare='N' then 'Nedeterminat' else 'Determinat'end) as mod_angajare,
	convert(varchar(10),i.Data_plec,101) as data_plec,RTRIM(i.tip_colab) as tip_colab,i.grad_invalid,i.coef_invalid,
	i.alte_surse,rtrim(f.denumire) as den_tip_salarizare,rtrim(d.LunaAlfa)+' '+CONVERT(varchar,year(i.data)) as luna_alfa,
	RTRIM(i.localitate)+', '+RTRIM(i.strada)+', nr.'+RTRIM(i.numar)+', bl.'+RTRIM(i.bloc)+', et.'+RTRIM(i.etaj)+', '+RTRIM(i.judet) as adresa
from #istoricPersonal i
	inner join dbo.fCalendar(@DataImpl,@DataInch) d on i.data=d.data
	, dbo.fTip_salarizare() f, lm l
where i.tip_salarizare=f.tip_salarizare and l.Cod=i.loc_de_munca   
order by convert(char(10),i.Data,111) desc
for xml raw    

if object_id('tempdb..#istoricPersonal') is not null drop table #istoricPersonal
