create procedure [dbo].[ProcGenAPBK] @Tip char(2), @Numar char(8), @Data datetime as 
begin 
DECLARE @contract char(20), @Subunitate char(9)
	,@Cantitate float, @Pret_de_stoc float, @Pret_valuta float, @Pret_vanzare float, @Adaos float
	,@Cota_TVA float,@TVA_deductibil float ,@Pret_cu_amanuntul float, @Valuta char(3), @Curs float
	,@DiscUnu float, @DiscDoi float, @DiscTrei float, @Discount float, @Pret_baza float, @nrDisc int 
	,@rotvalav int,@nrzec int, @RotPretV int,@SumaRotP float, @factura varchar(20),@tert varchar(20)
	
/*update pozdoc
set cantitate=cantitate-1
where tip=@tip and numar=@numar and data=@data*/
--print 'test'

select @contract=max([contract]),@factura=MAX(factura),@tert=MAX(tert) from pozdoc where Subunitate='1' and tip=@Tip and Numar=@Numar and data=@Data
exec luare_date_par @tip='GE', @par='SUBPRO', @val_l=0, @val_n=0, @val_a=@Subunitate output 
exec luare_date_par 'GE','ROTUNJ',@rotvalav output,@nrzec output,''
if @rotvalav=0 set @nrzec=2
exec luare_date_par 'GE','ROTPRET',@RotPretV output,@SumaRotP output,''

IF OBJECT_ID('tempdb..#pozcon') <> NULL
DROP TABLE	#pozcon

SELECT /*ROW_NUMBER() OVER( ORDER BY pc.subunitate, pc.tip, pc.Contract, pc.Cod) AS nrcrt, */
		pc.subunitate, pc.tip, pc.Contract, pc.Cod, 
		MAX(pc.Pret) AS Pret_baza, MAX(pc.Discount) AS DiscUnu, MAX(isnull(px.pret,0)) AS DiscDoi, MAX(isnull(px.cantitate,0)) AS DiscTrei, 
		MAX(pc.Valuta) AS Valuta, MAX(c.curs) AS Curs 
	INTO #pozcon FROM pozcon pc
	INNER JOIN con c ON c.Subunitate=pc.Subunitate and c.Tip=pc.Tip and c.Data=pc.Data and c.Tert=pc.Tert and c.Contract=pc.Contract
	LEFT JOIN pozcon px ON px.Subunitate='EXPAND' and px.Tip=pc.Tip and px.Data=pc.Data and px.Tert=pc.Tert and px.Contract=pc.Contract 
		and px.Cod=pc.Cod and px.Numar_pozitie=pc.Numar_pozitie 
	WHERE ABS(px.Pret+px.Cantitate)>0.001 
	GROUP BY pc.subunitate, pc.tip, pc.Contract, pc.Cod

CREATE UNIQUE NONCLUSTERED INDEX idxu ON #pozcon (subunitate, tip, Contract, Cod)

DECLARE csPozitiiAvizGenerat CURSOR FOR
SELECT Cantitate, Pret_de_stoc, Pret_valuta, Pret_vanzare, Adaos, Cota_TVA, TVA_deductibil, Pret_cu_amanuntul, DiscUnu
	,Pret_baza, DiscDoi, DiscTrei, pd.Valuta, pd.Curs
FROM pozdoc pd INNER JOIN #pozcon pc
	ON pd.Subunitate=pc.Subunitate and pc.Tip='BK' and pc.Contract=pd.Contract and pc.Cod=pd.Cod
WHERE pd.subunitate=@subunitate and pd.Tip=@Tip and pd.Numar=@Numar and pd.Data=@Data and pd.contract=@contract 

OPEN csPozitiiAvizGenerat
FETCH NEXT FROM csPozitiiAvizGenerat 
INTO @Cantitate, @Pret_de_stoc, @Pret_valuta, @Pret_vanzare, @Adaos, @Cota_TVA, @TVA_deductibil, @Pret_cu_amanuntul,@DiscUnu
	,@Pret_baza ,@DiscDoi, @DiscTrei, @Valuta, @Curs

WHILE @@FETCH_STATUS=0
BEGIN 
	IF ABS(@DiscUnu)+ABS(@DiscDoi)+ABS(@DiscTrei)>0.001
	BEGIN 
		SET @Pret_vanzare=Round(@Pret_valuta*(1-@DiscUnu/100)*(1-@DiscDoi/100)*(1-@DiscTrei/100)*CASE @Valuta WHEN '' THEN 1 ELSE 
							CASE @curs WHEN 0 THEN (SELECT TOP 1 curs FROM curs WHERE Valuta=@Valuta and data<=@Data ORDER BY Data DESC) 
							ELSE @curs END END,5)
		SET @Adaos=CASE @Pret_de_stoc WHEN 0 THEN 0 ELSE (@Pret_vanzare/@Pret_de_stoc -1)/100 END
		SET @TVA_deductibil=Round(@Cantitate*@Pret_vanzare*@Cota_TVA/100,@nrzec)
		SET @Pret_cu_amanuntul=Round(@Pret_vanzare*(1+@Cota_TVA/100),5)
		
		IF @RotPretV=1 SET @Pret_vanzare=dbo.rot_pret(@Pret_vanzare,@SumaRotP)
		
		UPDATE pozdoc
		SET Pret_valuta=@Pret_valuta, Pret_vanzare=@Pret_vanzare, Adaos=@Adaos, TVA_deductibil=@TVA_deductibil, 
			Pret_cu_amanuntul=@Pret_cu_amanuntul, Discount=@Discount
		WHERE CURRENT OF csPozitiiAvizGenerat
		
		SET @Pret_valuta=@Pret_valuta*(1-@DiscUnu/100)*(1-@DiscDoi/100)*(1-@DiscTrei/100)
	END
	FETCH NEXT FROM csPozitiiAvizGenerat
	INTO @Cantitate, @Pret_de_stoc, @Pret_valuta, @Pret_vanzare, @Adaos, @Cota_TVA, @TVA_deductibil, @Pret_cu_amanuntul,@DiscUnu
	,@Pret_baza ,@DiscDoi, @DiscTrei, @Valuta, @Curs
END
CLOSE csPozitiiAvizGenerat
DEALLOCATE csPozitiiAvizGenerat

delete facturi
where Subunitate='1' and tip=0x46 and tert=@tert and rtrim(factura)=''
end 
