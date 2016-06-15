--***
create procedure [dbo].[wIaDecSalariati] @sesiune varchar(30), @parXML XML
AS  
  
Declare  @marca varchar(9)

select @marca=isnull(@parXML.value('(/row/@marca)[1]', 'varchar(9)'), '')  

select a.Tip as tip, rtrim(a.Marca) as marca,RTRIM(a.Decont)as decont,RTRIM(cont)as cont, convert(varchar(10),a.Data,101) as data,
	convert(varchar(10),a.Data_scadentei,101) as data_scadentei,convert(decimal(12,4),Valoare) as valoare,RTRIM(valuta)as valuta,convert(decimal(12,4),curs) as curs,
	convert(decimal(12,4),Valoare_valuta) as valoare_valuta,convert(decimal(12,4),Decontat) as decontat,convert(decimal(12,4),sold) as sold,
	convert(decimal(12,4),Decontat_valuta) as decontat_valuta,convert(decimal(12,4),Sold_valuta) as sold_valuta,RTRIM(Loc_de_munca) as loc_de_munca,
	RTRIM(Comanda) as comanda,RTRIM(Explicatii) as explicatii
from deconturi a 
where a.Marca=@marca
	and (abs(a.Sold)>0.01 or abs(a.Sold_valuta)>0.01)
order by a.Decont
for xml raw
--select * from deconturi
