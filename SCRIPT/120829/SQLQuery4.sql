	DELETE
	FROM pozdoc
	WHERE subunitate = '1'
		AND tip = 'TE'
		--AND stare = 5
		AND data BETWEEN '2012-08-29'
			AND @datasus
		AND ( gestiune_primitoare = @gestiune or Gestiune=@gestiune )
		--and Gestiune in (select top 1 [dbo].[fStrToken](val_alfanumerica, 1, ';') from par where Tip_parametru='PG' and Parametru=@Gestiune )
		--AND charindex(';' + rtrim(gestiune) + ';', @listagestiuni) > 0
		AND (@codMeniu='RF' or Numar = @NrDoc)