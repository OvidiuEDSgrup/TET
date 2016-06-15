create procedure wpopRapFormChitanta (@sesiune varchar(50),	@parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @subunitate varchar(20),
			@cont varchar(20), @data datetime, @numar_pozitie varchar(20), @numar varchar(20), @nrExemplare int,
			@utilizatorASiS varchar(50)
	select	@cont=isnull(@parXML.value('(/row/@cont)[1]','varchar(20)'),@cont),
			@data=isnull(@parXML.value('(/row/@data)[1]','datetime'),@data),
			@numar_pozitie=isnull(@parXML.value('(/row/@numar_pozitie)[1]','varchar(20)'),@numar_pozitie),
			@numar=isnull(@parXML.value('(/row/@numar)[1]','varchar(20)'),@numar),
			@nrExemplare=2--isnull(@parXML.value('(/row/@nrExemplare)[1]','int'),@nrExemplare)
	set @numar=isnull(
		(select top 1 numar from pozplin p where p.Data=@data and p.Cont=@cont)
	,@numar)
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output
	select @cont cont, @data data, @numar_pozitie numar_pozitie, @numar numar, @nrExemplare nrExemplare
	for xml raw
end
