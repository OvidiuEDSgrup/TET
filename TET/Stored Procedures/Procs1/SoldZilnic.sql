--***
CREATE procedure SoldZilnic @cCodI VARCHAR(20),@cCont varchar(20),@pDataJ datetime, @pDataS datetime
as

BEGIN TRY
	DECLARE @dataInchidere121 DATETIME
	SELECT @dataInchidere121=CONVERT(DATETIME,Val_alfanumerica,102)
		FROM par WHERE Tip_parametru='CG' AND Parametru='DATAI121'
	IF @dataInchidere121 IS NULL
	begin
		SET @dataInchidere121='02/01/1901'
	END
	
	IF @dataInchidere121>@pDataJ AND EXISTS(SELECT * FROM expval WHERE Cod_indicator=@cCodI AND Data>@dataInchidere121)
		SET @pDataJ=@dataInchidere121
	
	DELETE FROM expval WHERE Cod_indicator=@cCodI AND data BETWEEN @pDataJ AND @pDataS

	DECLARE @sold FLOAT,@nF INT,@dData DATETIME,@sumad FLOAT,@sumac FLOAT,@DataCitita DATETIME,@data DATETIME
	select @sold=SUM(sold_debitor) FROM dbo.SolduriCont(@cCont,'', @pDataJ, '', '')
	SET @sold=ISNULL(@sold,0)


	DECLARE tmp CURSOR FOR 
	SELECT data,
		ISNULL(SUM((CASE WHEN Cont_debitor LIKE @cCont THEN Suma ELSE 0 END)),0) AS sumad,
		ISNULL(sum((CASE WHEN Cont_creditor LIKE @cCont THEN Suma ELSE 0 END)),0) AS sumac
		FROM dbo.pozincon
		WHERE (pozincon.Cont_debitor LIKE @cCont+'%' OR pozincon.Cont_creditor LIKE @cCont+'%')
		AND (dbo.pozincon.data BETWEEN @pDataJ AND @pDataS)
		GROUP BY data
		ORDER BY data
	OPEN tmp
	FETCH NEXT FROM tmp INTO @DataCitita,@sumad,@sumac
	SET @nF=@@FETCH_STATUS
	
	SET @data=@pDataJ
	

	WHILE @data<=@pDataS
	BEGIN
		WHILE @data<@DataCitita
		BEGIN
				PRINT @data
				INSERT INTO dbo.Expval(Cod_indicator ,Tip ,Data ,Element_1 ,Element_2 ,Element_3 ,Element_4 ,Element_5 ,Valoare)
				VALUES (@cCodI,'E',@data,@cCont,'','','','',@sold)
				
				SET @data=DATEADD(DAY,1,@data)
		end

		IF @nF=0
		BEGIN
			SET @sold=@sold+@sumad-@sumac
			INSERT INTO dbo.Expval(Cod_indicator ,Tip ,Data ,Element_1 ,Element_2 ,Element_3 ,Element_4 ,Element_5 ,Valoare)
			VALUES (@cCodI,'E',@data,@cCont,'','','','',@sold)			

			SET @data=DATEADD(DAY,1,@data)
			FETCH NEXT FROM tmp INTO @DataCitita,@sumad,@sumac
			SET @nF=@@FETCH_STATUS
		END
		ELSE --nu mai am ce citi din tablea
		BEGIN
			SET @data=DATEADD(day,1,@pDataS)
		END
			
	END
	CLOSE tmp
	DEALLOCATE tmp
	
end try
begin catch
	declare @eroare varchar(1000)
	set @eroare='SoldZilnic (linia '+ convert(varchar(20),ERROR_LINE())+'):'+char(10)+
				rtrim(ERROR_MESSAGE())
	raiserror(@eroare,16,1)
end catch
