--***
create procedure wScriuDelegati @sesiune varchar(40),@Tert varchar(20),@Nume varchar(30),@serieci varchar(2),@numar varchar(10),@eliberat varchar(40)
as
declare @idmax char(13),@nr int
set @idmax=(select MAX(convert(int,identificator)) from infotert where Subunitate='C1' and tert=@tert and isnumeric(identificator)=1)
if isnumeric(@idmax)=1
begin
	set @nr=CONVERT(int,@idmax)+1
end
else
	set @nr=1
declare @expeditie bit
set @expeditie=ISNULL((select val_logica from par where Tip_parametru='AR' and Parametru='EXPEDITIE'),0)
if @expeditie=1
	set @Tert=''
	
begin try
if ltrim(rtrim(@Nume))<>''
	insert into infotert(
	Subunitate,Tert,Identificator,Descriere,Loc_munca,Pers_contact,Nume_delegat,Buletin,Eliberat,Mijloc_tp,Adresa2,Telefon_fax2,e_mail,Banca2,Cont_in_banca2,Banca3,Cont_in_banca3,Indicator,Grupa13,Sold_ben,Discount,Zile_inc,Observatii)
	values ('C1',upper(@tert),ltrim(str(@nr)),@Nume,'','','',@serieci+','+@numar,@eliberat,'','','','','','','','',0,'',0,0,0,'')
end try

begin catch
	declare @mesaj varchar(254)
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch   
/*begin catch
	set @nr=0
end catch
select @nr as raspuns for xml raw*/
