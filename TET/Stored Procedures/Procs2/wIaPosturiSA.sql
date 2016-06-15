--***
create procedure [dbo].[wIaPosturiSA] @sesiune varchar(50), @parXML XML
as
if exists(select * from sysobjects where name='wIaPosturiSASP' and type='P')
	exec wIaPosturiSASP @sesiune, @parXML 
else      
begin
set transaction isolation level READ UNCOMMITTED

Declare @filtruLocMunca varchar(100),  @filtruConsilier varchar(100), @filtruDenumire varchar(100),
        @filtruPostLucru     varchar(100)

Select @filtruLocMunca= '%'+isnull(@parXML.value('(/row/@locmunca)[1]','varchar(100)'),'')+'%',
	   @filtruConsilier= '%'+isnull(@parXML.value('(/row/@consilier)[1]','varchar(100)'),'')+'%',
	   @filtruDenumire= '%'+isnull(@parXML.value('(/row/@denumire)[1]','varchar(100)'),'')+'%',  
       @filtruPostLucru='%'+isnull(@parXML.value('(/row/@postlucru)[1]','varchar(100)'),'')+'%'


select top 100

convert(varchar(100),pl.Postul_de_lucru) as postlucru,
RTRIM(pl.Loc_de_munca) as locmunca, 
RTRIM(pl.Consilier_responsabil) as consilier,
RTRIM(pl.Denumire) as denumire


from Posturi_de_lucru pl 

where pl.Loc_de_munca like @filtruLocMunca
and pl.Denumire like @filtruDenumire
and pl.Consilier_responsabil like @filtruConsilier
and pl.Postul_de_lucru like @filtruPostLucru+'%'


for xml raw

end
