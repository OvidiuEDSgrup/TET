create procedure wpopDateRevisal (@sesiune varchar(50), @parXML xml='<row/>')
as
begin
	set transaction isolation level read uncommitted
	declare @utilizatorASiS varchar(50), @marca varchar(6), @dataconsemn datetime, @cetatenie varchar(100), @nationalitate varchar(100), 
		@nrcontract varchar(20), @tipcontract varchar(100), @tipactident varchar(100), @repartizaretm varchar(100)

	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizatorASiS output

	if exists (select 1 from sysobjects o where o.name='wpopDateRevisalSP')
		exec wpopDateRevisalSP @sesiune=@sesiune, @parXML=@parXML output

	select @marca=@parXML.value('(/row/row/@marca)[1]','varchar(6)'), 
		@dataconsemn=isnull(@parXML.value('(/row/row/@dataconsemn)[1]','datetime'),''),
		@cetatenie=isnull(@parXML.value('(/row/row/@cetatenie)[1]','varchar(100)'),''), 
		@nationalitate=isnull(@parXML.value('(/row/row/@nationalitate)[1]','varchar(100)'),''), 
		@nrcontract=isnull(@parXML.value('(/row/row/@nrcontract)[1]','varchar(20)'),''),
		@tipcontract=isnull(@parXML.value('(/row/row/@tipcontract)[1]','varchar(100)'),''), 
		@tipactident=isnull(@parXML.value('(/row/row/@tipactident)[1]','varchar(100)'),''), 
		@repartizaretm=isnull(@parXML.value('(/row/row/@repartizaretm)[1]','varchar(100)'),'')

	select @nrcontract as nrcontract, 
		convert(char(10),(case when isnull(@dataconsemn,'01/01/1901')='01/01/1901' then getdate() end),101) dataconsemn,
		(case when @cetatenie=''  then 'Romana' end) as cetatenie, 
		(case when @nationalitate='' then 'Rom�nia' end) as nationalitate, 
		(case when @nationalitate='' then 'Rom�nia' end) as dennationalitate, 
		(case when @tipcontract='' then 'ContractIndividualMunca' end) as tipcontract, 
		(case when @tipactident='' then 'CarteIdentitate' end) as tipactident,
		(case when @repartizaretm='' then 'OreDeZi' end) as repartizaretm
	for xml raw
end
