--***
create procedure [dbo].[wIauNrDocUA] @Tip char(2),@userASiS char(10),@lm char(9),@Numar int output
as
set @Numar=0
declare @NrDocFisc int, @fXML xml,@mesaj varchar(200)
		
set @fXML = '<row/>'
set @fXML.modify ('insert attribute tipmacheta {"DO"} into (/row)[1]')
set @fXML.modify ('insert attribute tip {sql:variable("@tip")} into (/row)[1]')
set @fXML.modify ('insert attribute utilizator {sql:variable("@userASiS")} into (/row)[1]')
set @fXML.modify ('insert attribute lm {sql:variable("@lm")} into (/row)[1]')

begin try	
	set @NrDocFisc=0	
	exec wIauNrDocFiscale @fXML, @NrDocFisc output
	if ISNULL(@NrDocFisc, 0)<>0
		Set @Numar=@NrDocFisc
	else
	begin
		Set @Numar=0
		raiserror(50005,10,1,'Generare nr doc nereusit!')
		return -1
	end
end try
begin catch	
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
	return -1
end catch
