--***
create procedure wScriuProdNeterminata @sesiune varchar(50),@parXML xml
as 
declare @mesaj varchar(254), @data datetime, @lm varchar(20), @comanda varchar(20),
	@procent float, @cantitate float, @valoare float, @update int, @operatiune varchar(100),
	@datajos datetime, @datasus datetime

select @data=isnull(@parXML.value('(/*/@data)[1]','datetime'),''),
	@operatiune=isnull(@parXML.value('(/*/@operatiune)[1]','varchar(100)'),''),
	@comanda=isnull(@parXML.value('(/*/@comanda)[1]','varchar(20)'),''),
	@lm=isnull(@parXML.value('(/*/@lm)[1]','varchar(20)'),''),
	@procent=isnull(@parXML.value('(/*/@procent)[1]','float'),0),
	@cantitate=isnull(@parXML.value('(/*/@cantitate)[1]','float'),0),
	@valoare=isnull(@parXML.value('(/*/@valoare)[1]','float'),0),
	@datajos=@parxml.value('(row/@datajos)[1]','datetime'),
	@datasus=@parxml.value('(row/@datasus)[1]','datetime')

	if @operatiune='modificare'
		set @update=1
	else	
		set @update=0

begin try
	if @lm='' 
		raiserror('Introduceti un loc de munca!',11,1)

	if @comanda='' 
		raiserror('Introduceti o comanda!',11,1)

	if @update=1 
	begin  
		update nete set procent=@procent, cantitate=@cantitate, valoare=@valoare
		where data=@data and loc_de_munca=@lm and comanda=@comanda
	end
	else   
	begin 
		if exists(select 1 from nete where data=@data and loc_de_munca=@lm and comanda=@comanda)
			raiserror ('Productia neterminata pentru acest loc de munca si comanda a fost deja introdusa!',11,1)
		else			 
			insert into nete (Data, Loc_de_munca, Comanda, Procent, Cantitate, Valoare)  
			values (@data,@lm,@comanda,@procent,@cantitate,@valoare)  
	end  

	if @update=0
	begin
		SELECT 'Adaugare productie neterminata'  nume, 'NET' codmeniu, 'D' tipmacheta, 'NE'  tip, 'AD' subtip, 'O' fel
		FOR XML RAW('deschideMacheta'), ROOT('Mesaje')
	end
	
end try
begin catch
	set @mesaj = '(wScriuProdNeterminata:) '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)	
end catch
  /*
  sp_help nete
  select * from nete
  */ 
