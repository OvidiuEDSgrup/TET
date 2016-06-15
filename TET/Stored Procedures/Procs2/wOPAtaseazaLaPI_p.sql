create procedure  wOPAtaseazaLaPI_p @sesiune varchar(50), @parXML xml
as
declare @nrDoc varchar(30), @platiincasari int, @fdataAntet datetime, @stare int, @denStare varchar(50)
select	@nrDoc=isnull(@parXML.value('(/row/@numar)[1]','varchar(30)'),''),
		@fdataAntet=isnull(@parXML.value('(/row/@data)[1]','datetime'),'1900-01-01'),
		@denStare=isnull(@parXML.value('(/row/@denstare)[1]','varchar(40)'),'')
		
select @nrdoc nrdoc, convert(varchar(20),@fDataAntet,101) fDataAntet, @denstare denstare 
for xml raw