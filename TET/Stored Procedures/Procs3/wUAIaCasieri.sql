--***
Create PROCEDURE [dbo].[wUAIaCasieri]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
set transaction isolation level READ UNCOMMITTED
Declare @filtrucasier varchar(30),@utilizator char(10), @userASiS varchar(20)
                       
 select @filtrucasier = replace(isnull(@parXML.value('(/row/@filtrucasier)[1]','varchar(30)'),'%'),' ','%')

---------
set @Utilizator=dbo.iauUtilizatorCurent()  
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')  

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)

---------


select rtrim(a.cod_casier) as codcasier,rtrim(a.casier) as casier,RTRIM(a.serie_bi) as seriebi, 
rtrim(a.numar_bi) as numarbi, RTRIM(a.cnp) as cnp, RTRIM(serie) as serie,RTRIM(tip_incasare) as tipincasare,RTRIM (Formular_chitanta) as formchit,
RTRIM (a.Formular_chitanta_avans) as formchitav,RTRIM (a.Formular_chitanta_sold_avans) as formchitsoldav,RTRIM(a.formular_factura) as formfactura,b.denumire as denumire,rtrim(a.loc_de_munca) as lm,rtrim(d.denumire) as denlm,
rtrim(e.denumire_formular) as denformchit,rtrim(f.denumire_formular) as denformchitav,rtrim(h.denumire_formular) as denformchitsoldav,rtrim(g.denumire_formular) as denformfactura,

(case when a.Cod_casier not in (select ID from utilizatori)  then '#FF0000'  else '#000000' end) as culoare  

from casieri a 
left outer join Tipuri_de_incasare b on a.tip_incasare=b.id
left outer join lm d on a.loc_de_munca=d.cod
left outer join antform e on a.Formular_chitanta=e.numar_formular and e.Tip_formular='U'
left outer join antform f on a.Formular_chitanta_avans=f.numar_formular and f.Tip_formular='U'
left outer join antform g on a.Formular_factura=g.numar_formular and g.Tip_formular='U'
left outer join antform h on a.Formular_chitanta_sold_avans=h.numar_formular and h.Tip_formular='U'
left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod

where(a.casier like '%'+@filtrucasier+'%' or a.Cod_casier like @filtrucasier+'%' or @filtrucasier='') 
  and (@lista_lm=0 or lu.cod is not null)    
order by a.cod_casier
for xml raw
