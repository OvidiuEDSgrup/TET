create procedure wpopScriuDiurne (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @subtip varchar(2), @data_inceput datetime, @data_sfarsit datetime

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	select	@subtip=@parXML.value('(/row/@subtip)[1]','varchar(2)'),
			@data_inceput=dbo.BOM(isnull(@parXML.value('(/row/@datainceput)[1]','datetime'),getdate()))
	set @data_sfarsit=dbo.EOM(@data_inceput)
	
	if @subtip='AD'
		select '' as marca, convert(varchar(10),@data_inceput,101) as datainceput, convert(varchar(10),@data_sfarsit,101) as datasfarsit, 
			0 as zile, '' as tara, '' as valuta, 0.00 as curs
		for xml raw
end
