--***
create procedure wStergImplementare @sesiune varchar(50), @parXML xml
as
begin
declare @mesajeroare varchar(100)
set @mesajeroare=''
begin try

declare @tipFisa varchar(2), @masina varchar(20), @data datetime, @fisa varchar(20),
	@numar_pozitie int, @element varchar(20), @idActivitati int, @xmlStergere xml
Select @tipFisa= @parXML.value('(/row/row/@tipFisa)[1]','varchar(2)'),
	@masina= @parXML.value('(/row/row/@masina)[1]','varchar(20)'),
	@data= @parXML.value('(/row/row/@data)[1]','varchar(20)'),
	@fisa= @parXML.value('(/row/row/@fisa)[1]','varchar(20)'),
	@numar_pozitie= @parXML.value('(/row/row/@numar_pozitie)[1]','int'),
	@element= @parXML.value('(/row/row/@element)[1]','varchar(20)')

set @xmlStergere=(select @tipFisa tip, @fisa fisa, @data data, @numar_pozitie numar_pozitie for xml raw)
if (@idActivitati is null)
	select @idActivitati=a.idActivitati from activitati a where a.Tip=@tipFisa and a.Fisa=@fisa and a.Data=@data
exec wStergPozActivitati @sesiune=@sesiune, @parXML=@xmlStergere
if not exists (select 1 from pozactivitati p where p.idActivitati=@idActivitati)
	delete from activitati where idActivitati=@idActivitati
/*	--> codul urmator a fost inlocuit de wStergPozActivitati de deasupra:
	if @mesajeroare=''
		begin
			delete from elemactivitati where tip=@tipFisa and fisa=@fisa and data=@data and numar_pozitie=@numar_pozitie and element in (@element,'OREBORD','KMBORD')
			delete from coefmasini where Coeficient in (@element,'OREBORD','KMBORD') and Masina=@masina
			if not exists (select 1 from elemactivitati where tip=@tipFisa and fisa=@fisa and data=@data and numar_pozitie=@numar_pozitie)
				delete from pozactivitati where tip=@tipFisa and fisa=@fisa and data=@data and numar_pozitie=@numar_pozitie
			if not exists (select 1 from pozactivitati where tip=@tipFisa and fisa=@fisa and data=@data)
				delete from activitati where tip=@tipFisa and fisa=@fisa and data=@data and masina=@masina
		end
	else 
		raiserror(@mesajeroare, 11, 1)
*/
end try

begin catch
	set @mesajeroare = ERROR_MESSAGE()+' (wStergImplementare '+convert(varchar(20),error_line())+')'
	raiserror(@mesajeroare, 11, 1)	
end catch
if len(@mesajeroare)>0 raiserror(@mesajeroare,16,1)
end
