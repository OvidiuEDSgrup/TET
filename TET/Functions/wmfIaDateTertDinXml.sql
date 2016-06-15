/** citeste cod tert si cod punct livrare din xml */
create function dbo.wmfIaDateTertDinXml(@parXML xml)
returns @dateTert table (tert varchar(20), idPunctLivrare varchar(20))
as
begin
	insert @dateTert(tert, idPunctLivrare)
	values( @parXML.value('(/row/@tert)[1]','varchar(100)'), 
			@parXML.value('(/row/@pctliv)[1]','varchar(100)') ) 

	-- legacy - de eliminat dupa actualizarea procedurilor + modificare proc. SP la quantum
	if exists (select 1 from @dateTert where tert is null)
	begin -- nu am gasit @tert in xml
		declare @cod varchar(100), @index int
		select	@cod=@parXML.value('(/row/@wmIaTerti.cod)[1]','varchar(100)'),	/**	cod contine tert+'|'+punct de livrare*/
				@index=charindex('|',@cod,1)
			
		update @dateTert set tert=substring(@cod,1,@index-1), idPunctLivrare=isnull(substring(@cod,@index+1,100),'')
	end
	return 
end
