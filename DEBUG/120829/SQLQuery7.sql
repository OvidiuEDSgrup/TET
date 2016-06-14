	--/*
	select *
--*/	DELETE
	FROM pozdoc
	WHERE subunitate = '1'
		AND tip = 'TE'
		--AND stare = 5
		AND data BETWEEN '2012-08-29'
			AND '2012-08-29'
		AND ( gestiune_primitoare like '21_' or Gestiune like '21_' )
		--and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )
		--AND charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0
		--AND (@codMeniu='RF' or Numar = @NrDoc)