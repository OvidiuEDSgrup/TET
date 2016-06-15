--***  
/* procedura care afisaza facturile neincasate pe un tert si perimite alegerea facturilor care se vor incasa. */
CREATE procedure [dbo].[wmIncasareFacturi] @sesiune varchar(50), @parXML xml as  
set transaction isolation level READ UNCOMMITTED  
if exists(select * from sysobjects where name='wmIncasareFacturiSP' and type='P')
begin
	exec wmIncasareFacturiSP @sesiune, @parXML 
	return 0
end

declare @utilizator varchar(100),@subunitate varchar(9), @tert varchar(30), @xmlFinal xml, @linieXML xml,
		@facturaDeIncasat varchar(100)
exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output 
if @utilizator is null
	return -1

-- identificare tert din par xml
select @tert=f.tert--, @idPunctLivrare=f.idPunctLivrare
from dbo.wmfIaDateTertDinXml(@parXML) f

exec luare_date_par 'GE', 'SUBPRO', 0, 0, @subunitate output  

-- formez lista de facturi neachitate
set @xmlFinal=
	(select rtrim(f.Factura) as cod,
		rtrim(f.Factura)+' din '+convert(char(10),f.Data,103) as denumire,
		'Val:'+LTRIM(convert(char(20),convert(money,f.Valoare+f.TVA_22),1))+',Ach:'+LTRIM(convert(char(20),convert(money,f.Achitat),1)) as info,
		(case when tmp.factura is not null then '0x33FF00' else '0xFFFFFF' end) as culoare
	from facturi f
	left join tmp_facturi_de_listat tmp on tmp.utilizator=@utilizator and tmp.factura=f.Factura
	where tip=0x46 and tert=@tert and ABS(sold)>0.05
	order by data
	for xml raw, root('Date')
	)

-- formez si adaug un element pentru a vedea lista facturilor alese
set @linieXML= 
	(select '<INCASAREFACTURI>' as cod,  
		'Incaseaza facturi alese' as denumire, 'assets/Imagini/Meniu/incasari.png' as poza,
		'Nr facturi:'+isnull((select convert(varchar(30),COUNT(1))+', Suma:'+convert(varchar,convert(money,sum(f.Valoare+f.TVA_11+f.TVA_22)),1)
			from tmp_facturi_de_listat tmp inner join facturi f on tmp.factura=f.Factura and f.Tip=0x46 and f.Tert=@tert
			where tmp.utilizator=@utilizator),'0') as info,
		'0x0000ff' as culoare
	 for xml raw)
--set @xmlFinal.modify('insert sql:variable("@linieXML") as last into (/Date)[1]')
-- legacy 2005:
set @xmlFinal = convert(xml, (convert(nvarchar(max), isnull(@xmlFinal,'<Date />')) + convert(nvarchar(max), @linieXML)))
set @xmlFinal.modify('insert /*[2] as first into /*[1]')
set @xmlFinal.modify('delete /*[2]')

select @xmlFinal

select 'Incasare facturi' as titlu, 'wmIncasareFacturiHandler' as detalii,0 as areSearch, 'refresh' actiune
for xml raw,Root('Mesaje')   

--select * from tmp_facturi_de_listat
