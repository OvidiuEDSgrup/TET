
create procedure wOPAlegCursuriValute_p @sesiune varchar(50), @parXML xml
as
begin
	declare 
		@data datetime, @valutafiltru varchar(20)

	-- ca sa mearga si pe facturi si pe disponibil: data se trimite cand cum
	set @data=COALESCE(@parXML.value('(/*/@datacorectii)[1]','datetime'),@parXML.value('(/*/@dataplin)[1]','datetime'),GETDATE())
	set @valutafiltru=@parXML.value('(/*/@valutafiltru)[1]','varchar(20)')

	/**
		Populam Grid-ul editabil
	**/

	select convert(varchar(10),@data,101) data ,@valutafiltru valutafiltru
	for xml raw, ROOT('Date')
	select 
	(
		SELECT 
			crs.valuta, convert(decimal(15,4),curs) curs, rtrim(v.Denumire_valuta) denvaluta
		from 
			(
				SELECT 
					valuta, Curs, RANK() over (partition by valuta order by data desc) rn
				from curs
				where Data<=@data and valuta<>''
			) crs
		JOIN valuta v on v.Valuta=crs.valuta
		WHERE crs.rn=1 and (isnull(@valutafiltru,'')='' OR crs.Valuta=@valutafiltru)
		FOR XML RAW, TYPE
	)
	for XML PATH('DateGrid'),ROOT('Mesaje')
end
