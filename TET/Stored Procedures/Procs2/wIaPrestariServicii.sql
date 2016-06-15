--***
create procedure wIaPrestariServicii @sesiune varchar(20) , @parXML xml
as
declare @numar varchar(20),@data datetime,@subunitate char(9),@utilizator varchar(20),@lista_lm int,
	@tert varchar(13), @tip varchar(2),@valtotal float, @valPrest float, @valPrestTva float
        
select         
	@numar=@parXML.value('(/row/@numar)[1]','varchar(20)'),
	@data=@parXML.value('(/row/@data)[1]','datetime'),
	@tert=@parXML.value('(/row/@tert)[1]','varchar(13)'),
	@valtotal=@parXML.value('(/row/@valtotala)[1]','float'),
	@tip=@parXML.value('(/row/@tip)[1]','varchar(2)')

select @valPrest=convert(decimal(17,2),sum(isnull(Cantitate*Pret_valuta,0))),
	@valPrestTva=convert(decimal(17,2),sum(isnull(Tva_deductibil,0)))
from pozdoc 
where subunitate='1'
	and numar=@numar
	and data=@data
	and tip in('RP','RZ')

select @numar as numar, convert(char(10),@data,101) as data, RTRIM(@tert) as tert, @tip as tip, convert(decimal(17,2), @valtotal) valtotala,
	convert(decimal(17,2),isnull(@valPrest,0)) as valPrest, convert(decimal(17,2),isnull(@valPrestTva,0)) as valPrestTva,
	convert(decimal(17,2),isnull(@valPrest,0)+isnull(@valPrestTva,0)) as valTotalPrest
for xml raw

/*
select * from  pozdoc where tip='RP'
*/
