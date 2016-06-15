/****** Object:  StoredProcedure [dbo].[wUAACTipDateLunare]    Script Date: 01/06/2011 01:04:36 ******/
--***
create PROCEDURE  [dbo].[wUAACTipDateLunare]
	@sesiune [varchar](50),
	@parXML [xml]
WITH EXECUTE AS CALLER
AS
if exists(select * from sysobjects where name='wUAACTipDateLunareSP' and type='P')      
	exec wUAACTipDateLunareSP @sesiune,@parXML      
else      
begin
declare @subunitate varchar(9), @searchText varchar(80),@tip varchar(2)
  
select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '') ,
	   @tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), '') 	

set @searchText=REPLACE(@searchText, ' ', '%')

select a.cod as cod,a.denumire as denumire
from(
select 'PV'as cod,'PV-Proces verbal' as denumire
union all
select 'CF'as cod,'CF-Confirmare' as denumire
union all
select 'MM'as cod,'MM-Minim' as denumire
union all
select 'FX'as cod,'FX-Cantitate Fixa' as denumire
union all
select 'ME'as cod,'ME-Exceptie la minim' as denumire
union all
select 'EX'as cod,'EX-Exceptie' as denumire)a
where a.cod like '%'+@searchText or a.denumire like '%'+@searchText+'%'

for xml raw
end
