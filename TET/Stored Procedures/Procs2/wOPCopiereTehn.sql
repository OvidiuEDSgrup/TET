
create procedure wOPCopiereTehn @sesiune varchar(50), @parXML XML      
as
begin try    
	declare    
	  @codNomencl varchar(20), @idTehn int, @codNomencl_vechi varchar(20),@struct xml,@denumire varchar(80),@tip varchar(20),
	  @id int, @codTehn varchar(20)

	 SELECT
		@idTehn=isnull(@parXML.value('(/parametri/@id)[1]', 'int'), 0),    
		@codNomencl=isnull(@parXML.value('(/parametri/@codNou)[1]', 'varchar(20)'), '')   , 
		@codNomencl_vechi=isnull(@parXML.value('(/parametri/@codNomencl)[1]', 'varchar(20)'), ''),    
		@denumire=isnull(@parXML.value('(/parametri/@descriereNou)[1]', 'varchar(80)'), ''),    
		@codTehn=isnull(@parXML.value('(/parametri/@codTehnNou)[1]', 'varchar(20)'), ''),    
		@tip= ISNULL(@parXML.value('(/parametri/@tip_tehn)[1]', 'varchar(1)'),'')    
      
	 if @codNomencl = ''       
		raiserror('Cod nomenclator invalid!',11,1)     
     
	 if @codNomencl_vechi = @codNomencl     
		raiserror('S-a introdus acelasi cod de nomenclator!',11,1)      
     
	 if @codTehn=''    
		SELECT @codTehn= @codNomencl    

	 if exists (select 1 from tehnologii where cod=@codNomencl )    
		 raiserror('Exista tehnologie pentru acest cod!',11,1)       
     
	 if @denumire=''    
		select @denumire=rtrim(denumire) from nomencl where cod=@codNomencl    
     
	 SELECT @tip=SUBSTRING(@tip,1,1)    
	 
	 INSERT INTO tehnologii (cod,Denumire,tip,Data_operarii,detalii,codNomencl)    
	 SELECT @codNomencl,@denumire,@tip,GETDATE(),null,@codNomencl
 
	 declare @tabId table (id int)
	 insert into pozTehnologii (tip,cod) 
	 output inserted.id into @tabId   
	 SELECT 'T',@codNomencl
	 SELECT @id=id from @tabId
    
	;WITH arbore (id, tip, cod, resursa, cantitate, idp, parinteTop, idNou, nivel, cantitate_i, ordine_o, detalii)
	AS (
		SELECT id, tip, cod, resursa, convert(float,1), idp, parinteTop, @id, 0, cantitate_i, ordine_o, detalii
		FROM poztehnologii
		WHERE id = @idTehn
				
		UNION ALL
				
		SELECT pTehn.id, pTehn.tip, pTehn.cod, pTehn.resursa, pTehn.cantitate, pTehn.idp, pTehn.
			parinteTop, 0, arb.nivel + 1, pTehn.cantitate_i, pTehn.ordine_o, pTehn.detalii
		FROM pozTehnologii pTehn
		INNER JOIN arbore arb
			ON pTehn.tip IN ('M', 'O', 'R','F')
				AND arb.id = pTehn.idp
		)
	SELECT *
	INTO #tmpTehnologie
	FROM arbore 
				
	DECLARE @nivel INT, @maiSuntRanduri INT

	SET @nivel = 1
	SET @maiSuntRanduri = 1

	CREATE TABLE #idNoi (id INT, cod VARCHAR(20), tip VARCHAR(20))

	WHILE @maiSuntRanduri > 0
	BEGIN
		INSERT INTO pozTehnologii (tip, cod, resursa, cantitate, idp, parinteTop, cantitate_i, ordine_o, detalii)
		OUTPUT inserted.ID, inserted.cod, inserted.tip
		INTO #idNoi(id, cod, tip)

		SELECT tp.tip, tp.cod, tp.resursa, tp.cantitate, tp2.idNou, @id, tp.cantitate_i, tp.ordine_o, tp.detalii
		FROM #tmpTehnologie tp
		LEFT JOIN #tmpTehnologie tp2 ON tp.idp = tp2.id
		WHERE tp.nivel = @nivel

		SET @maiSuntRanduri = @@ROWCOUNT

		UPDATE #tmpTehnologie
		SET idNou = #idNoi.id
		FROM #idNoi
		WHERE #idNoi.tip = #tmpTehnologie.tip
			AND #idNoi.cod = #tmpTehnologie.cod
			AND #tmpTehnologie.nivel = @nivel

		SELECT @nivel = @nivel + 1
	END

END TRY
BEGIN CATCH
	declare
		@mesaj varchar(500)
	set @mesaj=ERROR_MESSAGE() + ' ('+OBJECT_NAME(@@PROCID)+')'
	raiserror (@mesaj, 15, 1)
END CATCH
