--***
if exists (select * from sysobjects where name ='yso_tr_validPozdoc' and xtype='TR')
	drop trigger yso_tr_ValidPozdoc
go
--***
create  trigger yso_tr_ValidPozdoc on pozdoc for insert,update,delete NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN
-- Ghita, 27.04.2012: acest trigger ar trebui sa se raporteze doar la cataloage, nu si la tabelele sinteza (acestea se actualizeaza prin triggere si nu se stie daca inainte sau dupa verificare)
begin try	
	declare @grupa varchar(13), @cod varchar(20), @discmax float, @msgerr varchar(250), @discount float, @dencod varchar(250)

--/*sp
	if update(discount) --Verificam discounturile
	begin
		select top 1 @cod=i.Cod, @discount=i.discount, @grupa=n.Grupa, @dencod=n.Denumire
		from inserted i 
			LEFT JOIN doc d on d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data
			left join nomencl n on i.cod=n.cod 
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') 
			and i.Discount>--/*dbo.valoare_minima(
			isnull((select top 1 CASE ISNUMERIC(valoare) when 1 then CONVERT(float,replace(Valoare,',','')) else null end 
				from proprietati pr where pr.Valoare<>'' and pr.Cod<>'' and tip='GRUPA' and cod_proprietate='DISCMAX' 
					and n.Grupa like RTRIM(pr.Cod)+'%'
				order by pr.cod desc, pr.Valoare desc),0.001) --*/
			/*isnull((select top 1 p.Discount 
				from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=i.Contract
					AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' 
				order by p.Cod desc, p.Discount desc),0.00)*/
		
		if @cod is not null
		begin
			set @msgerr='Eroare operare (pozcon.yso_tr_ValidPozdoc): Discountul de '+rtrim(convert(decimal(7,2),@discount))
				+' depaseste maximul '--de '+rtrim(convert(decimal(7,2),@discmax))
				+' admis pe grupa '+rtrim(@grupa)+' a articolului ('+rtrim(@cod)+') '+RTRIM(@dencod)+'!'
			raiserror(@msgerr,16,1)
		end
	end   	
	
	if exists (select top (1) 1 from inserted i join nomencl n on n.Cod = i.Cod
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') and n.Tip not in ('R', 'S') and i.Cantitate <= -0.001)
	begin
		declare @potStorna tinyint
		set @potStorna = COALESCE((SELECT TOP (1) val_logica FROM par P WHERE P.Tip_parametru = 'CG' AND P.Parametru = 'POTSTORNA'), 1)
		/*
		select top 1 @cod=i.Cod, @discount=i.discount, @grupa=n.Grupa, @dencod=n.Denumire
		from inserted i 
			LEFT JOIN doc d on d.Subunitate=i.Subunitate and d.Tip=i.Tip and d.Numar=i.Numar and d.Data=i.Data
			left join nomencl n on i.cod=n.cod 
		where i.Subunitate='1' and i.Tip in ('AP','AC','AS') 
			and i.Cantitate <= -0.001
		*/
		if @potStorna = 0
		begin
			set @msgerr='Eroare operare: In acest moment NU se pot efectua stornari! Cereti autorizare de la supervizorul aplicatiei. (pozcon.yso_tr_ValidPozdoc)'
			raiserror(@msgerr,16,1)
		end
	end 	
--sp*/	
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
