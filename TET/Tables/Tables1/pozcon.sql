CREATE TABLE [dbo].[pozcon] (
    [Subunitate]           CHAR (9)   NOT NULL,
    [Tip]                  CHAR (2)   NOT NULL,
    [Contract]             CHAR (20)  NOT NULL,
    [Tert]                 CHAR (13)  NOT NULL,
    [Punct_livrare]        CHAR (13)  NOT NULL,
    [Data]                 DATETIME   NOT NULL,
    [Cod]                  CHAR (20)  NOT NULL,
    [Cantitate]            FLOAT (53) NOT NULL,
    [Pret]                 FLOAT (53) NOT NULL,
    [Pret_promotional]     FLOAT (53) NOT NULL,
    [Discount]             REAL       NOT NULL,
    [Termen]               DATETIME   NOT NULL,
    [Factura]              CHAR (20)  NOT NULL,
    [Cant_disponibila]     FLOAT (53) NOT NULL,
    [Cant_aprobata]        FLOAT (53) NOT NULL,
    [Cant_realizata]       FLOAT (53) NOT NULL,
    [Valuta]               CHAR (3)   NOT NULL,
    [Cota_TVA]             REAL       NOT NULL,
    [Suma_TVA]             FLOAT (53) NOT NULL,
    [Mod_de_plata]         CHAR (8)   NOT NULL,
    [UM]                   CHAR (1)   NOT NULL,
    [Zi_scadenta_din_luna] SMALLINT   NOT NULL,
    [Explicatii]           CHAR (200) NOT NULL,
    [Numar_pozitie]        INT        NOT NULL,
    [Utilizator]           CHAR (10)  NOT NULL,
    [Data_operarii]        DATETIME   NOT NULL,
    [Ora_operarii]         CHAR (6)   NOT NULL,
    [detalii]              XML        NULL,
    [idPozCon]             INT        IDENTITY (-1, -1) NOT NULL,
    PRIMARY KEY NONCLUSTERED ([idPozCon] ASC)
);


GO
CREATE UNIQUE CLUSTERED INDEX [Principal]
    ON [dbo].[pozcon]([Subunitate] ASC, [Tip] ASC, [Contract] ASC, [Data] ASC, [Tert] ASC, [Cod] ASC, [Numar_pozitie] ASC);


GO
CREATE NONCLUSTERED INDEX [Cod]
    ON [dbo].[pozcon]([Subunitate] ASC, [Tip] ASC, [Cod] ASC);


GO
--***
create trigger livrpozprod on pozcon for insert, update, delete not for replication as
begin
declare @cSb char(9), @cComProd char(20), @cCod char(20), @cComLivr char(20), @dLivr datetime, @cBenef char(13), 
	@nCantRealizata float, @nCantDescarc float, @nCantRealizBK float, @nCantLivrata float 
set @cSb=isnull((select max(val_alfanumerica) from par where tip_parametru='GE' and parametru='SUBPRO'), '')
--realizat BK=>livrat pozprod
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.subunitate, d.subunitate)=@cSb and isnull(i.tip, d.tip)='BK' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
while @@fetch_status = 0
begin
	declare tmppozprod cursor for
	select p.comanda, cantitate_realizata, cantitate_livrata
	from pozprod p
	left outer join comenzi c on c.subunitate=@cSb and c.comanda=p.comanda
	where comanda_livrare=@cComLivr and data_comenzii=@dLivr and p.beneficiar=@cBenef and p.cod=@cCod
	order by datediff(day, getdate(), isnull(c.data_lansarii, '12/31/2999')) * sign(@nCantRealizBK) 
	open tmppozprod
	fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
	while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
	begin
		if @nCantRealizBK > 0 
			set @nCantDescarc = (case when @nCantRealizata - @nCantLivrata < @nCantRealizBK then @nCantRealizata - @nCantLivrata else @nCantRealizBK end)
		else 
			set @nCantDescarc = (case when @nCantLivrata < abs(@nCantRealizBK) then (-1) * @nCantLivrata else @nCantRealizBK end)
		
		set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
		update pozprod set cantitate_livrata = cantitate_livrata + @nCantDescarc
		where comanda=@cComProd and cod=@cCod and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozprod into @cComProd, @nCantRealizata, @nCantLivrata
	end
	close tmppozprod
	deallocate tmppozprod

	fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
end
close tmpcmdaprov
deallocate tmpcmdaprov
end

