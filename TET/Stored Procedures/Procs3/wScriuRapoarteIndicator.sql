--***
CREATE procedure  wScriuRapoarteIndicator  @sesiune varchar(50), @parXML XML
as
declare @update bit, @codInd varchar(10), @numeraport varchar(200), @o_numeraport varchar(200),
		@msgEroare varchar(500), @pathraport varchar(500), @procpopulare varchar(100), @existaRaport bit

begin try

	select	@update = isnull(@parXML.value('(/row/@update)[1]', 'int'), 0),
			@codInd = @parXML.value('(/row/@cod)[1]', 'varchar(20)'),
			@numeraport = @parXML.value('(/row/row/@numeraport)[1]', 'varchar(100)'),
			@o_numeraport = @parXML.value('(/row/row/@o_numeraport)[1]', 'varchar(100)'),
			@pathraport = @parXML.value('(/row/row/@pathraport)[1]', 'varchar(500)'),
			@procpopulare = @parXML.value('(/row/row/@procpopulare)[1]', 'varchar(100)')
	
	set @existaRaport= isnull((select max(1) from rapIndicatori where cod_indicator=@codInd and Nume_raport=@numeraport),0)

	if (@update=0 or @numeraport!=@o_numeraport) and @existaRaport=1
	begin
		set @msgEroare = 'Raportul cu numele: '+@numeraport+' este deja configurat in dreptul acestui indicator!'
		RAISERROR(@msgEroare,16,1)
	end
	
	if len(@numeraport)=0
	begin
		set @msgEroare = 'Numele raportului este invalid.'
		RAISERROR(@msgEroare,16,1)
	end
	
	if len(@pathraport)=0
	begin
		set @msgEroare = 'Path-ul raportului este invalid.'
		RAISERROR(@msgEroare,16,1)
	end
	
	if @update=0
		insert into rapIndicatori (Cod_Indicator, Nume_raport, Path_raport, Procedura_populare)
			values (@codInd, @numeraport, @pathraport, @procpopulare )
	else
		if @existaRaport=0
		begin
			set @msgEroare = 'Nu exista raportul cu numele: '+@codInd
			RAISERROR(@msgEroare,16,1)
		end
		else 
			update rapIndicatori set Nume_raport = @numeraport, Path_raport = @pathraport, Procedura_populare = @procpopulare
				where Cod_Indicator= @codInd and Nume_raport=@o_numeraport
end try
begin catch
	set @msgEroare=ERROR_MESSAGE()+'(wScriuRapoarteIndicator)'
	raiserror(@msgEroare,11,1)

end catch

