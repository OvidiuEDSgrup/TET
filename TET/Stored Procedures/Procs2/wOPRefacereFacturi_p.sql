create procedure wOPRefacereFacturi_p @sesiune varchar(50), @parXML xml   
as       

select 1 Furn, 1 Benef, (case when @parXML.exist('/row/@datasus')=1 
				then @parxml.value('(/row/@datasus)[1]','varchar(30)')
				else '01/01/2099' end) datasus
for xml raw