GO
--***
create trigger delpozaprov on pozcon for delete not for replication as
begin
	delete from pozaprov where pozaprov.tip='BK' and exists (select 1 from deleted 
		where deleted.tip='BK' and deleted.contract=pozaprov.comanda_livrare and deleted.tert=pozaprov.beneficiar and deleted.data=pozaprov.data_comenzii and deleted.cod=pozaprov.cod)
	delete from pozaprov where exists (select 1 from deleted 
		where deleted.tip='FC' and deleted.contract=pozaprov.contract and deleted.tert=pozaprov.furnizor and deleted.data=pozaprov.data and deleted.cod=pozaprov.cod)
end

GO
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

GO
--***
CREATE trigger pozconsterg on pozcon for update, delete  NOT FOR REPLICATION as

declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert into sysspcon
	select host_id(),host_name (),@Aplicatia,getdate(),@Utilizator, 
	Data_operarii , Ora_operarii ,
	Subunitate , Tip , Contract , Tert , Punct_livrare , Data , Cod , Cantitate , Pret , 
	Pret_promotional , Discount , Termen , Factura , Cant_disponibila , Cant_aprobata , 
	Cant_realizata , Valuta , Cota_TVA , Suma_TVA , Mod_de_plata , UM , Zi_scadenta_din_luna ,
	Explicatii , Numar_pozitie , Utilizator
   from deleted

GO
--***
create trigger [dbo].yso_ins_pozcon on [dbo].pozcon instead of insert as

INSERT INTO [dbo].pozcon
	([Subunitate]
	,[Tip]
	,[Contract]
	,[Tert]
	,[Punct_livrare]
	,[Data]
	,[Cod]
	,[Cantitate]
	,[Pret]
	,[Pret_promotional]
	,[Discount]
	,[Termen]
	,[Factura]
	,[Cant_disponibila]
	,[Cant_aprobata]
	,[Cant_realizata]
	,[Valuta]
	,[Cota_TVA]
	,[Suma_TVA]
	,[Mod_de_plata]
	,[UM]
	,[Zi_scadenta_din_luna]
	,[Explicatii]
	,[Numar_pozitie]
	,[Utilizator]
	,[Data_operarii]
	,[Ora_operarii])
SELECT
	i.Subunitate  --Subunitate	char	no	9
	,i.Tip --Tip	char	no	2
	,i.Contract  --Contract	char	no	20
	,i.Tert --Tert	char	no	13
	,i.Punct_livrare --Punct_livrare	char	no	13
	,i.Data --Data	datetime	no	8
	,i.Cod --Cod	char	no	30
	,i.Cantitate --Cantitate	float	no	8
	,CASE WHEN c.dobanda in (8,9) 
	THEN (select top 1 pret_vanzare 
		 from preturi p  
		 where p.UM IN (8,9) and tip_pret in ('2', '9') and (tip_pret<>'2' or data_superioara<='12/31/2997')  
		 and cod_produs=i.cod and p.UM=c.dobanda and i.data between data_inferioara and data_superioara 
		 order by (case when tip_pret='9' then 0 else 1 end),pret_vanzare, tip_pret DESC, data_inferioara desc, data_superioara)  
	ELSE i.Pret END --Pret	float	no	8
	,i.Pret_promotional --Pret_promotional	float	no	8
	,coalesce(nullif(i.Discount,0)
		,(select top 1 p.Discount from pozcon p where p.Subunitate= '1' AND p.tip= 'BF' AND p.Contract=c.Contract_coresp 
		AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Discount desc),0) 
		--Discount	real	no	4
	,i.Termen --Termen	datetime	no	8
	,i.Factura --Factura	char	no	9
	,i.Cant_disponibila --Cant_disponibila	float	no	8
	,i.Cant_aprobata --Cant_aprobata	float	no	8
	,i.Cant_realizata --Cant_realizata	float	no	8
	,i.Valuta --Valuta	char	no	3
	,i.Cota_TVA --Cota_TVA	real	no	4
