
create procedure wStergNcon @sesiune varchar(50), @parXML xml 
as
begin try
	
	declare 
		@cSub char(9), @tip varchar(2), @numar varchar(20), @data datetime
	
	exec luare_date_par 'GE', 'SUBPRO', 0,0,@cSub output 
	    
	select
		@tip=@parXML.value('(/*/@tip)[1]','varchar(2)'),
		@numar=@parXML.value('(/*/@numar)[1]','varchar(20)'),
		@data=@parXML.value('(/*/@data)[1]','datetime')

	IF EXISTS (select 1 from pozncon where Subunitate=@cSub and tip=@tip and data=@data and numar=@numar)
		raiserror('Documentul are pozitii', 16, 1)

	delete from nCon where Subunitate=@cSub and tip=@tip and numar=@numar and data=@data

end try
begin catch
	declare 
		@mesaj varchar(max)
	set @mesaj = ERROR_MESSAGE() + ' (wStergNcon)'
	raiserror(@mesaj, 11, 1)
end catch
