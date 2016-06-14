--***
IF  EXISTS (SELECT * FROM sysobjects WHERE id = OBJECT_ID(N'yso_ins_pozcon') AND type='TR')
DROP trigger yso_ins_pozcon
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
go