/*	,CASE WHEN i.Tip='BK' and i.subunitate NOT LIKE 'EXPAND%' THEN 
		CASE WHEN ABS(ISNULL(p.Pret,0)+ISNULL(p.Cantitate,0))>=0.001
			--THEN i.Cantitate*((i.Pret*(1-ISNULL(i.Discount,0)/100-0.99*ISNULL(p.Pret,0)/100))*i.Cota_TVA/100)
			THEN i.Cantitate*((((i.Pret*(1-i.Discount/100))*(1-ISNULL(p.Pret,0)/100))*(1-ISNULL(p.Cantitate,0)/100))*i.Cota_TVA/100)
		ELSE i.Suma_TVA END ELSE */,i.Suma_TVA --Suma_TVA	float	no	8
	,i.Mod_de_plata --Mod_de_plata	char	no	8
	,i.UM --UM	char	no	1
	,i.Zi_scadenta_din_luna --Zi_scadenta_din_luna	smallint	no	2
	,i.Explicatii --Explicatii	char	no	200
	,i.Numar_pozitie --Numar_pozitie	int	no	4
	,i.Utilizator --Utilizator	char	no	10
	,i.Data_operarii --Data_operarii	datetime	no	8
	,i.Ora_operarii --Ora_operarii	char	no	6
FROM inserted i 
	LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie
	LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
	left JOIN nomencl n ON  n.Cod=i.Cod
where i.Subunitate='1' and i.Tip='BK'


INSERT INTO [dbo].[pozcon]
	([Subunitate]
	,[Tip]
	,[Contract]
	,[Tert]
	,[Punct_livrare]
	,[Data]
	,[Cod]
	,[Cantitate]
	,[Pret]
	,[Pret_promotional]
	,[Discount]
	,[Termen]
	,[Factura]
	,[Cant_disponibila]
	,[Cant_aprobata]
	,[Cant_realizata]
	,[Valuta]
	,[Cota_TVA]
	,[Suma_TVA]
	,[Mod_de_plata]
	,[UM]
	,[Zi_scadenta_din_luna]
	,[Explicatii]
	,[Numar_pozitie]
	,[Utilizator]
	,[Data_operarii]
	,[Ora_operarii])
