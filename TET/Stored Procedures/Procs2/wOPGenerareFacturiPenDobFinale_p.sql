--***
create procedure wOPGenerareFacturiPenDobFinale_p @sesiune varchar(50), @parXML xml 
as
if exists (select 1 from sysobjects where [type]='P' and [name]='wOPGenerareFacturiPenDobFinale_pSP')
begin 
	declare @returnValue int -- variabila salveaza return value de la procedura specifica
	exec @returnValue = wOPGenerareFacturiPenDobFinale_pSP @sesiune, @parXML output
	return @returnValue
end  
begin try
declare @datajos datetime,@datasus datetime ,@mesaj varchar(500)

select 
	@datajos = isnull(@parXML.value('(/row/@datajos)[1]','datetime'),'1901-01-01'),
	@datasus = isnull(@parXML.value('(/row/@datasus)[1]','datetime'),'2099-01-01')

select convert(char(10),@datajos,101) data_penalizare_jos, convert(char(10),@datasus,101) data_penalizare_sus
for xml raw

end try	
begin catch
set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
