--***
create procedure wStergRapoarteIndicator @sesiune varchar(50), @parXML xml
as
declare @codInd varchar(20), @numeraport varchar(100), @mesajeroare varchar(100)

begin try
	select	@codInd = @parXML.value('(/row/@cod)[1]','varchar(20)'),
			@numeraport = @parXML.value('(/row/row/@numeraport)[1]','varchar(100)')

	--select @codind, @numeraport
	delete from rapIndicatori where Cod_indicator = @codInd and Nume_raport=@numeraport

end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)	
end catch
