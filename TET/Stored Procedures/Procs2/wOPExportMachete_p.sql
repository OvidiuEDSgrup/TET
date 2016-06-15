--***
create procedure wOPExportMachete_p @sesiune varchar(50)=null, @parXML xml='<row />'
as
begin
	select (
		select	replace(
				replace(
				@parXML.value('(row/@nume)[1]','varchar(max)')
				,' ','_')
				,'/','_')
			fisier for xml raw)
end
