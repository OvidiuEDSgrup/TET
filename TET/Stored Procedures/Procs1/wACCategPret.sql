--***

create procedure [dbo].[wACCategPret] @sesiune varchar(50), @parXML XML
as
	declare @searchText varchar(80),@lista_categpret int
	set @lista_categpret =(case when  exists (select 1 from fPropUtiliz(@sesiune) where cod_proprietate='CATEGPRET' and valoare<>'') then 1 else 0 end)
	select @searchText=ISNULL(@parXML.value('(/row/@searchText)[1]', 'varchar(80)'), '')
	set @searchText=REPLACE(@searchText, ' ', '%')

	select top 100 rtrim(convert(char(10), Categorie)) as cod, rtrim(Denumire)+' ('+LTRIM(str(categorie))+')' as denumire, 
	RTrim((case tip_categorie when 3 then 'Discount' when 2 then 'Pret amanunt' else 'Pret vanzare' end) 
		+ (case when In_valuta=1 then ' (in valuta)' else '' end)) as info
	from categpret cp
	left outer join fPropUtiliz(@sesiune) fp on cod_proprietate='CATEGPRET' and categorie=fp.valoare
	where (rtrim(convert(char(10), Categorie)) like '%' + @searchText + '%' or denumire like '%' + @searchText + '%')
	and cp.Categorie like ((case when fp.valoare is not null then rtrim(fp.valoare) else @searchText+'%'end)+'%')
	and (@lista_categpret=0 or fp.valoare is not null)
	order by 1
	for xml raw
