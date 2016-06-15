create procedure  [dbo].[wIaRectificariBugetare] @sesiune varchar(50), @parXML XML    
as    
set transaction isolation level READ UNCOMMITTED

 Declare  
     @gestiune varchar(20),@gestutiliz varchar(20), @categoriePret int, @cSub char(9), @utilizator varchar(20),@filtruCod_de_Bare varchar(80) ,
     @filtruAn varchar (100),@indbug varchar(20), @anfiltru int,@filtrulm varchar(80)
 
  select
     @indbug = @parXML.value('(/row/@indbug)[1]','varchar(20)'),
     @filtrulm = isnull(@parXML.value('(/row/@filtrulm)[1]','varchar(80)'),'')
  
     EXEC wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT


declare @anchar varchar(10)
set @anchar=isnull(@parXML.value('(/row/@anplan)[1]','varchar(10)'),'')
if isnumeric(@anchar)=1
	set @anfiltru=convert(int,@anchar)
else 
	set @anfiltru=year(getdate())

declare @lista_lm int
set @lista_lm=(case when exists (select 1 from proprietati 
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)
	    
select top 100 
	(case DATEPART(QUARTER,Data) when 1 then 'I' when 2 then 'II' when 3 then 'III' else 'IV' end) as trimestru,
    --convert(char(10), p.data, 101)  as dataR, convert(char(10), p.data, 101)  as data,
    rtrim(p.tert)  as dataR, 
    convert(decimal(12,3),p.suma) as suma,rtrim(p.valuta) as valuta ,convert(decimal(12,3),p.curs) as curs,
    convert(decimal(12,3),p.suma_valuta) as suma_valuta,ltrim(rtrim(p.explicatii))as explicatii,nr_pozitie,
    rtrim(numar) as numar,rtrim(comanda) as comanda,        
    RTRIM(p.loc_munca) as lm, RTRIM(lm.denumire) as denlm
from pozncon p 
left join lm on lm.Cod=p.Loc_munca
left outer join LMFiltrare lu on lu.utilizator=@utilizator and p.Loc_munca=lu.cod
where p.tip='AO'
  and left (p.numar,2)='RB' 
  and substring(p.comanda,21,20)=@indbug
  and year(p.data)=@anfiltru 
  and (@lista_lm=0 or lu.cod is not null)
  and (p.Loc_munca=@filtrulm or isnull(@filtrulm,'')='')
order by 1
for xml raw
