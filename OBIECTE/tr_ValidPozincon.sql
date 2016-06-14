drop trigger tr_ValidPozincon 
go
--***
create  trigger tr_ValidPozincon on pozincon for insert,update NOT FOR REPLICATION as
DECLARE @nrRanduri int,@mesaj varchar(255)
SET @nrRanduri=@@ROWCOUNT
IF @nrRanduri=0 
	RETURN

begin try
	Declare @lDrepModif int
	set @lDrepModif=0
	if left(cast(CONTEXT_INFO() as varchar),17)='specificebugetari'
	
	set @lDrepModif=1
	declare @userASiS varchar(50), @validlmstrict int 
	set @userASiS=dbo.fIaUtilizator(null)
	
	---->>>>>validare loc de munca<<<<<-----
	set @validlmstrict =isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru = 'CENTPROF'),0)
	if @validlmstrict=1 and exists(select 1 from inserted where loc_de_munca='' and inserted.subunitate<>'intrastat')
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Loc de munca necompletat!',16,1)
	if exists(select 1 from inserted where loc_de_munca<>'') 
		and not exists (select cod from inserted inner join lm on lm.cod=inserted.loc_de_munca)
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Loc de munca inexistent in catalog!',16,1)

	--Daca are loc de munca pus ca si proprietate se cauta in al doilea select 
	if exists (select * from proprietati pr where pr.Tip='UTILIZATOR' and pr.Cod_proprietate='LOCMUNCA' and pr.cod=@userASiS and valoare<>'') 
			and exists(select * from inserted where inserted.subunitate<>'intrastat' 
				and inserted.Loc_de_munca not in (select distinct lm.cod from proprietati p 	inner join lm on lm.cod like rtrim(p.valoare) + '%'
					where p.tip='UTILIZATOR' and p.cod=@userASiS and p.cod_proprietate='LOCMUNCA')and @lDrepModif=0 )
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Nu puteti opera pe acest loc de munca!',16,1)
	---->>>>>validare loc de munca<<<<<-----

	---->>>>>>validare camp comanda(comanda,indicator bugetar)<<<<----
	declare @validcomstrict int 
	set @validcomstrict =isnull((select max(val_numerica) from par where tip_parametru='GE' and parametru = 'COMANDA'),0)
	
	--validare comanda
	if @validcomstrict=1 and exists(select 1 from inserted where LEFT(inserted.comanda,20)='' 
		and inserted.subunitate<>'intrastat' and inserted.Tip_document<>'IC' )--notele de inchidere(IC) nu au comanda
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Comanda necompletata!',16,1)
	declare @xmlins xml=(select comtert= i.comanda  from inserted i for xml raw)
	if exists(select 1 from inserted where LEFT(inserted.comanda,20)<>'') 
		and not exists(select 1 from inserted inner join comenzi on comenzi.Comanda=LEFT(inserted.comanda,20)) 
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Comanda inexistenta in tabela de comenzi!',16,1)
	
	--validare indicator bugetar		
	if exists(select 1 from inserted where substring(inserted.comanda,21,20)<>'') 
		and not exists(select 1 from inserted inner join indbug on indbug.indbug=substring(inserted.comanda,21,20))
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Indicator bugetar inexistent in tabela de indicatori bugetari!',16,1)					
	---->>>>>>validare camp comanda(comanda,indicator bugetar)<<<<----
	
	
	---->>>>>>validare cont creditor<<<<<-----
	if exists (select 1 from inserted where((cont_creditor<>''and left(cont_creditor,1)<>'8' and left(cont_debitor,1)='8') 
		or (cont_creditor<>''and left(cont_creditor,1)<>'9' and left(cont_debitor,1)='9'))and inserted.subunitate<>'intrastat')
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Cont nepermis in coresp. cu cont clasa 8/9!',16,1)
	
	if exists (select 1 from inserted where cont_creditor='' and left(Cont_debitor,1)<>'8' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat')
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Cont creditor necompletat',16,1)
	
	if exists(select 1 from inserted where inserted.Cont_creditor<>'' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat') 
		and not exists(select 1 from inserted where inserted.Cont_creditor<>'' and inserted.cont_creditor =(select cont from conturi where cont=inserted.cont_creditor))-- and are_analitice='0'))
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Cont inexistent in planul de conturi!',16,1)
	
	if exists(select 1 from inserted where inserted.Cont_creditor<>'' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat') 
		and not exists(select 1 from inserted where inserted.cont_creditor =(select cont from conturi where cont=inserted.cont_creditor and are_analitice='0'))
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Contul introdus are analitice!',16,1)
	---->>>>>>validare cont creditor<<<<<----
			
		
	---->>>>>>validare cont debitor<<<<<----
	if exists(select 1 from inserted where ((cont_debitor<>'' and left(cont_debitor,1)<>'8'and left(cont_creditor,1)='8') 
		or  (cont_debitor<>'' and left(cont_debitor,1)<>'9'and left(cont_creditor,1)='9'))and inserted.subunitate<>'intrastat')
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Cont nepermis in coresp. cu cont clasa 8/9!',16,1)
	
	if exists (select 1 from inserted where cont_debitor=''and left(Cont_creditor,1)<>'8' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat')
		raiserror('Eroare operare (pozincon.tr_ValidPozincon): Cont debitor necompletat',16,1)
	
	if exists(select 1 from inserted where inserted.Cont_debitor<>'' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat') 
		and not exists(select 1 from inserted where inserted.Cont_debitor =(select cont from conturi where cont=inserted.Cont_debitor))-- and are_analitice='0'))
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Cont inexistent in planul de conturi!',16,1)
	
	if exists(select 1 from inserted where inserted.Cont_debitor<>'' and abs(suma)>=0.01 and inserted.subunitate<>'intrastat')
		and not exists(select 1 from inserted where inserted.cont_debitor =(select cont from conturi where cont=inserted.cont_debitor and are_analitice='0'))
		raiserror('Eroare operare (pozincon.tr_ValidPozincon):Contul introdus are analitice!',16,1)
	---->>>>>>validare cont debitor<<<<<----	
    
end try
begin catch
	--Daca exista erori
	ROLLBACK TRANSACTION
	set @mesaj = ERROR_MESSAGE()
	raiserror(@mesaj, 11, 1)
	RETURN
end catch
