--***
CREATE procedure wStergPozPrestariReceptii @sesiune varchar(50), @parXML xml
as
declare @subunitate char(9), @tip varchar(2), @numar varchar(20), @data datetime, @numar_pozitie int, @sb varchar(9), @utilizator varchar(20), @tipprestare varchar(2)

begin try
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator OUTPUT

	select @subunitate=ISNULL(@parXML.value('(/row/@subunitate)[1]', 'varchar(9)'), ''),
		@tip=ISNULL(@parXML.value('(/row/@tip)[1]', 'varchar(2)'), ''),
		@numar=ISNULL(@parXML.value('(/row/@numar)[1]', 'varchar(20)'), ''),
		@data=ISNULL(@parXML.value('(/row/@data)[1]', 'datetime'), '01/01/1901'),
		@numar_pozitie=ISNULL(@parXML.value('(/row/@numarpozitie)[1]', 'int'), ''),
		@tipprestare=ISNULL(@parXML.value('(/row/@tipprestare)[1]', 'varchar(2)'), '')

	exec luare_date_par 'GE', 'SUBPRO', 0, 0, @Sb output
	delete from pozdoc 
			where Subunitate=@Sb	
				and tip=@tipprestare
				and Numar=@Numar 
				and data=@Data 
				and Numar_pozitie=@Numar_pozitie	--stergere si pozitie din pozdoc
	
	-->apelare procedura de repartizare prestari pe receptie
	exec repartizarePrestariReceptii 'RM', @numar, @data			

	declare @docXMLIaPozdoc xml
	set @docXMLIaPozdoc = '<row subunitate="' + rtrim(@sb) + '" tip="' + rtrim('RM') + '" numar="' + 
		rtrim(@numar) + '" data="' + convert(char(10), @data, 101) +'"/>'
	exec wIaPozPrestariServicii @sesiune=@sesiune, @parXML=@docXMLIaPozdoc	

end try
begin catch
	declare @mesaj varchar(255)
	set @mesaj='(wStergPozPrestariReceptii): '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
end catch
