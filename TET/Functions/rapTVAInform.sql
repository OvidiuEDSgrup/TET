--***
create function  rapTVAInform
(@DataJ datetime,@DataS datetime)
returns @rtva table
(codtert char(13), codfisc char(20), dentert char(80), tipop char(1), baza float, tva float)
begin
	declare @parXML xml
	select @parXML=(select @DataJ datajos, @DataS datasus, 0 as pecoduri for xml raw)
	insert @rtva
	select max(codtert),codfisc,max(dentert) as dentert,tipop,sum(baza),sum(tva)
	from frapTVApecoduri(@parXML)	--> Procedura initiala a fost impartita in doua - rapTVApecoduri si rapTVAInform, pt declaratia 394
	group by codfisc,tipop
	order by tipop desc, dentert
	
return
end
