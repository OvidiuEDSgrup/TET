--***
create procedure [dbo].[wIaOperatiiSA] @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaOperatiiSASP' and type='P')
	exec wIaOperatiiSASP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @filtruCod varchar(100), @filtruDescriere varchar(100)

Select	@filtruCod = '%'+isnull(@parXML.value('(/row/@cod)[1]','varchar(100)'),'')+'%',
		@filtruDescriere = '%'+isnull(@parXML.value('(/row/@descriere)[1]','varchar(100)'),'')+'%'      


select top 100
rtrim(m.Cod) as cod,
RTRIM(m.Descriere) as descriere


from mot_service m 
--
where Cod like @filtruCod
and Descriere like @filtruDescriere


for xml raw

end
