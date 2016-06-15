
create procedure wmIaStocuriLocatie @sesiune varchar(50), @parXML xml
as

	declare
		@locatie varchar(20)

	set @locatie=ISNULL(@parXML.value('(/*/@cod)[1]','varchar(20)'),'')


	select 
		RTRIM(st.cod) as cod, RTRIM(n.denumire) as denumire,
		ltrim(convert(varchar(20),CONVERT(money,st.stoc),1))+' '+rtrim(n.um)  + '/ Cod intrare: '+rtrim(st.cod_intrare) info
	from stocuri st
	inner join nomencl n on st.cod=n.cod
	where st.Subunitate='1' and st.Locatie=@locatie  and ABS(st.stoc)>0
	for xml raw, root('Date')
