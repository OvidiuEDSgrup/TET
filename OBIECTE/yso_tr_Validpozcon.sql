--***
if exists (select * from sysobjects where name ='yso_tr_validPozcon' and xtype='TR')
	drop trigger yso_tr_validPozcon

go
--***
create  trigger yso_tr_validPozcon on pozcon for insert,update NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN
begin try
	declare @insertedx xml =(select * from inserted for XML raw)

	IF UPDATE(cod)
	begin	
		declare @codnefolosit varchar(20)=(select top 1 rtrim(MAX(i.cod)) from inserted i inner join nomencl n on n.Cod=i.Cod 
											where i.Subunitate='1' and i.Tip in ('BK','FC') and n.Tip='U')	

		if @codnefolosit is not null
		begin
			raiserror('Codul %s este de tipul U-Nefolosit si nu poate fi operat!',11,1,@codnefolosit)
		end
		
		declare @codInexistent varchar(20)=(select top 1 rtrim(MAX(i.cod)) from inserted i left join nomencl n on n.Cod=i.Cod 
											where i.Subunitate='1' and i.Tip in ('BK','FC') and n.Cod is null)	

		if @codInexistent is not null
		begin
			raiserror('Codul %s este nu exista in Nomenclatorul de articole si nu poate fi operat!',11,1,@codInexistent)
		end
	end
--/*sp
	if update(discount) --Verificam discounturile
	begin
		declare @grupa varchar(13), @cod varchar(20), @discmax float, @msgerr varchar(250), @discount float
		select top 1 @cod=i.Cod, @discount=i.discount, @grupa=n.Grupa
		from inserted i 
			LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
			left join nomencl n on i.cod=n.cod 
		where i.Subunitate='1' and i.Tip='BK'
			and i.Discount> --/*dbo.valoare_minima(
			isnull((select top 1 CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end 
				from proprietati pr where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' 
					and n.Grupa like RTRIM(pr.Cod)+'%'
				order by pr.cod desc, pr.Valoare desc),0.001) --*/
			/*isnull((select top 1 p.Discount 				from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=c.Contract_coresp 
					AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' 
				order by p.Cod desc, p.Discount desc),0)*/
			
		if @cod is not null
		begin
			set @msgerr='Eroare operare (pozcon.yso_tr_ValidPozcon): Discountul de '+rtrim(convert(decimal(7,2),@discount))
				+' depaseste maximul '--de '+rtrim(convert(decimal(7,2),@discmax))
				+' admis pe grupa '+rtrim(@grupa)+' a articolului '+rtrim(@cod)+'!'
			raiserror(@msgerr,16,1)
		end
	end   		
--sp*/
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = '(yso_tr_validPozcon): '+ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
