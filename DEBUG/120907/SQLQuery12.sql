/** Coloana idPozDoc in PozDoc **/
IF EXISTS (
		SELECT 1
		FROM sysobjects
		WHERE NAME = 'PozDoc'
		)
	AND NOT EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'PozDoc'
			AND sc.NAME = 'rowguid'
		)
	AND NOT EXISTS (
		SELECT 1
		FROM syscolumns sc, sysobjects so
		WHERE so.id = sc.id
			AND so.NAME = 'PozDoc'
			AND sc.NAME = 'idPozDoc'
		)
	ALTER TABLE PozDoc ADD idPozDoc INT identity (1, 1) PRIMARY KEY
