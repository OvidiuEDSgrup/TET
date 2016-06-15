/****** Object:  StoredProcedure [dbo].[wUAIaPreturi]    Script Date: 01/05/2011 23:51:25 ******/
--***
Create PROCEDURE  [dbo].[wUAIaPreturi] 
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
begin 
set transaction isolation level READ UNCOMMITTED
declare @cod varchar(20)

select @cod=isnull(@parXML.value('(/row/@cod)[1]', 'varchar(20)'), '')

select  top 100 rtrim(convert(char(2),a.categorie)) as categorie,
rtrim(a.categorie)+'-'+rtrim(b.denumire) as denumire,convert(char(10),a.Data_inferioara,101) as datainferioara,
convert(char(10),Data_superioara,101) as datasuperioara,convert(decimal(15,5),pret_vanzare) as pretvanzare ,
convert(decimal(15,5),pret_cu_amanuntul) as pretamanunt
from UApreturi a
left outer join  UACatpret b on a.categorie=b.categorie 
where cod=@cod


for xml raw
end