SELECT top 1
	'EXPAND'  --Subunitate	char	no	9
	,i.Tip --Tip	char	no	2
	,i.Contract  --Contract	char	no	20
	,i.Tert --Tert	char	no	13
	,i.Punct_livrare --Punct_livrare	char	no	13
	,i.Data --Data	datetime	no	8
	,i.Cod --Cod	char	no	30
	,isnull((select top 1 p.Cantitate from pozcon p where p.Subunitate= 'EXPAND' AND p.tip= 'BF' AND p.Contract=c.Contract_coresp 
		AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Cantitate desc),0) 
		--Cantitate	float	no	8
	,isnull((select top 1 p.Pret from pozcon p where p.Subunitate= 'EXPAND' AND p.tip= 'BF' AND p.Contract=c.Contract_coresp 
		AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' order by p.Cod desc, p.Pret desc),0)
		--Pret	float	no	8
	,i.Pret_promotional --Pret_promotional	float	no	8
	,0 --Discount	real	no	4
	,'' --Termen	datetime	no	8
	,'' --Factura	char	no	9
	,i.Cant_disponibila --Cant_disponibila	float	no	8
	,i.Cant_aprobata --Cant_aprobata	float	no	8
	,i.Cant_realizata --Cant_realizata	float	no	8
	,i.Valuta --Valuta	char	no	3
	,i.Cota_TVA --Cota_TVA	real	no	4
	,i.Suma_TVA--Suma_TVA	float	no	8
	,i.Mod_de_plata --Mod_de_plata	char	no	8
	,i.UM --UM	char	no	1
	,i.Zi_scadenta_din_luna --Zi_scadenta_din_luna	smallint	no	2
	,'' --Explicatii	char	no	200
	,i.Numar_pozitie --Numar_pozitie	int	no	4
	,i.Utilizator --Utilizator	char	no	10
	,i.Data_operarii --Data_operarii	datetime	no	8
	,i.Ora_operarii --Ora_operarii	char	no	6
FROM inserted i 
	left JOIN con c ON c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
	left JOIN nomencl n ON  n.Cod=i.Cod
WHERE i.Subunitate='1' and i.Tip='BK' 
	and exists (select top 1 p.Pret,p.Cantitate from pozcon p where p.Subunitate='EXPAND' AND p.tip='BF' AND p.Contract=c.Contract_coresp 
		AND p.Tert= i.Tert and p.Mod_de_plata='G' and n.Grupa like RTRIM(p.Cod)+'%' and p.Pret+p.Cantitate>0.001 order by p.Cod desc,p.Cantitate desc)
	and not exists (select 1 from pozcon p where p.Subunitate='EXPAND' AND p.tip=i.Tip AND p.Contract=i.Contract AND p.Tert=i.Tert 
		AND p.Data= i.Data and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie)

INSERT INTO [dbo].pozcon
	([Subunitate]
	,[Tip]
	,[Contract]
	,[Tert]
	,[Punct_livrare]
	,[Data]
	,[Cod]
	,[Cantitate]
	,[Pret]
	,[Pret_promotional]
	,[Discount]
	,[Termen]
	,[Factura]
	,[Cant_disponibila]
	,[Cant_aprobata]
	,[Cant_realizata]
	,[Valuta]
	,[Cota_TVA]
	,[Suma_TVA]
	,[Mod_de_plata]
	,[UM]
	,[Zi_scadenta_din_luna]
	,[Explicatii]
	,[Numar_pozitie]
	,[Utilizator]
	,[Data_operarii]
	,[Ora_operarii])
SELECT
	i.Subunitate  --Subunitate	char	no	9
	,i.Tip --Tip	char	no	2
	,i.Contract  --Contract	char	no	20
	,i.Tert --Tert	char	no	13
	,i.Punct_livrare --Punct_livrare	char	no	13
	,i.Data --Data	datetime	no	8
	,i.Cod --Cod	char	no	30
	,i.Cantitate --Cantitate	float	no	8
	,i.Pret --Pret	float	no	8
	,i.Pret_promotional --Pret_promotional	float	no	8
	,i.Discount	--Discount	real	no	4
	,i.Termen --Termen	datetime	no	8
	,i.Factura --Factura	char	no	9
	,i.Cant_disponibila --Cant_disponibila	float	no	8
	,i.Cant_aprobata --Cant_aprobata	float	no	8
	,i.Cant_realizata --Cant_realizata	float	no	8
	,i.Valuta --Valuta	char	no	3
	,i.Cota_TVA --Cota_TVA	real	no	4
	,i.Suma_TVA --Suma_TVA	float	no	8
	,i.Mod_de_plata --Mod_de_plata	char	no	8
	,i.UM --UM	char	no	1
	,i.Zi_scadenta_din_luna --Zi_scadenta_din_luna	smallint	no	2
	,i.Explicatii --Explicatii	char	no	200
	,i.Numar_pozitie --Numar_pozitie	int	no	4
	,i.Utilizator --Utilizator	char	no	10
	,i.Data_operarii --Data_operarii	datetime	no	8
	,i.Ora_operarii --Ora_operarii	char	no	6
FROM inserted i 
	--LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		--and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie
	--LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
	--left JOIN nomencl n ON  n.Cod=i.Cod
where NOT (i.Subunitate='1' and i.Tip='BK') and not exists 
	(select 1 from pozcon p where p.Subunitate=i.Subunitate AND p.tip=i.Tip AND p.Contract=i.Contract AND p.Tert=i.Tert 
		AND p.Data= i.Data and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie)

/*
declare @Utilizator char(10), @Aplicatia char(30)

set @Utilizator=dbo.fIauUtilizatorCurent()
select top 1 @Aplicatia=Aplicatia from sysunic where hostid=host_id() and data_iesirii is null order by data_intrarii desc
set @Aplicatia=left(isnull(@Aplicatia, APP_NAME()), 30)

insert yso_sysipcon
select top 1 host_id() [Host_id],host_name() [Host_name],@Aplicatia [Aplicatia],getdate() Data_stergerii,@Utilizator Stergator, 
	i.Data_operarii , i.Ora_operarii,
	(select top 1 d.Discount from pozcon d where d.Subunitate= '1' AND d.tip= 'BF' AND d.Contract=c.Contract_coresp 
		AND d.Tert= i.Tert and d.Mod_de_plata='G' and n.Grupa like RTRIM(d.Cod)+'%' order by d.Cod desc, d.Discount desc) as Disc_contr	
	,c.Contract_coresp
	,n.Grupa,
	i.Subunitate , i.Tip , i.Contract , i.Tert , i.Punct_livrare , i.Data , i.Cod , i.Cantitate , i.Pret ,
	i.Pret_promotional , i.Discount , i.Termen , i.Factura , i.Cant_disponibila , i.Cant_aprobata ,
	i.Cant_realizata , i.Valuta , i.Cota_TVA , i.Suma_TVA , i.Mod_de_plata , i.UM , i.Zi_scadenta_din_luna ,
	i.Explicatii , i.Numar_pozitie , i.Utilizator
FROM inserted i 
	LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie
	LEFT JOIN con c on c.Subunitate=i.Subunitate and c.Tip=i.Tip and c.Contract=i.Contract and c.Data=i.Data and c.Tert=i.Tert
	left JOIN nomencl n ON  n.Cod=i.Cod
where i.Subunitate='1' and i.Tip='BK'
--*/

GO
--***
create trigger delpozprod on pozcon for delete not for replication as
begin
	delete pozprod
	from pozprod, deleted 
	where deleted.tip='BK' and deleted.contract=pozprod.comanda_livrare and deleted.tert=pozprod.beneficiar 
		and deleted.data=pozprod.data_comenzii and deleted.cod=pozprod.cod
end

GO
--***
create trigger cantcon on pozcon for insert, update, delete not for replication as

-- sunt tratate doar aceste tipuri de document:
if exists (select 1 from inserted where tip in ('BK','FC', 'BP'))
	or exists (select 1 from deleted where tip in ('BK','FC', 'BP'))
begin
declare @csub char(9),@ccod char(20),@cmodpl char(8),@ctip char(2),@ccontr char(20),@ctert char(13),@semn int,@cant float, @dtermen datetime, @pozcon int, @contrcor char(20) 
begin try

-------------	din tabela par (parametri trimis de Magic):
	declare @rbfbkapr int, @stbktrans char(1), @stbkaprob char(1), @stbkfact char(1), @stbkreal char(1), 
			@defbkpart int,@pozsurse int
	set @rbfbkapr=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='RBFBKAPR'),0)
	set @stbktrans=isnull((select top 1 val_alfanumerica from par where tip_parametru='UC' and parametru='STBKTRANS'),'4')
	set @stbkaprob=isnull((select top 1 val_alfanumerica from par where tip_parametru='UC' and parametru='STBKAPROB'),'4')
	set @stbkfact=isnull((select top 1 val_alfanumerica from par where tip_parametru='UC' and parametru='STBKFACT'),'')
		declare @factbks3 int
		if (@stbkfact='')
		begin
			set @factbks3=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='FACTBKS3'),0)
			set @stbkfact=(case when @factbks3=1 then '3' else '1' end)
		end
	set @stbkreal=isnull((select top 1 val_alfanumerica from par where tip_parametru='UC' and parametru='STBKREAL'),'6')
	set @defbkpart=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='DEFBKPART'),0)
	set @pozsurse=isnull((select top 1 val_logica from par where tip_parametru='UC' and parametru='POZSURSE'),0)
