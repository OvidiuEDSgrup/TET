create procedure wOPDetaliiBeneficiar_p @sesiune varchar(50), @parXML xml
as 
declare @tert varchar(20),@dentert varchar(20), @iban varchar(30), @banca varchar(20), @denbanca varchar(50), @ataseaza int

select @tert=ISNULL(@parXML.value('(/row/row/@tert)[1]', 'varchar(20)'), '')
	 

select @iban=max(rtrim(gp.IBAN_beneficiar)), @banca=max(rtrim(gp.Banca_beneficiar)), @dentert=max(RTRIM(t.Denumire))
       from generareplati gp , terti t where gp.tert=t.tert and gp.Tert=@tert
	   

set @denbanca=(select denumire from bancibnr where cod=@banca)

select @dentert tert, @iban iban, @banca banca, @denbanca denbanca, @ataseaza ataseaza
for xml raw

	


