--***
CREATE procedure wStergPozplin @sesiune varchar(50), @parXML xml
as

if exists (select * from sysobjects where name ='wStergPlin') 
begin
	exec wStergPlin @sesiune, @parXML OUTPUT
end
else /*Incepe Vechiul wStergPozplin de baza*/
begin
	declare @iDoc int, @eroare xml ,@mesaj varchar(200)

	begin try
	

	if exists (select 1 from sysobjects where [type]='P' and [name]='wStergPozplinSP')
		exec wStergPozplinSP @sesiune, @parXML output

	exec sp_xml_preparedocument @iDoc output, @parXML

	delete pozplin
	from pozplin p, 
	OPENXML (@iDoc, '/row')
		WITH
		(
			subunitate char(9) '@subunitate', 
			cont varchar(40) '@cont', 
			data datetime '@data', 
			numar char(10) '@numar', 
			numar_pozitie int '@numarpozitie' 
		) as dx
	where p.subunitate = dx.subunitate and p.cont = dx.cont and p.data = dx.data and p.numar = dx.numar 
		and (dx.numar_pozitie is null or p.numar_pozitie = dx.numar_pozitie)


	exec sp_xml_removedocument @iDoc 

	end try
	begin catch
		-- ROLLBACK TRAN
		set @mesaj = '(wStergPozplin)'+ERROR_MESSAGE()
	end catch
end

exec wIaPozplin @sesiune=@sesiune, @parXML=@parXML

if LEN(@mesaj)>0
	raiserror(@mesaj, 11, 1)