-------------

	-- daca exista tabela StructCon se va cauta ramura(pozcon.pret_promotional) pe care se face update 
	declare @esteStruct int, @ramura float
	Set @esteStruct = (Select count(*) from sysobjects where type = 'U' and name = 'structcon')

	declare tmpCant cursor for
	select subunitate, tip,contract, tert, cod, mod_de_plata, (case when tip='BK' and @rbfbkapr=1 then cant_aprobata else cantitate end),1 as semn, termen,pret_promotional from inserted where tip in ('BK','FC', 'BP')
	union all
	select subunitate, tip,contract, tert, cod, mod_de_plata, (case when tip='BK' and @rbfbkapr=1 then cant_aprobata else cantitate end),-1 as semn, termen,pret_promotional from deleted where tip in ('BK','FC', 'BP')

	open tmpCant
	fetch next from tmpCant into @csub,@ctip,@ccontr,@ctert,@ccod,@cmodpl,@cant,@semn, @dtermen, @ramura
	declare @fetch int
	set @fetch=@@fetch_status 
	while @fetch=0 
	begin

		/* pt completarea cant realizate pe BF de pe BK */
		if @ctip='BK'
		begin
			set @contrcor = isnull((select max(contract_coresp) from con 
				where subunitate=@csub and tip='BK' and contract=@ccontr and tert=@ctert 
					and contract=@ccontr and tert=@ctert),'')
			
			-- mitz: nu fac modificari daca nu exista contract
			if 1=1 or len(rtrim(@contrcor))>0
			begin
				update pozcon set cant_realizata = cant_realizata + @cant * @semn
				where subunitate=@csub and tip='BF' and tert=@ctert and cod=@ccod and (@pozsurse=0 or mod_de_plata=@cmodpl) 
					and contract=@contrcor

				set @pozcon = (select max(numar_pozitie) 
				from pozcon 
				where subunitate=@csub and tip='BF' and tert=@ctert and cod=@ccod and (@pozsurse=0 or mod_de_plata=@cmodpl) 
					and contract=@contrcor)

				update termene set cant_realizata = cant_realizata + @cant * @semn
				where subunitate=@csub and tip='BF' and tert=@ctert and cod=(case when @pozsurse=0 then @ccod else ltrim(str(@pozcon)) end) 
					and termen=@dtermen	and contract=@contrcor
			end
		end

		/* pt completarea cant realizate pe FA de pe FC */
		if @ctip='FC'
			update pozcon set cant_realizata=cant_realizata + @cant * @semn
			where subunitate=@csub and tip='FA' and tert=@ctert and cod=@ccod
			and contract=isnull((select contract_coresp from con where tip='FC' and subunitate=@csub and contract=@ccontr and tert=@ctert),'')
			and (@esteStruct = 0 or (exists (select * from structcon s where s.subunitate = @csub and s.tip = @ctip and s.contract = @ccontr and s.tert = @ctert ) and pret_promotional = @ramura))

		-- starea transferat - doar daca gestiune_primitoare<>''
		if @ctip='BK'
		begin
			if (@defbkpart=1 or not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(pret_promotional)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(pret_promotional)<1) and punct_livrare<>''))
		and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (punct_livrare<>'' or abs(pret_promotional)>=0.001) and abs(cant_aprobata)>=0.001)
				update con set stare=@stbktrans where cod_dobanda<>'' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare in ('0', @stbkaprob, @stbkfact) )--or stare>=@stbkreal)

			-- TE pot genera si din stare Aprobat si din Facturabil -> o las in Facturabil...
			if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata-pret_promotional>=0.001 /*and punct_livrare <> ''*/)
				update con set stare=@stbkfact/*@stbkaprob*/ where cod_dobanda<>'' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare=@stbktrans
		end
		-- starea facturat (realizat) - doar daca tert<>''
		if @ctip='BK' or @ctip='BP'
		begin
			if not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(cant_realizata)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(cant_realizata)<1))
		and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and abs(cant_aprobata)>=0.001)
				update con set stare=@stbkreal where tert<>'' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare in ('0', @stbktrans, @stbkaprob, @stbkfact)

			if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (abs(cant_aprobata)-abs(cant_realizata)>=0.001 or abs(cant_aprobata)>=0.001 and sign(cant_aprobata)*sign(cant_realizata)<1)
			and (select max(stare) from con where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr)=@stbkreal)
				update con set stare=@stbkfact where tert<>'' and subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare=@stbkreal

			--update con set stare='0' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare in (@stbkaprob, @stbktrans, @stbkfact, @stbkreal) and not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
		end
		if @ctip='FC'
		begin
			if not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>cant_realizata)
				and exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
				update con set stare='6' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare in ('0', '1', '3', '4')

			if exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>cant_realizata)
				update con set stare='1' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and stare='6'

			--update con set stare='0' where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and (stare = '1' or stare = '3' or stare='4' or stare='6') and not exists (select 1 from pozcon where subunitate=@csub and tip=@ctip and tert=@ctert and contract=@ccontr and cant_aprobata>0)
		end
		fetch next from tmpCant into @csub,@ctip,@ccontr,@ctert,@ccod,@cmodpl,@cant,@semn, @dtermen, @ramura
		set @fetch=@@fetch_status 
	end
