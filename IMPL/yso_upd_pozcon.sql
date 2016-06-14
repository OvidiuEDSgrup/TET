ALTER trigger dbo.yso_upd_pozcon on [dbo].[pozcon] instead of update as

DECLARE @tSQLLog TABLE 
	(language_event NVARCHAR(100)
	,parametri INT
	,comanda NVARCHAR(4000)
	,moment DATETIME DEFAULT CURRENT_TIMESTAMP)

INSERT INTO @tSQLLog (language_event, parametri, comanda)
EXEC('DBCC INPUTBUFFER(@@SPID) WITH NO_INFOMSGS;') AS LOGIN = 'sa';

DELETE pozcon
FROM pozcon p INNER JOIN deleted d on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Data=d.Data and p.Tert=d.Tert and p.Contract=d.Contract 
	and p.Cod=d.Cod and p.Numar_pozitie=d.Numar_pozitie
WHERE not exists (select 1 from inserted i where d.Subunitate=i.Subunitate and d.Tip=d.Tip and d.Contract=i.Contract and d.Data=i.Data and d.Tert=i.Tert
		and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie)

UPDATE pozcon
   SET [Subunitate] = i.Subunitate
      ,[Tip] = i.Tip
      ,[Contract] = i.Contract
      ,[Tert] = i.Tert
      ,[Punct_livrare] = i.Punct_livrare
      ,[Data] = i.Data
      ,[Cod] = i.Cod
      ,[Cantitate] = i.Cantitate
      ,[Pret] = i.Pret
      ,[Pret_promotional] = i.Pret_promotional
      ,[Discount] = i.Discount
      ,[Termen] = i.Termen
      ,[Factura] = i.Factura
      ,[Cant_disponibila] = i.Cant_disponibila
      ,[Cant_aprobata] = CASE WHEN 1=0 and
			ISNULL((SELECT program_name FROM sys.dm_exec_sessions WHERE session_id=@@SPID),'') LIKE '%unipaas%'
			and (SELECT TOP 1 comanda FROM @tSQLLog l) LIKE '%pozcomlivrtmp%' and
			UPDATE(Cant_aprobata) and i.Tip='BK' and i.subunitate NOT LIKE 'EXPAND%' 
			THEN ISNULL(i.Cant_realizata+ISNULL((SELECT SUM(Stoc) AS Cant_rezervata
				FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
				WHERE s.Subunitate=i.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=i.Contract and s.Cod=i.Cod
				AND par.Val_logica=1 AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0) 
				AND s.Stoc>0.001)*0 ,0)
			+(SELECT SUM(t.Cant_aprobata) FROM dbo.pozcomlivrtmp t 
				WHERE t.Utilizator=dbo.fIaUtilizator(null) and t.cod=i.Cod and t.Comanda=i.Contract and t.Tert=i.Tert)
			,i.Cant_aprobata) ELSE i.Cant_aprobata END --Cant_aprobata	float	no	8
      ,[Cant_realizata] = i.Cant_realizata
      ,[Valuta] = i.Valuta
      ,[Cota_TVA] = i.Cota_TVA
      ,[Suma_TVA] = CASE WHEN UPDATE(Suma_TVA) and i.Tip='BK' and i.subunitate NOT LIKE 'EXPAND%' THEN 
		CASE WHEN ABS(ISNULL(p.Pret,0)+ISNULL(p.Cantitate,0))>0.001
			--THEN i.Cantitate*((i.Pret*(1-ISNULL(i.Discount,0)/100-0.99*ISNULL(p.Pret,0)/100))*i.Cota_TVA/100)
		THEN i.Cantitate*((((i.Pret*(1-i.Discount/100))*(1-ISNULL(p.Pret,0)/100))*(1-ISNULL(p.Cantitate,0)/100))*i.Cota_TVA/100)
		ELSE i.Suma_TVA END ELSE i.Suma_TVA END--Suma_TVA	float	no	8
      ,[Mod_de_plata] = i.Mod_de_plata
      ,[UM] = i.UM
      ,[Zi_scadenta_din_luna] = i.Zi_scadenta_din_luna
      ,[Explicatii] = i.Explicatii
      ,[Numar_pozitie] = i.Numar_pozitie
      ,[Utilizator] = i.Utilizator
      ,[Data_operarii] = i.Data_operarii
      ,[Ora_operarii] = i.Ora_operarii
 FROM inserted i 
 INNER JOIN deleted d ON d.Subunitate=i.Subunitate and d.Tip=d.Tip and d.Contract=i.Contract and d.Data=i.Data and d.Tert=i.Tert
	and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie
 INNER JOIN pozcon ON pozcon.Subunitate= i.Subunitate AND pozcon.tip= i.Tip AND pozcon.Contract=i.Contract AND pozcon.Tert= i.Tert AND pozcon.Data= i.Data 
		and pozcon.Cod= i.Cod and pozcon.Numar_pozitie= i.Numar_pozitie
 LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie


INSERT INTO pozcon
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
	,i.Discount --Discount	real	no	4
	,i.Termen --Termen	datetime	no	8
	,i.Factura --Factura	char	no	9
	,i.Cant_disponibila --Cant_disponibila	float	no	8
	,CASE WHEN i.Tip='BK' and i.subunitate NOT LIKE 'EXPAND%' THEN ISNULL(i.Cant_realizata
	+ISNULL((SELECT SUM(Stoc) AS Cant_rezervata
		FROM dbo.stocuri s LEFT JOIN par ON par.Tip_parametru='GE' AND par.Parametru='REZSTOCBK'
		WHERE s.Subunitate=i.subunitate and s.Tip_gestiune NOT IN ('F','T') and s.Contract=i.Contract and s.Cod=i.Cod
		AND par.Val_logica=1 AND (CHARINDEX(';'+RTRIM(s.cod_gestiune)+';',';'+RTRIM(par.Val_alfanumerica)+';')>0) 
		AND s.Stoc>0.001) ,0)
	+(SELECT SUM(t.Cant_aprobata) FROM dbo.pozcomlivrtmp t 
		WHERE t.Utilizator=dbo.fIaUtilizator(null) and t.cod=i.Cod and t.Comanda=i.Contract and t.Tert=i.Tert)
	,i.Cant_aprobata) ELSE i.Cant_aprobata END --Cant_aprobata	float	no	8
	,i.Cant_realizata --Cant_realizata	float	no	8
	,i.Valuta --Valuta	char	no	3
	,i.Cota_TVA --Cota_TVA	real	no	4
	,CASE WHEN i.Tip='BK' and i.subunitate NOT LIKE 'EXPAND%' THEN 
		CASE WHEN ABS(ISNULL(p.Pret,0)+ISNULL(p.Cantitate,0))>0.001
			--THEN i.Cantitate*((i.Pret*(1-ISNULL(i.Discount,0)/100-0.99*ISNULL(p.Pret,0)/100))*i.Cota_TVA/100)
			THEN i.Cantitate*((((i.Pret*(1-i.Discount/100))*(1-ISNULL(p.Pret,0)/100))*(1-ISNULL(p.Cantitate,0)/100))*i.Cota_TVA/100)
		ELSE i.Suma_TVA END ELSE i.Suma_TVA END--Suma_TVA	float	no	8
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
WHERE not exists (select 1 from deleted d where d.Subunitate=i.Subunitate and d.Tip=d.Tip and d.Contract=i.Contract and d.Data=i.Data and d.Tert=i.Tert
		and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie)
	--LEFT JOIN deleted d ON d.Subunitate=i.Subunitate and d.Tip=d.Tip and d.Contract=i.Contract and d.Data=i.Data and d.Tert=i.Tert
	--	and d.Cod=i.Cod and d.Numar_pozitie=i.Numar_pozitie
	