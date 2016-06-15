--***
create procedure [dbo].wIaPozFactInitiale @sesiune varchar(30), @parXML XML
AS    
	Declare @tiptert varchar(1),@doc xml,@an_impl int,@luna_impl int,@mod_impl int,@data_an datetime

select  @data_an=isnull(@parXML.value('(/row/@data_an)[1]', 'datetime'), '') , 
		@tiptert=isnull(@parXML.value('(/row/@tiptert)[1]', 'varchar(1)'), '')
		
	exec luare_date_par 'GE', 'ANULIMPL', 0, @an_impl output, ''
	exec luare_date_par 'GE', 'LUNAIMPL', 0, @luna_impl output, ''
	exec luare_date_par 'GE', 'IMPLEMENT', @mod_impl output, 0, ''

select top 100 rtrim(a.Loc_de_munca) as loc_de_munca,a.tip as tiptert,RTRIM(a.Cont_de_tert)as cont_de_tert, convert(varchar(10),a.Data,101) as data,
		convert(varchar(10),a.Data_scadentei,101) as data_scadentei,convert(decimal(17,4),a.valoare) as valoare,RTRIM(Factura)as factura,
		case when isnull(a.valuta,'')='' then convert(decimal(17,4),a.valoare) else convert(decimal(17,4),a.Valoare_valuta) end as valoaref,--valoare afisata in grid, in valuta sau nu 
		case when isnull(a.valuta,'')='' then convert(decimal(17,4),a.Sold) else convert(decimal(17,4),a.Sold_valuta) end as soldf,--sold afisat in grid, in valuta sau nu
		case when isnull(a.valuta,'')='' then convert(decimal(17,4),a.Achitat) else convert(decimal(17,4),a.Achitat_valuta) end as achitatf,--achitat afisat in grid, in valuta sau nu
		case when isnull(a.valuta,'')='' then 'RON' else RTRIM(a.Valuta) end as valutaf,--valuta afisata in grid, dc nu e completata->RON
		case when isnull(a.valuta,'')='' then  convert(decimal(17,4),a.TVA_22) when isnull(a.valuta,'')<>'' and ISNULL(a.Curs,0)<>0 then convert(decimal(17,4),a.TVA_22/a.Curs) else 0 end as tva_22f,
		convert(varchar(10),a.Data_ultimei_achitari,101) as data_ultimei_achitari,convert(decimal(17,4),a.TVA_11) as tva_11,convert(decimal(17,4),a.TVA_22) as tva_22,
		convert(decimal(17,4),a.Curs) as curs,RTRIM(a.tert)as tert,convert(decimal(17,2),Valoare_valuta) as valoare_valuta,convert(decimal(17,2),sold) as sold,
		RTRIM(Comanda) as comanda,convert(decimal(17,4),a.Achitat) as achitat,rtrim(a.tert)+'-'+rtrim(t.Denumire) as dentert,'FI' as subtip,'FI'as tip,
		RTRIM(v.Denumire_valuta)as denvaluta,RTRIM(a.Valuta)as valuta,
		1 as _nemodificabil
from istfact a 
		left outer join terti t on t.Tert=a.Tert
		left outer join valuta v on v.Valuta=a.Valuta
where a.Tip=@tiptert
   and a.Data_an=@data_an
order by a.Data desc
for xml raw
--select * from serii
--select * from istfact
--sp_help istfact
