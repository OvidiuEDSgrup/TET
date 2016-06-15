--***

create FUNCTION [dbo].[Nr2Text]( @nr float )     
RETURNS VARCHAR(255)    
BEGIN    
		--pentru cazurile in care valoarea este negativa
		declare @va bit
		set @va=case when @nr<0 then 1 else 0 end
		set @nr=abs(@nr)
		
      DECLARE @text VARCHAR(255)    
      SET @text = ''    
      --<procesare intreg>    
      DECLARE @intreg VARCHAR(25),@i TINYINT    
      SET @intreg = convert(int,@nr)    
      SET @intreg = CASE WHEN LEN(@intreg) % 3 <> 0 THEN  REPLICATE('0',3-(LEN(@intreg) % 3))+@intreg ELSE @intreg END    
      SET @i = 1    
      WHILE @i < LEN(@intreg)    
      BEGIN    
            --<procesare parte>    
            DECLARE @parte CHAR(3),@nr_nivel TINYINT    
            SET @parte = SUBSTRING(@intreg,@i,3)    
            SET @nr_nivel = LEN(@intreg)/3 - @i/3 - 1    
            IF ( @parte = '000' )    
                  SET @text = @text + CASE WHEN @nr_nivel = 0 AND LEN(@intreg)=3 THEN 'Zero'ELSE '' END    
            ELSE    
                  IF ( @parte = '001' AND @nr_nivel <> 0 )    
                        SET @text = @text + (SELECT TOP 1 N.Text FROM Nivele N WHERE N.Cifra = @nr_nivel AND Nr & 1 = 1)    
                  ELSE    
                        BEGIN    
                              DECLARE @s SMALLINT, @z SMALLINT, @u SMALLINT    
                              SET @s = POWER(2,CAST(SUBSTRING(@parte,1,1) AS TINYINT))    
                              SET @z = POWER(2,CAST(SUBSTRING(@parte,2,1) AS TINYINT))    
                              SET @u = POWER(2,CAST(SUBSTRING(@parte,3,1) AS TINYINT))    
    
                              SET @text = @text + (SELECT TOP 1 S.Text + ISNULL(Z.Text,'') + COALESCE(SZU.Text,ISNULL(SZU.TextX,'')+U.Text) + N.Text AS Descriere    
                              FROM Sute AS S, SuteZeciUnitatilc AS SZU, Zeci AS Z, Unitatilc AS U, Nivele AS N    
                              WHERE S.Biti & @s = @s    
                                    AND SZU.BitiZeci & @z = @z    
                                    AND SZU.BitiUnitatilc & @u = @u    
                                    AND Z.Biti & @z = @z    
                                    AND U.Biti & @u = @u    
                                    AND N.Cifra = @nr_nivel    
                                    AND N.Nr & 2 = 2)    
                        END    
            --</procesare parte>    
            SET @i = @i + 3    
      END    
      --</procesare intreg>    
   --<zecimale>    
	declare @frac varchar(25)
	set @frac=@nr-convert(int,@nr) 
	set @frac=(case when len(@frac)<4 then @frac+'0' else @frac end)   
	if @frac='00' 
		set @frac='0.'+@frac

	if @frac<>'0.00'
	begin
		select @z=SUBSTRING(@frac,3,1), @u=SUBSTRING(@frac,4,1)
		if @z='1'
			select @frac=text
			from SuteZeciUnitatilc SZU
			where SZU.BitiZeci = 2
			AND SZU.BitiUnitatilc = power(2,@u)
		ELSE
			SELECT @frac=z.Text+'Si'+u.Text
			from Unitatilc u, Zeci z
			where u.Cifra = @u
			AND z.Cifra = @z
		
		set @text=@text+'Lei'+'Si'+@frac+'Bani'
	end
	else
		set @text=@text+'Lei'
	--set @text=replace(@text,'DoiMii','DouaMii')+right(@frac,len(@frac)-1) -- si DoiMii ->DouaMii     
	set @text=replace(@text,'DoiMii','DouaMii')
	if @va=1 set @text='Minus '+@text
	--</zecimale>    
	RETURN @text    
END 
