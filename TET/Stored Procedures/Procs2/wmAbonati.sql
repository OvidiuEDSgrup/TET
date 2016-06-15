/****** Object:  StoredProcedure [dbo].[wUAACAbonati]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE [dbo].[wmAbonati]          
 @sesiune [varchar](50),          
 @parXML [xml]          
WITH EXECUTE AS CALLER          
AS          
begin          
declare @subunitate varchar(9), @searchText varchar(80) ,@utilizator char(10), @userASiS varchar(20)         
            
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')             
set @searchText=rtrim(ltrim(REPLACE(@searchText, ' ', '%')))          
      
---------      
set @Utilizator=dbo.iauUtilizatorCurent()        
set @userASiS=isnull((select max(id) from utilizatori where observatii=SUSER_name()), '')        
      
declare @lista_lm int      
set @lista_lm=(case when exists (select 1 from proprietati       
where tip='UTILIZATOR' and cod=@utilizator and cod_proprietate='LOCMUNCA' and Valoare<>'') then 1 else 0 end)      
      
---------      
          
select top 10 rtrim(a.abonat) as cod, rtrim(max(Denumire)) +' Sold: '+convert(varchar,sum(isnull(f.sold,0))) as denumire,      
isnull(RTRIM(max(s.Denumire_Strada)),max(a.observatii))+', nr '+isnull(max(a.numar),max(a.observatii)) as info          
from Abonati a      
left outer join FactAbon f on f.abonat=a.abonat        
left outer join LMFiltrare lu on lu.utilizator=@utilizator and a.loc_de_munca=lu.cod      
left join strazi s on a.strada=s.strada      
where (a.abonat like '%' + @searchText + '%' or denumire like '%' + @searchText + '%')          
  and (@lista_lm=0 or lu.cod is not null)      
group by a.abonat          
order by a.abonat            
for xml raw          

	select 'wmFacturiAbonatiGrafic' as detalii,1 as areSearch,1 as detalieregrafica
	for xml raw,Root('Mesaje')

end
