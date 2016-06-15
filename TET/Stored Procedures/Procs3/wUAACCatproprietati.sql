/****** Object:  StoredProcedure [dbo].[wUAACCatproprietati]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAACCatproprietati]   
 @sesiune [varchar](50),    
 @parXML [xml]    
WITH EXECUTE AS CALLER    
AS    
if exists(select * from sysobjects where name='wUAACCatproprietatiSP' and type='P')          
 exec wUAACCatproprietatiSP @sesiune,@parXML          
else          
begin    
declare @subunitate varchar(9), @searchText varchar(80)    
      
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')       
set @searchText=rtrim(ltrim(REPLACE(@searchText, ' ', '%')))    
    
select '1' as cod, 'Nomenclator abonati'  as denumire    
union all
select '2' as cod, 'Abonati'  as denumire   
union all
select '3' as cod, 'Contracte'  as denumire  
union all
select '4' as cod, 'Casieri'  as denumire  
union all
select '5' as cod, 'Zone'  as denumire  
union all
select '6' as cod, 'Centre'  as denumire  
   
order by cod      
for xml raw    
end
