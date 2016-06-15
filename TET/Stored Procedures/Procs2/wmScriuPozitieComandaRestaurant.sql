--***

create procedure wmScriuPozitieComandaRestaurant @sesiune varchar(50), @parXML xml
as
if exists(select * from sysobjects where name='wmScriuPozitieComandaRestaurantSP' and type='P')
begin
	exec wmScriuPozitieComandaRestaurantSP @sesiune, @parXML 
	return -1
end

set transaction isolation level READ UNCOMMITTED
declare 
	@utilizator varchar(100), @data datetime, @cod varchar(20),@idComanda int,
	@cantitate decimal(12,3),@pret decimal(12,3),@discount decimal(12,3),@primaCon bit, @eroare varchar(4000),
	@input XML, @tertgen varchar(20), @idUnitate int

begin try 
	
	set @data=convert(char(10),GETDATE(),101)
	
	exec wIaUtilizator @sesiune=@sesiune, @utilizator=@utilizator output  
	exec luare_date_par 'UC','TERTGEN',0,0,@tertgen OUTPUT
	
	
	select	@idComanda=@parXML.value('(/row/@idComanda)[1]','varchar(20)'),
			@cod=@parXML.value('(/row/@cod)[1]','varchar(20)'),
			@cantitate=@parXML.value('(/row/@cantitate)[1]','decimal(12,3)'),
			@pret=@parXML.value('(/row/@pret)[1]','decimal(12,3)'),
			@discount=@parXML.value('(/row/@discount)[1]','decimal(12,3)'),
			@idUnitate=@parXML.value('(/row/@idUnitate)[1]','int')

	if @idComanda IS NULL
	begin
		exec luare_date_par 'UC','TERTGEN',0,0,@tertgen OUTPUT
		select 
			@idUnitate= @parXML.value('(/*/@idUnitate)[1]','int')
			
		insert into ComenziHRC(idUnitate, tert, data)
		select @idUnitate, @tertgen, GETDATE()
		select @idComanda=IDENT_CURRENT('ComenziHRC')

		select @idComanda idComanda for xml raw('atribute'), root('Mesaje')
	end

	if not exists ( select 1 from ct where idComanda=@idComanda and Cod=@cod )
		insert into Ct(idComanda, cod, cantitate, pret, discount)
		SELECT @idComanda, @cod, @cantitate, @pret, @discount
	else
	begin 
		if @cantitate=0 -- cantitate=0 => sterg cod de pe comanda
			delete from ct where idComanda=@idComanda and cod=@cod
			
		
		update ct 
			set Cantitate=@cantitate,
			pret=(case when @pret is null then pret else @pret end), 
			discount=(case when @discount is null then discount else @discount end)
		where idComanda=@idComanda and cod=@cod
	end

	if isnull(@parXML.value('(/row/@faradetalii)[1]','int'),0)=0
		select 'back(1)' as actiune 
		for xml raw,Root('Mesaje')

end try
begin catch
	set @eroare=ERROR_MESSAGE()+'(wmScriuPozitieComandaRestaurant)'
	raiserror(@eroare,11,1)
end catch
