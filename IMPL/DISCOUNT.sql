

Create trigger [dbo].[ModifContStoc] on [dbo].[pozdoc] instead of --INSERT as

--INSERT pozdoc
(Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta,
Pret_de_stoc, Adaos, Pret_vanzare, Pret_cu_amanuntul, TVA_deductibil,
Cota_TVA, Utilizator, Data_operarii, Ora_operarii, Cod_intrare,
Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,
Tip_miscare, Locatie, Data_expirarii, Numar_pozitie, Loc_de_munca, Comanda,
Barcod, Cont_intermediar, Cont_venituri, Discount, Tert, Factura,
Gestiune_primitoare, Numar_DVI, Stare, Grupa, Cont_factura, Valuta, Curs,
Data_facturii, Data_scadentei, Procent_vama, Suprataxe_vama,
Accize_cumparare, Accize_datorate, Contract, Jurnal)


select 
Subunitate, Tip, Numar, Cod, Data, Gestiune, Cantitate, Pret_valuta,
Pret_de_stoc, Adaos, Pret_vanzare, 
(case when cont_factura='41112' then Pret_vanzare else Pret_cu_amanuntul
end), 
(case when cont_factura='41112' then 0 else TVA_deductibil end), 
(case when cont_factura='41112' then 0 else cota_tva end), Utilizator,
Data_operarii, Ora_operarii, Cod_intrare, 
Cont_de_stoc, Cont_corespondent, TVA_neexigibil, Pret_amanunt_predator,
Tip_miscare, Locatie, Data_expirarii,
 Numar_pozitie, Loc_de_munca, Comanda, Barcod, Cont_intermediar,
(case when cont_factura='41112' and cont_venituri='7011' and tip='AP' then
'7012'
      when cont_factura='41112' and cont_venituri='7071' and tip='AP' then
'7072' else Cont_venituri end),
 Discount, Tert, Factura, Gestiune_primitoare, Numar_DVI, Stare, Grupa,
Cont_factura, Valuta, Curs, Data_facturii, Data_scadentei, Procent_vama,
Suprataxe_vama, Accize_cumparare, Accize_datorate, Contract, Jurnal

from --INSERTed 
go

CREATE trigger dbo.[yso_insupd_pozcon] on [dbo].[pozcon] instead of --INSERT, --UPDATE as

--DELETE pozcon
FROM pozcon p INNER JOIN --DELETEd d on p.Subunitate=d.Subunitate and p.Tip=d.Tip and p.Data=d.Data and p.Tert=d.Tert and p.Contract=d.Contract 
	and p.Cod=d.Cod and p.Numar_pozitie=d.Numar_pozitie

--INSERT INTO [TET].[dbo].[pozcon]
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
	,i.Cant_aprobata --Cant_aprobata	float	no	8
	,i.Cant_realizata --Cant_realizata	float	no	8
	,i.Valuta --Valuta	char	no	3
	,i.Cota_TVA --Cota_TVA	real	no	4
	,CASE 
		WHEN i.subunitate NOT LIKE 'EXPAND%' AND ABS(ISNULL(p.Pret,0))>0.001
			--THEN i.Cantitate*((i.Pret*(1-ISNULL(i.Discount,0)/100-0.99*ISNULL(p.Pret,0)/100))*i.Cota_TVA/100)
			THEN i.Cantitate*(((i.Pret*(1-ISNULL(i.Discount,0)/100))*(1-ISNULL(p.Pret,0)/100))*i.Cota_TVA/100)
		ELSE i.Suma_TVA END--Suma_TVA	float	no	8
	,i.Mod_de_plata --Mod_de_plata	char	no	8
	,i.UM --UM	char	no	1
	,i.Zi_scadenta_din_luna --Zi_scadenta_din_luna	smallint	no	2
	,i.Explicatii --Explicatii	char	no	200
	,i.Numar_pozitie --Numar_pozitie	int	no	4
	,i.Utilizator --Utilizator	char	no	10
	,i.Data_operarii --Data_operarii	datetime	no	8
	,i.Ora_operarii --Ora_operarii	char	no	6
FROM --INSERTed i
	LEFT JOIN pozcon p ON p.Subunitate= 'EXPAND' AND p.tip= i.Tip AND p.Contract=i.Contract AND p.Tert= i.Tert AND p.Data= i.Data 
		and p.Cod= i.Cod and p.Numar_pozitie= i.Numar_pozitie

	GO
	

--pretvanzdisc1=5580
--pretvanzdisc2=5468.4
--PRETVANZ=(PRET*(1-DISC/100))
--SUMATVA=CANT*PRETVANZ*COTATVA/100
--sumaTVA=CANT*(PRET*(1-DISC/100))*COTATVA/100
select * from pozcon where Contract='TEST' AND UTILIZATOR='OVIDIU'

select 10*((120*(1-2/100))*i.Cota_TVA/100)
select ((500*(1-10/100))*24/100)

SELECT (500*(1-10/100))
NOMENCL
select 10*(((500*(1-ISNULL(10,0)/100))*(1-ISNULL(2,0)/100))*24/100)

Pret*(1-Discount/100)*(1-discdublu/100)
pret*(1-dd/100-d/100+d*dd/10000)
pret*(10000-100*dd-100*d+d*dd)/10000
pret*(10000-100*d-99*dd)/10000
pret*(100-d-0.99*dd)/100
pret*(1-d/100-0.99*dd/100)
pret*(1-d/100-dd/100)?nu cred ca asta ar fi ca si un discount adunat ex *(0.1+0.02)
pret*(1-(d-0.99*dd)/100)

sau

PRET_VANZARE=Round (pret_valuta*(1-disc/100)*IF (curs=0,1,curs),12,5)
adaos=IF (pret_stoc>0,(pret_vanzare/pret_stoc-1)*100,0)
suma_TVA=Round (cant*pret_vanzare*cota_tva/100,12,IF (rotunjirivalAP,nrzecimaleAP,2))
pret_cu_amanuntul=Round (pret_vanzare*(1+cota_tva/100),12,5)