end try 
begin catch
	declare @msgeroare varchar(2000)
	set @msgeroare=ERROR_MESSAGE()+'(pozcon.trigger.cantCon)'
	raiserror(@msgeroare,11,1)
end catch

close tmpCant
deallocate tmpCant

end

GO
--***
create trigger cantpozaprov on pozcon for insert, update, delete not for replication as
begin
declare @cComAprov char(20), @dAprov datetime, @cFurn char(13), @cCod char(20), @nCantReceptie float, 
	@cTip char(2), @cComLivr char(20), @dLivr datetime, @cBenef char(13), @nCantComandata float, @nCantReceptionata float, 
	@nCantDescarc float, @nCantRealizBK float, @nCantRealizata float 
-- realizata FC => receptionata pozaprov
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.tip, d.tip)='FC' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
while @@fetch_status = 0
begin
	declare tmppozaprov cursor for
	select tip, comanda_livrare, data_comenzii, beneficiar, cant_comandata, cant_receptionata
	from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod
	order by (case tip when 'BK' then 1 when 'C' then 2 else 3 end) * sign(@nCantReceptie), 
		datediff(day, getdate(), data_comenzii) * sign(@nCantReceptie) 
	open tmppozaprov
	fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
	while @@fetch_status = 0 and abs(@nCantReceptie) >= 0.001
	begin
		if @nCantReceptie > 0 
			set @nCantDescarc = (case when @nCantComandata - @nCantReceptionata < @nCantReceptie then @nCantComandata - @nCantReceptionata else @nCantReceptie end)
		else 
			set @nCantDescarc = (case when @nCantReceptionata < abs(@nCantReceptie) then (-1) * @nCantReceptionata else @nCantReceptie end)
		
		set @nCantReceptie = @nCantReceptie - @nCantDescarc
		update pozaprov set cant_receptionata = cant_receptionata + @nCantDescarc
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip=@cTip and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozaprov into @cTip, @cComLivr, @dLivr, @cBenef, @nCantComandata, @nCantReceptionata
	end
	close tmppozaprov
	deallocate tmppozaprov
	if (@nCantReceptie >= 0.001) begin -- s-a receptionat mai mult decat s-a comandat
		if exists (select 1 from pozaprov where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='' and comanda_livrare='') 
			update pozaprov set cant_receptionata = cant_receptionata + @nCantReceptie 
			where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod and tip='' and comanda_livrare=''
		else
			insert into pozaprov
			(Contract, Data, Furnizor, Cod, Comanda_livrare, Data_comenzii, Beneficiar, Cant_comandata, Cant_receptionata, Cant_realizata, Tip)
			select @cComAprov, @dAprov, @cFurn, @cCod, '', @dAprov, '', 0, @nCantReceptie, 0, '' 
	end
	fetch next from tmpcmdaprov into @cComAprov, @dAprov, @cFurn, @cCod, @nCantReceptie
