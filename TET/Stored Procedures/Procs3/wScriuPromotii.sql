
create procedure  wScriuPromotii @sesiune varchar(30), @parXML XML
as
begin try
	declare
		@idPromotie int, @denumire varchar(200), @cod varchar(20), @dela datetime, @panala datetime, @cantitate float, @cantitate_promo float

	select
		@idPromotie = @ParXML.value('(/row/@idPromotie)[1]','int'),
		@denumire = @ParXML.value('(/row/@denumire)[1]','varchar(100)'),
		@cod = @ParXML.value('(/row/@cod)[1]','varchar(20)'),
		@dela = @ParXML.value('(/row/@dela)[1]','datetime'),
		@panala = @ParXML.value('(/row/@panala)[1]','datetime'),
		@cantitate = @ParXML.value('(/row/@cantitate)[1]','float'),
		@cantitate_promo = @ParXML.value('(/row/@cantitate_promo)[1]','float')


	IF ISNULL(@cantitate,0)=0 OR ISNULL(@cantitate_promo,0)=0
		raiserror ('Cantitatile trebuie sa fie pozitie pentru o promotie valida!',16,1)

	IF @panala<@dela
		raiserror('Date de sfarsit a promotiei trebuie sa fie dupa data de inceput!',16,1)

	IF NOT EXISTS (select 1 from nomencl where cod=@cod)
		raiserror('Codul articolului nu este valid!',16,1)

	IF @idPromotie IS NOT NULL
		raiserror('Nu este permisa modificarea unei promotii',16,1)

	insert into Promotii (denumire, cod, dela, panala, cantitate, cantitate_promo)
	select @denumire, @cod, @dela, @panala, @cantitate, @cantitate_promo
	
		
end try
begin catch
	declare @mesaj varchar(1000)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
end catch
