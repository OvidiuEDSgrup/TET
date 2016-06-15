--***
create procedure dbo.wOPPlataRM_p (@sesiune varchar(50), @parXML xml) as
begin            
	declare @dataplatii datetime

	select @dataplatii = isnull(@parXML.value('(/*/@datafacturii)[1]', 'datetime'), isnull(@parXML.value('(/*/@data)[1]', 'datetime'), '2999-01-01'))

	select convert(VARCHAR(20), @dataplatii, 101) dataplatii
	for xml raw
end