end
close tmpcmdaprov
deallocate tmpcmdaprov

--realizat BK=>realizat pozaprov
declare tmpcmdaprov cursor for
select isnull(i.contract, d.contract) as cntr, isnull(i.data, d.data) as data, isnull(i.tert, d.tert) as tert, 
isnull(i.cod, d.cod) as cod, sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0)) as diferenta 
from inserted i full outer join deleted d on i.subunitate=d.subunitate and i.tip=d.tip and i.contract=d.contract 
	and i.data=d.data and i.tert=d.tert and i.cod=d.cod 
where isnull(i.tip, d.tip)='BK' 
group by isnull(i.contract, d.contract), isnull(i.data, d.data), isnull(i.tert, d.tert), isnull(i.cod, d.cod)
having abs(sum(isnull(i.cant_realizata, 0))-sum(isnull(d.cant_realizata, 0))) >= 0.001
open tmpcmdaprov
fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
while @@fetch_status = 0
begin
	declare tmppozaprov cursor for
	select contract, data, furnizor, cant_receptionata, cant_realizata
	from pozaprov where tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef and cod=@cCod
	order by datediff(day, getdate(), data) * sign(@nCantRealizBK) 
	open tmppozaprov
	fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
	while @@fetch_status = 0 and abs(@nCantRealizBK) >= 0.001
	begin
		if @nCantRealizBK > 0 
			set @nCantDescarc = (case when @nCantReceptionata - @nCantRealizata < @nCantRealizBK then @nCantReceptionata - @nCantRealizata else @nCantRealizBK end)
		else 
			set @nCantDescarc = (case when @nCantRealizata < abs(@nCantRealizBK) then (-1) * @nCantRealizata else @nCantRealizBK end)
		
		set @nCantRealizBK = @nCantRealizBK - @nCantDescarc
		update pozaprov set cant_realizata = cant_realizata + @nCantDescarc
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 
		fetch next from tmppozaprov into @cComAprov, @dAprov, @cFurn, @nCantReceptionata, @nCantRealizata
	end
	close tmppozaprov
	deallocate tmppozaprov
	if (@nCantRealizBK >= 0.001 and RTrim(@cComAprov) <> '') -- s-a realizat mai mult decat s-a receptionat, am pozitie pe BK in pozaprov
		update pozaprov set cant_realizata = cant_realizata + @nCantRealizBK 
		where contract=@cComAprov and data=@dAprov and furnizor=@cFurn and cod=@cCod 
			and tip='BK' and comanda_livrare=@cComLivr and data_comenzii=@dLivr and beneficiar=@cBenef 

	fetch next from tmpcmdaprov into @cComLivr, @dLivr, @cBenef, @cCod, @nCantRealizBK
end
close tmpcmdaprov
deallocate tmpcmdaprov
end

GO

--***
CREATE trigger [dbo].[yso_delpozconexp] on [dbo].[pozcon] for delete not for replication as
begin
	delete from pozcon where pozcon.Subunitate  like 'EXPAND%' and exists (select 1 from deleted 
		where deleted.tip=pozcon.tip and deleted.contract=pozcon.contract and deleted.tert=pozcon.tert and deleted.data=pozcon.data and deleted.cod=pozcon.cod and deleted.Numar_pozitie=pozcon.Numar_pozitie)

