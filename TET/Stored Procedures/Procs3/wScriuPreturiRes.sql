--***
/* 
*/
CREATE procedure wScriuPreturiRes @sesiune varchar(50), @parXML XML
as
--Declarare variabile 
Declare @codresursa varchar(20), @tipresursa varchar(1), @denumire varchar(100),  @UM varchar(100), @pret float, @tert varchar(13),
        @datapret datetime,  @cautare varchar(30), @o_codresursa varchar(13)

		
Set @codresursa = rtrim(isnull(@parXML.value('(/row/@codresursa )[1]', 'varchar(20)'), ''))
Set @tipresursa = rtrim(isnull(@parXML.value('(/row/@tipresursa )[1]', 'varchar(1)'), ''))
Set @tert = rtrim(isnull(@parXML.value('(/row/row/@tert )[1]', 'varchar(13)'), ''))
Set @o_codresursa = rtrim(isnull(@parXML.value('(/row/row/@o_codresursa )[1]', 'varchar(13)'), ''))
Set @pret =isnull(@parXML.value('(/row/row/@pret)[1]', 'float'), '9999999')
Set @datapret =isnull(@parXML.value('(/row/row/@datapret)[1]', 'datetime'), '01/01/1901')

--Aici incepe partea de modificare
declare @modificare int
set @modificare=isnull(@parXML.value('(/row/@update)[1]', 'int'), 0)

if @modificare=1
begin
	update ppreturi
				set tip_resursa=@tipresursa, tert=@tert , pret=@pret , data_pretului=@datapret
				where tert=@tert and cod_resursa=@o_codresursa and tip_resursa=@tipresursa
				     
	return
end

--Aici incepe partea de adaugare
if not exists(select 1 from ppreturi where Tert=@tert and cod_resursa=@codresursa and tip_resursa=@tipresursa)
begin
		insert into ppreturi (Tip_resursa,Cod_resursa,Tert,UM_secundara,Coeficient_de_conversie,Pret,Data_pretului,CodFurn,Nr_zile_livrare,Cant_minima)
		values (@tipresursa, @codresursa, @tert,'','',@pret,@datapret,'','','')
end	
	else
begin
	raiserror('Eroare adaugare linie - pozitia este adaugata deja!',11,1)
end

	
