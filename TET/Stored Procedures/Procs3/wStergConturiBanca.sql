create procedure  wStergConturiBanca @sesiune varchar(50), @parXML xml
as
begin try
	DECLARE @tert varchar(30),@cont_in_banca varchar(35),@banca varchar(20),@update bit,@numar_pozitie int,@sub varchar(9),@mesajeroare varchar(200)
    exec luare_date_par 'GE', 'SUBPRO', 0, 0, @sub output    
	select
         @numar_pozitie = isnull(@parXML.value('(/row/row/@numar_pozitie)[1]','int'),0),
		 @tert= isnull(@parXML.value('(/row/@tert)[1]','varchar(13)'),'')

	delete from ContBanci
	where Subunitate=@sub
		and tert=@tert
		and Numar_pozitie=@numar_pozitie 
end try
begin catch
	set @mesajeroare = ERROR_MESSAGE()
	raiserror(@mesajeroare, 11, 1)
end catch