end
GO
--***
create trigger yso_tr_actualizeazaPozContracte on pozcon after insert,update,delete
as
--if TRIGGER_NESTLEVEL()>2
--	return
BEGIN TRY
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 
	
	set identity_insert pozcontracte on	
	merge into pozcontracte as ct
		using (select actiune=(case when i.idPozCon is null then 'DEL' when d.idPozCon is null then 'INS' else 'UPD' end)
					,c.idCon
					,Subunitate=isnull(i.Subunitate,d.Subunitate)
					,Tip=(case isnull(i.Tip,d.Tip) when 'BF' then 'CB' when 'BK' then 'CL' when 'FA' then 'CF' when 'FC' then 'CA' end)
					,Numar=isnull(i.Contract,d.Contract)
					,Tert=isnull(i.Tert,d.Tert),Punct_livrare=isnull(i.Punct_livrare,d.Punct_livrare),Data=isnull(i.Data,d.Data)
					,Cod=isnull(i.Cod,d.Cod),Cantitate=isnull(i.Cantitate,d.Cantitate),Pret=isnull(i.Pret,d.Pret),Pret_promotional=isnull(i.Pret_promotional,d.Pret_promotional)
					,Discount=isnull(i.Discount,d.Discount),Termen=isnull(i.Termen,d.Termen),Factura=isnull(i.Factura,d.Factura),Cant_disponibila=isnull(i.Cant_disponibila,d.Cant_disponibila)
					,Cant_aprobata=isnull(i.Cant_aprobata,d.Cant_aprobata),Cant_realizata=isnull(i.Cant_realizata,d.Cant_realizata),Valuta=isnull(i.Valuta,d.Valuta),Cota_TVA=isnull(i.Cota_TVA,d.Cota_TVA),Suma_TVA=isnull(i.Suma_TVA,d.Suma_TVA),Mod_de_plata=isnull(i.Mod_de_plata,d.Mod_de_plata),UM=isnull(i.UM,d.UM),Zi_scadenta_din_luna=isnull(i.Zi_scadenta_din_luna,d.Zi_scadenta_din_luna),Explicatii=isnull(i.Explicatii,d.Explicatii),Numar_pozitie=isnull(i.Numar_pozitie,d.Numar_pozitie),Utilizator=isnull(i.Utilizator,d.Utilizator),Data_operarii=isnull(i.Data_operarii,d.Data_operarii),Ora_operarii=isnull(i.Ora_operarii,d.Ora_operarii),detalii=isnull(i.detalii,d.detalii)
					,idPozCon=isnull(i.idPozCon,d.idPozCon)
			from inserted i full join deleted d on d.idPozCon=i.idPozCon--d.subunitate=i.subunitate and d.tip=i.tip and d.contract=i.contract and d.tert=i.tert and d.Data=i.Data and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie
				inner join con c on c.subunitate=isnull(i.Subunitate,d.Subunitate) and c.Tip=isnull(i.Tip,d.Tip) and c.contract=isnull(i.Contract,d.Contract)
					and c.Tert=isnull(i.Tert,d.Tert) and c.Data=isnull(i.Data,d.Data)
				inner join contracte t on t.idcontract=c.idcon
			where isnull(i.Tip,d.Tip) in ('BF','BK','FA','FC')
			) as cn 
			on cn.idPozCon=ct.idPozContract 
		when matched and cn.actiune='DEL' then 
			delete 
		when matched then 
			update SET idContract=cn.idCon,cantitate=cn.cant_aprobata,pret=cn.pret,discount=cn.discount
				,termen=(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end)
				,periodicitate=null,explicatii=cn.explicatii,detalii=cn.detalii,cod_specific=null,idPozLansare=null,subtip=cn.tip
		--when not matched by target then
		when not matched by target then
			insert (idPozContract,idContract,cod,grupa,cantitate,pret,discount,termen,periodicitate,explicatii,detalii,cod_specific,idPozLansare,subtip)
			values (idPozCon,idCon,cod,cod,cant_aprobata,pret,discount,(case when cn.termen not in ('1900-01-01','1901-01-01',cn.data) then cn.termen end)
				,null,explicatii,detalii,null,null,cn.tip)
		;set identity_insert pozcontracte off
	
END TRY
BEGIN CATCH
	declare @mesaj varchar(600)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH 
